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
    ])
  ];
}