import 'package:flutter/material.dart';

import '../config/design_tokens.dart';

/// Skeleton pemuatan dashboard yang mengikuti struktur konten asli.
///
/// Sengaja statis (tanpa AnimationController) agar ringan saat startup.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 2.0).toDouble();

    return Semantics(
      label: 'Memuat dashboard',
      child: ExcludeSemantics(
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTokens.contentMaxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.space20,
                        AppTokens.space12,
                        AppTokens.space20,
                        AppTokens.space24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SkeletonBox(width: 150, height: AppTokens.fontTitle),
                          const SizedBox(height: AppTokens.space8),
                          _SkeletonBox(
                            width: 210,
                            height: AppTokens.fontCaption,
                          ),
                          const SizedBox(height: AppTokens.space10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 680
                                  ? 4
                                  : 2;
                              return GridView.count(
                                padding: EdgeInsets.zero,
                                crossAxisCount: columns,
                                mainAxisSpacing: AppTokens.space10,
                                crossAxisSpacing: AppTokens.space10,
                                mainAxisExtent: 136 * textScale,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: List.generate(
                                  4,
                                  (_) => const _SkeletonCard(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppTokens.space16),
                          _SkeletonBox(width: 110, height: AppTokens.fontTitle),
                          const SizedBox(height: AppTokens.space10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return GridView.count(
                                padding: EdgeInsets.zero,
                                crossAxisCount: 2,
                                mainAxisSpacing: AppTokens.space10,
                                crossAxisSpacing: AppTokens.space10,
                                mainAxisExtent: 76 * textScale,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: const [
                                  _SkeletonCard(compact: true),
                                  _SkeletonCard(compact: true),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppTokens.space16),
                          _SkeletonChart(textScale: textScale),
                          const SizedBox(height: AppTokens.space16),
                          _SkeletonBox(width: 170, height: AppTokens.fontTitle),
                          const SizedBox(height: AppTokens.space10),
                          const _SkeletonCard(height: 72, compact: true),
                          const SizedBox(height: AppTokens.space10),
                          const _SkeletonCard(height: 72, compact: true),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double? height;
  final bool compact;

  const _SkeletonCard({this.height, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.skeletonBorder),
      ),
      padding: const EdgeInsets.all(AppTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _SkeletonBox(width: 90, height: AppTokens.fontCaption),
          const SizedBox(height: AppTokens.space8),
          const _SkeletonBox(width: 120, height: AppTokens.fontTitle),
          if (!compact) ...[
            const SizedBox(height: AppTokens.space8),
            _SkeletonBox(
              width: 70,
              height: AppTokens.fontCaption,
              color: AppTokens.skeletonBase.withValues(alpha: 0.6),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkeletonChart extends StatelessWidget {
  final double textScale;

  const _SkeletonChart({required this.textScale});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250 * textScale,
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.skeletonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(width: 170, height: AppTokens.fontTitle),
          const SizedBox(height: AppTokens.space8),
          const _SkeletonBox(width: 130, height: AppTokens.fontCaption),
          const SizedBox(height: AppTokens.space16),
          _SkeletonBox(
            width: double.infinity,
            height: AppTokens.minTapTarget,
            color: AppTokens.skeletonBase.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppTokens.space16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final heights = <double>[40, 70, 55, 90, 65, 110, 80];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space4,
                    ),
                    child: Container(
                      height: heights[index] * textScale,
                      decoration: BoxDecoration(
                        color: AppTokens.skeletonBase,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTokens.space6),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final Color? color;

  const _SkeletonBox({this.width, required this.height, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? AppTokens.skeletonBase,
        borderRadius: BorderRadius.circular(AppTokens.space6),
      ),
    );
  }
}
