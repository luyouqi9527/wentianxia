/// 统一的业务异常：UI 层据此展示 SnackBar 文案。
class NewsApiException implements Exception {
  const NewsApiException(this.message, {this.code, this.isRateLimited = false});

  final String message;
  final int? code;

  /// 聚合数据免费额度用尽（错误码 10012 / 10001 等）。
  final bool isRateLimited;

  @override
  String toString() => 'NewsApiException($code): $message';
}
