import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key, required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HomeColors.paper,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: HomeColors.navy,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 30),
              child: Shimmer.fromColors(
                baseColor: HomeColors.navyMid,
                highlightColor: const Color(0xFF3D4F8C),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _bone(width: 44, height: 44, radius: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _bone(width: 72, height: 10, radius: 6),
                              const SizedBox(height: 8),
                              _bone(width: 140, height: 16, radius: 8),
                            ],
                          ),
                        ),
                        _bone(width: 36, height: 36, radius: 12),
                        const SizedBox(width: 10),
                        _bone(width: 36, height: 36, radius: 12),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _bone(width: double.infinity, height: 72, radius: 20),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
            sliver: SliverToBoxAdapter(
              child: Shimmer.fromColors(
                baseColor: const Color(0xFFE4E0D8),
                highlightColor: const Color(0xFFF4F1EA),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bone(width: double.infinity, height: 64, radius: 20),
                    const SizedBox(height: 14),
                    _bone(width: double.infinity, height: 110, radius: 24),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _bone(width: double.infinity, height: 86, radius: 22)),
                        const SizedBox(width: 12),
                        Expanded(child: _bone(width: double.infinity, height: 86, radius: 22)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _bone(width: double.infinity, height: 120, radius: 28),
                    const SizedBox(height: 22),
                    _bone(width: 90, height: 10, radius: 6),
                    const SizedBox(height: 8),
                    _bone(width: 160, height: 18, radius: 8),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _bone(width: double.infinity, height: 120, radius: 18)),
                        const SizedBox(width: 10),
                        Expanded(child: _bone(width: double.infinity, height: 120, radius: 18)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _bone(width: 140, height: 18, radius: 8),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 3,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, __) => _bone(width: 180, height: 120, radius: 18),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _bone(width: 180, height: 18, radius: 8),
                    const SizedBox(height: 14),
                    _bone(width: double.infinity, height: 88, radius: 20),
                    const SizedBox(height: 10),
                    _bone(width: double.infinity, height: 88, radius: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bone({required double width, required double height, double radius = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
