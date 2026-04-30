import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'actor_detail_screen.dart';
import 'reviews_screen.dart';
import 'widgets/app_rating_widget.dart';

class EpisodeDetailScreen extends StatefulWidget {
  final int tvId;
  final int seasonNumber;
  final int episodeNumber;
  final String tvName;

  const EpisodeDetailScreen({
    super.key,
    required this.tvId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.tvName,
  });

  @override
  State<EpisodeDetailScreen> createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen> {
  static const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';
  static const String _base = 'https://api.themoviedb.org/3';

  Map<String, dynamic>? _episode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEpisode();
  }

  Future<void> _fetchEpisode() async {
    try {
      final res = await http.get(Uri.parse(
          '$_base/tv/${widget.tvId}/season/${widget.seasonNumber}/episode/${widget.episodeNumber}?api_key=$_apiKey&append_to_response=credits,images,videos'));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _episode = jsonDecode(res.body);
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 2))
          : _episode == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.textMuted, size: 50),
                      const SizedBox(height: 10),
                      Text('Failed to load episode',
                          style: AppTheme.bodyText),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final ep = _episode!;
    final name = ep['name'] ?? 'Episode ${widget.episodeNumber}';
    final overview = ep['overview'] ?? '';
    final stillPath = ep['still_path'];
    final airDate = ep['air_date'] ?? '';
    final runtime = ep['runtime'];
    final rating = (ep['vote_average'] as num?)?.toDouble() ?? 0.0;
    final voteCount = ep['vote_count'] ?? 0;
    final epNum = ep['episode_number'] ?? widget.episodeNumber;
    final seasonNum = ep['season_number'] ?? widget.seasonNumber;

    // Credits
    final cast = (ep['credits']?['cast'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final guestStars = (ep['credits']?['guest_stars'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final crew = (ep['credits']?['crew'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    // Director & Writer
    final director = crew.firstWhere(
        (c) => c['job'] == 'Director',
        orElse: () => {});
    final writer = crew.firstWhere(
        (c) => c['job'] == 'Writer' || c['job'] == 'Screenplay',
        orElse: () => {});

    // Images
    final stills = (ep['images']?['stills'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Hero still image
        SliverAppBar(
          expandedHeight: stillPath != null ? 260 : 120,
          pinned: true,
          backgroundColor: AppTheme.background,
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
          flexibleSpace: FlexibleSpaceBar(
            background: stillPath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://image.tmdb.org/t/p/w780$stillPath',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppTheme.cardBg),
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
                  )
                : Container(color: AppTheme.cardBg),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Episode number badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'S${seasonNum}E$epNum',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.tvName,
                        style: AppTheme.caption,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(name, style: AppTheme.headingLarge),
                const SizedBox(height: 12),

                // Meta badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (rating > 0)
                      _badge(
                          icon: Icons.star_rounded,
                          label: '${rating.toStringAsFixed(1)} ($voteCount)',
                          color: AppTheme.accent),
                    if (airDate.isNotEmpty)
                      _badge(
                          icon: Icons.calendar_today_rounded,
                          label: airDate,
                          color: AppTheme.textSecondary),
                    if (runtime != null)
                      _badge(
                          icon: Icons.timer_rounded,
                          label: '${runtime}m',
                          color: AppTheme.textSecondary),
                    if (director.isNotEmpty)
                      _badge(
                          icon: Icons.movie_filter_rounded,
                          label: 'Dir: ${director['name'] ?? ''}',
                          color: AppTheme.textSecondary),
                    if (writer.isNotEmpty)
                      _badge(
                          icon: Icons.edit_rounded,
                          label: 'Writer: ${writer['name'] ?? ''}',
                          color: AppTheme.textSecondary),
                    // CineVerse app rating
                    AppRatingBadge(
                        collectionId:
                            'episode_${widget.tvId}_${widget.seasonNumber}_${widget.episodeNumber}'),
                  ],
                ),
                const SizedBox(height: 20),

                // Overview
                if (overview.isNotEmpty) ...[
                  _sectionTitle('Overview'),
                  const SizedBox(height: 8),
                  Text(overview, style: AppTheme.bodyText),
                  const SizedBox(height: 28),
                ],

                // Still images
                if (stills.isNotEmpty) ...[
                  _sectionTitle('Pictures'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: stills.length > 8 ? 8 : stills.length,
                      itemBuilder: (context, index) {
                        final path = stills[index]['file_path'] ?? '';
                        return GestureDetector(
                          onTap: () => _openStillFullscreen(stills, index),
                          child: Container(
                            width: 170,
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

                // Regular Cast
                if (cast.isNotEmpty) ...[
                  _sectionTitle('Cast'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: cast.length,
                      itemBuilder: (context, index) =>
                          _castCard(cast[index]),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Guest Stars
                if (guestStars.isNotEmpty) ...[
                  _sectionTitle('Guest Stars'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: guestStars.length,
                      itemBuilder: (context, index) =>
                          _castCard(guestStars[index]),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Crew highlights
                if (crew.isNotEmpty) ...[
                  _sectionTitle('Crew'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: crew
                        .where((c) => [
                              'Director',
                              'Writer',
                              'Screenplay',
                              'Producer',
                              'Executive Producer',
                              'Director of Photography',
                            ].contains(c['job']))
                        .take(10)
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.divider, width: 0.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    c['name'] ?? '',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    c['job'] ?? '',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],

                // Reviews section
                const SizedBox(height: 28),
                _buildReviewsSection(context, epNum, seasonNum),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(
      BuildContext context, int epNum, int seasonNum) {
    final collectionId =
        'episode_${widget.tvId}_${widget.seasonNumber}_${widget.episodeNumber}';
    final title =
        'S${seasonNum}E$epNum - ${_episode?['name'] ?? 'Episode'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews',
                style: AppTheme.sectionTitle
                    .copyWith(color: AppTheme.accent)),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsScreen(
                    mediaId: widget.tvId * 10000 +
                        widget.seasonNumber * 100 +
                        widget.episodeNumber,
                    mediaTitle: title,
                    mediaType: 'episode',
                    customCollectionId: collectionId,
                  ),
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
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('collectionId', isEqualTo: collectionId)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.hasData ? snapshot.data!.docs : [];
            if (docs.isEmpty) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewsScreen(
                      mediaId: widget.tvId * 10000 +
                          widget.seasonNumber * 100 +
                          widget.episodeNumber,
                      mediaTitle: title,
                      mediaType: 'episode',
                      customCollectionId: collectionId,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider, width: 0.5),
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
              children: docs.take(2).map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final author = d['author'] ?? 'Anonymous';
                final content = d['content'] ?? '';
                final rating = (d['rating'] as num?)?.toDouble();
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
                            backgroundColor:
                                AppTheme.accent.withOpacity(0.15),
                            child: Text(
                              author.isNotEmpty
                                  ? author[0].toUpperCase()
                                  : 'A',
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
                                Text(rating.toStringAsFixed(1),
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyText.copyWith(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _castCard(Map<String, dynamic> person) {
    final name = person['name'] ?? '';
    final character = person['character'] ?? '';
    final profilePath = person['profile_path'];
    final personId = person['id'];

    return GestureDetector(
      onTap: () {
        if (personId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActorDetailScreen(
                personId: personId,
                name: name,
                profilePath: profilePath ?? '',
              ),
            ),
          );
        }
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.cardBg,
              backgroundImage: profilePath != null && profilePath.isNotEmpty
                  ? NetworkImage(
                      'https://image.tmdb.org/t/p/w200$profilePath')
                  : null,
              child: profilePath == null || profilePath.isEmpty
                  ? const Icon(Icons.person_rounded,
                      color: AppTheme.textMuted, size: 28)
                  : null,
            ),
            const SizedBox(height: 5),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (character.isNotEmpty)
              Text(
                character,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppTheme.textMuted,
                  fontSize: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) =>
      Text(title, style: AppTheme.sectionTitle.copyWith(color: AppTheme.accent));

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

  void _openStillFullscreen(
      List<Map<String, dynamic>> stills, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StillsFullscreen(
          stills: stills,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _StillsFullscreen extends StatefulWidget {
  final List<Map<String, dynamic>> stills;
  final int initialIndex;
  const _StillsFullscreen(
      {required this.stills, required this.initialIndex});

  @override
  State<_StillsFullscreen> createState() => _StillsFullscreenState();
}

class _StillsFullscreenState extends State<_StillsFullscreen> {
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
            itemCount: widget.stills.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final path = widget.stills[index]['file_path'] ?? '';
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_current + 1} / ${widget.stills.length}',
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
