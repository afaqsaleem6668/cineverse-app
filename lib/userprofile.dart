import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'auth_screen.dart';
import 'services/user_service.dart';
import 'profile_lists_screen.dart';
import 'manage_account_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key, required this.username});
  final dynamic username;

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String _email = '';
  String _currentUsername = '';

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.username.toString();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _email = prefs.getString('email') ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header gradient banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar with first letter
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withOpacity(0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentUsername.isNotEmpty
                              ? _currentUsername[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_currentUsername, style: AppTheme.headingMedium),
                    const SizedBox(height: 4),
                    Text(
                      _email.isNotEmpty ? _email : 'Movie Enthusiast',
                      style: AppTheme.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Dynamic stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dynamicStat(
                          stream: UserService.watchlistStream()
                              .map((s) => s.docs.length.toString()),
                          label: 'Watchlist',
                        ),
                        Container(
                            width: 1,
                            height: 30,
                            color: AppTheme.divider,
                            margin: const EdgeInsets.symmetric(horizontal: 20)),
                        _dynamicStat(
                          stream: UserService.favoritesStream()
                              .map((s) => s.docs.length.toString()),
                          label: 'Favorites',
                        ),
                        Container(
                            width: 1,
                            height: 30,
                            color: AppTheme.divider,
                            margin: const EdgeInsets.symmetric(horizontal: 20)),
                        _dynamicStat(
                          stream: UserService.reviewsCountStream()
                              .map((c) => c.toString()),
                          label: 'Reviews',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Menu items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.manage_accounts_rounded,
                      label: 'Manage Account',
                      subtitle: _email.isNotEmpty ? _email : null,
                      onTap: () async {
                        final newUsername = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ManageAccountScreen()),
                        );
                        // Update username immediately if changed
                        if (newUsername != null && mounted) {
                          setState(() => _currentUsername = newUsername);
                        }
                      },
                    ),
                    _menuItem(
                      icon: Icons.bookmark_border_rounded,
                      label: 'My Watchlist',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileListsScreen(
                            listType: 'watchlist',
                            title: 'My Watchlist',
                          ),
                        ),
                      ),
                    ),
                    _menuItem(
                      icon: Icons.favorite_border_rounded,
                      label: 'Favorites',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileListsScreen(
                            listType: 'favorites',
                            title: 'Favorites',
                          ),
                        ),
                      ),
                    ),
                    _menuItem(
                      icon: Icons.star_border_rounded,
                      label: 'My Reviews',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileListsScreen(
                            listType: 'reviews',
                            title: 'My Reviews',
                          ),
                        ),
                      ),
                    ),
                    _menuItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    _menuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Sign out
                    GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('islogin', false);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const AuthScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.error.withOpacity(0.3),
                              width: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: AppTheme.error, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Sign Out',
                              style: GoogleFonts.poppins(
                                color: AppTheme.error,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dynamicStat(
      {required Stream<String> stream, required String label}) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snapshot) {
        return Column(
          children: [
            Text(
              snapshot.data ?? '0',
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label, style: AppTheme.caption),
          ],
        );
      },
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.accent, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(subtitle,
                        style: AppTheme.caption,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
