const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

const TMDB_API_KEY = 'e850641520c5c6eacf9b2f679e373ff4';
const TMDB_BASE = 'https://api.themoviedb.org/3';
const TMDB_IMG = 'https://image.tmdb.org/t/p/w500';

// ─────────────────────────────────────────────────────────────────────────────
// Scheduled function: runs every day at 10:00 AM Pakistan time (UTC+5 = 05:00 UTC)
// Checks TMDB for movies & TV shows releasing TODAY and sends FCM notifications
// ─────────────────────────────────────────────────────────────────────────────
exports.notifyNewReleases = functions.pubsub
  .schedule('0 5 * * *')   // 05:00 UTC = 10:00 AM PKT
  .timeZone('UTC')
  .onRun(async (context) => {
    const today = getTodayDate(); // YYYY-MM-DD
    console.log(`Checking new releases for: ${today}`);

    try {
      // Fetch movies and TV shows releasing today in parallel
      const [movies, tvShows] = await Promise.all([
        fetchMoviesReleasingToday(today),
        fetchTVShowsReleasingToday(today),
      ]);

      const allReleases = [...movies, ...tvShows];
      console.log(`Found ${allReleases.length} new releases today`);

      if (allReleases.length === 0) return null;

      // Send one notification per release (max 5 to avoid spam)
      const toNotify = allReleases.slice(0, 5);

      for (const item of toNotify) {
        const alreadyNotified = await checkAlreadyNotified(item.id, item.type);
        if (alreadyNotified) continue;

        await sendReleaseNotification(item);
        await markAsNotified(item.id, item.type, today);

        // Small delay between notifications
        await sleep(500);
      }

      return null;
    } catch (error) {
      console.error('Error in notifyNewReleases:', error);
      return null;
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// Fetch movies releasing today from TMDB
// ─────────────────────────────────────────────────────────────────────────────
async function fetchMoviesReleasingToday(today) {
  try {
    const res = await axios.get(`${TMDB_BASE}/discover/movie`, {
      params: {
        api_key: TMDB_API_KEY,
        'primary_release_date.gte': today,
        'primary_release_date.lte': today,
        sort_by: 'popularity.desc',
        'vote_count.gte': 0,
        page: 1,
      },
    });

    return (res.data.results || []).map((movie) => ({
      id: movie.id,
      type: 'movie',
      title: movie.title || 'Unknown Movie',
      overview: movie.overview || '',
      posterPath: movie.poster_path || null,
      rating: movie.vote_average || 0,
      releaseDate: movie.release_date || today,
    }));
  } catch (err) {
    console.error('Error fetching movies:', err.message);
    return [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fetch TV shows with first air date today from TMDB
// ─────────────────────────────────────────────────────────────────────────────
async function fetchTVShowsReleasingToday(today) {
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

    return (res.data.results || []).map((show) => ({
      id: show.id,
      type: 'tv',
      title: show.name || 'Unknown Show',
      overview: show.overview || '',
      posterPath: show.poster_path || null,
      rating: show.vote_average || 0,
      releaseDate: show.first_air_date || today,
    }));
  } catch (err) {
    console.error('Error fetching TV shows:', err.message);
    return [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Send FCM notification to 'new_releases' topic
// ─────────────────────────────────────────────────────────────────────────────
async function sendReleaseNotification(item) {
  const isMovie = item.type === 'movie';
  const typeLabel = isMovie ? '🎬 New Movie' : '📺 New TV Show';
  const posterUrl = item.posterPath
    ? `${TMDB_IMG}${item.posterPath}`
    : null;

  // Short overview (max 100 chars)
  const shortOverview = item.overview.length > 100
    ? item.overview.substring(0, 97) + '...'
    : item.overview;

  const message = {
    topic: 'new_releases',
    notification: {
      title: `${typeLabel}: ${item.title}`,
      body: shortOverview || `Now available to watch!`,
      ...(posterUrl && { imageUrl: posterUrl }),
    },
    android: {
      notification: {
        // Big picture style — shows poster image in expanded notification
        imageUrl: posterUrl || undefined,
        color: '#F5C518',          // CineVerse gold accent color
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        channelId: 'cineverse_high_importance',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true,
        // Ticker text shown in status bar
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
  console.log(`✅ Notification sent for: ${item.title} (${item.type})`);
}

// ─────────────────────────────────────────────────────────────────────────────
// Firestore helpers — prevent duplicate notifications
// ─────────────────────────────────────────────────────────────────────────────
async function checkAlreadyNotified(mediaId, mediaType) {
  const doc = await admin
    .firestore()
    .collection('notified_releases')
    .doc(`${mediaType}_${mediaId}`)
    .get();
  return doc.exists;
}

async function markAsNotified(mediaId, mediaType, date) {
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

// ─────────────────────────────────────────────────────────────────────────────
// Utility
// ─────────────────────────────────────────────────────────────────────────────
function getTodayDate() {
  const now = new Date();
  // Convert to PKT (UTC+5)
  const pkt = new Date(now.getTime() + 5 * 60 * 60 * 1000);
  return pkt.toISOString().split('T')[0]; // YYYY-MM-DD
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
