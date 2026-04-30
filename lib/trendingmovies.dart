import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'Upcomming_Movies_model.dart';

class PopularMovies extends StatefulWidget {
  const PopularMovies({Key? key}) : super(key: key);

  @override
  _PopularMoviesState createState() => _PopularMoviesState();
}

class _PopularMoviesState extends State<PopularMovies> {
  static List<UpcomingMovies>? _cache;
  late Future<List<UpcomingMovies>> _future;

  @override
  void initState() {
    super.initState();
    _future = _cache != null ? Future.value(_cache) : _fetchData();
  }

  Future<List<UpcomingMovies>> _fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/movie/popular?api_key=e850641520c5c6eacf9b2f679e373ff4'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['results'] as List;
      _cache = data.map((json) => UpcomingMovies.fromJson(json)).toList();
      return _cache!;
    }
    throw Exception('Failed to load data');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UpcomingMovies>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 2));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No data', style: TextStyle(color: AppTheme.textMuted)));
        }
        final movies = snapshot.data!;
        return CarouselSlider.builder(
          itemCount: movies.length,
          itemBuilder: (context, index, _) {
            final movie = movies[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => Moviedetails(movie: movie)),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'carousel_${movie.id}',
                        child: Image.network(
                          'https://image.tmdb.org/t/p/w500/${movie.posterPath}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.cardBg,
                            child: const Icon(Icons.movie_rounded,
                                color: AppTheme.textMuted, size: 50),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xDD000000),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.5, 1.0],
                          ),
                        ),
                      ),
                      // Title + rating at bottom
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
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
                                  movie.voteAverage.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppTheme.accent.withOpacity(0.4),
                                        width: 0.5),
                                  ),
                                  child: Text(
                                    'Popular',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
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
