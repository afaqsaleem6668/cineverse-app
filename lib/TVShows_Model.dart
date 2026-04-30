import 'dart:convert';

class PopularTvShows {
  bool adult;
  String? backdropPath; // Make nullable
  List<int> genreIds;
  int id;
  List<String> originCountry;
  String originalLanguage;
  String originalName;
  String overview;
  double popularity;
  String? posterPath; // Make nullable
  DateTime? firstAirDate; // Make nullable
  String name;
  double voteAverage;
  int voteCount;

  PopularTvShows({
    required this.adult,
    required this.backdropPath,
    required this.genreIds,
    required this.id,
    required this.originCountry,
    required this.originalLanguage,
    required this.originalName,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.firstAirDate,
    required this.name,
    required this.voteAverage,
    required this.voteCount,
  });

  factory PopularTvShows.fromJson(Map<String, dynamic> json) {
    try {
      return PopularTvShows(
        adult: json["adult"],
        backdropPath: json["backdrop_path"], // Nullable
        genreIds: List<int>.from(json["genre_ids"].map((x) => x)),
        id: json["id"],
        originCountry: List<String>.from(json["origin_country"].map((x) => x)),
        originalLanguage: json["original_language"],
        originalName: json["original_name"],
        overview: json["overview"],
        popularity: json["popularity"].toDouble(),
        posterPath: json["poster_path"], // Nullable
        firstAirDate: parseDate(json["first_air_date"]), // Custom date parsing
        name: json["name"],
        voteAverage: json["vote_average"].toDouble(),
        voteCount: json["vote_count"],
      );
    } catch (e) {
      print('Error parsing PopularTvShows: $e');
      rethrow; // Rethrow the exception to propagate it further
    }
  }

  Map<String, dynamic> toJson() => {
    "adult": adult,
    "backdrop_path": backdropPath,
    "genre_ids": List<dynamic>.from(genreIds.map((x) => x)),
    "id": id,
    "origin_country": List<dynamic>.from(originCountry.map((x) => x)),
    "original_language": originalLanguage,
    "original_name": originalName,
    "overview": overview,
    "popularity": popularity,
    "poster_path": posterPath,
    "first_air_date": firstAirDate?.toIso8601String(), // Convert DateTime to ISO 8601 format for JSON
    "name": name,
    "vote_average": voteAverage,
    "vote_count": voteCount,
  };

  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    // List of potential date formats to try
    List<String> formats = [
      'yyyy-MM-dd', // Example: 2023-06-15
      'yyyy-MM-ddTHH:mm:ssZ', // Example: 2023-06-15T13:30:00Z
      'yyyy-MM-dd HH:mm:ss', // Example: 2023-06-15 13:30:00
      // Add more formats as needed based on your API's possible responses
    ];

    for (String format in formats) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing date with format $format: $e');
        continue; // Try next format
      }
    }

    // If none of the formats worked
    print('Invalid date format: $dateStr');
    return null;
  }
}
