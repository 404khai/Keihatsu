class ReaderImageHeaders {
  static Map<String, String>? forSource({
    required String sourceId,
    required String mangaUrl,
    required String? referer,
    required String userAgent,
  }) {
    if (!{'batcave', 'mangafire'}.contains(sourceId.toLowerCase())) {
      return null;
    }
    return {
      'User-Agent': userAgent,
      'Referer': referer?.isNotEmpty == true ? referer! : mangaUrl,
      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    };
  }
}
