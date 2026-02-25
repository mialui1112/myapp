import type { Context, ScheduledEvent } from "@netlify/functions";
import * as admin from "firebase-admin";
import axios from "axios";

// --- Cấu hình Firebase Admin SDK ---
// Đọc thông tin xác thực từ biến môi trường của Netlify
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY || '{}');

// Khởi tạo app Firebase chỉ một lần
if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// --- Các Interfaces (giống hệt như trước) ---
interface FavoriteManga {
  name: string;
  thumb_url: string;
  endpoint: string;
  last_chapter_name?: string;
}

interface ApiChapter {
  server_name: string;
  server_data: {
    name: string;
    slug: string;
    filename: string;
    chapter_name: string;
    chapter_title: string;
    chapter_api_data: string;
  }[];
}

// --- Logic của hàm (gần như giống hệt) ---

/**
 * Fetches the latest chapters for a given manga endpoint.
 */
async function getLatestChaptersFromApi(endpoint: string): Promise<ApiChapter[]> {
  try {
    const baseUrl = "https://otruyen-api.calm.workers.dev/manga/";
    const url = `${baseUrl}${endpoint}`;
    const response = await axios.get(url);
    return response.data?.item?.chapters ?? [];
  } catch (error) {
    console.error(`Failed to fetch chapters for ${endpoint}:`, error);
    return [];
  }
}

/**
 * Sends notifications to a list of users.
 */
async function sendNotificationToUsers(userIds: string[], mangaName: string, chapterName: string, imageUrl: string) {
  for (const userId of userIds) {
    const tokensSnapshot = await db.collection("users").doc(userId).collection("tokens").get();
    if (tokensSnapshot.empty) continue;

    const tokens = tokensSnapshot.docs.map(doc => doc.id);
    const message: admin.messaging.MulticastMessage = {
      notification: {
        title: `New Chapter: ${mangaName}`,
        body: chapterName,
        imageUrl: imageUrl,
      },
      tokens: tokens,
      webpush: { notification: { icon: imageUrl } },
      android: { notification: { imageUrl: imageUrl } },
      apns: { payload: { aps: { "mutable-content": 1 } }, fcmOptions: { imageUrl: imageUrl } },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Sent to ${response.successCount} devices for ${userId}.`);

      if (response.failureCount > 0) {
        const tokensToRemove: Promise<FirebaseFirestore.WriteResult>[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const failedToken = tokens[idx];
            const errorCode = resp.error?.code;
            if (errorCode === "invalid-registration-token" || errorCode === "registration-token-not-registered") {
              const tokenRef = db.collection("users").doc(userId).collection("tokens").doc(failedToken);
              tokensToRemove.push(tokenRef.delete());
            }
          }
        });
        await Promise.all(tokensToRemove);
        console.log(`Cleaned up ${tokensToRemove.length} invalid tokens.`);
      }
    } catch (error) {
      console.error(`Error sending to user ${userId}:`, error);
    }
  }
}

// --- Điểm vào của Netlify Function ---
const handler = async (event: ScheduledEvent, context: Context) => {
  console.log("Starting chapter check job triggered by Netlify Cron.");

  const favoritesSnapshot = await db.collectionGroup("favorites").get();
  if (favoritesSnapshot.empty) {
    console.log("No favorited manga found. Exiting job.");
    return { statusCode: 200, body: "No favorites found." };
  }

  const uniqueMangas = new Map<string, FavoriteManga>();
  favoritesSnapshot.forEach(doc => {
    const manga = doc.data() as FavoriteManga;
    if (manga.endpoint) {
      uniqueMangas.set(manga.endpoint, manga);
    }
  });

  console.log(`Found ${uniqueMangas.size} unique manga to check.`);

  for (const [endpoint, mangaData] of uniqueMangas.entries()) {
    const chapterGroups = await getLatestChaptersFromApi(endpoint);
    if (chapterGroups.length === 0 || chapterGroups[0].server_data.length === 0) continue;

    const latestChapter = chapterGroups[0].server_data[0];
    const latestChapterName = latestChapter.chapter_name;
    const storedLatestChapter = mangaData.last_chapter_name;

    if (latestChapterName !== storedLatestChapter) {
      console.log(`New chapter for ${mangaData.name}! New: "${latestChapterName}", Old: "${storedLatestChapter}"`);

      const usersToNotifySnapshot = await db.collectionGroup("favorites").where("endpoint", "==", endpoint).get();
      const userIds: string[] = usersToNotifySnapshot.docs.map(doc => doc.ref.parent.parent?.id).filter((id): id is string => !!id);

      await sendNotificationToUsers(userIds, mangaData.name, latestChapterName, mangaData.thumb_url);

      const batch = db.batch();
      usersToNotifySnapshot.forEach(doc => {
        batch.update(doc.ref, { last_chapter_name: latestChapterName });
      });
      await batch.commit();
      console.log(`Updated last_chapter_name for ${mangaData.name}`);
    }
  }

  console.log("Chapter check job finished.");
  return { statusCode: 200, body: "Job finished successfully." };
};

export { handler };
