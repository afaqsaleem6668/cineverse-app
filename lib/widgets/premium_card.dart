import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';

class PremiumMovieCard extends StatefulWidget {
  final String posterPath;
  final String title;
  final double? rating;
  final VoidCallback onTap;
  final String heroTag;
  final double width;
  final double height;

  const PremiumMovieCard({
    Key? key,
    required this.posterPath,
    required this.title,
    this.rating,
    required this.onTap,
    required this.heroTag,
    this.width = 130,
    this.height = 185,
  }) : super(key: key);

  @override
  State<PremiumMovieCard> createState() => _PremiumMovieCardState();
}

class _PremiumMovieCardState extends State<PremiumMovieCard> {
  bool _showRatings = true;
  String _imgSize = 'w500';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showRatings = p.getBool('show_ratings') ?? true;
        final quality = p.getString('image_quality') ?? 'High';
        _imgSize = quality == 'Low'
            ? 'w185'
            : quality == 'Medium'
                ? 'w342'
                : 'w500';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = widget.posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/$_imgSize/${widget.posterPath}'
        : '';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: widget.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imgUrl.isNotEmpty
                        ? Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.posterOverlay,
                        ),
                      ),
                    ),
                    // Rating badge — only if setting is ON
                    if (_showRatings && widget.rating != null)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.72),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: AppTheme.accent.withOpacity(0.5),
                                width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppTheme.accent, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                widget.rating!.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  color: AppTheme.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.cardBg,
      child: const Center(
        child: Icon(Icons.movie_creation_rounded,
            color: AppTheme.textMuted, size: 36),
      ),
    );
  }
}
