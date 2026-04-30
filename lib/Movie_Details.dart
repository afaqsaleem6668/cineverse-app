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
import 'MovieCast.dart';
import 'Trailer_Model.dart';
import 'Upcomming_Movies_model.dart';
import 'trailer_player_screen.dart';
import 'reviews_screen.dart';
import 'models/watch_providers_model.dart';
import 'models/collection_model.dart';
import 'models/external_ids_model.dart';
import 'models/certification_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'collection_screen.dart';
import 'media_gallery_screen.dart';
import 'widgets/app_rating_widget.dart';
import 'widgets/action_buttons.dart';

class Moviedetails extends StatefulWidget {
  const Moviedetails({Key? key, required this.movie}) : super(key: key);
  final UpcomingMovies movie;

  @override
  State<Moviedetails> createState() => _MoviedetailsState();
}

class _MoviedetailsState extends State<Moviedetails> {
  List<MovieCast> cast = [];
  List<Map<String, dynamic>> reviews = [];
  List<UpcomingMovies> recommendations = [];
  List<UpcomingMovies> similar = [];
  List<Trailer> trailers = [];
  
  // New API data
  Map<String, dynamic>? movieDetails;
  List<WatchProvider> streamingProviders = [];
  MovieCollection? collection;
  ExternalIds? externalIds;
  String? certification;
  List<Map<String, dynamic>> images = [];
  bool _showVoteCount = true;
  
  static const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

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
      print('🎬 Fetching movie details for ID: ${widget.movie.id}');
      
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/movie/${widget.movie.id}/credits?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/movie/${widget.movie.id}/reviews?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/movie/${widget.movie.id}/recommendations?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/movie/${widget.movie.id}/similar?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/movie/${widget.movie.id}/videos?api_key=$_apiKey')),
        // New API calls
        http.get(Uri.parse('$_baseUrl/movie/${widget.movie.id}?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/movie/${widget.movie.id}/watch/providers?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/movie/${widget.movie.id}/external_ids?api_key=$_apiKey')),
        http.get(Uri.parse('$_baseUrl/movie/${widget.movie.id}/images?api_key=$_apiKey')),
      ]);

      if (!mounted) return;

      print('✅ API calls completed');
      print('📊 Status codes: ${results.map((r) => r.statusCode).toList()}');

      setState(() {
        // Cast
        if (results[0].statusCode == 200) {
          final data = jsonDecode(results[0].body)['cast'] as List;
          cast = data.map((j) => MovieCast.fromJson(j)).toList();
          print('🎭 Cast loaded: ${cast.length}');
        }
        // Reviews
        if (results[1].statusCode == 200) {
          final data = jsonDecode(results[1].body)['results'] as List;
          reviews = data.cast<Map<String, dynamic>>().take(5).toList();
          print('💬 Reviews loaded: ${reviews.length}');
        }
        // Recommendations
        if (results[2].statusCode == 200) {
          final data = jsonDecode(results[2].body)['results'] as List;
          recommendations = data
              .where((j) => j['poster_path'] != null)
              .map((j) => UpcomingMovies.fromJson(j))
              .toList();
          print('🎯 Recommendations loaded: ${recommendations.length}');
        }
        // Similar
        if (results[3].statusCode == 200) {
          final data = jsonDecode(results[3].body)['results'] as List;
          similar = data
              .where((j) => j['poster_path'] != null)
              .map((j) => UpcomingMovies.fromJson(j))
              .toList();
          print('🎬 Similar movies loaded: ${similar.length}');
        }
        // Trailers
        if (results[4].statusCode == 200) {
          final data = jsonDecode(results[4].body)['results'] as List;
          trailers = data
              .map((j) => Trailer.fromJson(j))
              .where((t) => t.site == 'YouTube')
              .toList();
          print('🎥 Trailers loaded: ${trailers.length}');
        }
        // Movie Details (new)
        if (results[5].statusCode == 200) {
          movieDetails = jsonDecode(results[5].body);
          print('📝 Movie details loaded');
          print('   - Runtime: ${movieDetails!['runtime']}');
          print('   - Budget: ${movieDetails!['budget']}');
          print('   - Revenue: ${movieDetails!['revenue']}');
          print('   - Certification: ${movieDetails!['certification']}');
          
          // Fetch collection if exists
          if (movieDetails!['belongs_to_collection'] != null) {
            final collectionId = movieDetails!['belongs_to_collection']['id'];
            print('🎞️ Collection found, ID: $collectionId');
            _fetchCollection(collectionId);
          }
          // Fetch certification
          _fetchCertification();
        } else {
          print('❌ Movie details failed: ${results[5].statusCode}');
        }
        // Watch Providers (new)
        if (results[6].statusCode == 200) {
          final data = jsonDecode(results[6].body);
          if (data['results'] != null) {
            final providers = WatchProvidersResponse.fromJson(data);
            // Get PK (Pakistan) or US providers
            final pkProviders = providers.results['PK'] ?? providers.results['US'];
            if (pkProviders != null && pkProviders.flatrate.isNotEmpty) {
              streamingProviders = pkProviders.flatrate;
              print('📺 Streaming providers loaded: ${streamingProviders.length}');
            } else {
              print('⚠️ No streaming providers found for PK/US');
            }
          }
        } else {
          print('❌ Watch providers failed: ${results[6].statusCode}');
        }
        // External IDs (new)
        if (results[7].statusCode == 200) {
          externalIds = ExternalIds.fromJson(jsonDecode(results[7].body));
          print('🔗 External IDs loaded - IMDb: ${externalIds?.imdbId}');
        } else {
          print('❌ External IDs failed: ${results[7].statusCode}');
        }
        // Images (new)
        if (results[8].statusCode == 200) {
          final data = jsonDecode(results[8].body);
          if (data['backdrops'] != null) {
            images = (data['backdrops'] as List)
                .take(10)
                .map((e) => e as Map<String, dynamic>)
                .toList();
            print('🖼️ Images loaded: ${images.length}');
          }
        } else {
          print('❌ Images failed: ${results[8].statusCode}');
        }
      });
    } catch (e, stackTrace) {
      print('❌ Error in _fetchAll: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _fetchCollection(int collectionId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/collection/$collectionId?api_key=$_apiKey'));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          collection = MovieCollection.fromJson(jsonDecode(response.body));
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchCertification() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/certification/movie/list?api_key=$_apiKey'));
      if (response.statusCode == 200 && mounted) {
        final data = CertificationList.fromJson(jsonDecode(response.body));
        // Get US certification
        final usCerts = data.certifications['US'] ?? [];
        final cert = movieDetails!['certification'];
        if (cert != null && cert.isNotEmpty) {
          setState(() {
            certification = cert;
          });
        }
      }
    } catch (_) {}
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
                  Image.network(
                    'https://image.tmdb.org/t/p/w500/${widget.movie.posterPath}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.cardBg,
                        child: const Icon(Icons.movie_rounded,
                            color: AppTheme.textMuted, size: 60)),
                  ),
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
                  Text(widget.movie.title, style: AppTheme.headingLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _badge(icon: Icons.star_rounded,
                          label: widget.movie.voteAverage.toStringAsFixed(1),
                          color: AppTheme.accent),
                      if (widget.movie.releaseDate != null)
                        _badge(
                            icon: Icons.calendar_today_rounded,
                            label: DateFormat('MMM yyyy')
                                .format(widget.movie.releaseDate!),
                            color: AppTheme.textSecondary),
                      if (_showVoteCount)
                        _badge(
                            icon: Icons.how_to_vote_rounded,
                            label: '${widget.movie.voteCount} votes',
                            color: AppTheme.textSecondary),
                      // CineVerse app rating
                      AppRatingBadge(
                          collectionId: 'movie_${widget.movie.id}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Favorite + Watchlist buttons
                  MediaActionButtons(
                    mediaId: widget.movie.id,
                    mediaType: 'movie',
                    title: widget.movie.title,
                    posterPath: widget.movie.posterPath,
                    voteAverage: widget.movie.voteAverage,
                  ),
                  const SizedBox(height: 20),

                  // Overview
                  _sectionTitle('Overview'),
                  const SizedBox(height: 8),
                  Text(widget.movie.overview, style: AppTheme.bodyText),
                  const SizedBox(height: 28),

                  // Movie Details (Runtime, Budget, Revenue, Certification)
                  if (movieDetails != null) ...[
                    _sectionTitle('Details'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (movieDetails!['runtime'] != null)
                          _badge(
                              icon: Icons.timer_rounded,
                              label: '${_formatRuntime(movieDetails!['runtime'])}',
                              color: AppTheme.textSecondary),
                        if (certification != null)
                          _badge(
                              icon: Icons.shield_rounded,
                              label: certification!,
                              color: AppTheme.accent),
                        if (movieDetails!['status'] != null)
                          _badge(
                              icon: Icons.info_outline_rounded,
                              label: movieDetails!['status'],
                              color: AppTheme.textSecondary),
                      ],
                    ),
                    if (movieDetails!['budget'] != null && movieDetails!['budget'] > 0 ||
                        movieDetails!['revenue'] != null && movieDetails!['revenue'] > 0) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (movieDetails!['budget'] != null && movieDetails!['budget'] > 0)
                            Expanded(
                              child: _infoCard(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Budget',
                                value: _formatCurrency(movieDetails!['budget']),
                              ),
                            ),
                          if (movieDetails!['budget'] != null && movieDetails!['budget'] > 0 &&
                              movieDetails!['revenue'] != null && movieDetails!['revenue'] > 0)
                            const SizedBox(width: 12),
                          if (movieDetails!['revenue'] != null && movieDetails!['revenue'] > 0)
                            Expanded(
                              child: _infoCard(
                                icon: Icons.trending_up_rounded,
                                label: 'Revenue',
                                value: _formatCurrency(movieDetails!['revenue']),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],

                  // External Links (IMDb)
                  if (externalIds?.imdbId != null) ...[
                    GestureDetector(
                      onTap: () async {
                        final url = Uri.parse('https://www.imdb.com/title/${externalIds!.imdbId}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.open_in_new_rounded, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'View on IMDb',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Where to Watch (Streaming Providers)
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
                          final provider = streamingProviders[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    'https://image.tmdb.org/t/p/w92${provider.logoPath}',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.tv_rounded, color: AppTheme.textMuted),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider.providerName,
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                    fontSize: 9,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                  : '${widget.movie.title} — Trailer',
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
                  if (images.isNotEmpty) ...[
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
                              title: widget.movie.title,
                              backdrops: images,
                              posters: const [],
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
                        itemCount: images.length > 6 ? 6 : images.length,
                        itemBuilder: (context, index) {
                          final path = images[index]['file_path'] ?? '';
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => MediaGalleryScreen(
                                title: widget.movie.title,
                                backdrops: images,
                                posters: const [],
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
                          mediaId: widget.movie.id,
                          mediaTitle: widget.movie.title,
                          mediaType: 'movie',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('collectionId',
                            isEqualTo: 'movie_${widget.movie.id}')
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
                                mediaId: widget.movie.id,
                                mediaTitle: widget.movie.title,
                                mediaType: 'movie',
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
                          // Firestore user reviews
                          ...firestoreDocs.take(2).map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return _DetailReviewCard(data: d, isFirestore: true);
                          }),
                          // TMDB reviews
                          ...reviews.take(2 - firestoreDocs.length.clamp(0, 2))
                              .map((r) => _DetailReviewCard(data: r, isFirestore: false)),
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
                          final m = recommendations[index];
                          return _SmallMovieCard(
                              movie: m, heroTag: 'rec_${m.id}_$index');
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Similar
                  if (similar.isNotEmpty) ...[
                    _sectionTitle('Similar Movies'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: similar.length,
                        itemBuilder: (context, index) {
                          final m = similar[index];
                          return _SmallMovieCard(
                              movie: m, heroTag: 'sim_${m.id}_$index');
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

  Widget _sectionTitle(String title) =>
      Text(title, style: AppTheme.sectionTitle.copyWith(color: AppTheme.accent));

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

  Widget _badge(
      {required IconData icon, required String label, required Color color}) {
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

  String _formatRuntime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$$amount';
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small card widgets ──────────────────────────────────────────────────────

class _SmallMovieCard extends StatelessWidget {
  final UpcomingMovies movie;
  final String heroTag;
  const _SmallMovieCard({required this.movie, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Moviedetails(movie: movie)),
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
                      'https://image.tmdb.org/t/p/w300/${movie.posterPath}',
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
                            Text(movie.voteAverage.toStringAsFixed(1),
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
            Text(movie.title,
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

// ── Review card ─────────────────────────────────────────────────────────────

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

// ── Detail page review card (Firestore + TMDB) ──────────────────────────────

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
    final author = widget.isFirestore
        ? (widget.data['author'] ?? 'Anonymous')
        : (widget.data['author'] ?? 'Anonymous');
    final content = widget.isFirestore
        ? (widget.data['content'] ?? '')
        : (widget.data['content'] ?? '');
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
