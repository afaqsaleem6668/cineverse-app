import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'Genre_Model.dart';
import 'Movie_Details.dart';
import 'TVShows_Details.dart';
import 'TVShows_Model.dart';
import 'Upcomming_Movies_model.dart';
import 'api_cache.dart';
import 'services/app_settings.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  static const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';
  static const String _base = 'https://api.themoviedb.org/3';

  // Filter state
  String _mediaType = 'movie'; // movie or tv
  String _sortBy = 'popularity.desc';
  double _minRating = 0.0;
  double _maxRating = 10.0;
  int _minYear = 2000;
  int _maxYear = DateTime.now().year + 1;
  String _language = 'all';
  List<Genre> _genres = [];
  Set<int> _selectedGenres = {};

  List<dynamic> _results = [];
  bool _loading = false;
  bool _searched = false;

  final List<Map<String, String>> _sortOptions = [
    {'value': 'popularity.desc', 'label': 'Most Popular'},
    {'value': 'popularity.asc', 'label': 'Least Popular'},
    {'value': 'vote_average.desc', 'label': 'Rating ↓'},
    {'value': 'vote_average.asc', 'label': 'Rating ↑'},
    {'value': 'release_date.desc', 'label': 'Newest'},
    {'value': 'release_date.asc', 'label': 'Oldest'},
    {'value': 'revenue.desc', 'label': 'Top Revenue'},
  ];

  final List<Map<String, String>> _languageOptions = [
    {'value': 'all', 'label': 'All'},
    {'value': 'en', 'label': 'English'},
    {'value': 'hi', 'label': 'Hindi'},
    {'value': 'ur', 'label': 'Urdu'},
    {'value': 'ko', 'label': 'Korean'},
    {'value': 'ja', 'label': 'Japanese'},
    {'value': 'fr', 'label': 'French'},
    {'value': 'es', 'label': 'Spanish'},
    {'value': 'de', 'label': 'German'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    final cacheKey = 'discover_genres_$_mediaType';
    final cache = ApiCache();
    if (cache.has(cacheKey)) {
      setState(() => _genres = cache.get<List<Genre>>(cacheKey)!);
      return;
    }
    try {
      final endpoint = _mediaType == 'movie'
          ? '$_base/genre/movie/list?api_key=$_apiKey'
          : '$_base/genre/tv/list?api_key=$_apiKey';
      final res = await http.get(Uri.parse(endpoint));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['genres'] as List;
        final genres = data.map((j) => Genre.fromJson(j)).toList();
        cache.set(cacheKey, genres);
        if (mounted) setState(() => _genres = genres);
      }
    } catch (_) {}
  }

  Future<void> _discover() async {
    setState(() {
      _loading = true;
      _searched = true;
    });

    try {
      // Read user settings
      final includeAdult = await AppSettings.showAdult();
      final defaultLang = await AppSettings.defaultLanguage();

      final genreParam = _selectedGenres.isNotEmpty
          ? '&with_genres=${_selectedGenres.join(',')}'
          : '';

      // If user picked a specific language in filters, use that; otherwise fall
      // back to the default language from settings
      final effectiveLang =
          _language != 'all' ? _language : defaultLang;
      final langParam = '&with_original_language=$effectiveLang';

      final yearParam = _mediaType == 'movie'
          ? '&primary_release_date.gte=$_minYear-01-01&primary_release_date.lte=$_maxYear-12-31'
          : '&first_air_date.gte=$_minYear-01-01&first_air_date.lte=$_maxYear-12-31';

      final adultParam = '&include_adult=$includeAdult';

      final url =
          '$_base/discover/$_mediaType?api_key=$_apiKey&sort_by=$_sortBy'
          '&vote_average.gte=$_minRating&vote_average.lte=$_maxRating'
          '$yearParam$genreParam$langParam$adultParam&vote_count.gte=10';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body)['results'] as List;
        setState(() {
          _results = data
              .map((item) => {
                    ...Map<String, dynamic>.from(item),
                    'media_type': _mediaType,
                  })
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetFilters() {
    setState(() {
      _mediaType = 'movie';
      _sortBy = 'popularity.desc';
      _minRating = 0.0;
      _maxRating = 10.0;
      _minYear = 2000;
      _maxYear = DateTime.now().year + 1;
      _language = 'all';
      _selectedGenres = {};
      _results = [];
      _searched = false;
    });
    _fetchGenres();
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
                  Text('Discover', style: AppTheme.headingMedium),
                  const Spacer(),
                  GestureDetector(
                    onTap: _resetFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.divider, width: 0.5),
                      ),
                      child: Text('Reset',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Filters + Results
            Expanded(
              child: _searched && !_loading
                  ? _buildResultsView()
                  : _buildFiltersView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Media Type
          _sectionLabel('Content Type'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _mediaTypeCard(
                  'movie',
                  'Movies',
                  Icons.movie_creation_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _mediaTypeCard(
                  'tv',
                  'TV Shows',
                  Icons.live_tv_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Sort By
          _sectionLabel('Sort By'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((opt) {
              final selected = _sortBy == opt['value'];
              return _filterChip(
                label: opt['label']!,
                selected: selected,
                onTap: () => setState(() => _sortBy = opt['value']!),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 3. Genres
          if (_genres.isNotEmpty) ...[
            _sectionLabel('Genres'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genres.map((g) {
                final selected = _selectedGenres.contains(g.id);
                return _filterChip(
                  label: g.name,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedGenres.remove(g.id);
                      } else {
                        _selectedGenres.add(g.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // 4. Rating Range
          _sectionLabel(
              'Rating  ${_minRating.toStringAsFixed(1)} – ${_maxRating.toStringAsFixed(1)}'),
          RangeSlider(
            values: RangeValues(_minRating, _maxRating),
            min: 0,
            max: 10,
            divisions: 20,
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.divider,
            labels: RangeLabels(
              _minRating.toStringAsFixed(1),
              _maxRating.toStringAsFixed(1),
            ),
            onChanged: (v) => setState(() {
              _minRating = v.start;
              _maxRating = v.end;
            }),
          ),

          // 5. Year Range
          _sectionLabel('Year  $_minYear – $_maxYear'),
          RangeSlider(
            values: RangeValues(_minYear.toDouble(), _maxYear.toDouble()),
            min: 1900,
            max: (DateTime.now().year + 2).toDouble(),
            divisions: 120,
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.divider,
            labels: RangeLabels('$_minYear', '$_maxYear'),
            onChanged: (v) => setState(() {
              _minYear = v.start.round();
              _maxYear = v.end.round();
            }),
          ),
          const SizedBox(height: 8),

          // 6. Language
          _sectionLabel('Language'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languageOptions.map((opt) {
              final selected = _language == opt['value'];
              return _filterChip(
                label: opt['label']!,
                selected: selected,
                onTap: () => setState(() => _language = opt['value']!),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Discover button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: GestureDetector(
              onTap: _discover,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.black),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.explore_rounded,
                              color: Colors.black, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Discover',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: [
        // Results header with back to filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Text(
                '${_results.length} results',
                style: AppTheme.caption,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _searched = false;
                  _results = [];
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.accent.withOpacity(0.3), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: AppTheme.accent, size: 14),
                      const SizedBox(width: 4),
                      Text('Edit Filters', style: AppTheme.accentText),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded,
                          color: AppTheme.textMuted, size: 50),
                      const SizedBox(height: 10),
                      Text('No results found', style: AppTheme.bodyText),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => setState(() {
                          _searched = false;
                          _results = [];
                        }),
                        child: Text('Try different filters',
                            style: AppTheme.accentText),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final posterPath = item['poster_path'] as String?;
                    final isMovie = item['media_type'] == 'movie';
                    final title = isMovie
                        ? (item['title'] as String? ?? '')
                        : (item['name'] as String? ?? '');
                    final rating =
                        (item['vote_average'] as num?)?.toDouble() ?? 0.0;

                    return GestureDetector(
                      onTap: () {
                        if (isMovie) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Moviedetails(
                                movie: UpcomingMovies.fromJson(
                                    Map<String, dynamic>.from(item)),
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TVShowsDetails(
                                tvshowsdetails: PopularTvShows.fromJson(
                                    Map<String, dynamic>.from(item)),
                              ),
                            ),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  posterPath != null
                                      ? Image.network(
                                          'https://image.tmdb.org/t/p/w500/$posterPath',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                  color: AppTheme.cardBg),
                                        )
                                      : Container(color: AppTheme.cardBg),
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              color: AppTheme.accent,
                                              size: 9),
                                          const SizedBox(width: 2),
                                          Text(
                                            rating.toStringAsFixed(1),
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
                ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _mediaTypeCard(String type, String label, IconData icon) {
    final selected = _mediaType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mediaType = type;
          _selectedGenres = {};
          _genres = [];
        });
        _fetchGenres();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.goldGradient : null,
          color: selected ? null : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : AppTheme.divider,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.black : AppTheme.textSecondary,
                size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: selected ? Colors.black : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.divider,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
