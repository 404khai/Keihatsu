import 'package:keihatsu/models/user.dart';

class Comment {
  final String id;
  final String content;
  final List<String> images;
  final String userId;
  final User? user;
  final String mangaId;
  final String chapterId;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likes;
  final List<Comment> replies;
  final List<CommentLike>? userLikes;

  Comment({
    required this.id,
    required this.content,
    required this.images,
    required this.userId,
    this.user,
    required this.mangaId,
    required this.chapterId,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.likes = 0,
    this.replies = const [],
    this.userLikes,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      userId: json['userId'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      mangaId: json['mangaId'] ?? '',
      chapterId: json['chapterId'] ?? '',
      parentId: json['parentId'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      likes: json['likes'] ?? 0,
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e))
              .toList() ??
          [],
      userLikes: (json['userLikes'] as List<dynamic>?)
          ?.map((e) => CommentLike.fromJson(e))
          .toList(),
    );
  }
}

class CommentLike {
  final String id;

  CommentLike({required this.id});

  factory CommentLike.fromJson(Map<String, dynamic> json) {
    return CommentLike(id: json['id'] ?? '');
  }
}
