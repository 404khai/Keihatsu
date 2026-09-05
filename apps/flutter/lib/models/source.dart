class Source {
  final String id;
  final String name;
  final String lang;
  final String baseUrl;
  final String? iconUrl;
  final int versionId;

  Source({
    required this.id,
    required this.name,
    required this.lang,
    required this.baseUrl,
    this.iconUrl,
    required this.versionId,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'],
      name: json['name'],
      lang: json['lang'],
      baseUrl: json['baseUrl'],
      iconUrl: json['iconUrl'],
      versionId: json['versionId'],
    );
  }
}
