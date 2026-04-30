import 'dart:convert';

// TV Seasons & Episodes Model

class TvSeason {
  final String? airDate;
  final int episodeCount;
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final int seasonNumber;
  final double voteAverage;

  TvSeason({
    this.airDate,
    required this.episodeCount,
    required this.id,
    required this.name,
    required this.overview,
    this.posterPath,
    required this.seasonNumber,
    required this.voteAverage,
  });

  factory TvSeason.fromJson(Map<String, dynamic> json) {
    return TvSeason(
      airDate: json['air_date'],
      episodeCount: json['episode_count'] ?? 0,
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      seasonNumber: json['season_number'] ?? 0,
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
    );
  }
}

class TvSeasonDetails {
  final String? airDate;
  final List<TvEpisode> episodes;
  final String name;
  final String overview;
  final int id;
  final String? posterPath;
  final int seasonNumber;

  TvSeasonDetails({
    this.airDate,
    this.episodes = const [],
    required this.name,
    required this.overview,
    required this.id,
    this.posterPath,
    required this.seasonNumber,
  });

  factory TvSeasonDetails.fromJson(Map<String, dynamic> json) {
    return TvSeasonDetails(
      airDate: json['air_date'],
      episodes: json['episodes'] != null
          ? (json['episodes'] as List)
              .map((e) => TvEpisode.fromJson(e))
              .toList()
          : [],
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      id: json['id'] ?? 0,
      posterPath: json['poster_path'],
      seasonNumber: json['season_number'] ?? 0,
    );
  }
}

class TvEpisode {
  final int episodeNumber;
  final String name;
  final String overview;
  final String? airDate;
  final double voteAverage;
  final int voteCount;
  final int id;
  final String? stillPath;
  final double? runtime;
  final List<int> guestStars;

  TvEpisode({
    required this.episodeNumber,
    required this.name,
    required this.overview,
    this.airDate,
    required this.voteAverage,
    required this.voteCount,
    required this.id,
    this.stillPath,
    this.runtime,
    this.guestStars = const [],
  });

  factory TvEpisode.fromJson(Map<String, dynamic> json) {
    return TvEpisode(
      episodeNumber: json['episode_number'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      airDate: json['air_date'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      id: json['id'] ?? 0,
      stillPath: json['still_path'],
      runtime: json['runtime']?.toDouble(),
      guestStars: json['guest_stars'] != null
          ? (json['guest_stars'] as List).map((e) => (e['id'] as num?)?.toInt() ?? 0).toList()
          : [],
    );
  }
}
