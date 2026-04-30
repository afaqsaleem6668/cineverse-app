import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'api_cache.dart';
import 'app_theme.dart';
import 'Genre_Model.dart';
import 'Movie_Details.dart';
import 'Upcomming_Movies_model.dart';

class PopularMoviesMovies2 extends StatefulWidget {
  final Genre? selectedGenre;
  const PopularMoviesMovies2({Key? key, this.selectedGenre}) : super(key: key);

  @override
  State<PopularMoviesMovies2> createState() => _PopularMoviesMovies2State();
}

class _PopularMoviesMovies2State extends State<PopularMoviesMovies2> {
  late Future<List<UpcomingMovies>> _future;

  @override
  void initState() {
    super.initState();
    final cacheKey = 'popular_movies_${widget.selectedGenre?.id}';
    final cache = ApiCache();
    if (widget.selectedGenre == null && cache.has(cacheKey)) {
      _future = Future.value(cache.get<List<UpcomingMovies>>(cacheKey));
    } else {
      _future = _fetchData();
    }
  }

  @override
  void didUpdateWidget(PopularMoviesMovies2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGenre != widget.selectedGenre) {
      final f = _fetchData();
      setState(() => _future = f);
    }
  }

  Future<List<UpcomingMovies>> _fetchData() async {
    final genreId = widget.selectedGenre?.id;
    final cacheKey = 'popular_movies_$genreId';
    final url = genreId == null
        ? 'https://api.themoviedb.org/3/movie/popular?api_key=e850641520c5c6eacf9b2f679e373ff4'
        : 'https://api.themoviedb.org/3/discover/movie?api_key=e850641520c5c6eacf9b2f679e373ff4&with_genres=$genreId&sort_by=popularity.desc';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['results'] as List;
      final result = data.map((json) => UpcomingMovies.fromJson(json)).toList();
      if (genreId == null) {
        ApiCache().set(cacheKey, result);
      }
      return result;
    }
    return [];
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
              child: Text('No data',
                  style: TextStyle(color: AppTheme.textMuted)));
        }
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final movie = snapshot.data![index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Moviedetails(movie: movie)),
              ),
              child: Container(
                width: 130,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 185,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              'https://image.tmdb.org/t/p/w500/${movie.posterPath}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.cardBg,
                                child: const Icon(Icons.movie_rounded,
                                    color: AppTheme.textMuted, size: 40),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 60,
                                decoration: const BoxDecoration(
                                    gradient: AppTheme.posterOverlay),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppTheme.accent.withOpacity(0.5),
                                      width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: AppTheme.accent, size: 11),
                                    const SizedBox(width: 3),
                                    Text(
                                      movie.voteAverage.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.accent,
                                        fontSize: 10,
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
                    const SizedBox(height: 8),
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
