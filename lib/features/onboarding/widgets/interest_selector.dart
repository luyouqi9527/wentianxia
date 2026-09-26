import 'package:flutter/material.dart';

import '../../../core/widgets/blur_container.dart';
import '../../news/data/news_channels.dart';

/// Material 3 [Chip] 兴趣选择器：每个 Chip 外层包裹高斯模糊容器。
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
    return BlurGroup(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: channels.map((NewsChannel channel) {
          final bool isSelected = selected.contains(channel.type);
          // 每个模糊控件的模糊强度略有差异，形成层次感（10 ± 4）。
          final double sigma = 10 + (channel.type.hashCode % 5);
          return RepaintBoundary(
            child: BlurContainer(
              borderRadius: BorderRadius.circular(24),
              blur: sigma,
              opacity: isSelected ? 0.34 : 0.12,
              tint: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
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
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
