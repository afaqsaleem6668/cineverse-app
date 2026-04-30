import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'TVShows_Details.dart';
import 'TVShows_Model.dart';
import 'Upcomming_Movies_model.dart';

const String _trendKey = 'e850641520c5c6eacf9b2f679e373ff4';

class TrendingCarousel extends StatelessWidget {
  const TrendingCarousel({super.key});

  Future<List<Map<String, dynamic>>> _fetchTrending() async {
    final movieRes = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/trending/movie/day?api_key=$_trendKey'));
    final tvRes = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/trending/tv/day?api_key=$_trendKey'));

    List<Map<String, dynamic>> combined = [];
    if (movieRes.statusCode == 200) {
      final data = jsonDecode(movieRes.body)['results'] as List;
      combined.addAll(data.take(10).map((e) => {...e, 'media': 'movie'}));
    }
    if (tvRes.statusCode == 200) {
      final data = jsonDecode(tvRes.body)['results'] as List;
      combined.addAll(data.take(10).map((e) => {...e, 'media': 'tv'}));
    }
    combined.shuffle();
    return combined.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTrending(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 380,
            child: Center(
                child: CircularProgressIndicator(
                    color: AppTheme.accent, strokeWidth: 2)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data!;
        return CarouselSlider.builder(
          itemCount: items.length,
          itemBuilder: (context, index, _) {
            final item = items[index];
            final isMovie = item['media'] == 'movie';
            final title = isMovie
                ? (item['title'] ?? item['original_title'] ?? '')
                : (item['name'] ?? item['original_name'] ?? '');
            final poster = item['poster_path'] ?? '';
            final rating = (item['vote_average'] as num?)?.toDouble() ?? 0.0;

            return GestureDetector(
              onTap: () {
                if (isMovie) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          Moviedetails(movie: UpcomingMovies.fromJson(item)),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TVShowsDetails(
                          tvshowsdetails: PopularTvShows.fromJson(item)),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      poster.isNotEmpty
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w500/$poster',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: AppTheme.cardBg),
                            )
                          : Container(color: AppTheme.cardBg),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xDD000000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.5, 1.0],
                          ),
                        ),
                      ),
                      // Trending badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded,
                                  color: Colors.black, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                'Trending',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Type badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isMovie
                                ? Colors.blue.withOpacity(0.85)
                                : Colors.purple.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isMovie ? 'Movie' : 'TV',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppTheme.accent, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 380,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayCurve: Curves.easeInOutCubic,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: true,
            enlargeFactor: 0.25,
            viewportFraction: 0.78,
          ),
        );
      },
    );
  }
}
