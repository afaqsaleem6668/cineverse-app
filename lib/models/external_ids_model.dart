// External IDs Model
class ExternalIds {
  final String? imdbId;
  final String? facebookId;
  final String? instagramId;
  final String? twitterId;
  final String? wikidataId;

  ExternalIds({
    this.imdbId,
    this.facebookId,
    this.instagramId,
    this.twitterId,
    this.wikidataId,
  });

  factory ExternalIds.fromJson(Map<String, dynamic> json) {
    return ExternalIds(
      imdbId: json['imdb_id']?.toString(),
      facebookId: json['facebook_id']?.toString(),
      instagramId: json['instagram_id']?.toString(),
      twitterId: json['twitter_id']?.toString(),
      wikidataId: json['wikidata_id']?.toString(),
    );
  }
}
