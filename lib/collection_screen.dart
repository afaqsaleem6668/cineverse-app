import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'Upcomming_Movies_model.dart';
import 'models/collection_model.dart';

class CollectionScreen extends StatelessWidget {
  final MovieCollection collection;

  const CollectionScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                collection.name,
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: collection.backdropPath != null
                  ? Image.network(
                      'https://image.tmdb.org/t/p/original${collection.backdropPath}',
                      fit: BoxFit.cover,
                    )
                  : Container(color: AppTheme.cardBg),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${collection.parts.length} Movies',
                    style: AppTheme.accentText,
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: collection.parts.length,
                    itemBuilder: (context, index) {
                      final movie = collection.parts[index];
                      return _CollectionMovieCard(
                        movie: movie,
                        index: index,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionMovieCard extends StatelessWidget {
  final CollectionMovie movie;
  final int index;

  const _CollectionMovieCard({
    required this.movie,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Moviedetails(
              movie: UpcomingMovies(
                adult: movie.adult,
                backdropPath: movie.backdropPath ?? '',
                genreIds: movie.genreIds,
                id: movie.id,
                originalTitle: movie.originalTitle,
                overview: movie.overview,
                popularity: movie.popularity,
                posterPath: movie.posterPath ?? '',
                releaseDate: movie.releaseDate != null
                    ? DateTime.tryParse(movie.releaseDate!)
                    : null,
                title: movie.title,
                video: movie.video,
                voteAverage: movie.voteAverage,
                voteCount: movie.voteCount,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: movie.posterPath != null
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w185${movie.posterPath}',
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 150,
                      color: AppTheme.surface,
                      child: const Icon(Icons.movie_rounded,
                          color: AppTheme.textMuted, size: 40),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (movie.releaseDate != null)
                      Text(
                        movie.releaseDate!,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.accent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            color: AppTheme.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
