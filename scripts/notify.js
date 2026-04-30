const axios = require('axios');
const admin = require('firebase-admin');

// ── Init Firebase Admin from GitHub Secret ────────────────────────────────────
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: process.env.FIREBASE_PROJECT_ID,
});

const TMDB_API_KEY = process.env.TMDB_API_KEY;
const TMDB_BASE = 'https://api.themoviedb.org/3';
const TMDB_IMG = 'https://image.tmdb.org/t/p/w500';

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const today = getTodayPKT();
  console.log(`🗓  Checking new releases for: ${today}`);

  const [movies, tvShows] = await Promise.all([
    fetchMovies(today),
    fetchTVShows(today),
  ]);

  const all = [...movies, ...tvShows];
  console.log(`📦 Found ${all.length} releases today`);

  if (all.length === 0) {
    console.log('No new releases today. Exiting.');
    process.exit(0);
  }

  // Max 5 notifications per day to avoid spam
  const toNotify = all.slice(0, 5);

  for (const item of toNotify) {
    const alreadyDone = await checkNotified(item.id, item.type);
    if (alreadyDone) {
      console.log(`⏭  Already notified: ${item.title}`);
      continue;
    }

    await sendNotification(item);
    await markNotified(item.id, item.type, today);
    await sleep(600);
  }

  console.log('✅ Done!');
  process.exit(0);
}

// ── Fetch movies releasing today ──────────────────────────────────────────────
async function fetchMovies(today) {
  try {
    const res = await axios.get(`${TMDB_BASE}/discover/movie`, {
      params: {
        api_key: TMDB_API_KEY,
        'primary_release_date.gte': today,
        'primary_release_date.lte': today,
        sort_by: 'popularity.desc',
        page: 1,
      },
    });
    return (res.data.results || []).map((m) => ({
      id: m.id,
      type: 'movie',
      title: m.title || 'Unknown Movie',
      overview: m.overview || '',
      posterPath: m.poster_path || null,
      rating: m.vote_average || 0,
      releaseDate: today,
    }));
  } catch (e) {
    console.error('Error fetching movies:', e.message);
    return [];
  }
}

// ── Fetch TV shows with first air date today ──────────────────────────────────
async function fetchTVShows(today) {
  try {
    const res = await axios.get(`${TMDB_BASE}/discover/tv`, {
      params: {
        api_key: TMDB_API_KEY,
        'first_air_date.gte': today,
        'first_air_date.lte': today,
        sort_by: 'popularity.desc',
        page: 1,
      },
    });
    return (res.data.results || []).map((s) => ({
      id: s.id,
      type: 'tv',
      title: s.name || 'Unknown Show',
      overview: s.overview || '',
      posterPath: s.poster_path || null,
      rating: s.vote_average || 0,
      releaseDate: today,
    }));
  } catch (e) {
    console.error('Error fetching TV shows:', e.message);
    return [];
  }
}

// ── Send FCM notification to topic ───────────────────────────────────────────
async function sendNotification(item) {
  const isMovie = item.type === 'movie';
  const emoji = isMovie ? '🎬' : '📺';
  const typeLabel = isMovie ? 'New Movie' : 'New TV Show';
  const posterUrl = item.posterPath ? `${TMDB_IMG}${item.posterPath}` : null;

  const shortOverview =
    item.overview.length > 100
      ? item.overview.substring(0, 97) + '...'
      : item.overview || 'Now available to watch!';

  const message = {
    topic: 'new_releases',
    notification: {
      title: `${emoji} ${typeLabel}: ${item.title}`,
      body: shortOverview,
      ...(posterUrl && { imageUrl: posterUrl }),
    },
    android: {
      notification: {
        imageUrl: posterUrl || undefined,
        color: '#F5C518',
        channelId: 'cineverse_high_importance',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true,
        ticker: `New release: ${item.title}`,
      },
      priority: 'high',
    },
    data: {
      screen: 'home',
      mediaId: String(item.id),
      mediaType: item.type,
      mediaTitle: item.title,
      posterPath: item.posterPath || '',
      releaseDate: item.releaseDate,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
  };

  await admin.messaging().send(message);
  console.log(`✅ Sent: ${item.title} (${item.type})`);
}

// ── Firestore duplicate check ─────────────────────────────────────────────────
async function checkNotified(mediaId, mediaType) {
  const doc = await admin
    .firestore()
    .collection('notified_releases')
    .doc(`${mediaType}_${mediaId}`)
    .get();
  return doc.exists;
}

async function markNotified(mediaId, mediaType, date) {
  await admin
    .firestore()
    .collection('notified_releases')
    .doc(`${mediaType}_${mediaId}`)
    .set({
      mediaId,
      mediaType,
      notifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      releaseDate: date,
    });
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function getTodayPKT() {
  const now = new Date();
  const pkt = new Date(now.getTime() + 5 * 60 * 60 * 1000);
  return pkt.toISOString().split('T')[0];
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

main().catch((e) => {
  console.error('Fatal error:', e);
  process.exit(1);
});
