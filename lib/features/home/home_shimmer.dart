import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key, required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HomeColors.surface,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [HomeColors.navyMid, HomeColors.navyLine],
                ),
                // border: Border(bottom: BorderSide(color: HomeColors.navyDeep)),
              ),
              padding: EdgeInsets.fromLTRB(12, topInset + 10, 12, 12),
              child: Shimmer.fromColors(
                baseColor: HomeColors.navyLine,
                highlightColor: HomeColors.navyMuted,
                child: Row(
                  children: [
                    _bone(width: 36, height: 36, radius: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bone(width: 120, height: 14, radius: 7),
                          const SizedBox(height: 6),
                          _bone(width: 90, height: 10, radius: 5),
                        ],
                      ),
                    ),
                    _bone(width: 52, height: 26, radius: 13),
                    const SizedBox(width: 6),
                    _bone(width: 34, height: 34, radius: 17),
                    const SizedBox(width: 6),
                    _bone(width: 36, height: 36, radius: 18),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 36),
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
