import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

/// YouTube app mein open karo — play/pause/fullscreen/10sec skip sab milta hai
Future<void> _launchYouTube(String videoId) async {
  // Pehle YouTube app try karo
  final appUri = Uri.parse('youtube://www.youtube.com/watch?v=$videoId');
  // Fallback: browser
  final webUri = Uri.parse('https://www.youtube.com/watch?v=$videoId');

  if (await canLaunchUrl(appUri)) {
    await launchUrl(appUri);
  } else {
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

/// Thumbnail card — tap karo toh YouTube mein open ho
class TrailerThumbnailCard extends StatelessWidget {
  final String videoId;
  final String title;

  const TrailerThumbnailCard({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchYouTube(videoId),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thumbnail
              Image.network(
                'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.cardBg,
                    child: const Center(
                      child: Icon(Icons.movie_rounded,
                          color: AppTheme.textMuted, size: 40),
                    ),
                  ),
                ),
              ),
              // Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Play button
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.9), width: 2),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 30),
              ),
              // YouTube badge
              Positioned(
                bottom: 8,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 11),
                      const SizedBox(width: 3),
                      Text('YouTube',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ),
              // Title
              Positioned(
                bottom: 8,
                left: 10,
                right: 80,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 6)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
