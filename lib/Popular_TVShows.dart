import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_cache.dart';
import 'app_theme.dart';
import 'Genre_Model.dart';
import 'TVShows_Details.dart';
import 'TVShows_Model.dart';
import 'widgets/premium_card.dart';

class Popuplar_TVShows extends StatefulWidget {
  const Popuplar_TVShows({Key? key, this.selectedGenre}) : super(key: key);
  final Genre? selectedGenre;

  @override
  State<Popuplar_TVShows> createState() => _Popuplar_TVShowsState();
}

class _Popuplar_TVShowsState extends State<Popuplar_TVShows> {
  late Future<List<PopularTvShows>> _future;

  @override
  void initState() {
    super.initState();
    final cacheKey = 'popular_tv_${widget.selectedGenre?.id}';
    final cache = ApiCache();
    if (widget.selectedGenre == null && cache.has(cacheKey)) {
      _future = Future.value(cache.get<List<PopularTvShows>>(cacheKey));
    } else {
      _future = _fetchData();
    }
  }

  @override
  void didUpdateWidget(Popuplar_TVShows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGenre != widget.selectedGenre) {
      final f = _fetchData();
      setState(() => _future = f);
    }
  }

  Future<List<PopularTvShows>> _fetchData() async {
    final genreId = widget.selectedGenre?.id;
    final cacheKey = 'popular_tv_$genreId';
    final url = genreId == null
        ? 'https://api.themoviedb.org/3/tv/popular?api_key=e850641520c5c6eacf9b2f679e373ff4'
        : 'https://api.themoviedb.org/3/discover/tv?api_key=e850641520c5c6eacf9b2f679e373ff4&with_genres=$genreId&sort_by=popularity.desc';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['results'] as List;
      final result =
          data.map((json) => PopularTvShows.fromJson(json)).toList();
      if (genreId == null) {
        ApiCache().set(cacheKey, result);
      }
      return result;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PopularTvShows>>(
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
            final show = snapshot.data![index];
            return PremiumMovieCard(
              posterPath: show.posterPath ?? '',
              title: show.name,
              rating: show.voteAverage,
              heroTag: 'popular_tv_${show.id}_$index',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TVShowsDetails(tvshowsdetails: show)),
              ),
            );
          },
        );
      },
    );
  }
}
