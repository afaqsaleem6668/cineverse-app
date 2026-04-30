import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'HomeScreen_Search.dart';
import 'Now_Playing_Movies_Widget.dart';
import 'OnTheAir.dart';
import 'Popular_TVShows.dart';
import 'Top_Rated_Movies.dart';
import 'TopRated_TVShow.dart';
import 'UpcomingMovies.dart';
import 'Upcomming_Movies_model.dart';
import 'popular_movies_home.dart';
import 'popular_stars_widget.dart';
import 'see_all_screen.dart';
import 'trending_widget.dart';
import 'watch_providers_screen.dart';
import 'discover_screen.dart';

const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final TextEditingController _searchController = TextEditingController();
  static List<UpcomingMovies>? _cachedMovies;
  late Future<List<UpcomingMovies>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _cachedMovies != null
        ? Future.value(_cachedMovies)
        : _getData();
  }

  Future<List<UpcomingMovies>> _getData() async {
    final response = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/movie/now_playing?api_key=$_apiKey'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['results'] as List;
      _cachedMovies = data.map((json) => UpcomingMovies.fromJson(json)).toList();
      return _cachedMovies!;
    }
    return [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goSeeAll(String title, String url, SeeAllType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeeAllScreen(title: title, apiUrl: url, type: type),
      ),
    );
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
              onTap: () => _goSeeAll(title, apiUrl, type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('CV',
                          style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('CineVerse',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.divider, width: 0.5),
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        color: AppTheme.textSecondary, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search + Discover button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary, fontSize: 14),
                      decoration:
                          AppTheme.searchDecoration('Search movies, shows...'),
                      onSubmitted: (search) {
                        if (search.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    HomeScreen_Search(query: search)),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Discover/Filter button
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DiscoverScreen()),
                    ),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<UpcomingMovies>>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _cachedMovies == null) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.accent, strokeWidth: 2));
                  }
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔥 Trending Today (movies + tv mixed)
                        _sectionHeader('Trending Today'),
                        const SizedBox(height: 380, child: TrendingCarousel()),
                        const SizedBox(height: 28),

                        // Popular Movies
                        _sectionHeader('Popular Movies',
                            apiUrl: 'https://api.themoviedb.org/3/movie/popular?api_key=$_apiKey',
                            type: SeeAllType.movies),
                        const SizedBox(height: 260, child: PopularMoviesHome()),
                        const SizedBox(height: 28),

                        // Popular TV Shows
                        _sectionHeader('Popular TV Shows',
                            apiUrl: 'https://api.themoviedb.org/3/tv/popular?api_key=$_apiKey',
                            type: SeeAllType.tvShows),
                        const SizedBox(height: 260, child: Popuplar_TVShows()),
                        const SizedBox(height: 28),

                        // ⭐ Popular Stars
                        _sectionHeader('Popular Stars'),
                        const SizedBox(height: 140, child: PopularStarsWidget()),
                        const SizedBox(height: 28),

                        // Upcoming Movies
                        _sectionHeader('Upcoming Movies',
                            apiUrl: 'https://api.themoviedb.org/3/movie/upcoming?api_key=$_apiKey',
                            type: SeeAllType.movies),
                        const SizedBox(height: 260, child: UpcomingMoviesWidget()),
                        const SizedBox(height: 28),

                        // On The Air
                        _sectionHeader('On The Air',
                            apiUrl: 'https://api.themoviedb.org/3/tv/on_the_air?api_key=$_apiKey',
                            type: SeeAllType.tvShows),
                        const SizedBox(height: 260, child: OnTheAir()),
                        const SizedBox(height: 28),

                        // Now Playing
                        _sectionHeader('Now Playing',
                            apiUrl: 'https://api.themoviedb.org/3/movie/now_playing?api_key=$_apiKey',
                            type: SeeAllType.movies),
                        const SizedBox(height: 260, child: Now_Playing_Movies_Widget()),
                        const SizedBox(height: 28),

                        // Top Rated TV Shows
                        _sectionHeader('Top Rated TV Shows',
                            apiUrl: 'https://api.themoviedb.org/3/tv/top_rated?api_key=$_apiKey',
                            type: SeeAllType.tvShows),
                        const SizedBox(height: 260, child: TopRatedTVShows()),
                        const SizedBox(height: 28),

                        // Top Rated Movies
                        _sectionHeader('Top Rated Movies',
                            apiUrl: 'https://api.themoviedb.org/3/movie/top_rated?api_key=$_apiKey',
                            type: SeeAllType.movies),
                        const SizedBox(height: 260, child: TopRatedMovies()),
                        const SizedBox(height: 28),

                        // 🎬 Streaming Services button
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WatchProvidersScreen()),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppTheme.accent.withOpacity(0.3),
                                  width: 0.8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_circle_rounded,
                                    color: AppTheme.accent, size: 22),
                                const SizedBox(width: 10),
                                Text('Browse Streaming Services',
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: AppTheme.textMuted, size: 14),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
