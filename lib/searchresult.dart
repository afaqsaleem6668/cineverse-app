import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'Upcomming_Movies_model.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late Future<List<UpcomingMovies>> _searchResults;

  @override
  void initState() {
    super.initState();
    _searchResults = _searchMovies(widget.query);
  }

  Future<List<UpcomingMovies>> _searchMovies(String query) async {
    final response = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/search/movie?api_key=e850641520c5c6eacf9b2f679e373ff4&query=$query'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['results'] as List;
      return data.map((json) => UpcomingMovies.fromJson(json)).toList();
    }
    throw Exception('Failed to load movies');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Results', style: AppTheme.headingMedium),
            Text('"${widget.query}"', style: AppTheme.caption),
          ],
        ),
        elevation: 0,
      ),
      body: FutureBuilder<List<UpcomingMovies>>(
        future: _searchResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.accent, strokeWidth: 2));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_rounded,
                      color: AppTheme.textMuted, size: 60),
                  const SizedBox(height: 12),
                  Text('No results found', style: AppTheme.bodyText),
                ],
              ),
            );
          }
          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.6,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final movie = snapshot.data![index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => Moviedetails(movie: movie)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              'https://image.tmdb.org/t/p/w500/${movie.posterPath}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.cardBg,
                                child: const Icon(Icons.movie_rounded,
                                    color: AppTheme.textMuted),
                              ),
                            ),
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
                                    Text(
                                      movie.voteAverage.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                          color: AppTheme.accent,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      movie.title,
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
        },
      ),
    );
  }
}
