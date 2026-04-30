import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api_cache.dart';
import 'app_theme.dart';
import 'Genre_Model.dart';
import 'Now_Playing_Movies_Widget.dart';
import 'Popular_Movies_Movies2.dart';
import 'Top_Rated_Movies.dart';
import 'UpcomingMovies.dart';
import 'searchresult.dart';
import 'see_all_screen.dart';

const String _moviesApiKey = 'e850641520c5c6eacf9b2f679e373ff4';

class Movies extends StatefulWidget {
  const Movies({super.key});

  @override
  State<Movies> createState() => _MoviesState();
}

class _MoviesState extends State<Movies> {
  List<Genre> genres = [];
  Genre? selectedGenre;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGenres() async {
    const cacheKey = 'movie_genres';
    final cache = ApiCache();
    if (cache.has(cacheKey)) {
      setState(() => genres = cache.get<List<Genre>>(cacheKey)!);
      return;
    }
    try {
      final response = await http.get(Uri.parse(
          'https://api.themoviedb.org/3/genre/movie/list?api_key=e850641520c5c6eacf9b2f679e373ff4'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['genres'] as List;
        final result = data.map((json) => Genre.fromJson(json)).toList();
        cache.set(cacheKey, result);
        setState(() => genres = result);
      }
    } catch (_) {}
  }

  Widget _sectionHeader(String title, {String? apiUrl, SeeAllType? type}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTheme.sectionTitle),
            ],
          ),
          if (apiUrl != null && type != null)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SeeAllScreen(title: title, apiUrl: apiUrl, type: type),
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.3), width: 0.5),
                ),
                child: Text('See all', style: AppTheme.accentText),
              ),
            ),
        ],
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Movies', style: AppTheme.headingMedium),
                  const Spacer(),
                  if (selectedGenre != null)
                    GestureDetector(
                      onTap: () => setState(() => selectedGenre = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.accent.withOpacity(0.4),
                              width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Text(selectedGenre!.name,
                                style: AppTheme.accentText),
                            const SizedBox(width: 4),
                            const Icon(Icons.close_rounded,
                                color: AppTheme.accent, size: 14),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary, fontSize: 14),
                decoration: AppTheme.searchDecoration('Search movies...'),
                onSubmitted: (search) {
                  if (search.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SearchResultsScreen(query: search)),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 14),
            // Genre chips
            if (genres.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    final isSelected = selectedGenre?.id == genre.id;
                    return GestureDetector(
                      onTap: () {
                        // Synchronous setState — no Future inside setState
                        final newGenre = isSelected ? null : genre;
                        setState(() => selectedGenre = newGenre);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppTheme.goldGradient : null,
                          color: isSelected ? null : AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppTheme.divider,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          genre.name,
                          style: GoogleFonts.poppins(
                            color: isSelected
                                ? Colors.black
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Popular Movies',
                        apiUrl: 'https://api.themoviedb.org/3/movie/popular?api_key=$_moviesApiKey',
                        type: SeeAllType.movies),
                    SizedBox(
                        height: 260,
                        child: PopularMoviesMovies2(
                          key: ValueKey('pop_movies_${selectedGenre?.id}'),
                          selectedGenre: selectedGenre,
                        )),
                    const SizedBox(height: 28),
                    _sectionHeader('Upcoming Movies',
                        apiUrl: 'https://api.themoviedb.org/3/movie/upcoming?api_key=$_moviesApiKey',
                        type: SeeAllType.movies),
                    SizedBox(
                        height: 260,
                        child: UpcomingMoviesWidget(
                          key: ValueKey('upcoming_movies_${selectedGenre?.id}'),
                          selectedGenre: selectedGenre,
                        )),
                    const SizedBox(height: 28),
                    _sectionHeader('Now Playing',
                        apiUrl: 'https://api.themoviedb.org/3/movie/now_playing?api_key=$_moviesApiKey',
                        type: SeeAllType.movies),
                    SizedBox(
                        height: 260,
                        child: Now_Playing_Movies_Widget(
                          key: ValueKey('now_playing_${selectedGenre?.id}'),
                          selectedGenre: selectedGenre,
                        )),
                    const SizedBox(height: 28),
                    _sectionHeader('Top Rated',
                        apiUrl: 'https://api.themoviedb.org/3/movie/top_rated?api_key=$_moviesApiKey',
                        type: SeeAllType.movies),
                    SizedBox(
                        height: 260,
                        child: TopRatedMovies(
                          key: ValueKey('top_rated_movies_${selectedGenre?.id}'),
                          selectedGenre: selectedGenre,
                        )),
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
}
