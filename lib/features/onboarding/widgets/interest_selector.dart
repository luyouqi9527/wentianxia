import 'package:flutter/material.dart';

import '../../../core/widgets/blur_container.dart';
import '../../news/data/news_channels.dart';

/// Material 3 [Chip] 兴趣选择器：每个 Chip 外层包裹高斯模糊容器。
///
/// ## 1.0.1 修复说明
/// 这里原先给每个 Chip 包了 `RepaintBoundary`。`BackdropFilter` 的采样范围
/// 会被 `RepaintBoundary` 截断在独立层内，于是 Chip 下方会出现**图像缺失的
/// 空白带**，滑动时还会闪烁。现在改为：Chip 自身只用 `BlurContainer`
/// （`ClipRRect` + `BackdropFilter`），隔离重绘交给页面级的整块内容，
/// 并由页面底部的 `GlassBackdrop` 保证模糊下方永远有像素。
class InterestSelector extends StatelessWidget {
  const InterestSelector({
    super.key,
    required this.selected,
    required this.onToggle,
    this.channels = kAllChannels,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final List<NewsChannel> channels;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return BlurGroup(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: channels.map((NewsChannel channel) {
          final bool isSelected = selected.contains(channel.type);
          // 每个模糊控件的模糊强度略有差异，形成层次感（10 ~ 14）。
          final double sigma = 10 + (channel.type.hashCode % 5);

          return BlurContainer(
            borderRadius: BorderRadius.circular(24),
            blur: sigma,
            opacity: isSelected ? 0.34 : 0.12,
            tint: isSelected ? scheme.primary : scheme.surface,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onToggle(channel.type),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(channel.icon, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Text(
                        channel.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (isSelected) ...<Widget>[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle, size: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
