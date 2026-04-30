import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'TVShows_Details.dart';
import 'TVShows_Model.dart';
import 'Upcomming_Movies_model.dart';
import 'widgets/premium_card.dart';

enum SeeAllType { movies, tvShows }

class SeeAllScreen extends StatefulWidget {
  final String title;
  final String apiUrl;
  final SeeAllType type;

  const SeeAllScreen({
    Key? key,
    required this.title,
    required this.apiUrl,
    required this.type,
  }) : super(key: key);

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allItems = [];
  List<dynamic> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      List<dynamic> combined = [];
      for (int page = 1; page <= 3; page++) {
        final url = widget.apiUrl.contains('?')
            ? '${widget.apiUrl}&page=$page'
            : '${widget.apiUrl}?page=$page';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['results'] as List;
          combined.addAll(data);
        }
      }
      if (mounted) {
        setState(() {
          _allItems = combined;
          _filtered = combined;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String q) {
    final query = q.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = _allItems;
      } else {
        _filtered = _allItems.where((item) {
          final name = widget.type == SeeAllType.movies
              ? (item['title'] ?? '').toString().toLowerCase()
              : (item['name'] ?? '').toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      // Use resizeToAvoidBottomInset to prevent overflow when keyboard opens
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        border: Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(widget.title,
                        style: AppTheme.headingMedium,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary, fontSize: 14),
                decoration:
                    AppTheme.searchDecoration('Search ${widget.title}...'),
                onChanged: _onSearch,
              ),
            ),
            const SizedBox(height: 10),
            // Count row
            if (!_loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${_filtered.length} results',
                    style: AppTheme.caption),
              ),
            const SizedBox(height: 8),
            // Grid — Expanded takes remaining space, no overflow
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accent, strokeWidth: 2))
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  color: AppTheme.textMuted, size: 50),
                              const SizedBox(height: 10),
                              Text('No results found',
                                  style: AppTheme.bodyText),
                            ],
                          ),
                        )
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            // height = poster(185) + gap(6) + title(2lines*14.3=~29) = ~220
                            // width = (screenW - 32 - 24) / 3 ≈ 107
                            // ratio = 107/220 ≈ 0.486
                            childAspectRatio: 0.49,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final item = _filtered[index];
                            try {
                              if (widget.type == SeeAllType.movies) {
                                final movie = UpcomingMovies.fromJson(item);
                                return PremiumMovieCard(
                                  posterPath: movie.posterPath,
                                  title: movie.title,
                                  rating: movie.voteAverage,
                                  // Unique tag with screen prefix + index
                                  heroTag: 'sa_m_${movie.id}_$index',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            Moviedetails(movie: movie)),
                                  ),
                                );
                              } else {
                                final show = PopularTvShows.fromJson(item);
                                return PremiumMovieCard(
                                  posterPath: show.posterPath ?? '',
                                  title: show.name,
                                  rating: show.voteAverage,
                                  heroTag: 'sa_tv_${show.id}_$index',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => TVShowsDetails(
                                            tvshowsdetails: show)),
                                  ),
                                );
                              }
                            } catch (_) {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
