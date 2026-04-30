import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_cache.dart';
import 'app_theme.dart';
import 'Movie_Details.dart';
import 'Upcomming_Movies_model.dart';
import 'widgets/premium_card.dart';

class PopularMoviesHome extends StatefulWidget {
  const PopularMoviesHome({super.key});

  @override
  State<PopularMoviesHome> createState() => _PopularMoviesHomeState();
}

class _PopularMoviesHomeState extends State<PopularMoviesHome> {
  late Future<List<UpcomingMovies>> _future;

  @override
  void initState() {
    super.initState();
    const cacheKey = 'popular_movies_home';
    final cache = ApiCache();
    if (cache.has(cacheKey)) {
      _future = Future.value(cache.get<List<UpcomingMovies>>(cacheKey));
    } else {
      _future = _fetchData();
    }
  }

  Future<List<UpcomingMovies>> _fetchData() async {
    const cacheKey = 'popular_movies_home';
    final response = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/movie/popular?api_key=e850641520c5c6eacf9b2f679e373ff4'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['results'] as List;
      final result = data.map((json) => UpcomingMovies.fromJson(json)).toList();
      ApiCache().set(cacheKey, result);
      return result;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UpcomingMovies>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 2));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No data',
                  style: TextStyle(color: AppTheme.textMuted)));
        }
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final movie = snapshot.data![index];
            return PremiumMovieCard(
              posterPath: movie.posterPath,
              title: movie.title,
              rating: movie.voteAverage,
              heroTag: 'home_pop_${movie.id}_$index',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Moviedetails(movie: movie)),
              ),
            );
          },
        );
      },
    );
  }
}
