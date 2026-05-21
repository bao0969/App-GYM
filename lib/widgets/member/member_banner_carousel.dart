import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MemberBannerCarousel extends StatefulWidget {
  const MemberBannerCarousel({super.key});

  @override
  State<MemberBannerCarousel> createState() => _MemberBannerCarouselState();
}

class _MemberBannerCarouselState extends State<MemberBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<BannerItem> _banners = [
    BannerItem(
      title: 'Không Có Gì Là Không Thể',
      subtitle: 'Hãy tin vào bản thân và nỗ lực mỗi ngày',
      imageUrl:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
    ),
    BannerItem(
      title: 'Cơ Bắp Được Tạo Ra Ở Phòng Gym',
      subtitle: 'Nhưng thân hình được tạo ra ở bếp',
      imageUrl:
          'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800&q=80',
    ),
    BannerItem(
      title: 'Đau Hôm Nay, Mạnh Ngày Mai',
      subtitle: 'Mỗi giọt mồ hôi đều đáng giá',
      imageUrl:
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80',
    ),
    BannerItem(
      title: 'Thành Công Không Đến Từ Ước Mơ',
      subtitle: 'Mà đến từ hành động và kiên trì',
      imageUrl:
          'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80',
    ),
    BannerItem(
      title: 'Hãy Tập Vì Chính Bạn',
      subtitle: 'Không phải để chứng minh với ai',
      imageUrl:
          'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                return _BannerCard(banner: _banners[index]);
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.success
                      : AppColors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerItem banner;

  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: AppColors.textHint,
                      size: 40,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.surface,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.success,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 3,
              child: Container(
                decoration: BoxDecoration(gradient: AppColors.greenGradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BannerItem {
  final String title;
  final String subtitle;
  final String imageUrl;

  BannerItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}
