import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/models/campaign_model.dart';
import '../../../core/theme/uber_money_theme.dart';

class CampaignPopup extends StatefulWidget {
  final List<CampaignModel> campaigns;
  final VoidCallback onClose;

  const CampaignPopup({
    super.key,
    required this.campaigns,
    required this.onClose,
  });

  @override
  State<CampaignPopup> createState() => _CampaignPopupState();
}

class _CampaignPopupState extends State<CampaignPopup>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  Timer? _slideTimer;
  Timer? _closeTimer;
  int _currentPage = 0;
  bool _imagesReady = false;
  int _loadedImages = 0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Progress animation for the 5-second timer
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();

    // Pre-cache images before showing content
    _precacheImages();

    // Auto close after 5 seconds
    _closeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  Future<void> _precacheImages() async {
    final imagesToCache = widget.campaigns
        .where((c) => c.bannerUrl != null && c.bannerUrl!.isNotEmpty)
        .toList();

    if (imagesToCache.isEmpty) {
      // No images to cache, show immediately with placeholder
      if (mounted) {
        setState(() => _imagesReady = true);
        _startSlideTimer();
      }
      return;
    }

    // Precache all images with timeout
    for (final campaign in imagesToCache) {
      if (campaign.bannerUrl != null) {
        try {
          await precacheImage(
            CachedNetworkImageProvider(campaign.bannerUrl!),
            context,
          ).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              // Continue even if one image times out
              debugPrint('Image precache timed out: ${campaign.bannerUrl}');
            },
          );
        } catch (e) {
          debugPrint('Failed to precache image: $e');
        }

        if (mounted) {
          setState(() => _loadedImages++);
        }
      }
    }

    // Mark as ready and start sliding
    if (mounted) {
      setState(() => _imagesReady = true);
      _startSlideTimer();
    }
  }

  void _startSlideTimer() {
    // Auto slide every 2 seconds (only if multiple campaigns)
    if (widget.campaigns.length > 1) {
      _slideTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_currentPage < widget.campaigns.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        if (mounted && _pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _closeTimer?.cancel();
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Main content - either loading or campaigns
                if (!_imagesReady)
                  _buildLoadingState()
                else
                  _buildCampaignContent(),

                // Progress bar at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildProgressBar(),
                ),

                // Page indicators (if multiple campaigns)
                if (_imagesReady && widget.campaigns.length > 1)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: _buildPageIndicators(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            UberMoneyTheme.primary,
            UberMoneyTheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading indicator
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading campaign...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.campaigns.isNotEmpty)
              Text(
                widget.campaigns.first.shopName,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignContent() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.campaigns.length,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemBuilder: (context, index) {
        final campaign = widget.campaigns[index];
        return _buildCampaignPage(campaign);
      },
    );
  }

  Widget _buildCampaignPage(CampaignModel campaign) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image with proper loading/error handling
        if (campaign.bannerUrl != null && campaign.bannerUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: campaign.bannerUrl!,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 300),
            placeholder: (context, url) => Container(
              color: UberMoneyTheme.primary,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) =>
                _buildPlaceholderContent(campaign),
          )
        else
          _buildPlaceholderContent(campaign),

        // Overlay Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 1.0],
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),

        // Shop info at bottom
        Positioned(
          bottom: 32,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                campaign.shopName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: UberMoneyTheme.accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.black87),
                    SizedBox(width: 4),
                    Text(
                      'Sponsored',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderContent(CampaignModel campaign) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [UberMoneyTheme.primary, const Color(0xFF8B5CF6)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              campaign.shopName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Container(
          height: 4,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressController.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.8)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.campaigns.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
