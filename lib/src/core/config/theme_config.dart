import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {
  final ColorScheme scheme;

  ThemeConfig({required this.scheme});

  ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: _buildTextTheme(),
    appBarTheme: _buildAppBarTheme()
  );

  TextTheme _buildTextTheme() {
    final base = Typography.material2021().black; // Or .white for dark theme
    return base.copyWith(
      headlineLarge: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 32.sp),
      headlineMedium: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 28.sp),
      headlineSmall: GoogleFonts.roboto(fontWeight: FontWeight.w400, fontSize: 24.sp),

      titleLarge: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 24.sp),
      titleMedium: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 20.sp),
      titleSmall: GoogleFonts.roboto(fontWeight: FontWeight.w400, fontSize: 16.sp),

      bodyLarge: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 16.sp),
      bodyMedium: GoogleFonts.roboto(fontWeight: FontWeight.w400, fontSize: 14.sp),
      bodySmall: GoogleFonts.roboto(fontWeight: FontWeight.w300, fontSize: 12.sp),

      labelLarge: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 14.sp),
      labelMedium: GoogleFonts.roboto(fontWeight: FontWeight.w400, fontSize: 12.sp),
      labelSmall: GoogleFonts.roboto(fontWeight: FontWeight.w300, fontSize: 10.sp),
    );
  }

  AppBarTheme _buildAppBarTheme() => AppBarTheme(
    centerTitle: true,
    titleTextStyle: _buildTextTheme().titleLarge?.copyWith(
      color: scheme.onSurface
    ),
  );
}
