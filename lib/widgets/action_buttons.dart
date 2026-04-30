import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/user_service.dart';

/// Favorite + Watchlist buttons for movie/TV detail pages
class MediaActionButtons extends StatelessWidget {
  final int mediaId;
  final String mediaType; // 'movie' or 'tv'
  final String title;
  final String? posterPath;
  final double voteAverage;

  const MediaActionButtons({
    super.key,
    required this.mediaId,
    required this.mediaType,
    required this.title,
    this.posterPath,
    required this.voteAverage,
  });

  Map<String, dynamic> get _itemData => {
        'id': mediaId,
        'media_type': mediaType,
        'title': mediaType == 'movie' ? title : null,
        'name': mediaType == 'tv' ? title : null,
        'poster_path': posterPath,
        'vote_average': voteAverage,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Favorite button
        Expanded(
          child: StreamBuilder<bool>(
            stream: UserService.isFavoriteStream(mediaType, mediaId),
            builder: (context, snapshot) {
              final isFav = snapshot.data ?? false;
              return GestureDetector(
                onTap: () async {
                  if (isFav) {
                    await UserService.removeFavorite(mediaType, mediaId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed from Favorites',
                              style: GoogleFonts.poppins(color: Colors.white)),
                          backgroundColor: AppTheme.cardBg,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    await UserService.addFavorite(_itemData);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to Favorites ❤️',
                              style: GoogleFonts.poppins(color: Colors.white)),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isFav
                        ? AppTheme.error.withOpacity(0.15)
                        : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFav
                          ? AppTheme.error.withOpacity(0.5)
                          : AppTheme.divider,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? AppTheme.error : AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isFav ? 'Favorited' : 'Favorite',
                        style: GoogleFonts.poppins(
                          color: isFav ? AppTheme.error : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        // Watchlist button
        Expanded(
          child: StreamBuilder<bool>(
            stream: UserService.isInWatchlistStream(mediaType, mediaId),
            builder: (context, snapshot) {
              final inWatchlist = snapshot.data ?? false;
              return GestureDetector(
                onTap: () async {
                  if (inWatchlist) {
                    await UserService.removeFromWatchlist(mediaType, mediaId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed from Watchlist',
                              style: GoogleFonts.poppins(color: Colors.white)),
                          backgroundColor: AppTheme.cardBg,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    await UserService.addToWatchlist(_itemData);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to Watchlist 🔖',
                              style: GoogleFonts.poppins(color: Colors.white)),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: inWatchlist
                        ? AppTheme.accent.withOpacity(0.12)
                        : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: inWatchlist
                          ? AppTheme.accent.withOpacity(0.5)
                          : AppTheme.divider,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        inWatchlist
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: inWatchlist
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        inWatchlist ? 'Watchlisted' : 'Watchlist',
                        style: GoogleFonts.poppins(
                          color: inWatchlist
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
