import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaq;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I add a movie to my favorites?',
      'a':
          'Open any movie or TV show detail page and tap the ❤️ Favorite button below the title. It will be saved to your Favorites list in your profile.',
    },
    {
      'q': 'How does the CineVerse rating work?',
      'a':
          'The CV rating (shown in purple) is the average of all ratings given by CineVerse users. It\'s separate from the TMDB rating (shown in gold) which comes from the official database.',
    },
    {
      'q': 'Can I write reviews for TV show episodes?',
      'a':
          'Yes! Open a TV show, go to Seasons & Episodes, tap any episode, and scroll down to find the Reviews section.',
    },
    {
      'q': 'How do I search with filters?',
      'a':
          'On the home screen, tap the compass icon (🧭) next to the search bar to open the Discover screen. Set your filters and tap Discover.',
    },
    {
      'q': 'Why is a trailer not showing?',
      'a':
          'Some movies and shows don\'t have trailers available on TMDB. In that case, the Photos section will be shown instead.',
    },
    {
      'q': 'How do I change my username?',
      'a':
          'Go to Profile → Manage Account → tap the edit icon next to your username → enter new name → Save.',
    },
    {
      'q': 'How do I reset my password?',
      'a':
          'Go to Profile → Manage Account → Change Password. A reset link will be sent to your email.',
    },
    {
      'q': 'What is the Watchlist?',
      'a':
          'Watchlist is a list of movies and shows you want to watch later. Tap the 🔖 Watchlist button on any detail page to add it.',
    },
  ];

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
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Help & Support', style: AppTheme.headingMedium),
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
                    // Quick links
                    _sectionHeader('Quick Help', Icons.flash_on_rounded),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _quickCard(
                            icon: Icons.movie_rounded,
                            label: 'How to use',
                            color: AppTheme.accent,
                            onTap: () => setState(() => _expandedFaq = 0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickCard(
                            icon: Icons.star_rounded,
                            label: 'Reviews',
                            color: const Color(0xFF6C63FF),
                            onTap: () => setState(() => _expandedFaq = 2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickCard(
                            icon: Icons.search_rounded,
                            label: 'Search',
                            color: Colors.blue,
                            onTap: () => setState(() => _expandedFaq = 3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // FAQ
                    _sectionHeader('Frequently Asked Questions',
                        Icons.help_outline_rounded),
                    const SizedBox(height: 10),
                    ..._faqs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final faq = entry.value;
                      final isExpanded = _expandedFaq == i;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _expandedFaq = isExpanded ? null : i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? AppTheme.accent.withOpacity(0.06)
                                : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isExpanded
                                  ? AppTheme.accent.withOpacity(0.3)
                                  : AppTheme.divider,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      faq['q']!,
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                ],
                              ),
                              if (isExpanded) ...[
                                const SizedBox(height: 10),
                                Text(
                                  faq['a']!,
                                  style: AppTheme.bodyText
                                      .copyWith(fontSize: 12, height: 1.5),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Contact
                    _sectionHeader('Contact Us', Icons.contact_support_rounded),
                    const SizedBox(height: 10),
                    _contactItem(
                      icon: Icons.email_outlined,
                      label: 'Email Support',
                      subtitle: 'afaq.saleem6668@gmail.com',
                      onTap: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'afaq.saleem6668@gmail.com',
                          queryParameters: {
                            'subject': 'CineVerse App Support',
                          },
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    _contactItem(
                      icon: Icons.bug_report_outlined,
                      label: 'Report a Bug',
                      subtitle: 'afaq.saleem6668@gmail.com',
                      onTap: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'afaq.saleem6668@gmail.com',
                          queryParameters: {
                            'subject': 'CineVerse Bug Report',
                            'body':
                                'Bug Description:\n\nSteps to reproduce:\n1. \n2. \n\nExpected behavior:\n\nActual behavior:\n\nDevice info:\n',
                          },
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // App info
                    _sectionHeader('App Info', Icons.info_outline_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          _infoRow('App Name', 'CineVerse'),
                          _infoRow('Version', '1.0.0'),
                        ],
                      ),
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

  Widget _quickCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _contactItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
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
            const Icon(Icons.open_in_new_rounded,
                color: AppTheme.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppTheme.textMuted, fontSize: 12)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
