import 'package:cloud_firestore/cloud_firestore.dart';

/// Post content type
enum PostType { video, photo, text }

/// Social Post Model for the Feed
/// Stored in Firestore collection: 'social'
class SocialPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final PostType type;

  // Content
  final String? mediaUrl; // R2 URL for video/photo
  final String? thumbnailUrl; // Video thumbnail (generated)
  final String? textContent; // Caption or text-only content
  final double? aspectRatio; // For proper video/image display

  // Engagement
  final int likes;
  final int dislikes;
  final int commentCount;
  final List<String> likedBy; // User IDs who liked
  final List<String> dislikedBy; // User IDs who disliked

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  // Download tracking (for analytics)
  final int downloadCount;

  const SocialPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.type,
    this.mediaUrl,
    this.thumbnailUrl,
    this.textContent,
    this.aspectRatio,
    this.likes = 0,
    this.dislikes = 0,
    this.commentCount = 0,
    this.likedBy = const [],
    this.dislikedBy = const [],
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.downloadCount = 0,
  });

  /// Check if current user has liked this post
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Check if current user has disliked this post
  bool isDislikedBy(String userId) => dislikedBy.contains(userId);

  /// Factory from Firestore
  factory SocialPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SocialPost(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorPhotoUrl: data['authorPhotoUrl'],
      type: _parsePostType(data['type']),
      mediaUrl: data['mediaUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      textContent: data['textContent'],
      aspectRatio: (data['aspectRatio'] as num?)?.toDouble(),
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      dislikedBy: List<String>.from(data['dislikedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      downloadCount: data['downloadCount'] ?? 0,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'textContent': textContent,
      'aspectRatio': aspectRatio,
      'likes': likes,
      'dislikes': dislikes,
      'commentCount': commentCount,
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'downloadCount': downloadCount,
    };
  }

  /// Copy with new values
  SocialPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    PostType? type,
    String? mediaUrl,
    String? thumbnailUrl,
    String? textContent,
    double? aspectRatio,
    int? likes,
    int? dislikes,
    int? commentCount,
    List<String>? likedBy,
    List<String>? dislikedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? downloadCount,
  }) {
    return SocialPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      textContent: textContent ?? this.textContent,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      commentCount: commentCount ?? this.commentCount,
      likedBy: likedBy ?? this.likedBy,
      dislikedBy: dislikedBy ?? this.dislikedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      downloadCount: downloadCount ?? this.downloadCount,
    );
  }

  static PostType _parsePostType(String? type) {
    switch (type) {
      case 'video':
        return PostType.video;
      case 'photo':
        return PostType.photo;
      case 'text':
        return PostType.text;
      default:
        return PostType.text;
    }
  }
}

/// Comment Model for Social Posts
class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final DateTime createdAt;
  final String? parentCommentId; // For replies
  final int likes;
  final List<String> likedBy;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    required this.createdAt,
    this.parentCommentId,
    this.likes = 0,
    this.likedBy = const [],
  });

  bool get isReply => parentCommentId != null;

  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorPhotoUrl: data['authorPhotoUrl'],
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentCommentId: data['parentCommentId'],
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentCommentId': parentCommentId,
      'likes': likes,
      'likedBy': likedBy,
    };
  }
}
