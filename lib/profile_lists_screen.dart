import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'TVShows_Details.dart';
import 'TVShows_Model.dart';
import 'Upcomming_Movies_model.dart';
import 'services/user_service.dart';

class ProfileListsScreen extends StatefulWidget {
  final String listType; // 'favorites', 'watchlist', 'reviews'
  final String title;

  const ProfileListsScreen({
    super.key,
    required this.listType,
    required this.title,
  });

  @override
  State<ProfileListsScreen> createState() => _ProfileListsScreenState();
}

class _ProfileListsScreenState extends State<ProfileListsScreen> {
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _email = prefs.getString('email') ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                  Text(widget.title, style: AppTheme.headingMedium),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.listType == 'favorites') {
      return StreamBuilder<QuerySnapshot>(
        stream: UserService.favoritesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.accent, strokeWidth: 2));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState(
                'No favorites yet', Icons.favorite_border_rounded);
          }
          return _mediaGrid(snapshot.data!.docs, canDelete: true,
              onDelete: (doc) {
            final d = doc.data() as Map<String, dynamic>;
            UserService.removeFavorite(
                d['media_type'], d['id']);
          });
        },
      );
    }

    if (widget.listType == 'watchlist') {
      return StreamBuilder<QuerySnapshot>(
        stream: UserService.watchlistStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.accent, strokeWidth: 2));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState(
                'Watchlist is empty', Icons.bookmark_border_rounded);
          }
          return _mediaGrid(snapshot.data!.docs, canDelete: true,
              onDelete: (doc) {
            final d = doc.data() as Map<String, dynamic>;
            UserService.removeFromWatchlist(
                d['media_type'], d['id']);
          });
        },
      );
    }

    // Reviews
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: _email)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 2));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState('No reviews yet', Icons.rate_review_outlined);
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final d = doc.data() as Map<String, dynamic>;
            final rating = (d['rating'] as num?)?.toDouble();
            final ts = d['createdAt'] as Timestamp?;
            final date = ts != null
                ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['mediaTitle'] ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (date.isNotEmpty)
                              Text(date, style: AppTheme.caption),
                          ],
                        ),
                      ),
                      if (rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.accent.withOpacity(0.3),
                                width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppTheme.accent, size: 12),
                              const SizedBox(width: 3),
                              Text(rating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => doc.reference.delete(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.error, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d['content'] ?? '',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyText.copyWith(fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _mediaGrid(
    List<QueryDocumentSnapshot> docs, {
    bool canDelete = false,
    Function(QueryDocumentSnapshot)? onDelete,
  }) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.58,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final d = doc.data() as Map<String, dynamic>;
        final isMovie = d['media_type'] == 'movie';
        final title = isMovie ? (d['title'] ?? '') : (d['name'] ?? '');
        final poster = d['poster_path'] as String?;
        final rating = (d['vote_average'] as num?)?.toDouble() ?? 0.0;

        return GestureDetector(
          onTap: () {
            if (isMovie) {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Moviedetails(
                        movie: UpcomingMovies.fromJson(
                            Map<String, dynamic>.from(d))),
                  ),
                );
              } catch (_) {}
            } else {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TVShowsDetails(
                        tvshowsdetails: PopularTvShows.fromJson(
                            Map<String, dynamic>.from(d))),
                  ),
                );
              } catch (_) {}
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 155,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      poster != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w300/$poster',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: AppTheme.cardBg),
                            )
                          : Container(color: AppTheme.cardBg),
                      // Rating badge
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppTheme.accent, size: 9),
                              const SizedBox(width: 2),
                              Text(rating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.accent,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      // Delete button
                      if (canDelete && onDelete != null)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: GestureDetector(
                            onTap: () => onDelete(doc),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 60),
          const SizedBox(height: 12),
          Text(msg, style: AppTheme.bodyText),
          const SizedBox(height: 6),
          Text('Items you add will appear here', style: AppTheme.caption),
        ],
      ),
    );
  }
}
