import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'Movies.dart';
import 'TVShows.dart';
import 'homescreen.dart';
import 'userprofile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key, required this.username}) : super(key: key);
  final dynamic username;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final labels = ['Home', 'Movies', 'TV Shows', 'Profile'];
    final icons = [
      Icons.home_rounded,
      Icons.movie_creation_rounded,
      Icons.live_tv_rounded,
      Icons.person_rounded,
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      // Use simple switch — only active screen is in tree, no GlobalKey conflicts
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.navBg,
          border: Border(
            top: BorderSide(color: AppTheme.divider, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (i) {
                final selected = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accent.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[i],
                          color: selected ? AppTheme.accent : AppTheme.textMuted,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[i],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color:
                                selected ? AppTheme.accent : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const Homescreen();
      case 1:
        return const Movies();
      case 2:
        return const TVSHOWS();
      case 3:
        return UserProfile(username: widget.username);
      default:
        return const Homescreen();
    }
  }
}
