import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jetvpn/src/core/config/theme_config.dart';

import 'core/routes/app_router.dart';
import 'core/config/locator.dart';

class JetVpnApp extends StatelessWidget {
  const JetVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              themeMode: ThemeMode.dark,
              theme: ThemeConfig(scheme: lightDynamic ??
                  ColorScheme.fromSeed(seedColor: Colors.green)).theme,
              darkTheme: ThemeConfig(scheme: darkDynamic ??
                  ColorScheme.fromSeed(seedColor: Colors.green)).theme,
              routerConfig: getIt<AppRouter>().router,
            );
          },
        );
      },
    );
  }
}
