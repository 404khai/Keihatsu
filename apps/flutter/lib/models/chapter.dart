class Chapter {
  final String id;
  final String url;
  final String name;
  final int dateUpload;
  final double chapterNumber;
  final String? scanlator;

  Chapter({
    required this.id,
    required this.url,
    required this.name,
    required this.dateUpload,
    required this.chapterNumber,
    this.scanlator,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      url: json['url'],
      name: json['name'],
      dateUpload: json['dateUpload'],
      chapterNumber: (json['chapterNumber'] as num).toDouble(),
      scanlator: json['scanlator'],
    );
  }
}

class ReaderPage {
  final int index;
  final String imageUrl;
  final String url;

  ReaderPage({
    required this.index,
    required this.imageUrl,
    required this.url,
  });

  factory ReaderPage.fromJson(Map<String, dynamic> json) {
    return ReaderPage(
      index: json['index'],
      imageUrl: json['imageUrl'],
      url: json['url'],
    );
  }
}
