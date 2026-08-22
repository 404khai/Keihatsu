class Manga {
  final String id;
  final String url;
  final String title;
  final String thumbnailUrl;
  final String? description;
  final String? author;
  final String? artist;
  final String? status;
  final List<String>? genres;
  final String sourceId;
  final String? lang;

  Manga({
    required this.id,
    required this.url,
    required this.title,
    required this.thumbnailUrl,
    this.description,
    this.author,
    this.artist,
    this.status,
    this.genres,
    required this.sourceId,
    this.lang,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    String stringValue(String key) => (json[key] as String?)?.trim() ?? '';

    return Manga(
      id: stringValue('id'),
      url: stringValue('url'),
      title: stringValue('title'),
      thumbnailUrl: stringValue('thumbnailUrl'),
      description: json['description'] as String?,
      author: json['author'] as String?,
      artist: json['artist'] as String?,
      status: json['status'] as String?,
      genres: json['genres'] is List
          ? (json['genres'] as List)
                .whereType<String>()
                .map((genre) => genre.trim())
                .where((genre) => genre.isNotEmpty)
                .toList()
          : null,
      sourceId: stringValue('sourceId'),
      lang: json['lang'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'author': author,
      'artist': artist,
      'status': status,
      'genres': genres,
      'sourceId': sourceId,
      'lang': lang,
    };
  }
}

class MangasPage {
  final List<Manga> mangas;
  final bool hasNextPage;

  MangasPage({required this.mangas, required this.hasNextPage});

  factory MangasPage.fromJson(Map<String, dynamic> json) {
    return MangasPage(
      mangas: (json['mangas'] as List).map((m) => Manga.fromJson(m)).toList(),
      hasNextPage: json['hasNextPage'],
    );
  }
}
