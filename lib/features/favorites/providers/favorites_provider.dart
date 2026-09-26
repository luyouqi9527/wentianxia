import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../shared/hive/hive_service.dart';
import '../../news/models/news_article.dart';

/// 收藏控制器：Hive 为唯一数据源，任何写操作都会通过 Box 的 watch 流
/// 自动通知 UI 刷新（收藏页 / 卡片上的心形图标保持一致）。
class FavoritesController extends StateNotifier<List<NewsArticle>> {
  FavoritesController(this._hive) : super(_hive.favorites()) {
    _sub = _hive.favoritesBox.watch().listen((BoxEvent _) {
      if (mounted) state = _hive.favorites();
    });
  }

  final HiveService _hive;
  late final StreamSubscription<BoxEvent> _sub;

  /// 收藏 / 取消收藏，返回操作后的收藏状态。
  Future<bool> toggle(NewsArticle article) async {
    final bool favorite = await _hive.toggleFavorite(article);
    state = _hive.favorites();
    return favorite;
  }

  /// 左滑删除收藏。
  Future<void> remove(NewsArticle article) async {
    await _hive.removeFavorite(article);
    state = _hive.favorites();
  }

  Future<void> clearAll() async {
    await _hive.favoritesBox.clear();
    await _hive.favoritesBox.flush();
    state = _hive.favorites();
  }

  void reload() => state = _hive.favorites();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// 收藏列表 Provider（收藏页与卡片心形图标共用）。
final StateNotifierProvider<FavoritesController, List<NewsArticle>>
    favoritesProvider =
    StateNotifierProvider<FavoritesController, List<NewsArticle>>((Ref ref) {
  return FavoritesController(ref.watch(hiveServiceProvider));
});

/// 某条新闻是否已收藏（局部刷新，避免整页重建）。
final ProviderFamily<bool, String> isFavoriteProvider =
    Provider.family<bool, String>((Ref ref, String id) {
  final List<NewsArticle> favorites = ref.watch(favoritesProvider);
  return favorites.any((NewsArticle a) => a.key == id);
});
