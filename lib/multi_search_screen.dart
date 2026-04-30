import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'TVShows_Details.dart';
import 'TVShows_Model.dart';
import 'Upcomming_Movies_model.dart';
import 'actor_detail_screen.dart';

class MultiSearchScreen extends StatefulWidget {
  final String query;

  const MultiSearchScreen({super.key, required this.query});

  @override
  State<MultiSearchScreen> createState() => _MultiSearchScreenState();
}

class _MultiSearchScreenState extends State<MultiSearchScreen> {
  static const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    _performSearch(widget.query);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _loading = true);

    try {
      final response = await http.get(Uri.parse(
          'https://api.themoviedb.org/3/search/multi?api_key=$_apiKey&query=${Uri.encodeComponent(query)}'));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body)['results'] as List;
        setState(() {
          _results = data.where((item) {
            final mediaType = item['media_type'];
            return mediaType == 'movie' ||
                mediaType == 'tv' ||
                mediaType == 'person';
          }).map((e) => e as Map<String, dynamic>).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search movies, shows, people...',
            hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
            border: InputBorder.none,
          ),
          onSubmitted: (value) => _performSearch(value),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
            )
          : _results.isEmpty
              ? const Center(
                  child: Text('No results found',
                      style: TextStyle(color: AppTheme.textMuted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final mediaType = item['media_type'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildResultCard(item, mediaType),
                    );
                  },
                ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item, String mediaType) {
    final posterPath = item['poster_path'] ?? item['profile_path'] ?? '';
    final title = item['title'] ?? item['name'] ?? 'Unknown';
    final overview = item['overview'] ?? '';
    final voteAverage = (item['vote_average'] ?? 0).toDouble();
    final releaseDate = item['release_date'] ?? item['first_air_date'] ?? '';

    return GestureDetector(
      onTap: () {
        if (mediaType == 'movie') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Moviedetails(
                movie: UpcomingMovies(
                  adult: item['adult'] ?? false,
                  backdropPath: item['backdrop_path'] ?? '',
                  genreIds: item['genre_ids'] != null
                      ? (item['genre_ids'] as List).map((e) => (e as num).toInt()).toList()
                      : [],
                  id: item['id'] ?? 0,
                  originalTitle: item['original_title'] ?? '',
                  overview: overview,
                  popularity: (item['popularity'] ?? 0).toDouble(),
                  posterPath: posterPath,
                  releaseDate: releaseDate.isNotEmpty
                      ? DateTime.tryParse(releaseDate)
                      : null,
                  title: title,
                  video: item['video'] ?? false,
                  voteAverage: voteAverage,
                  voteCount: item['vote_count'] ?? 0,
                ),
              ),
            ),
          );
        } else if (mediaType == 'tv') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TVShowsDetails(
                tvshowsdetails: PopularTvShows(
                  adult: item['adult'] ?? false,
                  backdropPath: item['backdrop_path'] ?? '',
                  genreIds: item['genre_ids'] != null
                      ? (item['genre_ids'] as List).map((e) => (e as num).toInt()).toList()
                      : [],
                  id: item['id'] ?? 0,
                  name: title,
                  originCountry: item['origin_country'] != null
                      ? (item['origin_country'] as List).map((e) => e.toString()).toList()
                      : [],
                  originalLanguage: item['original_language'] ?? '',
                  originalName: item['original_name'] ?? '',
                  overview: overview,
                  popularity: (item['popularity'] ?? 0).toDouble(),
                  posterPath: posterPath,
                  voteAverage: voteAverage,
                  voteCount: item['vote_count'] ?? 0,
                  firstAirDate: releaseDate.isNotEmpty
                      ? DateTime.tryParse(releaseDate)
                      : null,
                ),
              ),
            ),
          );
        } else if (mediaType == 'person') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActorDetailScreen(
                personId: item['id'] ?? 0,
                name: title,
                profilePath: posterPath,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: posterPath.isNotEmpty
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w185$posterPath',
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 120,
                      color: AppTheme.surface,
                      child: Icon(
                        mediaType == 'person'
                            ? Icons.person_rounded
                            : Icons.movie_rounded,
                        color: AppTheme.textMuted,
                        size: 30,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mediaType.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: AppTheme.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (releaseDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        releaseDate.split('-')[0],
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.accent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          voteAverage.toStringAsFixed(1),
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
            ),
          ],
        ),
      ),
    );
  }
}
