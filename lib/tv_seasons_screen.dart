import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'episode_detail_screen.dart';

class TvSeasonsScreen extends StatefulWidget {
  final int tvId;
  final String tvName;
  final int numberOfSeasons;

  const TvSeasonsScreen({
    super.key,
    required this.tvId,
    required this.tvName,
    required this.numberOfSeasons,
  });

  @override
  State<TvSeasonsScreen> createState() => _TvSeasonsScreenState();
}

class _TvSeasonsScreenState extends State<TvSeasonsScreen> {
  static const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';
  static const String _base = 'https://api.themoviedb.org/3';

  int? _expandedSeason;
  final Map<int, List<Map<String, dynamic>>> _episodeCache = {};
  final Map<int, bool> _loadingEpisodes = {};
  Map<int, Map<String, dynamic>> _seasonDetails = {};

  @override
  void initState() {
    super.initState();
    _fetchAllSeasons();
  }

  Future<void> _fetchAllSeasons() async {
    for (int i = 1; i <= widget.numberOfSeasons; i++) {
      try {
        final res = await http.get(Uri.parse(
            '$_base/tv/${widget.tvId}/season/$i?api_key=$_apiKey'));
        if (res.statusCode == 200 && mounted) {
          final data = jsonDecode(res.body);
          setState(() => _seasonDetails[i] = data);
        }
      } catch (_) {}
    }
  }

  Future<void> _loadEpisodes(int seasonNumber) async {
    if (_episodeCache.containsKey(seasonNumber)) return;
    setState(() => _loadingEpisodes[seasonNumber] = true);
    try {
      final res = await http.get(Uri.parse(
          '$_base/tv/${widget.tvId}/season/$seasonNumber?api_key=$_apiKey'));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final episodes = (data['episodes'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        setState(() {
          _episodeCache[seasonNumber] = episodes;
          _loadingEpisodes[seasonNumber] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEpisodes[seasonNumber] = false);
    }
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
                        border: Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seasons & Episodes',
                            style: AppTheme.headingMedium),
                        Text(widget.tvName,
                            style: AppTheme.caption,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: widget.numberOfSeasons,
                itemBuilder: (context, index) {
                  final seasonNum = index + 1;
                  final isExpanded = _expandedSeason == seasonNum;
                  final seasonData = _seasonDetails[seasonNum];
                  final episodes = _episodeCache[seasonNum] ?? [];
                  final isLoading = _loadingEpisodes[seasonNum] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isExpanded
                            ? AppTheme.accent.withOpacity(0.4)
                            : AppTheme.divider,
                        width: isExpanded ? 0.8 : 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Season header — full card tappable
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _expandedSeason =
                                  isExpanded ? null : seasonNum;
                            });
                            if (!isExpanded) _loadEpisodes(seasonNum);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Season poster
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: seasonData?['poster_path'] != null
                                      ? Image.network(
                                          'https://image.tmdb.org/t/p/w92${seasonData!['poster_path']}',
                                          width: 50,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _seasonPlaceholder(),
                                        )
                                      : _seasonPlaceholder(),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Season $seasonNum',
                                        style: GoogleFonts.poppins(
                                          color: AppTheme.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (seasonData != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(seasonData['episodes'] as List?)?.length ?? 0} episodes',
                                          style: AppTheme.caption,
                                        ),
                                        if (seasonData['air_date'] != null)
                                          Text(
                                            seasonData['air_date']
                                                .toString()
                                                .substring(0, 4),
                                            style: AppTheme.caption,
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Episodes list
                        if (isExpanded) ...[
                          Container(
                            height: 0.5,
                            color: AppTheme.divider,
                          ),
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.accent, strokeWidth: 2),
                              ),
                            )
                          else
                            ...episodes.map((ep) => _EpisodeTile(
                              episode: ep,
                              tvId: widget.tvId,
                              tvName: widget.tvName,
                              seasonNumber: seasonNum,
                            )),
                        ],
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

  Widget _seasonPlaceholder() {
    return Container(
      width: 50,
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.tv_rounded, color: AppTheme.textMuted, size: 24),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Map<String, dynamic> episode;
  final int tvId;
  final String tvName;
  final int seasonNumber;

  const _EpisodeTile({
    required this.episode,
    required this.tvId,
    required this.tvName,
    required this.seasonNumber,
  });

  @override
  Widget build(BuildContext context) {
    final epNum = episode['episode_number'] ?? 0;
    final name = episode['name'] ?? 'Episode $epNum';
    final overview = episode['overview'] ?? '';
    final stillPath = episode['still_path'];
    final rating = (episode['vote_average'] as num?)?.toDouble() ?? 0.0;
    final runtime = episode['runtime'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EpisodeDetailScreen(
            tvId: tvId,
            seasonNumber: seasonNumber,
            episodeNumber: epNum,
            tvName: tvName,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Episode still
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: stillPath != null
                ? Image.network(
                    'https://image.tmdb.org/t/p/w185$stillPath',
                    width: 100,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _stillPlaceholder(),
                  )
                : _stillPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'E$epNum',
                        style: GoogleFonts.poppins(
                          color: AppTheme.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (rating > 0) ...[
                      const Icon(Icons.star_rounded,
                          color: AppTheme.accent, size: 11),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                              color: AppTheme.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                    ],
                    if (runtime != null)
                      Text('${runtime}m',
                          style: AppTheme.caption.copyWith(fontSize: 10)),
                  ],
                ),
                if (overview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    overview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption.copyWith(fontSize: 10, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ), // GestureDetector closing
  );
  }

  Widget _stillPlaceholder() {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.movie_rounded, color: AppTheme.textMuted, size: 20),
    );
  }
}
