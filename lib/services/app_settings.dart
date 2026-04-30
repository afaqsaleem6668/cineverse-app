import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central settings reader — use anywhere in the app.
/// Reads from SharedPreferences (fast, local).
/// Settings are saved to both SharedPreferences + Firestore by SettingsScreen.
class AppSettings {
  static Future<bool> showRatings() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('show_ratings') ?? true;
  }

  static Future<bool> showVoteCount() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('show_vote_count') ?? true;
  }

  static Future<bool> showAdult() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('show_adult') ?? false;
  }

  static Future<String> defaultRegion() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('default_region') ?? 'PK';
  }

  static Future<String> defaultLanguage() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('default_language') ?? 'en';
  }

  static Future<String> imageQuality() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('image_quality') ?? 'High';
  }

  /// Returns TMDB image size based on quality setting
  static Future<String> imageSize() async {
    final q = await imageQuality();
    switch (q) {
      case 'Low':
        return 'w185';
      case 'Medium':
        return 'w342';
      case 'High':
      default:
        return 'w500';
    }
  }

  /// Syncs settings from Firestore → SharedPreferences.
  /// Call this on app start (after login) to restore settings on new devices.
  static Future<void> syncFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('preferences')
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final prefs = await SharedPreferences.getInstance();

      if (data['show_ratings'] != null) {
        await prefs.setBool('show_ratings', data['show_ratings'] as bool);
      }
      if (data['show_vote_count'] != null) {
        await prefs.setBool(
            'show_vote_count', data['show_vote_count'] as bool);
      }
      if (data['show_adult'] != null) {
        await prefs.setBool('show_adult', data['show_adult'] as bool);
      }
      if (data['default_region'] != null) {
        await prefs.setString(
            'default_region', data['default_region'] as String);
      }
      if (data['default_language'] != null) {
        await prefs.setString(
            'default_language', data['default_language'] as String);
      }
      if (data['image_quality'] != null) {
        await prefs.setString(
            'image_quality', data['image_quality'] as String);
      }
      if (data['notif_new_releases'] != null) {
        await prefs.setBool(
            'notif_new_releases', data['notif_new_releases'] as bool);
      }
      if (data['notif_review_replies'] != null) {
        await prefs.setBool(
            'notif_review_replies', data['notif_review_replies'] as bool);
      }
      if (data['notif_recommendations'] != null) {
        await prefs.setBool(
            'notif_recommendations', data['notif_recommendations'] as bool);
      }
    } catch (_) {
      // Silently fail — local prefs will be used as fallback
    }
  }
}
