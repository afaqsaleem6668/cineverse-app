import 'dart:convert';

List<UpcomingMovies> upcomingMoviesFromJson(String str) => List<UpcomingMovies>.from(json.decode(str).map((x) => UpcomingMovies.fromJson(x)));

String upcomingMoviesToJson(List<UpcomingMovies> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class UpcomingMovies {
  bool adult;
  String backdropPath;
  List<int> genreIds;
  int id;
  String originalTitle;
  String overview;
  double popularity;
  String posterPath;
  DateTime? releaseDate; // Make releaseDate nullable
  String title;
  bool video;
  double voteAverage;
  int voteCount;

  UpcomingMovies({
    required this.adult,
    required this.backdropPath,
    required this.genreIds,
    required this.id,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    this.releaseDate, // Make releaseDate nullable
    required this.title,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
  });

  factory UpcomingMovies.fromJson(Map<String, dynamic> json) => UpcomingMovies(
    adult: json["adult"],
    backdropPath: json["backdrop_path"] ?? '',
    genreIds: List<int>.from(json["genre_ids"].map((x) => x)),
    id: json["id"],
    originalTitle: json["original_title"],
    overview: json["overview"],
    popularity: json["popularity"].toDouble(),
    posterPath: json["poster_path"] ?? '',
    releaseDate: json["release_date"] != null && json["release_date"].isNotEmpty ? DateTime.parse(json["release_date"]) : null,
    title: json["title"],
    video: json["video"],
    voteAverage: json["vote_average"].toDouble(),
    voteCount: json["vote_count"],
  );

  Map<String, dynamic> toJson() => {
    "adult": adult,
    "backdrop_path": backdropPath,
    "genre_ids": List<dynamic>.from(genreIds.map((x) => x)),
    "id": id,
    "original_title": originalTitle,
    "overview": overview,
    "popularity": popularity,
    "poster_path": posterPath,
    "release_date": releaseDate != null ? "${releaseDate!.year.toString().padLeft(4, '0')}-${releaseDate!.month.toString().padLeft(2, '0')}-${releaseDate!.day.toString().padLeft(2, '0')}" : null,
    "title": title,
    "video": video,
    "vote_average": voteAverage,
    "vote_count": voteCount,
  };
}

enum OriginalLanguage {
  EN,
  FR,
  JA,
  PT
}

final originalLanguageValues = EnumValues({
  "en": OriginalLanguage.EN,
  "fr": OriginalLanguage.FR,
  "ja": OriginalLanguage.JA,
  "pt": OriginalLanguage.PT
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
