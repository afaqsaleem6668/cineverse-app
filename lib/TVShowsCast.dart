// To parse this JSON data, do
//
//     final tvShowsCast = tvShowsCastFromJson(jsonString);

import 'dart:convert';

List<TvShowsCast> tvShowsCastFromJson(String str) => List<TvShowsCast>.from(json.decode(str).map((x) => TvShowsCast.fromJson(x)));

String tvShowsCastToJson(List<TvShowsCast> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TvShowsCast {
  bool adult;
  int gender;
  int id;
  String knownForDepartment;
  String name;
  String originalName;
  double popularity;
  String? profilePath;
  String character;
  String creditId;
  int order;

  TvShowsCast({
    required this.adult,
    required this.gender,
    required this.id,
    required this.knownForDepartment,
    required this.name,
    required this.originalName,
    required this.popularity,
    required this.profilePath,
    required this.character,
    required this.creditId,
    required this.order,
  });

  factory TvShowsCast.fromJson(Map<String, dynamic> json) => TvShowsCast(
    adult: json["adult"],
    gender: json["gender"],
    id: json["id"],
    knownForDepartment: json["known_for_department"],
    name: json["name"],
    originalName: json["original_name"],
    popularity: json["popularity"].toDouble(),
    profilePath: json["profile_path"],
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
    "character": character,
    "credit_id": creditId,
    "order": order,
  };
}
