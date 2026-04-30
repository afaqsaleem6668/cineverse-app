import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' show YoutubePlayer;
import 'actor_detail_screen.dart';
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'TVShowsCast.dart';
import 'TVShows_Model.dart';
import 'TVShows_Trailer.dart';
import 'Upcomming_Movies_model.dart';
import 'trailer_player_screen.dart';
import 'reviews_screen.dart';
import 'widgets/app_rating_widget.dart';
import 'widgets/action_buttons.dart';
import 'models/watch_providers_model.dart';
import 'tv_seasons_screen.dart';
import 'media_gallery_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TVShowsDetails extends StatefulWidget {
  const TVShowsDetails({Key? key, required this.tvshowsdetails}) : super(key: key);
  final PopularTvShows tvshowsdetails;

  @override
  State<TVShowsDetails> createState() => _TVShowsDetailsState();
}

class _TVShowsDetailsState extends State<TVShowsDetails> {
  static const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  List<TvShowsCast> cast = [];
  List<TvShowsTrailer> trailers = [];
  List<Map<String, dynamic>> reviews = [];
  List<PopularTvShows> recommendations = [];
  List<PopularTvShows> similar = [];
  bool _showVoteCount = true;

  Map<String, dynamic>? tvDetails;
  List<Map<String, dynamic>> streamingProviders = [];
  List<Map<String, dynamic>> backdropImages = [];
  List<Map<String, dynamic>> posterImages = [];
  String? contentRating;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadSettings();
    _fetchAll();
  }

  Future<void> _loadSettings() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _showVoteCount = p.getBool('show_vote_count') ?? true);
  }

  Future<void> _fetchAll() async {
    try {
      final id = widget.tvshowsdetails.id;
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/tv/$id/credits?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/tv/$id/videos?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/tv/$id/reviews?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/tv/$id/recommendations?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/tv/$id/similar?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/tv/$id?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/tv/$id/watch/providers?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/tv/$id/images?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/tv/$id/content_ratings?api_key=$_apiKey')),
      ]);

      if (!mounted) return;

      setState(() {
        if (results[0].statusCode == 200) {
          final data = jsonDecode(results[0].body)['cast'] as List;
          cast = data.map((j) => TvShowsCast.fromJson(j)).toList();
        }
        if (results[1].statusCode == 200) {
          final data = jsonDecode(results[1].body)['results'] as List;
          trailers = data
              .map((j) => TvShowsTrailer.fromJson(j))
              .where((t) => t.site == 'YouTube')
              .toList();
        }
        if (results[2].statusCode == 200) {
          final data = jsonDecode(results[2].body)['results'] as List;
          reviews = data.cast<Map<String, dynamic>>().take(5).toList();
        }
        if (results[3].statusCode == 200) {
          final data = jsonDecode(results[3].body)['results'] as List;
          recommendations = data
              .where((j) => j['poster_path'] != null)
              .map((j) => PopularTvShows.fromJson(j))
              .toList();
        }
        if (results[4].statusCode == 200) {
          final data = jsonDecode(results[4].body)['results'] as List;
          similar = data
              .where((j) => j['poster_path'] != null)
              .map((j) => PopularTvShows.fromJson(j))
              .toList();
        }
        if (results[5].statusCode == 200) {
          tvDetails = jsonDecode(results[5].body);
        }
        if (results[6].statusCode == 200) {
          final data = jsonDecode(results[6].body);
          final resultsMap = data['results'] as Map<String, dynamic>?;
          final providers = resultsMap?['PK'] ?? resultsMap?['US'];
          if (providers != null) {
            final flatrate = providers['flatrate'] as List?;
            if (flatrate != null) {
              streamingProviders = flatrate.cast<Map<String, dynamic>>();
            }
          }
        }
        if (results[7].statusCode == 200) {
          final data = jsonDecode(results[7].body);
          final backdrops = data['backdrops'] as List?;
          final posters = data['posters'] as List?;
          if (backdrops != null) {
            backdropImages = backdrops.cast<Map<String, dynamic>>().take(15).toList();
          }
          if (posters != null) {
            posterImages = posters.cast<Map<String, dynamic>>().take(15).toList();
          }
        }
        if (results[8].statusCode == 200) {
          final ratingsData = jsonDecode(results[8].body);
          final ratingsList = ratingsData['results'] as List?;
          if (ratingsList != null) {
            try {
              final usRating = ratingsList.firstWhere(
                (r) => r['iso_3166_1'] == 'US',
                orElse: () => {},
              );
              contentRating = usRating['rating'];
            } catch (_) {}
          }
        }
      });
    } catch (_) {}
  }

  Widget _sectionTitle(String t) =>
      Text(t, style: AppTheme.sectionTitle.copyWith(color: AppTheme.accent));

  Widget _sectionHeaderWithAction(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTheme.sectionTitle.copyWith(color: AppTheme.accent)),
        GestureDetector(
          onTap: onSeeAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 0.5),
            ),
            child: Text('See all', style: AppTheme.accentText),
          ),
        ),
      ],
    );
  }

  Widget _badge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: AppTheme.background,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.tvshowsdetails.posterPath != null
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w500/${widget.tvshowsdetails.posterPath}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppTheme.cardBg),
                        )
                      : Container(color: AppTheme.cardBg),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppTheme.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.tvshowsdetails.name, style: AppTheme.headingLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _badge(icon: Icons.star_rounded,
                          label: widget.tvshowsdetails.voteAverage.toStringAsFixed(1),
                          color: AppTheme.accent),
                      if (widget.tvshowsdetails.firstAirDate != null)
                        _badge(
                            icon: Icons.calendar_today_rounded,
                            label: DateFormat('MMM yyyy')
                                .format(widget.tvshowsdetails.firstAirDate!),
                            color: AppTheme.textSecondary),
                      _badge(
                          icon: Icons.how_to_vote_rounded,
                          label: '${widget.tvshowsdetails.voteCount} votes',
                          color: AppTheme.textSecondary),
                      // CineVerse app rating
                      AppRatingBadge(
                          collectionId: 'tv_${widget.tvshowsdetails.id}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Favorite + Watchlist buttons
                  MediaActionButtons(
                    mediaId: widget.tvshowsdetails.id,
                    mediaType: 'tv',
                    title: widget.tvshowsdetails.name,
                    posterPath: widget.tvshowsdetails.posterPath,
                    voteAverage: widget.tvshowsdetails.voteAverage,
                  ),
                  const SizedBox(height: 20),

                  _sectionTitle('Overview'),
                  const SizedBox(height: 8),
                  Text(widget.tvshowsdetails.overview, style: AppTheme.bodyText),
                  const SizedBox(height: 28),

                  // Content Rating + Details badges
                  if (tvDetails != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (contentRating != null)
                          _badge(icon: Icons.shield_rounded, label: contentRating!, color: AppTheme.accent),
                        if (tvDetails!['status'] != null)
                          _badge(icon: Icons.info_outline_rounded, label: tvDetails!['status'], color: AppTheme.textSecondary),
                        if (tvDetails!['number_of_seasons'] != null)
                          _badge(icon: Icons.layers_rounded, label: '${tvDetails!['number_of_seasons']} Seasons', color: AppTheme.textSecondary),
                        if (tvDetails!['number_of_episodes'] != null)
                          _badge(icon: Icons.play_circle_outline_rounded, label: '${tvDetails!['number_of_episodes']} Episodes', color: AppTheme.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Seasons & Episodes button
                  if (tvDetails != null && (tvDetails!['number_of_seasons'] ?? 0) > 0) ...[
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TvSeasonsScreen(
                          tvId: widget.tvshowsdetails.id,
                          tvName: widget.tvshowsdetails.name,
                          numberOfSeasons: tvDetails!['number_of_seasons'],
                        ),
                      )),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 0.8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.layers_rounded, color: AppTheme.accent, size: 20),
                            const SizedBox(width: 8),
                            Text('View All Seasons & Episodes',
                                style: GoogleFonts.poppins(color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.accent, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Where to Watch
                  if (streamingProviders.isNotEmpty) ...[
                    _sectionTitle('Where to Watch'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: streamingProviders.length,
                        itemBuilder: (context, index) {
                          final p = streamingProviders[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: p['logo_path'] != null
                                      ? Image.network('https://image.tmdb.org/t/p/w92${p['logo_path']}',
                                          width: 50, height: 50, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: AppTheme.cardBg))
                                      : Container(width: 50, height: 50, color: AppTheme.cardBg),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 55,
                                  child: Text(p['provider_name'] ?? '',
                                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 9),
                                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Trailers — 90% width swipeable PageView
                  if (trailers.isNotEmpty) ...[
                    _sectionTitle('Trailers'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.92),
                        physics: const BouncingScrollPhysics(),
                        itemCount: trailers.length,
                        itemBuilder: (context, index) {
                          final t = trailers[index];
                          final videoId = YoutubePlayer.convertUrlToId(
                                  'https://www.youtube.com/watch?v=${t.key}') ??
                              t.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: TrailerThumbnailCard(
                              videoId: videoId,
                              title: t.name.isNotEmpty
                                  ? t.name
                                  : '${widget.tvshowsdetails.name} — Trailer',
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Cast
                  if (cast.isNotEmpty) ...[
                    _sectionTitle('Cast'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: cast.length,
                        itemBuilder: (context, index) {
                          final actor = cast[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActorDetailScreen(
                                  personId: actor.id,
                                  name: actor.name,
                                  profilePath: actor.profilePath ?? '',
                                ),
                              ),
                            ),
                            child: Container(
                              width: 72,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: AppTheme.cardBg,
                                    backgroundImage: actor.profilePath != null &&
                                            actor.profilePath!.isNotEmpty
                                        ? NetworkImage(
                                            'https://image.tmdb.org/t/p/w200${actor.profilePath}')
                                        : null,
                                    child: actor.profilePath == null ||
                                            actor.profilePath!.isEmpty
                                        ? const Icon(Icons.person_rounded,
                                            color: AppTheme.textMuted, size: 28)
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    actor.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.textPrimary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Photo Gallery — horizontal scroll + See all
                  if (backdropImages.isNotEmpty || posterImages.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4, height: 20,
                              decoration: BoxDecoration(
                                gradient: AppTheme.goldGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('Photos', style: AppTheme.sectionTitle),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => MediaGalleryScreen(
                              title: widget.tvshowsdetails.name,
                              backdrops: backdropImages,
                              posters: posterImages,
                            ),
                          )),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 0.5),
                            ),
                            child: Text('See all', style: AppTheme.accentText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: backdropImages.length > 6 ? 6 : backdropImages.length,
                        itemBuilder: (context, index) {
                          final path = backdropImages[index]['file_path'] ?? '';
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => MediaGalleryScreen(
                                title: widget.tvshowsdetails.name,
                                backdrops: backdropImages,
                                posters: posterImages,
                              ),
                            )),
                            child: Container(
                              width: 180,
                              margin: const EdgeInsets.only(right: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  'https://image.tmdb.org/t/p/w300$path',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: AppTheme.cardBg),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Reviews — Firestore + TMDB combined
                  _sectionHeaderWithAction(
                    'Reviews',
                    onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewsScreen(
                          mediaId: widget.tvshowsdetails.id,
                          mediaTitle: widget.tvshowsdetails.name,
                          mediaType: 'tv',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('collectionId',
                            isEqualTo: 'tv_${widget.tvshowsdetails.id}')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final firestoreDocs =
                          snapshot.hasData ? snapshot.data!.docs : [];
                      final hasAny =
                          firestoreDocs.isNotEmpty || reviews.isNotEmpty;

                      if (!hasAny) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewsScreen(
                                mediaId: widget.tvshowsdetails.id,
                                mediaTitle: widget.tvshowsdetails.name,
                                mediaType: 'tv',
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppTheme.divider, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.rate_review_outlined,
                                    color: AppTheme.textMuted, size: 20),
                                const SizedBox(width: 10),
                                Text('Be the first to review!',
                                    style: AppTheme.bodyText),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...firestoreDocs.take(2).map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return _DetailReviewCard(
                                data: d, isFirestore: true);
                          }),
                          ...reviews
                              .take(2 - firestoreDocs.length.clamp(0, 2))
                              .map((r) => _DetailReviewCard(
                                  data: r, isFirestore: false)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Recommendations
                  if (recommendations.isNotEmpty) ...[
                    _sectionTitle('Recommended'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final s = recommendations[index];
                          return _SmallTVCard(
                              show: s, heroTag: 'rec_tv_${s.id}_$index');
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Similar
                  if (similar.isNotEmpty) ...[
                    _sectionTitle('Similar Shows'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: similar.length,
                        itemBuilder: (context, index) {
                          final s = similar[index];
                          return _SmallTVCard(
                              show: s, heroTag: 'sim_tv_${s.id}_$index');
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small TV card ────────────────────────────────────────────────────────────

class _SmallTVCard extends StatelessWidget {
  final PopularTvShows show;
  final String heroTag;
  const _SmallTVCard({required this.show, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TVShowsDetails(tvshowsdetails: show)),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 170,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://image.tmdb.org/t/p/w300/${show.posterPath}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppTheme.cardBg),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
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
                            Text(show.voteAverage.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                    color: AppTheme.accent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(show.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Review card ──────────────────────────────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final author = widget.review['author'] ?? 'Anonymous';
    final content = widget.review['content'] ?? '';
    final rating = widget.review['author_details']?['rating'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accent.withOpacity(0.2),
                child: Text(
                  author.isNotEmpty ? author[0].toUpperCase() : 'A',
                  style: GoogleFonts.poppins(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(author,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              if (rating != null)
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppTheme.accent, size: 13),
                    const SizedBox(width: 3),
                    Text(rating.toString(),
                        style: GoogleFonts.poppins(
                            color: AppTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: AppTheme.bodyText.copyWith(fontSize: 12),
          ),
          if (content.length > 150) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Show less' : 'Read more',
                  style: AppTheme.accentText),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Detail page review card ──────────────────────────────────────────────────

class _DetailReviewCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isFirestore;
  const _DetailReviewCard({required this.data, required this.isFirestore});

  @override
  State<_DetailReviewCard> createState() => _DetailReviewCardState();
}

class _DetailReviewCardState extends State<_DetailReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final author = widget.data['author'] ?? 'Anonymous';
    final content = widget.data['content'] ?? '';
    final rating = widget.isFirestore
        ? (widget.data['rating'] as num?)?.toDouble()
        : widget.data['author_details']?['rating'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accent.withOpacity(0.15),
                child: Text(
                  author.isNotEmpty ? author[0].toUpperCase() : 'A',
                  style: GoogleFonts.poppins(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(author,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              if (rating != null)
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppTheme.accent, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      rating is double
                          ? rating.toStringAsFixed(1)
                          : rating.toString(),
                      style: GoogleFonts.poppins(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: AppTheme.bodyText.copyWith(fontSize: 12),
          ),
          if (content.length > 150) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Show less' : 'Read more',
                  style: AppTheme.accentText),
            ),
          ],
        ],
      ),
    );
  }
}
