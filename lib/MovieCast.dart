// To parse this JSON data, do
//
//     final movieCast = movieCastFromJson(jsonString);

import 'dart:convert';

List<MovieCast> movieCastFromJson(String str) => List<MovieCast>.from(json.decode(str).map((x) => MovieCast.fromJson(x)));

String movieCastToJson(List<MovieCast> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class MovieCast {
  bool adult;
  int gender;
  int id;
  String knownForDepartment;
  String name;
  String originalName;
  double popularity;
  String? profilePath; // Make profilePath nullable
  int castId;
  String character;
  String creditId;
  int order;

  MovieCast({
    required this.adult,
    required this.gender,
    required this.id,
    required this.knownForDepartment,
    required this.name,
    required this.originalName,
    required this.popularity,
    required this.profilePath,
    required this.castId,
    required this.character,
    required this.creditId,
    required this.order,
  });

  factory MovieCast.fromJson(Map<String, dynamic> json) => MovieCast(
    adult: json["adult"],
    gender: json["gender"],
    id: json["id"],
    knownForDepartment: json["known_for_department"],
    name: json["name"],
    originalName: json["original_name"],
    popularity: json["popularity"].toDouble(),
    profilePath: json["profile_path"],
    castId: json["cast_id"],
    character: json["character"],
    creditId: json["credit_id"],
    order: json["order"],
  );

  Map<String, dynamic> toJson() => {
    "adult": adult,
    "gender": gender,
    "id": id,
    "known_for_department": knownForDepartment,
    "name": name,
    "original_name": originalName,
    "popularity": popularity,
    "profile_path": profilePath,
    "cast_id": castId,
    "character": character,
    "credit_id": creditId,
    "order": order,
  };
}
