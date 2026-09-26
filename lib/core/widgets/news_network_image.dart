import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 统一的网络图片控件：`cached_network_image` + 占位 + 失败兜底。
///
/// 需求：图片加载使用 cached_network_image，必须带 `placeholder` 与 `errorWidget`。
class NewsNetworkImage extends StatelessWidget {
  const NewsNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackSeed = 0,
    this.fallbackLabel,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int fallbackSeed;
  final String? fallbackLabel;

  static const List<List<Color>> _gradients = <List<Color>>[
    <Color>[Color(0xFF5B4B8A), Color(0xFF2C2540)],
    <Color>[Color(0xFF1F4E5F), Color(0xFF14232A)],
    <Color>[Color(0xFF6B3F3F), Color(0xFF2A1A1A)],
    <Color>[Color(0xFF2F5D50), Color(0xFF16221F)],
    <Color>[Color(0xFF3D4C7A), Color(0xFF1B2033)],
  ];

  List<Color> get _gradient => _gradients[fallbackSeed.abs() % _gradients.length];

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _fallback(context);

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (BuildContext context, String url) => _placeholder(context),
      errorWidget: (BuildContext context, String url, Object error) =>
          _fallback(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.image_not_supported_outlined,
              size: 30, color: Colors.white70),
          if (fallbackLabel != null && fallbackLabel!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                fallbackLabel!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
