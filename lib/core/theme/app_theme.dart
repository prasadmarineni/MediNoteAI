import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Medical theme: Soft blues, clean whites, and professional grays
  static final ThemeData light = FlexThemeData.light(
    scheme: FlexScheme.blueM3,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      cardRadius: 16,
      elevatedButtonRadius: 12,
      outlinedButtonRadius: 12,
      inputDecoratorRadius: 12,
      inputDecoratorIsFilled: true,
      inputDecoratorFillColor: Color(0xFFF0F4F8),
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
  );

  static final ThemeData dark = FlexThemeData.dark(
    scheme: FlexScheme.blueM3,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      cardRadius: 16,
      elevatedButtonRadius: 12,
      outlinedButtonRadius: 12,
      inputDecoratorRadius: 12,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
  );
}
