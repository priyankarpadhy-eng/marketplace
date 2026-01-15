import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/social_post_model.dart';
import '../../core/services/r2_storage_service.dart';
import '../../core/theme/uber_money_theme.dart';
import 'social_feed_provider.dart';

/// Create Post Screen with Video/Photo/Text upload and progress bar
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _selectedFile;
  PostType? _selectedType;
  VideoPlayerController? _videoPreviewController;
  bool _isVideoInitialized = false;
  bool _isUploading = false; // Track uploading state locally

  @override
  void dispose() {
    _captionController.dispose();
    _videoPreviewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadStateProvider);
    final userInfoAsync = ref.watch(currentUserInfoProvider);

    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: UberMoneyTheme.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text('Create Post', style: UberMoneyTheme.headlineMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildPostButton(uploadState),
          ),
        ],
      ),
      body: _isUploading || uploadState.progress > 0 || uploadState.isComplete
          ? _buildUploadingState(uploadState)
          : _buildEditorState(userInfoAsync),
    );
  }

  Widget _buildPostButton(UploadState uploadState) {
    final hasContent =
        _selectedFile != null || _captionController.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: hasContent && !_isUploading ? _handlePost : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: UberMoneyTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: _isUploading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Post'),
      ),
    );
  }

  Widget _buildEditorState(AsyncValue<Map<String, dynamic>?> userInfoAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Header
          userInfoAsync.when(
            data: (userInfo) => _buildUserHeader(userInfo),
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox(height: 40),
          ),

          const SizedBox(height: 16),

          // Post Type Selector
          _buildTypeSelector(),

          const SizedBox(height: 16),

          // Media Preview (if selected)
          if (_selectedFile != null) _buildMediaPreview(),

          // Text Input
          _buildCaptionInput(),

          const SizedBox(height: 16),

          // Media Picker Buttons
          _buildMediaPickers(),
        ],
      ),
    );
  }

  Widget _buildUserHeader(Map<String, dynamic>? userInfo) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: UberMoneyTheme.primary,
          backgroundImage: userInfo?['photoUrl'] != null
              ? CachedNetworkImageProvider(userInfo!['photoUrl'])
              : null,
          child: userInfo?['photoUrl'] == null
              ? Text(
                  (userInfo?['displayName'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userInfo?['displayName'] ?? 'Anonymous',
              style: UberMoneyTheme.titleMedium,
            ),
            Row(
              children: [
                const Icon(
                  Icons.public,
                  size: 14,
                  color: UberMoneyTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text('Public', style: UberMoneyTheme.caption),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TypeChip(
            icon: Icons.text_fields,
            label: 'Text',
            isSelected: _selectedType == PostType.text,
            onTap: () => setState(() {
              _selectedType = PostType.text;
              _selectedFile = null;
            }),
          ),
          _TypeChip(
            icon: Icons.photo,
            label: 'Photo',
            isSelected: _selectedType == PostType.photo,
            onTap: () => _pickMedia(ImageSource.gallery, isVideo: false),
          ),
          _TypeChip(
            icon: Icons.videocam,
            label: 'Video',
            isSelected: _selectedType == PostType.video,
            onTap: () => _pickMedia(ImageSource.gallery, isVideo: true),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: UberMoneyTheme.shadowSmall,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (_selectedType == PostType.video)
              _buildVideoPreview()
            else if (_selectedType == PostType.photo)
              _buildPhotoPreview(),

            // Remove button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _removeMedia,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_isVideoInitialized || _videoPreviewController == null) {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoPreviewController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoPreviewController!),
          IconButton(
            iconSize: 64,
            icon: Icon(
              _videoPreviewController!.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            onPressed: () {
              setState(() {
                if (_videoPreviewController!.value.isPlaying) {
                  _videoPreviewController!.pause();
                } else {
                  _videoPreviewController!.play();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    if (_selectedFile == null) return const SizedBox.shrink();

    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: _selectedFile!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
            );
          }
          return Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    return Image.file(
      File(_selectedFile!.path),
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }

  Widget _buildCaptionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: UberMoneyTheme.shadowSmall,
      ),
      child: TextField(
        controller: _captionController,
        decoration: InputDecoration(
          hintText: _selectedFile != null
              ? 'Write a caption...'
              : 'What\'s on your mind?',
          hintStyle: UberMoneyTheme.bodyMedium.copyWith(
            color: UberMoneyTheme.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        maxLines: _selectedFile != null ? 3 : 8,
        minLines: _selectedFile != null ? 1 : 4,
        style: UberMoneyTheme.bodyLarge,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildMediaPickers() {
    return Row(
      children: [
        _PickerButton(
          icon: Icons.photo_library,
          label: 'Photo',
          onTap: () => _pickMedia(ImageSource.gallery, isVideo: false),
        ),
        const SizedBox(width: 12),
        _PickerButton(
          icon: Icons.videocam,
          label: 'Video',
          onTap: () => _pickMedia(ImageSource.gallery, isVideo: true),
        ),
        const SizedBox(width: 12),
        _PickerButton(
          icon: Icons.camera_alt,
          label: 'Camera',
          onTap: () => _pickMedia(ImageSource.camera, isVideo: false),
        ),
      ],
    );
  }

  Widget _buildUploadingState(UploadState uploadState) {
    // Determine what to show based on upload state
    final isComplete = uploadState.isComplete;
    final hasProgress = uploadState.progress > 0;
    final hasError = uploadState.hasError;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success State
            if (isComplete && !hasError) ...[
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: UberMoneyTheme.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: UberMoneyTheme.success,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Post Created!',
                style: UberMoneyTheme.headlineLarge.copyWith(
                  color: UberMoneyTheme.success,
                ),
              ),
              const SizedBox(height: 8),
              Text('Returning to feed...', style: UberMoneyTheme.bodyMedium),
            ]
            // Error State
            else if (hasError) ...[
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: UberMoneyTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: UberMoneyTheme.error,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Upload Failed',
                style: UberMoneyTheme.headlineMedium.copyWith(
                  color: UberMoneyTheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                uploadState.errorMessage ?? 'Something went wrong',
                style: UberMoneyTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(uploadStateProvider.notifier).reset();
                  setState(() => _isUploading = false);
                },
                child: const Text('Try Again'),
              ),
            ]
            // Uploading State
            else ...[
              // Animated upload circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: UberMoneyTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: hasProgress
                          ? CircularProgressIndicator(
                              value: uploadState.progress,
                              strokeWidth: 6,
                              backgroundColor: Colors.grey[200],
                              color: UberMoneyTheme.primary,
                            )
                          : const CircularProgressIndicator(
                              strokeWidth: 6,
                              color: UberMoneyTheme.primary,
                            ),
                    ),
                    if (hasProgress)
                      Text(
                        uploadState.progressText,
                        style: UberMoneyTheme.headlineMedium.copyWith(
                          color: UberMoneyTheme.primary,
                        ),
                      )
                    else
                      Icon(
                        Icons.cloud_upload,
                        size: 36,
                        color: UberMoneyTheme.primary,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                hasProgress ? 'Uploading...' : 'Preparing upload...',
                style: UberMoneyTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              if (hasProgress)
                Text(uploadState.bytesText, style: UberMoneyTheme.bodyMedium)
              else
                Text('Please wait...', style: UberMoneyTheme.bodyMedium),
              const SizedBox(height: 24),
              // Progress Bar
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: hasProgress
                      ? LinearProgressIndicator(
                          value: uploadState.progress,
                          backgroundColor: Colors.grey[200],
                          color: UberMoneyTheme.primary,
                          minHeight: 8,
                        )
                      : LinearProgressIndicator(
                          backgroundColor: Colors.grey[200],
                          color: UberMoneyTheme.primary,
                          minHeight: 8,
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo}) async {
    try {
      XFile? file;

      if (isVideo) {
        file = await _picker.pickVideo(source: source);
      } else {
        file = await _picker.pickImage(source: source, imageQuality: 85);
      }

      if (file != null) {
        setState(() {
          _selectedFile = file;
          _selectedType = isVideo ? PostType.video : PostType.photo;
        });

        if (isVideo) {
          _initVideoPreview(file);
        }
      }
    } catch (e) {
      debugPrint('Pick media error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _initVideoPreview(XFile file) async {
    try {
      _videoPreviewController?.dispose();

      if (kIsWeb) {
        _videoPreviewController = VideoPlayerController.networkUrl(
          Uri.parse(file.path),
        );
      } else {
        _videoPreviewController = VideoPlayerController.file(File(file.path));
      }

      await _videoPreviewController!.initialize();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('Video preview init error: $e');
    }
  }

  void _removeMedia() {
    _videoPreviewController?.dispose();
    setState(() {
      _selectedFile = null;
      _selectedType = null;
      _isVideoInitialized = false;
      _videoPreviewController = null;
    });
  }

  Future<void> _handlePost() async {
    final caption = _captionController.text.trim();

    if (_selectedFile == null && caption.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add some content')));
      return;
    }

    // Set uploading state
    setState(() => _isUploading = true);

    bool success;

    if (_selectedFile != null) {
      // Media post
      success = await ref
          .read(uploadStateProvider.notifier)
          .createPost(
            file: _selectedFile!,
            type: _selectedType ?? PostType.photo,
            caption: caption.isNotEmpty ? caption : null,
          );
    } else {
      // Text-only post
      success = await ref
          .read(uploadStateProvider.notifier)
          .createTextPost(caption);
    }

    if (success && mounted) {
      // Wait longer to show "Done" state with checkmark
      await Future.delayed(const Duration(seconds: 2));

      ref.read(uploadStateProvider.notifier).reset();
      setState(() => _isUploading = false);

      if (mounted) {
        context.pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Post created successfully!'),
              ],
            ),
            backgroundColor: UberMoneyTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (!success && mounted) {
      setState(() => _isUploading = false);

      // Show error message
      final errorMessage =
          ref.read(uploadStateProvider).errorMessage ?? 'Failed to create post';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: UberMoneyTheme.error,
        ),
      );

      // Reset upload state on error
      ref.read(uploadStateProvider.notifier).reset();
    }
  }
}

/// Type selector chip
class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? UberMoneyTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : UberMoneyTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: UberMoneyTheme.labelMedium.copyWith(
                  color: isSelected
                      ? Colors.white
                      : UberMoneyTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Media picker button
class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: UberMoneyTheme.shadowSmall,
          ),
          child: Column(
            children: [
              Icon(icon, color: UberMoneyTheme.primary, size: 28),
              const SizedBox(height: 4),
              Text(label, style: UberMoneyTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
