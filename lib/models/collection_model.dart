import 'dart:convert';

// Movie Collection Model
class MovieCollection {
  final int id;
  final String name;
  final String? posterPath;
  final String? backdropPath;
  final List<CollectionMovie> parts;

  MovieCollection({
    required this.id,
    required this.name,
    this.posterPath,
    this.backdropPath,
    this.parts = const [],
  });

  factory MovieCollection.fromJson(Map<String, dynamic> json) {
    return MovieCollection(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      parts: json['parts'] != null
          ? (json['parts'] as List)
              .map((e) => CollectionMovie.fromJson(e))
              .toList()
          : [],
    );
  }
}

class CollectionMovie {
  final bool adult;
  final String? backdropPath;
  final List<int> genreIds;
  final int id;
  final String? originalLanguage;
  final String originalTitle;
  final String overview;
  final double popularity;
  final String? posterPath;
  final String? releaseDate;
  final String title;
  final bool video;
  final double voteAverage;
  final int voteCount;

  CollectionMovie({
    required this.adult,
    this.backdropPath,
    required this.genreIds,
    required this.id,
    this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    this.posterPath,
    this.releaseDate,
    required this.title,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
  });

  factory CollectionMovie.fromJson(Map<String, dynamic> json) {
    return CollectionMovie(
      adult: json['adult'] ?? false,
      backdropPath: json['backdrop_path'],
      genreIds: json['genre_ids'] != null
          ? (json['genre_ids'] as List).map((e) => (e as num).toInt()).toList()
          : [],
      id: json['id'] ?? 0,
      originalLanguage: json['original_language'],
      originalTitle: json['original_title'] ?? '',
      overview: json['overview'] ?? '',
      popularity: (json['popularity'] ?? 0).toDouble(),
      posterPath: json['poster_path'],
      releaseDate: json['release_date'],
      title: json['title'] ?? '',
      video: json['video'] ?? false,
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
    );
  }
}
