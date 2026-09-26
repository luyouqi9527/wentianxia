/// 聚合数据新闻头条 API 的频道定义。
///
/// 接口：`https://v.juhe.cn/toutiao/index?type=<channel>&key=<apiKey>`
/// 免费额度：50 次/天（每次请求计一次，因此同一批频道会被并发但受控地请求）。
class NewsChannel {
  const NewsChannel(this.type, this.label, {this.icon = '📰'});

  /// 接口 `type` 参数。
  final String type;

  /// 中文显示名。
  final String label;

  /// 兴趣选择 Chip 上的图标。
  final String icon;

  @override
  bool operator ==(Object other) => other is NewsChannel && other.type == type;

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => '$label($type)';
}

/// 全部可选频道（引导页兴趣选择 / 首页频道切换 / 设置页复用）。
const List<NewsChannel> kAllChannels = <NewsChannel>[
  NewsChannel('top', '头条', icon: '🔥'),
  NewsChannel('guonei', '国内', icon: '🇨🇳'),
  NewsChannel('guoji', '国际', icon: '🌍'),
  NewsChannel('yule', '娱乐', icon: '🎬'),
  NewsChannel('tiyu', '体育', icon: '⚽'),
  NewsChannel('junshi', '军事', icon: '🛡️'),
  NewsChannel('keji', '科技', icon: '🚀'),
  NewsChannel('caijing', '财经', icon: '💰'),
  NewsChannel('youxi', '游戏', icon: '🎮'),
  NewsChannel('qiche', '汽车', icon: '🚗'),
  NewsChannel('jiankang', '健康', icon: '🩺'),
  NewsChannel('shishang', '时尚', icon: '👗'),
  NewsChannel('jiaoyu', '教育', icon: '🎓'),
  NewsChannel('lvyou', '旅游', icon: '✈️'),
];

/// 按接口 type 查频道定义。
NewsChannel channelOf(String type) => kAllChannels.firstWhere(
      (NewsChannel c) => c.type == type,
      orElse: () => NewsChannel(type, type),
    );

/// 按中文标签查频道（兼容历史数据里存的是中文名的情况）。
NewsChannel? channelByLabel(String label) {
  for (final NewsChannel c in kAllChannels) {
    if (c.label == label) return c;
  }
  return null;
}

/// 把历史 / 用户数据里的频道标识统一成接口 type。
String normalizeChannelType(String raw) {
  final String v = raw.trim();
  if (v.isEmpty) return 'top';
  for (final NewsChannel c in kAllChannels) {
    if (c.type == v) return c.type;
  }
  return channelByLabel(v)?.type ?? v;
}
