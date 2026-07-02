/// Song / on-air metadata that is pushed to streaming servers.
class Metadata {
  String artist;
  String title;
  String onAirName;

  Metadata({
    this.artist = '',
    this.title = '',
    this.onAirName = '',
  });

  /// Returns the combined "Artist - Title" song string used by streaming
  /// protocols (ICY / Icecast metadata).
  String get songString {
    if (artist.isNotEmpty && title.isNotEmpty) return '$artist - $title';
    if (artist.isNotEmpty) return artist;
    if (title.isNotEmpty) return title;
    return '';
  }

  Map<String, dynamic> toJson() => {
        'artist': artist,
        'title': title,
        'on_air': onAirName,
      };

  factory Metadata.fromJson(Map<String, dynamic> json) => Metadata(
        artist: (json['artist'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        onAirName: (json['on_air'] as String?) ?? '',
      );

  Metadata copyWith({String? artist, String? title, String? onAirName}) =>
      Metadata(
        artist: artist ?? this.artist,
        title: title ?? this.title,
        onAirName: onAirName ?? this.onAirName,
      );
}
