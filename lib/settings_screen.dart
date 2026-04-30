import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification settings
  bool _newReleases = true;
  bool _reviewReplies = true;
  bool _recommendations = false;

  // Content preferences
  bool _showAdult = false;
  String _defaultRegion = 'PK';
  String _defaultLanguage = 'en';

  // Display
  bool _showRatings = true;
  bool _showVoteCount = true;
  String _imageQuality = 'High';

  bool _isSaving = false;

  final List<String> _regions = ['PK', 'US', 'UK', 'IN', 'CA', 'AU'];
  final List<Map<String, String>> _languages = [
    {'value': 'en', 'label': 'English'},
    {'value': 'hi', 'label': 'Hindi'},
    {'value': 'ur', 'label': 'Urdu'},
    {'value': 'ko', 'label': 'Korean'},
    {'value': 'ja', 'label': 'Japanese'},
  ];
  final List<String> _qualities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _newReleases = prefs.getBool('notif_new_releases') ?? true;
        _reviewReplies = prefs.getBool('notif_review_replies') ?? true;
        _recommendations = prefs.getBool('notif_recommendations') ?? false;
        _showAdult = prefs.getBool('show_adult') ?? false;
        _defaultRegion = prefs.getString('default_region') ?? 'PK';
        _defaultLanguage = prefs.getString('default_language') ?? 'en';
        _showRatings = prefs.getBool('show_ratings') ?? true;
        _showVoteCount = prefs.getBool('show_vote_count') ?? true;
        _imageQuality = prefs.getString('image_quality') ?? 'High';
      });
    }
  }

  /// Saves locally to SharedPreferences AND syncs to Firestore in background
  Future<void> _saveSetting(String key, dynamic value) async {
    if (mounted) setState(() => _isSaving = true);

    // 1. Save locally first (instant)
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);

    // 2. Sync to Firestore in background
    _syncToFirestore(key, value);

    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _syncToFirestore(String key, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('preferences')
          .set({key: value}, SetOptions(merge: true));
    } catch (_) {
      // Silently fail — local prefs already saved
    }
  }

  /// Handles FCM topic subscription for notification toggles
  Future<void> _handleNotificationToggle(String topic, bool enabled) async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification permission denied. Enable it in device settings.',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    if (enabled) {
      await messaging.subscribeToTopic(topic);
    } else {
      await messaging.unsubscribeFromTopic(topic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Settings', style: AppTheme.headingMedium),
                  const Spacer(),
                  if (_isSaving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accent,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Notifications ──────────────────────────────────────
                    _sectionHeader(
                        'Notifications', Icons.notifications_outlined),
                    const SizedBox(height: 8),
                    _switchItem(
                      label: 'New Releases',
                      subtitle: 'Get notified about new movies & shows',
                      value: _newReleases,
                      onChanged: (v) async {
                        setState(() => _newReleases = v);
                        await _saveSetting('notif_new_releases', v);
                        await _handleNotificationToggle('new_releases', v);
                      },
                    ),
                    _switchItem(
                      label: 'Review Replies',
                      subtitle: 'When someone replies to your review',
                      value: _reviewReplies,
                      onChanged: (v) async {
                        setState(() => _reviewReplies = v);
                        await _saveSetting('notif_review_replies', v);
                        await _handleNotificationToggle('review_replies', v);
                      },
                    ),
                    _switchItem(
                      label: 'Recommendations',
                      subtitle: 'Personalized movie & show suggestions',
                      value: _recommendations,
                      onChanged: (v) async {
                        setState(() => _recommendations = v);
                        await _saveSetting('notif_recommendations', v);
                        await _handleNotificationToggle('recommendations', v);
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Content Preferences ────────────────────────────────
                    _sectionHeader('Content', Icons.tune_rounded),
                    const SizedBox(height: 8),
                    _switchItem(
                      label: 'Adult Content',
                      subtitle: 'Show adult rated content in results',
                      value: _showAdult,
                      onChanged: (v) {
                        setState(() => _showAdult = v);
                        _saveSetting('show_adult', v);
                      },
                    ),
                    _dropdownItem(
                      label: 'Default Region',
                      subtitle: 'For streaming providers & releases',
                      value: _defaultRegion,
                      items: _regions
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r,
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _defaultRegion = v);
                          _saveSetting('default_region', v);
                        }
                      },
                    ),
                    _dropdownItem(
                      label: 'Default Language',
                      subtitle: 'Preferred content language',
                      value: _defaultLanguage,
                      items: _languages
                          .map((l) => DropdownMenuItem(
                                value: l['value']!,
                                child: Text(l['label']!,
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _defaultLanguage = v);
                          _saveSetting('default_language', v);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Display ────────────────────────────────────────────
                    _sectionHeader(
                        'Display', Icons.display_settings_outlined),
                    const SizedBox(height: 8),
                    _switchItem(
                      label: 'Show Ratings',
                      subtitle: 'Display star ratings on cards',
                      value: _showRatings,
                      onChanged: (v) {
                        setState(() => _showRatings = v);
                        _saveSetting('show_ratings', v);
                      },
                    ),
                    _switchItem(
                      label: 'Show Vote Count',
                      subtitle: 'Display number of votes',
                      value: _showVoteCount,
                      onChanged: (v) {
                        setState(() => _showVoteCount = v);
                        _saveSetting('show_vote_count', v);
                      },
                    ),
                    _dropdownItem(
                      label: 'Image Quality',
                      subtitle: 'Higher quality uses more data',
                      value: _imageQuality,
                      items: _qualities
                          .map((q) => DropdownMenuItem(
                                value: q,
                                child: Text(q,
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _imageQuality = v);
                          _saveSetting('image_quality', v);
                        }
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 16),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _switchItem({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accent,
            activeTrackColor: AppTheme.accent.withOpacity(0.3),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.divider,
          ),
        ],
      ),
    );
  }

  Widget _dropdownItem<T>({
    required String label,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            dropdownColor: AppTheme.surface,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textMuted, size: 18),
            style: GoogleFonts.poppins(
                color: AppTheme.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
