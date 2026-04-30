import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

/// Shows CineVerse app average rating from Firestore reviews
class AppRatingBadge extends StatelessWidget {
  final String collectionId; // e.g. 'movie_123', 'tv_456', 'episode_789_1_3'

  const AppRatingBadge({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('collectionId', isEqualTo: collectionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        final ratings = docs
            .map((d) => (d.data() as Map<String, dynamic>)['rating'])
            .where((r) => r != null)
            .map((r) => (r as num).toDouble())
            .toList();

        if (ratings.isEmpty) return const SizedBox.shrink();

        final avg = ratings.reduce((a, b) => a + b) / ratings.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.5), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFF6C63FF), size: 13),
              const SizedBox(width: 4),
              Text(
                avg.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6C63FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'CV',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6C63FF).withOpacity(0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
