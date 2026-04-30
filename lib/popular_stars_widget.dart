import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'actor_detail_screen.dart';

class PopularStarsWidget extends StatelessWidget {
  const PopularStarsWidget({super.key});

  Future<List<Map<String, dynamic>>> _fetchStars() async {
    final response = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/person/popular?api_key=e850641520c5c6eacf9b2f679e373ff4'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['results'] as List;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchStars(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 2));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final person = snapshot.data![index];
            final name = person['name'] ?? '';
            final profilePath = person['profile_path'] ?? '';
            final knownFor = (person['known_for_department'] ?? 'Acting');

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActorDetailScreen(
                    personId: person['id'],
                    name: name,
                    profilePath: profilePath,
                  ),
                ),
              ),
              child: Container(
                width: 90,
                margin: const EdgeInsets.only(right: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.accent.withOpacity(0.4), width: 2),
                      ),
                      child: ClipOval(
                        child: profilePath.isNotEmpty
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w200$profilePath',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppTheme.cardBg,
                                  child: const Icon(Icons.person_rounded,
                                      color: AppTheme.textMuted, size: 36),
                                ),
                              )
                            : Container(
                                color: AppTheme.cardBg,
                                child: const Icon(Icons.person_rounded,
                                    color: AppTheme.textMuted, size: 36),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      knownFor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
