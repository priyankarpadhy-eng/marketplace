import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import '../../core/models/social_post_model.dart';
import '../../core/theme/uber_money_theme.dart';
import '../../core/services/share_service.dart';
import 'social_feed_provider.dart';
import 'comments_sheet.dart';

/// Screen to display a shared post when opened from a deep link
/// Shows post details and allows interaction if user is logged in
class SharedPostScreen extends ConsumerStatefulWidget {
  final String postId;

  const SharedPostScreen({super.key, required this.postId});

  @override
  ConsumerState<SharedPostScreen> createState() => _SharedPostScreenState();
}

class _SharedPostScreenState extends ConsumerState<SharedPostScreen> {
  bool _isLoading = true;
  SocialPost? _post;
  String? _error;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('social')
          .doc(widget.postId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'This post no longer exists';
          _isLoading = false;
        });
        return;
      }

      final post = SocialPost.fromFirestore(doc);
      setState(() {
        _post = post;
        _isLoading = false;
      });

      // Initialize video if needed
      if (post.type == PostType.video && post.mediaUrl != null) {
        _initializeVideo(post.mediaUrl!);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load post';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideo(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        showControls: true,
        aspectRatio: _post?.aspectRatio ?? 16 / 9,
      );

      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: UberMoneyTheme.backgroundPrimary,
        title: Text('Post', style: UberMoneyTheme.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/social'),
        ),
        actions: [
          if (_post != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => ShareService.sharePost(_post!),
            ),
        ],
      ),
      body: _buildBody(currentUser),
    );
  }

  Widget _buildBody(User? currentUser) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading post...'),
          ],
        ),
      );
    }

    if (_error != null) {
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
            Text(_error!, style: UberMoneyTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              currentUser == null
                  ? 'Please log in to view posts'
                  : 'The post may have been deleted',
              style: UberMoneyTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/social'),
              icon: const Icon(Icons.feed),
              label: const Text('Go to Feed'),
            ),
          ],
        ),
      );
    }

    if (currentUser == null) {
      return _buildLoginPrompt();
    }

    final post = _post!;
    final userId = currentUser.uid;
    final isLiked = post.isLikedBy(userId);
    final isDisliked = post.isDislikedBy(userId);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          _buildHeader(post),

          // Media Content
          _buildContent(post),

          // Caption
          if (post.textContent != null && post.textContent!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(post.textContent!, style: UberMoneyTheme.bodyLarge),
            ),

          // Engagement Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('${post.likes} likes', style: UberMoneyTheme.caption),
                const SizedBox(width: 16),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount} comments',
                  style: UberMoneyTheme.caption,
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Action Buttons
          _buildActions(post, isLiked, isDisliked, userId),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 64,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            Text('Login Required', style: UberMoneyTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Please log in to view this post and interact with it.',
              style: UberMoneyTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Login to Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SocialPost post) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: UberMoneyTheme.primary,
            backgroundImage: post.authorPhotoUrl != null
                ? CachedNetworkImageProvider(post.authorPhotoUrl!)
                : null,
            child: post.authorPhotoUrl == null
                ? Text(
                    post.authorName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.authorName, style: UberMoneyTheme.titleMedium),
                Text(
                  timeago.format(post.createdAt),
                  style: UberMoneyTheme.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SocialPost post) {
    switch (post.type) {
      case PostType.video:
        return AspectRatio(
          aspectRatio: post.aspectRatio ?? 16 / 9,
          child: _isVideoInitialized && _chewieController != null
              ? Chewie(controller: _chewieController!)
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
        );
      case PostType.photo:
        return AspectRatio(
          aspectRatio: post.aspectRatio ?? 1.0,
          child: CachedNetworkImage(
            imageUrl: post.mediaUrl ?? '',
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
        );
      case PostType.text:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActions(
    SocialPost post,
    bool isLiked,
    bool isDisliked,
    String userId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Like Button
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: 'Like',
            color: isLiked ? Colors.red : null,
            onTap: () {
              SocialActions.likePost(post.id, userId);
              _loadPost(); // Refresh
            },
          ),

          // Dislike Button
          _buildActionButton(
            icon: isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
            label: 'Dislike',
            color: isDisliked ? UberMoneyTheme.primary : null,
            onTap: () {
              SocialActions.dislikePost(post.id, userId);
              _loadPost(); // Refresh
            },
          ),

          // Comment Button
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Comment',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CommentsSheet(post: post),
              );
            },
          ),

          // Share Button
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () => ShareService.sharePost(post),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color ?? UberMoneyTheme.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: UberMoneyTheme.caption.copyWith(
                color: color ?? UberMoneyTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
