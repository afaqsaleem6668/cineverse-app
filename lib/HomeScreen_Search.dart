import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'TVShows_Details.dart';
import 'TVShows_Model.dart';
import 'Upcomming_Movies_model.dart';

class HomeScreen_Search extends StatefulWidget {
  const HomeScreen_Search({super.key, required this.query});
  final String query;

  @override
  State<HomeScreen_Search> createState() => _HomeScreen_SearchState();
}

class _HomeScreen_SearchState extends State<HomeScreen_Search>
    with SingleTickerProviderStateMixin {
  late String _query;
  List<dynamic> _allResults = [];
  List<dynamic> _filtered = [];
  bool _loading = true;

  // Filter state
  Set<String> _mediaTypes = {'movie', 'tv'};
  String _sortBy = 'relevance';
  double _minRating = 0.0;
  double _maxRating = 10.0;
  int _minYear = 1900;
  int _maxYear = DateTime.now().year + 2;
  bool _showFilters = false;
  bool _includeAdult = false;
  String _language = 'all';

  late AnimationController _filterAnimController;
  late Animation<double> _filterHeightAnim;

  static const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';

  final List<Map<String, String>> _sortOptions = [
    {'value': 'relevance', 'label': 'Relevance'},
    {'value': 'rating_desc', 'label': 'Rating ↓'},
    {'value': 'rating_asc', 'label': 'Rating ↑'},
    {'value': 'date_desc', 'label': 'Newest'},
    {'value': 'date_asc', 'label': 'Oldest'},
    {'value': 'title_asc', 'label': 'A→Z'},
    {'value': 'title_desc', 'label': 'Z→A'},
  ];

  final List<Map<String, String>> _languageOptions = [
    {'value': 'all', 'label': 'All'},
    {'value': 'en', 'label': 'English'},
    {'value': 'hi', 'label': 'Hindi'},
    {'value': 'ur', 'label': 'Urdu'},
    {'value': 'ko', 'label': 'Korean'},
    {'value': 'ja', 'label': 'Japanese'},
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.query;

    _filterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterHeightAnim = CurvedAnimation(
      parent: _filterAnimController,
      curve: Curves.easeInOut,
    );

    _fetchResults();
  }

  @override
  void dispose() {
    _filterAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchResults() async {
    setState(() => _loading = true);

    try {
      final movieRes = await http.get(Uri.parse(
          'https://api.themoviedb.org/3/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(_query)}&include_adult=$_includeAdult'));
      final tvRes = await http.get(Uri.parse(
          'https://api.themoviedb.org/3/search/tv?api_key=$_apiKey&query=${Uri.encodeComponent(_query)}&include_adult=$_includeAdult'));

      List<dynamic> combined = [];
      if (movieRes.statusCode == 200) {
        final data = jsonDecode(movieRes.body)['results'] as List;
        combined.addAll(data.map((m) => {
              ...Map<String, dynamic>.from(m),
              'media_type': 'movie',
            }));
      }
      if (tvRes.statusCode == 200) {
        final data = jsonDecode(tvRes.body)['results'] as List;
        combined.addAll(data.map((t) => {
              ...Map<String, dynamic>.from(t),
              'media_type': 'tv',
            }));
      }

      setState(() {
        _allResults = combined;
        _loading = false;
      });
      _applyFilters();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    List<dynamic> results = List.from(_allResults);

    // 1. Media type filter
    results = results
        .where((item) => _mediaTypes.contains(item['media_type']))
        .toList();

    // 2. Rating filter
    results = results.where((item) {
      final rating = (item['vote_average'] as num?)?.toDouble() ?? 0.0;
      return rating >= _minRating && rating <= _maxRating;
    }).toList();

    // 3. Year filter
    results = results.where((item) {
      final isMovie = item['media_type'] == 'movie';
      final dateStr = isMovie
          ? (item['release_date'] as String? ?? '')
          : (item['first_air_date'] as String? ?? '');
      if (dateStr.isEmpty) return true;
      final year = int.tryParse(dateStr.split('-').first) ?? 0;
      if (year == 0) return true;
      return year >= _minYear && year <= _maxYear;
    }).toList();

    // 4. Language filter
    if (_language != 'all') {
      results = results.where((item) {
        final lang = item['original_language'] as String? ?? '';
        return lang == _language;
      }).toList();
    }

    // 5. Sort
    switch (_sortBy) {
      case 'rating_desc':
        results.sort((a, b) {
          final ra = (a['vote_average'] as num?)?.toDouble() ?? 0.0;
          final rb = (b['vote_average'] as num?)?.toDouble() ?? 0.0;
          return rb.compareTo(ra);
        });
        break;
      case 'rating_asc':
        results.sort((a, b) {
          final ra = (a['vote_average'] as num?)?.toDouble() ?? 0.0;
          final rb = (b['vote_average'] as num?)?.toDouble() ?? 0.0;
          return ra.compareTo(rb);
        });
        break;
      case 'date_desc':
        results.sort((a, b) {
          final da = _getDate(a);
          final db = _getDate(b);
          return db.compareTo(da);
        });
        break;
      case 'date_asc':
        results.sort((a, b) {
          final da = _getDate(a);
          final db = _getDate(b);
          return da.compareTo(db);
        });
        break;
      case 'title_asc':
        results.sort((a, b) {
          final ta = _getTitle(a).toLowerCase();
          final tb = _getTitle(b).toLowerCase();
          return ta.compareTo(tb);
        });
        break;
      case 'title_desc':
        results.sort((a, b) {
          final ta = _getTitle(a).toLowerCase();
          final tb = _getTitle(b).toLowerCase();
          return tb.compareTo(ta);
        });
        break;
      case 'relevance':
      default:
        // Keep original order
        break;
    }

    setState(() => _filtered = results);
  }

  String _getDate(dynamic item) {
    final isMovie = item['media_type'] == 'movie';
    return isMovie
        ? (item['release_date'] as String? ?? '')
        : (item['first_air_date'] as String? ?? '');
  }

  String _getTitle(dynamic item) {
    final isMovie = item['media_type'] == 'movie';
    return isMovie
        ? (item['title'] as String? ?? '')
        : (item['name'] as String? ?? '');
  }

  bool get _hasActiveFilters {
    return !_mediaTypes.containsAll({'movie', 'tv'}) ||
        _mediaTypes.length != 2 ||
        _sortBy != 'relevance' ||
        _minRating != 0.0 ||
        _maxRating != 10.0 ||
        _minYear != 1900 ||
        _maxYear != DateTime.now().year + 2 ||
        _includeAdult ||
        _language != 'all';
  }

  void _resetFilters() {
    setState(() {
      _mediaTypes = {'movie', 'tv'};
      _sortBy = 'relevance';
      _minRating = 0.0;
      _maxRating = 10.0;
      _minYear = 1900;
      _maxYear = DateTime.now().year + 2;
      _includeAdult = false;
      _language = 'all';
    });
    _applyFilters();
  }

  void _toggleFilterPanel() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterAnimController.forward();
    } else {
      _filterAnimController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildAppBar(context),
          SizeTransition(
            sizeFactor: _filterHeightAnim,
            axisAlignment: -1,
            child: _buildFilterPanel(),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.accent, strokeWidth: 2))
                : _buildResultsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.background,
          border: Border(
            bottom: BorderSide(color: AppTheme.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider, width: 0.5),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.textPrimary, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search Results',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      )),
                  Text('"$_query"',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Filter button
            GestureDetector(
              onTap: _toggleFilterPanel,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _hasActiveFilters
                      ? AppTheme.accent.withOpacity(0.15)
                      : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _hasActiveFilters
                        ? AppTheme.accent.withOpacity(0.5)
                        : AppTheme.divider,
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: _hasActiveFilters
                      ? AppTheme.accent
                      : AppTheme.textMuted,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Media Type
            _filterSectionLabel('Media Type'),
            const SizedBox(height: 8),
            Row(
              children: [
                _mediaTypeChip('movie', 'Movies'),
                const SizedBox(width: 8),
                _mediaTypeChip('tv', 'TV Shows'),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Sort By
            _filterSectionLabel('Sort By'),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _sortOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final opt = _sortOptions[i];
                  final selected = _sortBy == opt['value'];
                  return _sortChip(opt['value']!, opt['label']!, selected);
                },
              ),
            ),
            const SizedBox(height: 16),

            // 3. Rating Range
            _filterSectionLabel(
                'Rating Range  ${_minRating.toStringAsFixed(1)} – ${_maxRating.toStringAsFixed(1)}'),
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
              onChanged: (v) {
                setState(() {
                  _minRating = v.start;
                  _maxRating = v.end;
                });
              },
            ),

            // 4. Year Range
            _filterSectionLabel(
                'Year Range  $_minYear – $_maxYear'),
            RangeSlider(
              values: RangeValues(_minYear.toDouble(), _maxYear.toDouble()),
              min: 1900,
              max: (DateTime.now().year + 2).toDouble(),
              divisions: 120,
              activeColor: AppTheme.accent,
              inactiveColor: AppTheme.divider,
              labels: RangeLabels('$_minYear', '$_maxYear'),
              onChanged: (v) {
                setState(() {
                  _minYear = v.start.round();
                  _maxYear = v.end.round();
                });
              },
            ),

            // 5. Language
            _filterSectionLabel('Language'),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _languageOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final opt = _languageOptions[i];
                  final selected = _language == opt['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _language = opt['value']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accent
                            : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.accent
                              : AppTheme.divider,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        opt['label']!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.black
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 6. Adult Content toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _filterSectionLabel('Adult Content'),
                Switch(
                  value: _includeAdult,
                  onChanged: (v) => setState(() => _includeAdult = v),
                  activeColor: AppTheme.accent,
                  activeTrackColor: AppTheme.accent.withOpacity(0.3),
                  inactiveThumbColor: AppTheme.textMuted,
                  inactiveTrackColor: AppTheme.divider,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppTheme.textMuted, width: 0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _applyFilters();
                      _fetchResults();
                      _toggleFilterPanel();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Apply',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _mediaTypeChip(String type, String label) {
    final selected = _mediaTypes.contains(type);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            // Don't allow deselecting both
            if (_mediaTypes.length > 1) _mediaTypes.remove(type);
          } else {
            _mediaTypes.add(type);
          }
        });
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.divider,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == 'movie'
                  ? Icons.movie_rounded
                  : Icons.tv_rounded,
              size: 14,
              color: selected ? Colors.black : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.black : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String value, String label, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

  Widget _buildResultsGrid() {
    if (_allResults.isEmpty) {
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

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_off_rounded,
                color: AppTheme.textMuted, size: 60),
            const SizedBox(height: 12),
            Text(
              'No results match your filters',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _resetFilters,
              child: Text(
                'Reset filters',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_filtered.length} result${_filtered.length == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.6,
            ),
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final item = _filtered[index];
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
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppTheme.cardBg,
                                      child: const Icon(Icons.movie_rounded,
                                          color: AppTheme.textMuted),
                                    ),
                                  )
                                : Container(
                                    color: AppTheme.cardBg,
                                    child: const Icon(Icons.movie_rounded,
                                        color: AppTheme.textMuted),
                                  ),
                            // Gradient overlay
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.5),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                            // Type badge
                            Positioned(
                              bottom: 5,
                              left: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isMovie
                                      ? AppTheme.accent.withOpacity(0.9)
                                      : Colors.blue.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  isMovie ? 'Movie' : 'TV',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
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
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.accent,
                                        fontSize: 8,
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
}
