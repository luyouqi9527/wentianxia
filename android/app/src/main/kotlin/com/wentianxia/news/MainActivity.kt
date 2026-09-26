package com.wentianxia.news

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 闻天下 Android 宿主 Activity。
 *
 * 仅提供一个原生能力：系统分享面板（MethodChannel: com.wentianxia.wentianxia/share）。
 * 使用原生 Intent 而不是第三方插件，减少 CodeMagic 构建期的插件兼容风险。
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val SHARE_CHANNEL = "com.wentianxia.wentianxia/share"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareText" -> {
                        val title = call.argument<String>("title") ?: "闻天下"
                        val text = call.argument<String>("text") ?: ""
                        result.success(shareText(title, text))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareText(title: String, text: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_SUBJECT, title)
                putExtra(Intent.EXTRA_TEXT, text)
            }
            val chooser = Intent.createChooser(intent, "分享到").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(chooser)
            true
        } catch (e: Exception) {
            false
        }
    }
}
