import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'AiringToday.dart';
import 'api_cache.dart';
import 'Genre_Model.dart';
import 'OnTheAir.dart';
import 'Popular_TVShows.dart';
import 'TopRated_TVShow.dart';
import 'TVShows_Search_Result.dart';
import 'app_theme.dart';
import 'see_all_screen.dart';

const String _tvApiKey = 'e850641520c5c6eacf9b2f679e373ff4';

class TVSHOWS extends StatefulWidget {
  const TVSHOWS({Key? key}) : super(key: key);

  @override
  State<TVSHOWS> createState() => _TVSHOWSState();
}

class _TVSHOWSState extends State<TVSHOWS> {
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
    const cacheKey = 'tv_genres';
    final cache = ApiCache();
    if (cache.has(cacheKey)) {
      setState(() => genres = cache.get<List<Genre>>(cacheKey)!);
      return;
    }
    try {
      final response = await http.get(Uri.parse(
          'https://api.themoviedb.org/3/genre/tv/list?api_key=e850641520c5c6eacf9b2f679e373ff4'));
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
                  Text('TV Shows', style: AppTheme.headingMedium),
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
                decoration: AppTheme.searchDecoration('Search TV shows...'),
                onSubmitted: (search) {
                  if (search.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TVShowsSearch(search: search)),
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
                    _sectionHeader('Popular Shows',
                        apiUrl: 'https://api.themoviedb.org/3/tv/popular?api_key=$_tvApiKey',
                        type: SeeAllType.tvShows),
                    SizedBox(
                        height: 260,
                        child: Popuplar_TVShows(
                          key: ValueKey('pop_tv_${selectedGenre?.id}'),
                          selectedGenre: selectedGenre,
                        )),
                    const SizedBox(height: 28),
                    _sectionHeader('Airing Today',
                        apiUrl: 'https://api.themoviedb.org/3/tv/airing_today?api_key=$_tvApiKey',
                        type: SeeAllType.tvShows),
                    SizedBox(
                        height: 260,
                        child: Airingtoday(
                          key: ValueKey('airing_today_${selectedGenre?.id}'),
                          selectedGenre: selectedGenre,
                        )),
                    const SizedBox(height: 28),
                    _sectionHeader('On The Air',
                        apiUrl: 'https://api.themoviedb.org/3/tv/on_the_air?api_key=$_tvApiKey',
                        type: SeeAllType.tvShows),
                    SizedBox(
                        height: 260,
                        child: OnTheAir(
                          key: ValueKey('on_the_air_${selectedGenre?.id}'),
                          selectedGenre: selectedGenre,
                        )),
                    const SizedBox(height: 28),
                    _sectionHeader('Top Rated',
                        apiUrl: 'https://api.themoviedb.org/3/tv/top_rated?api_key=$_tvApiKey',
                        type: SeeAllType.tvShows),
                    SizedBox(
                        height: 260,
                        child: TopRatedTVShows(
                          key: ValueKey('top_rated_tv_${selectedGenre?.id}'),
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
