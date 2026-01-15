import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/models/social_post_model.dart';
import '../../core/theme/uber_money_theme.dart';
import '../../core/services/share_service.dart';
import '../auth/auth_controller.dart';
import 'social_feed_provider.dart';
import 'comments_sheet.dart';

/// Social Feed Screen - Instagram/TikTok style scrollable feed
class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(socialFeedProvider);

    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: UberMoneyTheme.backgroundPrimary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: UberMoneyTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text('Social Feed', style: UberMoneyTheme.headlineMedium),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600;

          return feedAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(socialFeedProvider);
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop
                          ? 800
                          : (isTablet ? 600 : double.infinity),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: isDesktop ? 24 : 0,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isDesktop ? 8 : 0,
                          ),
                          child: _PostCard(post: posts[index]),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error.toString()),
          );
        },
      ),
      // FAB for all logged-in users (removed verification requirement)
      floatingActionButton: FirebaseAuth.instance.currentUser != null
          ? _buildCreateFAB(context)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCreateFAB(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 70), // Offset for bottom navbar
      child: FloatingActionButton.extended(
        onPressed: () => context.push('/social/create'),
        backgroundColor: UberMoneyTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create',
          style: UberMoneyTheme.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, size: 80, color: UberMoneyTheme.textMuted),
          const SizedBox(height: 16),
          Text('No posts yet', style: UberMoneyTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Be the first to share something!',
            style: UberMoneyTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 400,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: UberMoneyTheme.error,
          ),
          const SizedBox(height: 16),
          Text('Error loading feed', style: UberMoneyTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            error,
            style: UberMoneyTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.invalidate(socialFeedProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Individual Post Card with Video Player support
class _PostCard extends ConsumerStatefulWidget {
  final SocialPost post;

  const _PostCard({required this.post});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.type == PostType.video && widget.post.mediaUrl != null) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.post.mediaUrl!),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true, // Auto-play when video loads
        looping: true,
        showControls: true,
        aspectRatio: widget.post.aspectRatio ?? 16 / 9,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 42),
                const SizedBox(height: 8),
                Text(
                  'Error loading video',
                  style: UberMoneyTheme.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (_chewieController == null) return;

    // Auto-play when 60% visible, pause when less than 20% visible
    if (info.visibleFraction > 0.6) {
      if (!_videoController!.value.isPlaying) {
        _videoController!.play();
      }
    } else if (info.visibleFraction < 0.2) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';
    final isLiked = widget.post.isLikedBy(userId);
    final isDisliked = widget.post.isDislikedBy(userId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: UberMoneyTheme.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: UberMoneyTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          _buildHeader(),

          // Media Content
          _buildContent(),

          // Caption
          if (widget.post.textContent != null &&
              widget.post.textContent!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.post.textContent!,
                style: UberMoneyTheme.bodyLarge.copyWith(
                  color: UberMoneyTheme.textPrimary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Engagement Actions
          _buildActions(isLiked, isDisliked, userId),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: UberMoneyTheme.primary,
            backgroundImage: widget.post.authorPhotoUrl != null
                ? CachedNetworkImageProvider(widget.post.authorPhotoUrl!)
                : null,
            child: widget.post.authorPhotoUrl == null
                ? Text(
                    widget.post.authorName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Name & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.post.authorName, style: UberMoneyTheme.titleMedium),
                Text(
                  timeago.format(widget.post.createdAt),
                  style: UberMoneyTheme.caption,
                ),
              ],
            ),
          ),

          // Options Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) {
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              final isOwner = currentUserId == widget.post.authorId;
              final authState = ref.read(authControllerProvider);
              final isAdmin =
                  authState is AuthAuthenticated && authState.user.isAdmin;

              return [
                const PopupMenuItem(value: 'report', child: Text('Report')),
                if (isOwner || isAdmin)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      isAdmin && !isOwner ? 'Delete (Admin)' : 'Delete',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.post.type) {
      case PostType.video:
        return _buildVideoContent();
      case PostType.photo:
        return _buildPhotoContent();
      case PostType.text:
        return const SizedBox.shrink(); // Text is shown in caption area
    }
  }

  Widget _buildVideoContent() {
    return VisibilityDetector(
      key: Key('video-${widget.post.id}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: AspectRatio(
        aspectRatio: widget.post.aspectRatio ?? 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: _isVideoInitialized && _chewieController != null
              ? Chewie(controller: _chewieController!)
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPhotoContent() {
    return GestureDetector(
      onDoubleTap: () {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          SocialActions.likePost(widget.post.id, userId);
        }
      },
      child: AspectRatio(
        aspectRatio: widget.post.aspectRatio ?? 1.0,
        child: CachedNetworkImage(
          imageUrl: widget.post.mediaUrl ?? '',
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(bool isLiked, bool isDisliked, String userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Like Button
          _ActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: '${widget.post.likes}',
            color: isLiked ? Colors.red : null,
            onTap: () {
              if (userId.isNotEmpty) {
                SocialActions.likePost(widget.post.id, userId);
              }
            },
          ),

          // Dislike Button
          _ActionButton(
            icon: isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
            label: '${widget.post.dislikes}',
            color: isDisliked ? UberMoneyTheme.primary : null,
            onTap: () {
              if (userId.isNotEmpty) {
                SocialActions.dislikePost(widget.post.id, userId);
              }
            },
          ),

          // Comment Button
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: '${widget.post.commentCount}',
            onTap: () => _showCommentsSheet(),
          ),

          const Spacer(),

          // Download Button (Video/Photo only) - R2 has ZERO egress fees!
          if (widget.post.type != PostType.text && widget.post.mediaUrl != null)
            _ActionButton(
              icon: _isDownloading ? Icons.hourglass_empty : Icons.download,
              label: 'Save',
              onTap: _isDownloading ? null : () => _downloadMedia(),
            ),

          // Share Button
          _ActionButton(
            icon: Icons.share_outlined,
            label: '',
            onTap: () => ShareService.sharePost(widget.post),
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(post: widget.post),
    );
  }

  Future<void> _downloadMedia() async {
    if (widget.post.mediaUrl == null) return;

    setState(() => _isDownloading = true);

    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission required')),
          );
        }
        return;
      }

      final success = await SocialActions.downloadMedia(
        widget.post.mediaUrl!,
        'marketplace_${widget.post.id}',
        isVideo: widget.post.type == PostType.video,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Saved to gallery!' : 'Download failed'),
            backgroundColor: success
                ? UberMoneyTheme.success
                : UberMoneyTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'report':
        _showReportDialog();
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Post?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
          final authState = ref.read(authControllerProvider);
          final isAdmin =
              authState is AuthAuthenticated && authState.user.isAdmin;
          final success = await SocialActions.deletePost(
            widget.post.id,
            userId,
            isAdmin: isAdmin,
          );
          if (mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        break;
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String reason = '';
        return AlertDialog(
          title: const Text('Report Post'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Why are you reporting this post?',
            ),
            maxLines: 3,
            onChanged: (value) => reason = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reason.isNotEmpty) {
                  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                  SocialActions.reportPost(widget.post.id, userId, reason);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

/// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? UberMoneyTheme.textSecondary),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: UberMoneyTheme.labelMedium.copyWith(
                  color: color ?? UberMoneyTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
