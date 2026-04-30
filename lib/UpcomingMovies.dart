import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_cache.dart';
import 'app_theme.dart';
import 'Genre_Model.dart';
import 'Movie_Details.dart';
import 'Upcomming_Movies_model.dart';
import 'widgets/premium_card.dart';

class UpcomingMoviesWidget extends StatefulWidget {
  const UpcomingMoviesWidget({Key? key, this.selectedGenre}) : super(key: key);
  final Genre? selectedGenre;

  @override
  State<UpcomingMoviesWidget> createState() => _UpcomingMoviesWidgetState();
}

class _UpcomingMoviesWidgetState extends State<UpcomingMoviesWidget> {
  late Future<List<UpcomingMovies>> _future;

  @override
  void initState() {
    super.initState();
    final cacheKey = 'upcoming_movies_${widget.selectedGenre?.id}';
    final cache = ApiCache();
    if (widget.selectedGenre == null && cache.has(cacheKey)) {
      _future = Future.value(cache.get<List<UpcomingMovies>>(cacheKey));
    } else {
      _future = _fetchData();
    }
  }

  @override
  void didUpdateWidget(UpcomingMoviesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGenre != widget.selectedGenre) {
      final f = _fetchData();
      setState(() => _future = f);
    }
  }

  Future<List<UpcomingMovies>> _fetchData() async {
    final genreId = widget.selectedGenre?.id;
    final cacheKey = 'upcoming_movies_$genreId';
    final url = genreId == null
        ? 'https://api.themoviedb.org/3/movie/upcoming?api_key=e850641520c5c6eacf9b2f679e373ff4'
        : 'https://api.themoviedb.org/3/discover/movie?api_key=e850641520c5c6eacf9b2f679e373ff4&with_genres=$genreId&sort_by=release_date.desc';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['results'] as List;
      final result = data.map((json) => UpcomingMovies.fromJson(json)).toList();
      if (genreId == null) {
        ApiCache().set(cacheKey, result);
      }
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
              heroTag: 'upcoming_${movie.id}_$index',
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
