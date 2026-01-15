import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/models/social_post_model.dart';
import '../../core/theme/uber_money_theme.dart';
import 'social_feed_provider.dart';

/// Bottom sheet for viewing and adding comments
class CommentsSheet extends ConsumerStatefulWidget {
  final SocialPost post;

  const CommentsSheet({super.key, required this.post});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _commentController = TextEditingController();
  String? _replyingToCommentId;
  String? _replyingToAuthor;
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));
    final userInfoAsync = ref.watch(currentUserInfoProvider);

    // Wrap with Padding to push the sheet up when keyboard appears
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text('Comments', style: UberMoneyTheme.headlineMedium),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: UberMoneyTheme.backgroundPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.post.commentCount}',
                          style: UberMoneyTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Comments List
                Expanded(
                  child: commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return _buildEmptyComments();
                      }

                      // Separate top-level comments and replies
                      final topLevel = comments
                          .where((c) => !c.isReply)
                          .toList();

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: topLevel.length,
                        itemBuilder: (context, index) {
                          final comment = topLevel[index];
                          final replies = comments
                              .where((c) => c.parentCommentId == comment.id)
                              .toList();

                          return _CommentTile(
                            comment: comment,
                            replies: replies,
                            onReply: () => _setReplyingTo(comment),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),

                // Reply indicator
                if (_replyingToCommentId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: UberMoneyTheme.backgroundPrimary,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.reply,
                          size: 16,
                          color: UberMoneyTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Replying to $_replyingToAuthor',
                          style: UberMoneyTheme.caption,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _replyingToCommentId = null;
                              _replyingToAuthor = null;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                // Input area - wrapped in SafeArea to respect bottom nav
                SafeArea(
                  top: false,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 8,
                      top: 8,
                      // Add extra padding for keyboard, plus bottom nav bar height (~80px)
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0
                          ? 8 // When keyboard is open, viewInsets handles it
                          : 8, // Normal padding when keyboard is closed
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: userInfoAsync.when(
                      data: (userInfo) {
                        if (userInfo == null) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Log in to comment',
                              style: UberMoneyTheme.bodyMedium,
                            ),
                          );
                        }
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: UberMoneyTheme.primary,
                              backgroundImage: userInfo['photoUrl'] != null
                                  ? CachedNetworkImageProvider(
                                      userInfo['photoUrl'],
                                    )
                                  : null,
                              child: userInfo['photoUrl'] == null
                                  ? Text(
                                      (userInfo['displayName'] ?? 'U')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: _replyingToCommentId != null
                                      ? 'Write a reply...'
                                      : 'Add a comment...',
                                  hintStyle: UberMoneyTheme.bodyMedium,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                maxLines: 3,
                                minLines: 1,
                              ),
                            ),
                            _isSending
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.send,
                                      color: UberMoneyTheme.primary,
                                    ),
                                    onPressed: () => _submitComment(userInfo),
                                  ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: UberMoneyTheme.textMuted,
          ),
          const SizedBox(height: 12),
          Text('No comments yet', style: UberMoneyTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Be the first to comment!', style: UberMoneyTheme.bodyMedium),
        ],
      ),
    );
  }

  void _setReplyingTo(PostComment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToAuthor = comment.authorName;
    });
    _commentController.clear();
  }

  Future<void> _submitComment(Map<String, dynamic> userInfo) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await SocialActions.addComment(
        postId: widget.post.id,
        content: content,
        authorId: userInfo['uid'],
        authorName: userInfo['displayName'],
        authorPhotoUrl: userInfo['photoUrl'],
        parentCommentId: _replyingToCommentId,
      );

      _commentController.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToAuthor = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

/// Individual Comment Tile
class _CommentTile extends StatelessWidget {
  final PostComment comment;
  final List<PostComment> replies;
  final VoidCallback onReply;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        _buildCommentContent(comment, isReply: false),

        // Replies (indented)
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: replies
                  .map((reply) => _buildCommentContent(reply, isReply: true))
                  .toList(),
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCommentContent(PostComment c, {required bool isReply}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: UberMoneyTheme.teal,
            backgroundImage: c.authorPhotoUrl != null
                ? CachedNetworkImageProvider(c.authorPhotoUrl!)
                : null,
            child: c.authorPhotoUrl == null
                ? Text(
                    c.authorName[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isReply ? 10 : 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.authorName,
                      style: UberMoneyTheme.labelLarge.copyWith(
                        fontSize: isReply ? 12 : 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(c.createdAt),
                      style: UberMoneyTheme.caption.copyWith(
                        fontSize: isReply ? 10 : 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  c.content,
                  style: UberMoneyTheme.bodyMedium.copyWith(
                    color: UberMoneyTheme.textPrimary,
                    fontSize: isReply ? 13 : 14,
                  ),
                ),
                if (!isReply)
                  TextButton(
                    onPressed: onReply,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Reply',
                      style: UberMoneyTheme.labelMedium.copyWith(
                        color: UberMoneyTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
