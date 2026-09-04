import 'package:keihatsu/models/chapter.dart';
import 'package:keihatsu/models/local_models.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme_provider.dart';
import 'UserProfileSheet.dart';
import '../providers/auth_provider.dart';
import '../providers/comments_provider.dart';
import '../models/comment.dart';
import 'user_blobatar.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CommentsBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final int currentChapterIndex;
  final String mangaId;
  final String chapterId;
  final List<dynamic> chapters;
  final Function(int) onChapterChange;

  const CommentsBottomSheet({
    super.key,
    required this.scrollController,
    required this.currentChapterIndex,
    required this.mangaId,
    required this.chapterId,
    required this.chapters,
    required this.onChapterChange,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isFocused = false;
  bool _isOnline = true;
  late int _currentIndex;
  String? _replyingToCommentId;
  String? _replyingToUsername;
  Set<String> _expandedComments = {};

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 100000)
      return '${(count / 1000).toStringAsFixed(1)}k'.replaceAll('.0', '');
    return '${(count / 1000000).toStringAsFixed(1)}m'.replaceAll('.0', '');
  }

  int _getTotalCommentsCount(List<Comment> comments) {
    int count = 0;
    for (var c in comments) {
      count += 1; // parent
      if (c.replies.isNotEmpty) {
        count += _getTotalCommentsCount(c.replies);
      }
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentChapterIndex;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });

    // Fetch comments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCommentsForCurrentChapter();
    });
  }

  void _fetchCommentsForCurrentChapter() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chapter = widget.chapters[_currentIndex];
    final chapterId = chapter is Chapter
        ? chapter.id
        : (chapter as LocalChapter).chapterId;

    Provider.of<CommentsProvider>(
      context,
      listen: false,
    ).fetchComments(widget.mangaId, chapterId, auth.token);
  }

  void _goToNextChapter() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      widget.onChapterChange(_currentIndex);
      _fetchCommentsForCurrentChapter();
    }
  }

  void _goToPreviousChapter() {
    if (_currentIndex < widget.chapters.length - 1) {
      setState(() {
        _currentIndex++;
      });
      widget.onChapterChange(_currentIndex);
      _fetchCommentsForCurrentChapter();
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (mounted) {
      setState(() {
        _isOnline = !result.contains(ConnectivityResult.none);
      });
    }
  }

  void _showUserProfile(
    BuildContext context,
    String userId,
    String username,
    String? userImage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => UserProfileSheet(
        userId: userId,
        username: username,
        userImage: userImage,
      ),
    );
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
      // Ensure focus to show expanded state
      if (!_isFocused) {
        _focusNode.requestFocus();
      }
    }
  }

  Future<void> _handlePostComment() async {
    if (_commentController.text.trim().isEmpty && _selectedImages.isEmpty)
      return;

    final content = _commentController.text;
    final images = List<String>.from(_selectedImages.map((e) => e.path));
    final String? parentId = _replyingToCommentId; // Capture before clearing

    _commentController.clear();
    setState(() {
      _selectedImages = [];
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
    _focusNode.unfocus();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final commentsProvider = Provider.of<CommentsProvider>(
        context,
        listen: false,
      );
      final chapter = widget.chapters[_currentIndex];
      final chapterId = chapter is Chapter
          ? chapter.id
          : (chapter as LocalChapter).chapterId;

      await commentsProvider.postComment(
        widget.mangaId,
        chapterId,
        content,
        auth.token ?? '',
        parentId: parentId,
        imagePaths: images,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to post comment: $e")));
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final commentsProvider = Provider.of<CommentsProvider>(context);
    final user = authProvider.user;

    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.effectiveBgColor;
    final isDarkMode = themeProvider.isDarkTheme;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final userAvatar = UserBlobatar(
      seed: user?.id ?? 'keihatsu-guest',
      label: user?.username ?? 'Reader',
      size: 36,
      hue: user?.avatarHue,
      shape: user?.avatarShape,
      expression: user?.avatarExpression ?? 'happy',
      animated: user?.avatarAnimated ?? false,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Navigation & Meta Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _goToPreviousChapter,
                              child: _buildNavButton(
                                context,
                                PhosphorIcons.caretLeft(),
                                "Previous",
                                isEnabled:
                                    _currentIndex < widget.chapters.length - 1,
                              ),
                            ),
                            Text(
                              "Chapter ${_currentIndex + 1}", // Assuming 1-based index for display
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: _goToNextChapter,
                              child: _buildNavButton(
                                context,
                                PhosphorIcons.caretRight(),
                                "Next",
                                isRight: true,
                                isEnabled: _currentIndex > 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              PhosphorIcons.house(),
                              size: 22,
                              color: textColor.withOpacity(0.7),
                            ),
                            const SizedBox(width: 20),
                            Icon(
                              PhosphorIcons.info(),
                              size: 22,
                              color: textColor.withOpacity(0.7),
                            ),
                            const SizedBox(width: 20),
                            Icon(
                              PhosphorIcons.shareNetwork(),
                              size: 22,
                              color: textColor.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 30, thickness: 0.5),

                  // Content Area
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: "Comments ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            children: [
                              TextSpan(
                                text: _formatCount(
                                  _getTotalCommentsCount(
                                    commentsProvider.comments,
                                  ),
                                ),
                                style: TextStyle(
                                  color: textColor.withOpacity(0.5),
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        // Sorting Filters
                        Row(
                          children: [
                            _buildFilterChip("Top", true, brandColor),
                            const SizedBox(width: 12),
                            _buildFilterChip("New", false, brandColor),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Threaded Comment List
                        if (commentsProvider.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (commentsProvider.error != null)
                          Center(child: Text(commentsProvider.error!))
                        else if (commentsProvider.comments.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                Icon(
                                  PhosphorIcons.chatTeardropDots(
                                    PhosphorIconsStyle.fill,
                                  ),
                                  size: 64,
                                  color: textColor.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Be the first to comment",
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...commentsProvider.comments.map(
                            (comment) =>
                                _buildCommentThread(context, comment: comment),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Input Area
            _buildInputArea(
              context,
              bgColor,
              textColor,
              userAvatar,
              brandColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    Color bgColor,
    Color textColor,
    Widget userAvatar,
    Color brandColor,
  ) {
    if (!_isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: textColor.withOpacity(0.1))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.wifiSlash(),
                color: textColor.withOpacity(0.5),
              ),
              const SizedBox(width: 10),
              Text(
                "Go online to comment",
                style: TextStyle(color: textColor.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: textColor.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: _isFocused
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                ClipOval(child: userAvatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: !_isFocused
                        ? BoxDecoration(
                            color: textColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          )
                        : null,
                    constraints: _isFocused
                        ? const BoxConstraints(maxHeight: 120)
                        : const BoxConstraints(minHeight: 45),
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _commentController,
                      maxLines: null,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: _replyingToUsername != null
                            ? "Replying to $_replyingToUsername..."
                            : "Add comments...",
                        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: !_isFocused
                            ? const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              )
                            : EdgeInsets.zero,
                        isDense: true,
                        suffixIcon: !_isFocused
                            ? GestureDetector(
                                onTap: _pickImage,
                                child: Icon(
                                  PhosphorIcons.image(),
                                  color: textColor.withOpacity(0.6),
                                  size: 24,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isFocused) ...[
              const SizedBox(height: 12),
              if (_selectedImages.isNotEmpty)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedImages[index].path),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: _buildActionIcon(PhosphorIcons.image(), textColor),
                  ),
                  const SizedBox(width: 20),
                  const Spacer(),
                  GestureDetector(
                    onTap: _handlePostComment,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.shade400, // Brand-like color
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, {double size = 24}) {
    return Icon(icon, color: color.withOpacity(0.6), size: size);
  }

  Widget _buildNavButton(
    BuildContext context,
    PhosphorIconData icon,
    String label, {
    bool isRight = false,
    bool isEnabled = true,
  }) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (!isRight) Icon(icon, size: 18, color: textColor),
            if (!isRight) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: textColor,
              ),
            ),
            if (isRight) const SizedBox(width: 8),
            if (isRight) Icon(icon, size: 18, color: textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Color brandColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? brandColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? brandColor : Colors.black12),
      ),
      child: Row(
        children: [
          if (isSelected)
            Icon(
              PhosphorIcons.crown(PhosphorIconsStyle.fill),
              size: 16,
              color: brandColor,
            ),
          if (isSelected) const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? brandColor : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentThread(
    BuildContext context, {
    required Comment comment,
    bool isReply = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final commentsProvider = Provider.of<CommentsProvider>(
      context,
      listen: false,
    );

    final textColor = themeProvider.isDarkTheme ? Colors.white : Colors.black87;

    final profileUserId = comment.user?.id ?? comment.userId;
    final user = comment.user?.username ?? "Unknown";
    final commentUser = comment.user;
    final time = _formatTime(comment.createdAt);
    final text = comment.content;
    final int likeCount = comment.likes;

    // Check if user liked it
    final isLiked = comment.userLikes?.isNotEmpty == true;
    final bool isExpanded = _expandedComments.contains(comment.id);

    return Padding(
      padding: EdgeInsets.only(bottom: isReply ? 12.0 : 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _showUserProfile(context, profileUserId, user, null),
            child: ClipOval(
              child: UserBlobatar(
                seed: profileUserId,
                label: user,
                size: isReply ? 28 : 36,
                hue: commentUser?.avatarHue,
                shape: commentUser?.avatarShape,
                expression: commentUser?.avatarExpression ?? 'happy',
                animated: commentUser?.avatarAnimated ?? false,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                GestureDetector(
                  onTap: () =>
                      _showUserProfile(context, profileUserId, user, null),
                  child: Text(
                    user,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Comment text
                Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
                // Images
                if (comment.images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: comment.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                comment.images[index],
                                height: 180,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Bottom Actions Row (Time, Reply, Likes)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingToCommentId = comment.id;
                          _replyingToUsername = user;
                        });
                        _focusNode.requestFocus();
                      },
                      child: Text(
                        "Reply",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Heart and Count
                    GestureDetector(
                      onTap: () {
                        if (auth.token != null) {
                          commentsProvider.likeComment(
                            comment.id,
                            auth.token!,
                            widget.mangaId,
                            widget.chapterId,
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 25,
                            color: isLiked
                                ? Colors.red
                                : textColor.withOpacity(0.5),
                          ),
                          if (likeCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              _formatCount(likeCount),
                              style: TextStyle(
                                fontSize: 13,
                                color: isLiked
                                    ? Colors.red
                                    : textColor.withOpacity(0.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                // Collapsible Replies Toggle
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedComments.remove(comment.id);
                        } else {
                          _expandedComments.add(comment.id);
                        }
                      });
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 1,
                          color: textColor.withOpacity(0.3),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExpanded
                              ? "Hide replies"
                              : "View ${comment.replies.length} replies",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded
                              ? PhosphorIcons.caretUp()
                              : PhosphorIcons.caretDown(),
                          size: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 16),
                    ...comment.replies.map(
                      (reply) => _buildCommentThread(
                        context,
                        comment: reply,
                        isReply: true,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
