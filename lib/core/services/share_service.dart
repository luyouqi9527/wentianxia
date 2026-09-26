import 'package:flutter/services.dart';

/// 调用 Android 原生分享面板（MethodChannel，见 MainActivity.kt）。
///
/// 说明：不引入 share_plus 等第三方依赖，避免 CodeMagic 构建期的插件兼容风险。
class ShareService {
  const ShareService._();

  static const MethodChannel _channel =
      MethodChannel('com.wentianxia.wentianxia/share');

  /// 分享纯文本；失败时静默返回 false（调用方可用 SnackBar 提示）。
  static Future<bool> shareText({required String title, required String text}) async {
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'shareText',
        <String, String>{'title': title, 'text': text},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
