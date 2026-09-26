import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/favorites/views/favorites_page.dart';
import '../features/news/models/news_article.dart';
import '../features/news/views/article_detail_page.dart';
import '../features/news/views/news_feed_page.dart';
import '../features/onboarding/views/onboarding_page.dart';
import '../features/settings/views/settings_page.dart';
import '../shared/hive/app_settings.dart';
import '../shared/hive/settings_provider.dart';
import 'main_shell.dart';

/// 全站路由路径常量。
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String news = '/news';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String article = '/article';
}

/// go_router 配置持有者：把 router 与 [Listenable] 一起暴露，
/// 便于 `refreshListenable` 在本地设置变化时重新触发 redirect。
class GoRouterConfig {
  GoRouterConfig({required this.router, required this.listenable});

  final GoRouter router;
  final Listenable listenable;

  /// 供 MaterialApp 使用。
  RouterConfig<Object> get routerConfig => router;
}

/// 把本地设置变化桥接成 [Listenable]，驱动 go_router 重新计算 redirect。
class _SettingsNotifier extends ChangeNotifier {
  _SettingsNotifier(Ref ref) {
    _sub = ref.listen<AsyncValue<AppSettings>>(
      settingsProvider,
      (AsyncValue<AppSettings>? previous, AsyncValue<AppSettings> next) {
        if (previous?.valueOrNull != next.valueOrNull) {
          notifyListeners();
        }
      },
    );
  }

  late final ProviderSubscription<AsyncValue<AppSettings>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// 全局路由 Provider。
final Provider<GoRouterConfig> appRouterProvider =
    Provider<GoRouterConfig>((Ref ref) {
  final _SettingsNotifier listenable = _SettingsNotifier(ref);
  ref.onDispose(listenable.dispose);

  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<AppSettings> settingsAsync = ref.read(settingsProvider);

      // 设置仍在从 Hive 读取：停留在启动页，避免闪烁。
      if (settingsAsync.isLoading && !settingsAsync.hasValue) {
        return state.matchedLocation == AppRoutes.splash ? null : null;
      }

      final AppSettings? settings = settingsAsync.valueOrNull;
      // 首次启动（isFirstLaunch == true）或未填写 API Key → 必须走引导页。
      final bool needOnboarding = settings == null ||
          settings.isFirstLaunch ||
          !settings.hasApiKey;

      final bool atOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (needOnboarding) {
        return atOnboarding ? null : AppRoutes.onboarding;
      }
      if (atOnboarding || state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.news;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const _SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsPage(),
      ),
      // 全文阅读页：滑动/淡入过渡动画。
      GoRoute(
        path: AppRoutes.article,
        name: 'article',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final NewsArticle? article = state.extra is NewsArticle
              ? state.extra! as NewsArticle
              : null;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            fullscreenDialog: true,
            transitionDuration: const Duration(milliseconds: 380),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            child: ArticleDetailPage(
              article: article,
              articleId: state.uri.queryParameters['id'],
            ),
            transitionsBuilder: (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final Animation<double> curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      // 底部 Tab（新闻 / 收藏）外壳。
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell shell,
        ) =>
            MainShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.news,
                name: 'news',
                builder: (BuildContext context, GoRouterState state) =>
                    const NewsFeedPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.favorites,
                name: 'favorites',
                builder: (BuildContext context, GoRouterState state) =>
                    const FavoritesPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('页面不存在：${state.uri}'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.news),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return GoRouterConfig(router: router, listenable: listenable);
});

/// 启动页：Hive 读取设置的极短过渡。
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('闻天下', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
            SizedBox(height: 20),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ],
        ),
      ),
    );
  }
}
