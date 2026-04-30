import 'dart:convert';

// Network Model
class Network {
  final int id;
  final String name;
  final String? logoPath;
  final String? originCountry;
  final String? headquarters;
  final String? homepage;

  Network({
    required this.id,
    required this.name,
    this.logoPath,
    this.originCountry,
    this.headquarters,
    this.homepage,
  });

  factory Network.fromJson(Map<String, dynamic> json) {
    return Network(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logoPath: json['logo_path'],
      originCountry: json['origin_country'],
      headquarters: json['headquarters'],
      homepage: json['homepage'],
    );
  }
}

// Company/Studio Model
class Company {
  final int id;
  final String name;
  final String? logoPath;
  final String? headquarters;
  final String? homepage;
  final String? originCountry;
  final List<int> movies;

  Company({
    required this.id,
    required this.name,
    this.logoPath,
    this.headquarters,
    this.homepage,
    this.originCountry,
    this.movies = const [],
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logoPath: json['logo_path'],
      headquarters: json['headquarters'],
      homepage: json['homepage'],
      originCountry: json['origin_country'],
      movies: json['movies'] != null
          ? (json['movies'] as List).map((e) => (e as num).toInt()).toList()
          : [],
    );
  }
}

// Network/Company with their content
class NetworkWithShows {
  final Network network;
  final List<NetworkShow> shows;

  NetworkWithShows({
    required this.network,
    this.shows = const [],
  });

  factory NetworkWithShows.fromJson(Map<String, dynamic> json) {
    return NetworkWithShows(
      network: Network.fromJson(json),
      shows: json['results'] != null
          ? (json['results'] as List)
              .map((e) => NetworkShow.fromJson(e))
              .toList()
          : [],
    );
  }
}

class NetworkShow {
  final bool adult;
  final String? backdropPath;
  final List<int> genreIds;
  final int id;
  final List<String> originCountry;
  final String originalLanguage;
  final String originalName;
  final String overview;
  final double popularity;
  final String? posterPath;
  final String? firstAirDate;
  final String name;
  final double voteAverage;
  final int voteCount;

  NetworkShow({
    required this.adult,
    this.backdropPath,
    required this.genreIds,
    required this.id,
    required this.originCountry,
    required this.originalLanguage,
    required this.originalName,
    required this.overview,
    required this.popularity,
    this.posterPath,
    this.firstAirDate,
    required this.name,
    required this.voteAverage,
    required this.voteCount,
  });

  factory NetworkShow.fromJson(Map<String, dynamic> json) {
    return NetworkShow(
      adult: json['adult'] ?? false,
      backdropPath: json['backdrop_path'],
      genreIds: json['genre_ids'] != null
          ? (json['genre_ids'] as List).map((e) => (e as num).toInt()).toList()
          : [],
      id: json['id'] ?? 0,
      originCountry: json['origin_country'] != null
          ? (json['origin_country'] as List).map((e) => e.toString()).toList()
          : [],
      originalLanguage: json['original_language'] ?? '',
      originalName: json['original_name'] ?? '',
      overview: json['overview'] ?? '',
      popularity: (json['popularity'] ?? 0).toDouble(),
      posterPath: json['poster_path'],
      firstAirDate: json['first_air_date'],
      name: json['name'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
    );
  }
}
