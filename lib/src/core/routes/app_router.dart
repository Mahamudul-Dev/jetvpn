import 'package:go_router/go_router.dart';

import '../../presentations/pages/pages.dart';

part 'app_routes.dart';


class AppRouter {
  late GoRouter _router;
  get router => _router;

  AppRouter() {
    _router = GoRouter(
      routes: _routes,
    );
  }



  final List<RouteBase> _routes = [
    ShellRoute(
        builder: (context, state, child)=> PageWrapper(child: child),
        routes: [
      GoRoute(
        path: AppRoutes.home.path,
        name: AppRoutes.home.name,
        builder: (context, state) => const HomePage(),
      ),

      GoRoute(
        path: AppRoutes.servers.path,
        name: AppRoutes.servers.name,
        builder: (context, state) => const ServersPage(),
      ),
    ]),

    GoRoute(
        path: AppRoutes.subscriptions.path,
        name: AppRoutes.subscriptions.name,
        builder: (context, state) => const SubscriptionsPage(),
      ),

      GoRoute(
        path: AppRoutes.webview.path,
        name: AppRoutes.webview.name,
        builder: (context, state) => WebviewPage(url: state.extra as String,),
      ),

      
  ];
}