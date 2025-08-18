part of 'app_router.dart';

class RouteModel {
  final String name;
  final String path;

  RouteModel(this.name, this.path);

}


class AppRoutes {
  static final home = RouteModel('home', '/');
  static final login = RouteModel('login', '/login');
  static final register = RouteModel('register', '/register');
  static final forgotPassword = RouteModel('forgotPassword', '/forgot-password');
  static final servers = RouteModel('servers', '/servers');
  static final subscriptions = RouteModel('subscriptions', '/subscriptions');
}