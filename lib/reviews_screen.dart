import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  final int mediaId;
  final String mediaTitle;
  final String mediaType;
  final String? customCollectionId; // for episodes

  const ReviewsScreen({
    super.key,
    required this.mediaId,
    required this.mediaTitle,
    required this.mediaType,
    this.customCollectionId,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';
  List<Map<String, dynamic>> _apiReviews = [];
  bool _loadingApi = true;
  bool _showAddReview = false;
  final _reviewCtrl = TextEditingController();
  double _userRating = 7.0;
  String _username = 'Anonymous';
  String _userId = '';

  final _firestore = FirebaseFirestore.instance;

  String get _collectionId =>
      widget.customCollectionId ?? '${widget.mediaType}_${widget.mediaId}';

  @override
  void initState() {
    super.initState();
    _fetchApiReviews();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? 'Anonymous';
        _userId = prefs.getString('email') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      });
    }
  }

  Future<void> _fetchApiReviews() async {
    // Episodes don't have TMDB reviews API
    if (widget.mediaType == 'episode') {
      if (mounted) setState(() => _loadingApi = false);
      return;
    }
    try {
      List<Map<String, dynamic>> all = [];
      for (int page = 1; page <= 3; page++) {
        final res = await http.get(Uri.parse(
            'https://api.themoviedb.org/3/${widget.mediaType}/${widget.mediaId}/reviews?api_key=$_apiKey&page=$page'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body)['results'] as List;
          all.addAll(data.cast<Map<String, dynamic>>());
        }
      }
      if (mounted) setState(() {
        _apiReviews = all;
        _loadingApi = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingApi = false);
    }
  }

  Future<void> _submitReview() async {
    if (_reviewCtrl.text.trim().isEmpty) return;
    try {
      // Check if user already reviewed this media
      final existing = await _firestore
          .collection('reviews')
          .where('collectionId', isEqualTo: _collectionId)
          .where('userId', isEqualTo: _userId)
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have already reviewed this!',
                  style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      await _firestore.collection('reviews').add({
        'collectionId': _collectionId,
        'mediaId': widget.mediaId,
        'mediaType': widget.mediaType,
        'mediaTitle': widget.mediaTitle,
        'author': _username,
        'userId': _userId,
        'content': _reviewCtrl.text.trim(),
        'rating': _userRating,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _showAddReview = false;
          _reviewCtrl.clear();
          _userRating = 7.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review submitted!',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _deleteReview(String docId) async {
    await _firestore.collection('reviews').doc(docId).delete();
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
                        Text('Reviews', style: AppTheme.headingMedium),
                        Text(widget.mediaTitle,
                            style: AppTheme.caption,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      // Check if user already reviewed
                      final existing = await _firestore
                          .collection('reviews')
                          .where('collectionId', isEqualTo: _collectionId)
                          .where('userId', isEqualTo: _userId)
                          .get();
                      if (existing.docs.isNotEmpty) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('You have already reviewed this!',
                                  style: GoogleFonts.poppins(color: Colors.white)),
                              backgroundColor: AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                        return;
                      }
                      if (mounted) setState(() => _showAddReview = !_showAddReview);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded,
                              color: Colors.black, size: 14),
                          const SizedBox(width: 5),
                          Text('Review',
                              style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Add review form
            if (_showAddReview)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.3), width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Review',
                        style: AppTheme.sectionTitle
                            .copyWith(color: AppTheme.accent)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.accent, size: 18),
                        const SizedBox(width: 8),
                        Text(_userRating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        Expanded(
                          child: Slider(
                            value: _userRating,
                            min: 1,
                            max: 10,
                            divisions: 18,
                            activeColor: AppTheme.accent,
                            inactiveColor: AppTheme.divider,
                            onChanged: (v) =>
                                setState(() => _userRating = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: TextField(
                        controller: _reviewCtrl,
                        maxLines: 4,
                        style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Write your review...',
                          hintStyle: GoogleFonts.poppins(
                              color: AppTheme.textMuted, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _showAddReview = false),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.divider, width: 0.5),
                              ),
                              child: Center(
                                child: Text('Cancel',
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _submitReview,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: AppTheme.goldGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text('Submit',
                                    style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // Reviews list — Firestore real-time + API reviews
            Expanded(
              child: _loadingApi
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accent, strokeWidth: 2))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('reviews')
                          .where('collectionId', isEqualTo: _collectionId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final firestoreReviews = snapshot.hasData
                            ? snapshot.data!.docs
                            : <QueryDocumentSnapshot>[];

                        final totalCount =
                            firestoreReviews.length + _apiReviews.length;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: Row(
                                children: [
                                  Text('$totalCount reviews',
                                      style: AppTheme.caption),
                                  if (firestoreReviews.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.goldGradient,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                          '${firestoreReviews.length} user',
                                          style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: totalCount == 0
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              Icons.rate_review_outlined,
                                              color: AppTheme.textMuted,
                                              size: 50),
                                          const SizedBox(height: 10),
                                          Text('No reviews yet',
                                              style: AppTheme.bodyText),
                                          const SizedBox(height: 6),
                                          Text('Be the first to review!',
                                              style: AppTheme.caption),
                                        ],
                                      ),
                                    )
                                  : ListView(
                                      physics:
                                          const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 20),
                                      children: [
                                        // Firestore user reviews first
                                        ...firestoreReviews.map((doc) {
                                          final data = doc.data()
                                              as Map<String, dynamic>;
                                          final isOwn =
                                              data['userId'] == _userId;
                                          return _FirestoreReviewCard(
                                            data: data,
                                            isOwn: isOwn,
                                            docId: doc.id,
                                            onDelete: isOwn
                                                ? () =>
                                                    _deleteReview(doc.id)
                                                : null,
                                          );
                                        }),
                                        // TMDB API reviews
                                        ..._apiReviews.map((r) =>
                                            _ApiReviewCard(review: r)),
                                      ],
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Firestore review card
class _FirestoreReviewCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isOwn;
  final VoidCallback? onDelete;
  final String docId;

  const _FirestoreReviewCard({
    required this.data,
    required this.isOwn,
    required this.docId,
    this.onDelete,
  });

  @override
  State<_FirestoreReviewCard> createState() => _FirestoreReviewCardState();
}

class _FirestoreReviewCardState extends State<_FirestoreReviewCard> {
  bool _expanded = false;
  bool _editing = false;
  late TextEditingController _editCtrl;
  late double _editRating;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.data['content'] ?? '');
    _editRating = (widget.data['rating'] as num?)?.toDouble() ?? 7.0;
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    if (_editCtrl.text.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.docId)
        .update({
      'content': _editCtrl.text.trim(),
      'rating': _editRating,
    });
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.data['author'] ?? 'Anonymous';
    final content = widget.data['content'] ?? '';
    final rating = (widget.data['rating'] as num?)?.toDouble();
    final ts = widget.data['createdAt'] as Timestamp?;
    final date = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isOwn
            ? AppTheme.accent.withOpacity(0.06)
            : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isOwn
              ? AppTheme.accent.withOpacity(0.3)
              : AppTheme.divider,
          width: widget.isOwn ? 0.8 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.accent.withOpacity(0.2),
                child: Text(
                  author.isNotEmpty ? author[0].toUpperCase() : 'A',
                  style: GoogleFonts.poppins(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(author,
                            style: GoogleFonts.poppins(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        if (widget.isOwn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text('You',
                                style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    if (date.isNotEmpty)
                      Text(date, style: AppTheme.caption),
                  ],
                ),
              ),
              if (rating != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.accent.withOpacity(0.3),
                        width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.accent, size: 12),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              if (widget.isOwn && widget.onDelete != null) ...[
                const SizedBox(width: 8),
                // Edit button
                GestureDetector(
                  onTap: () => setState(() => _editing = !_editing),
                  child: Icon(
                    _editing ? Icons.close_rounded : Icons.edit_rounded,
                    color: AppTheme.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.error, size: 18),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Edit mode
          if (_editing) ...[
            // Rating slider
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppTheme.accent, size: 16),
                const SizedBox(width: 6),
                Text(_editRating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Expanded(
                  child: Slider(
                    value: _editRating,
                    min: 1,
                    max: 10,
                    divisions: 18,
                    activeColor: AppTheme.accent,
                    inactiveColor: AppTheme.divider,
                    onChanged: (v) => setState(() => _editRating = v),
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider, width: 0.5),
              ),
              child: TextField(
                controller: _editCtrl,
                maxLines: 4,
                style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Edit your review...',
                  hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _editing = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: Center(
                        child: Text('Cancel',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _saveEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('Save',
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              content,
              maxLines: _expanded ? null : 4,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: AppTheme.bodyText.copyWith(fontSize: 13, height: 1.5),
            ),
            if (content.length > 200) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show less' : 'Read more',
                    style: AppTheme.accentText),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// TMDB API review card
class _ApiReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  const _ApiReviewCard({required this.review});

  @override
  State<_ApiReviewCard> createState() => _ApiReviewCardState();
}

class _ApiReviewCardState extends State<_ApiReviewCard> {
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
                radius: 18,
                backgroundColor: AppTheme.accent.withOpacity(0.15),
                child: Text(
                  author.isNotEmpty ? author[0].toUpperCase() : 'A',
                  style: GoogleFonts.poppins(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.accent.withOpacity(0.3),
                        width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.accent, size: 12),
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
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            maxLines: _expanded ? null : 4,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: AppTheme.bodyText.copyWith(fontSize: 13, height: 1.5),
          ),
          if (content.length > 200) ...[
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
