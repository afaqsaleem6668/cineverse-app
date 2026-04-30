import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'TVShows_Details.dart';
import 'TVShows_Model.dart';
import 'Upcomming_Movies_model.dart';

class ActorDetailScreen extends StatefulWidget {
  final int personId;
  final String name;
  final String profilePath;

  const ActorDetailScreen({
    super.key,
    required this.personId,
    required this.name,
    required this.profilePath,
  });

  @override
  State<ActorDetailScreen> createState() => _ActorDetailScreenState();
}

class _ActorDetailScreenState extends State<ActorDetailScreen>
    with SingleTickerProviderStateMixin {
  static const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';
  static const String _base = 'https://api.themoviedb.org/3';

  Map<String, dynamic>? _details;
  List<Map<String, dynamic>> _movieCredits = [];
  List<Map<String, dynamic>> _tvCredits = [];
  List<Map<String, dynamic>> _images = [];
  Map<String, dynamic>? _externalIds;
  bool _loading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_base/person/${widget.personId}?api_key=$_apiKey')),
        http.get(Uri.parse('$_base/person/${widget.personId}/movie_credits?api_key=$_apiKey')),
        http.get(Uri.parse('$_base/person/${widget.personId}/tv_credits?api_key=$_apiKey')),
        http.get(Uri.parse('$_base/person/${widget.personId}/images?api_key=$_apiKey')),
        http.get(Uri.parse('$_base/person/${widget.personId}/external_ids?api_key=$_apiKey')),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].statusCode == 200) {
            _details = jsonDecode(results[0].body);
          }
          if (results[1].statusCode == 200) {
            final cast = jsonDecode(results[1].body)['cast'] as List? ?? [];
            _movieCredits = cast
                .cast<Map<String, dynamic>>()
                .where((c) => c['poster_path'] != null)
                .toList()
              ..sort((a, b) => ((b['popularity'] as num?) ?? 0)
                  .compareTo((a['popularity'] as num?) ?? 0));
          }
          if (results[2].statusCode == 200) {
            final cast = jsonDecode(results[2].body)['cast'] as List? ?? [];
            _tvCredits = cast
                .cast<Map<String, dynamic>>()
                .where((c) => c['poster_path'] != null)
                .toList()
              ..sort((a, b) => ((b['popularity'] as num?) ?? 0)
                  .compareTo((a['popularity'] as num?) ?? 0));
          }
          if (results[3].statusCode == 200) {
            final profiles = jsonDecode(results[3].body)['profiles'] as List? ?? [];
            _images = profiles.cast<Map<String, dynamic>>().take(20).toList();
          }
          if (results[4].statusCode == 200) {
            _externalIds = jsonDecode(results[4].body);
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: AppTheme.background,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.profilePath.isNotEmpty
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w500${widget.profilePath}',
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
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.accent, strokeWidth: 2)),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name, style: AppTheme.headingLarge),
                        const SizedBox(height: 8),

                        if (_details != null) ...[
                          // Meta badges
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_details!['known_for_department'] != null)
                                _badge(
                                  icon: Icons.work_outline_rounded,
                                  label: _details!['known_for_department'],
                                  color: AppTheme.accent,
                                ),
                              if (_details!['birthday'] != null)
                                _badge(
                                  icon: Icons.cake_outlined,
                                  label: _details!['birthday'],
                                  color: AppTheme.textSecondary,
                                ),
                              if (_details!['place_of_birth'] != null)
                                _badge(
                                  icon: Icons.location_on_outlined,
                                  label: _details!['place_of_birth'],
                                  color: AppTheme.textSecondary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Social media links
                          if (_externalIds != null) ...[
                            _buildSocialLinks(),
                            const SizedBox(height: 20),
                          ],

                          // Biography
                          if (_details!['biography'] != null &&
                              (_details!['biography'] as String).isNotEmpty) ...[
                            Text('Biography',
                                style: AppTheme.sectionTitle
                                    .copyWith(color: AppTheme.accent)),
                            const SizedBox(height: 8),
                            _ExpandableBio(bio: _details!['biography'] as String),
                            const SizedBox(height: 28),
                          ],
                        ],

                        // Photos gallery
                        if (_images.isNotEmpty) ...[
                          Text('Photos',
                              style: AppTheme.sectionTitle
                                  .copyWith(color: AppTheme.accent)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              itemCount: _images.length,
                              itemBuilder: (context, index) {
                                final img = _images[index];
                                final path = img['file_path'] ?? '';
                                return GestureDetector(
                                  onTap: () => _openPhotoFullscreen(index),
                                  child: Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        'https://image.tmdb.org/t/p/w185$path',
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

                        // Credits tabs
                        if (_movieCredits.isNotEmpty || _tvCredits.isNotEmpty) ...[
                          // Tab bar
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.divider, width: 0.5),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                gradient: AppTheme.goldGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              labelColor: Colors.black,
                              unselectedLabelColor: AppTheme.textMuted,
                              labelStyle: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              unselectedLabelStyle: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w400),
                              tabs: [
                                Tab(text: 'Movies (${_movieCredits.length})'),
                                Tab(text: 'TV Shows (${_tvCredits.length})'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 220,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildCreditsList(_movieCredits, isMovie: true),
                                _buildCreditsList(_tvCredits, isMovie: false),
                              ],
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

  Widget _buildSocialLinks() {
    final imdb = _externalIds?['imdb_id'];
    final instagram = _externalIds?['instagram_id'];
    final twitter = _externalIds?['twitter_id'];
    final facebook = _externalIds?['facebook_id'];

    final links = <Widget>[];

    if (imdb != null && imdb.toString().isNotEmpty) {
      links.add(_socialButton(
        icon: Icons.movie_rounded,
        label: 'IMDb',
        color: const Color(0xFFF5C518),
        onTap: () => _launchUrl('https://www.imdb.com/name/$imdb'),
      ));
    }
    if (instagram != null && instagram.toString().isNotEmpty) {
      links.add(_socialButton(
        icon: Icons.camera_alt_rounded,
        label: 'Instagram',
        color: const Color(0xFFE1306C),
        onTap: () => _launchUrl('https://www.instagram.com/$instagram'),
      ));
    }
    if (twitter != null && twitter.toString().isNotEmpty) {
      links.add(_socialButton(
        icon: Icons.alternate_email_rounded,
        label: 'Twitter',
        color: const Color(0xFF1DA1F2),
        onTap: () => _launchUrl('https://twitter.com/$twitter'),
      ));
    }
    if (facebook != null && facebook.toString().isNotEmpty) {
      links.add(_socialButton(
        icon: Icons.facebook_rounded,
        label: 'Facebook',
        color: const Color(0xFF1877F2),
        onTap: () => _launchUrl('https://www.facebook.com/$facebook'),
      ));
    }

    if (links.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: links);
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsList(List<Map<String, dynamic>> credits,
      {required bool isMovie}) {
    if (credits.isEmpty) {
      return Center(
        child: Text('No credits found', style: AppTheme.bodyText),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: credits.length > 20 ? 20 : credits.length,
      itemBuilder: (context, index) {
        final credit = credits[index];
        final title = isMovie
            ? (credit['title'] ?? '')
            : (credit['name'] ?? '');
        final poster = credit['poster_path'] ?? '';
        final rating = (credit['vote_average'] as num?)?.toDouble() ?? 0.0;

        return GestureDetector(
          onTap: () {
            if (isMovie) {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        Moviedetails(movie: UpcomingMovies.fromJson(credit)),
                  ),
                );
              } catch (_) {}
            } else {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TVShowsDetails(
                        tvshowsdetails: PopularTvShows.fromJson(credit)),
                  ),
                );
              } catch (_) {}
            }
          },
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
                        poster.isNotEmpty
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w300$poster',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: AppTheme.cardBg),
                              )
                            : Container(color: AppTheme.cardBg),
                        if (rating > 0)
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
                                  Text(rating.toStringAsFixed(1),
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
                Text(title,
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
      },
    );
  }

  void _openPhotoFullscreen(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoFullscreen(
          images: _images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
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
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoFullscreen extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;
  const _PhotoFullscreen({required this.images, required this.initialIndex});

  @override
  State<_PhotoFullscreen> createState() => _PhotoFullscreenState();
}

class _PhotoFullscreenState extends State<_PhotoFullscreen> {
  late PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final path = widget.images[index]['file_path'] ?? '';
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    'https://image.tmdb.org/t/p/original$path',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.white54,
                        size: 60),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_current + 1} / ${widget.images.length}',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableBio extends StatefulWidget {
  final String bio;
  const _ExpandableBio({required this.bio});

  @override
  State<_ExpandableBio> createState() => _ExpandableBioState();
}

class _ExpandableBioState extends State<_ExpandableBio> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.bio,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: AppTheme.bodyText,
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Read more',
            style: AppTheme.accentText,
          ),
        ),
      ],
    );
  }
}
