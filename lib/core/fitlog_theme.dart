import 'package:flutter/material.dart';

enum FitLogThemeKey {
  green('green'),
  blue('blue'),
  blackOrange('black_orange');

  const FitLogThemeKey(this.storageValue);

  final String storageValue;

  static FitLogThemeKey fromStorageValue(String? value) {
    for (final key in values) {
      if (key.storageValue == value) {
        return key;
      }
    }
    return FitLogThemeKey.green;
  }
}

class FitLogColors extends ThemeExtension<FitLogColors> {
  const FitLogColors({
    required this.key,
    required this.brightness,
    required this.seed,
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceVariant,
    required this.input,
    required this.outline,
    required this.outlineSubtle,
    required this.primary,
    required this.primaryBright,
    required this.primaryDeep,
    required this.primaryStrong,
    required this.primaryText,
    required this.primarySoft,
    required this.primarySoftPressed,
    required this.primarySoftSelected,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.pageGradientTop,
    required this.pageGradientMiddle,
    required this.pageGradientBottom,
    required this.navBackground,
    required this.navIndicator,
    required this.shadow,
  });

  final FitLogThemeKey key;
  final Brightness brightness;
  final Color seed;
  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color surfaceVariant;
  final Color input;
  final Color outline;
  final Color outlineSubtle;
  final Color primary;
  final Color primaryBright;
  final Color primaryDeep;
  final Color primaryStrong;
  final Color primaryText;
  final Color primarySoft;
  final Color primarySoftPressed;
  final Color primarySoftSelected;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color pageGradientTop;
  final Color pageGradientMiddle;
  final Color pageGradientBottom;
  final Color navBackground;
  final Color navIndicator;
  final Color shadow;

  bool get isDarkLike => brightness == Brightness.dark;

  @override
  FitLogColors copyWith({
    FitLogThemeKey? key,
    Brightness? brightness,
    Color? seed,
    Color? background,
    Color? surface,
    Color? surfaceSubtle,
    Color? surfaceVariant,
    Color? input,
    Color? outline,
    Color? outlineSubtle,
    Color? primary,
    Color? primaryBright,
    Color? primaryDeep,
    Color? primaryStrong,
    Color? primaryText,
    Color? primarySoft,
    Color? primarySoftPressed,
    Color? primarySoftSelected,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? pageGradientTop,
    Color? pageGradientMiddle,
    Color? pageGradientBottom,
    Color? navBackground,
    Color? navIndicator,
    Color? shadow,
  }) {
    return FitLogColors(
      key: key ?? this.key,
      brightness: brightness ?? this.brightness,
      seed: seed ?? this.seed,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      input: input ?? this.input,
      outline: outline ?? this.outline,
      outlineSubtle: outlineSubtle ?? this.outlineSubtle,
      primary: primary ?? this.primary,
      primaryBright: primaryBright ?? this.primaryBright,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      primaryText: primaryText ?? this.primaryText,
      primarySoft: primarySoft ?? this.primarySoft,
      primarySoftPressed: primarySoftPressed ?? this.primarySoftPressed,
      primarySoftSelected: primarySoftSelected ?? this.primarySoftSelected,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      pageGradientTop: pageGradientTop ?? this.pageGradientTop,
      pageGradientMiddle: pageGradientMiddle ?? this.pageGradientMiddle,
      pageGradientBottom: pageGradientBottom ?? this.pageGradientBottom,
      navBackground: navBackground ?? this.navBackground,
      navIndicator: navIndicator ?? this.navIndicator,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  FitLogColors lerp(ThemeExtension<FitLogColors>? other, double t) {
    if (other is! FitLogColors) {
      return this;
    }
    return FitLogColors(
      key: t < 0.5 ? key : other.key,
      brightness: t < 0.5 ? brightness : other.brightness,
      seed: Color.lerp(seed, other.seed, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      input: Color.lerp(input, other.input, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineSubtle: Color.lerp(outlineSubtle, other.outlineSubtle, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryBright: Color.lerp(primaryBright, other.primaryBright, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primarySoftPressed: Color.lerp(
        primarySoftPressed,
        other.primarySoftPressed,
        t,
      )!,
      primarySoftSelected: Color.lerp(
        primarySoftSelected,
        other.primarySoftSelected,
        t,
      )!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      pageGradientTop: Color.lerp(pageGradientTop, other.pageGradientTop, t)!,
      pageGradientMiddle: Color.lerp(
        pageGradientMiddle,
        other.pageGradientMiddle,
        t,
      )!,
      pageGradientBottom: Color.lerp(
        pageGradientBottom,
        other.pageGradientBottom,
        t,
      )!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      navIndicator: Color.lerp(navIndicator, other.navIndicator, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class FitLogPalettes {
  FitLogPalettes._();

  static const green = FitLogColors(
    key: FitLogThemeKey.green,
    brightness: Brightness.light,
    seed: Color(0xFF78BE5B),
    background: Color(0xFFF5F8F1),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF8FBF5),
    surfaceVariant: Color(0xFFFCFDFC),
    input: Color(0xFFFFFFFF),
    outline: Color(0xFFE2ECDD),
    outlineSubtle: Color(0xFFE8EFE3),
    primary: Color(0xFF4E9E3B),
    primaryBright: Color(0xFF74BF56),
    primaryDeep: Color(0xFF355A32),
    primaryStrong: Color(0xFF3E7A31),
    primaryText: Color(0xFF234120),
    primarySoft: Color(0xFFEAF6E3),
    primarySoftPressed: Color(0xFFDCEFD1),
    primarySoftSelected: Color(0xFFE9F7DF),
    onPrimary: Colors.white,
    textPrimary: Color(0xFF152013),
    textSecondary: Color(0xFF61715D),
    textMuted: Color(0xFF7A8973),
    textDisabled: Color(0xFF98A494),
    pageGradientTop: Color(0xFFFAFCF7),
    pageGradientMiddle: Color(0xFFF3F7EE),
    pageGradientBottom: Color(0xFFF7FAF3),
    navBackground: Color(0xFFFFFFFF),
    navIndicator: Color(0xFFEAF6E3),
    shadow: Color(0xFF13200F),
  );

  static const blue = FitLogColors(
    key: FitLogThemeKey.blue,
    brightness: Brightness.light,
    seed: Color(0xFF55DCE2),
    background: Color(0xFFF3FBFA),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF6FDFC),
    surfaceVariant: Color(0xFFFAFEFE),
    input: Color(0xFFFFFFFF),
    outline: Color(0xFFD4EEEE),
    outlineSubtle: Color(0xFFE5F5F4),
    primary: Color(0xFF55DCE2),
    primaryBright: Color(0xFF55DCE2),
    primaryDeep: Color(0xFF176C75),
    primaryStrong: Color(0xFF31B7C0),
    primaryText: Color(0xFF0D3F47),
    primarySoft: Color(0xFFE5FAFA),
    primarySoftPressed: Color(0xFFBCEFF2),
    primarySoftSelected: Color(0xFFD2F6F7),
    onPrimary: Color(0xFF0D3F47),
    textPrimary: Color(0xFF062326),
    textSecondary: Color(0xFF456A6E),
    textMuted: Color(0xFF6B8588),
    textDisabled: Color(0xFF9DB3B5),
    pageGradientTop: Color(0xFFFAFEFD),
    pageGradientMiddle: Color(0xFFEFFAF9),
    pageGradientBottom: Color(0xFFF7FCFB),
    navBackground: Color(0xFFFFFFFF),
    navIndicator: Color(0xFFE5FAFA),
    shadow: Color(0xFF0D3F47),
  );

  static const blackOrange = FitLogColors(
    key: FitLogThemeKey.blackOrange,
    brightness: Brightness.dark,
    seed: Color(0xFFFF6B01),
    background: Color(0xFF171813),
    surface: Color(0xFF24231F),
    surfaceSubtle: Color(0xFF2A2924),
    surfaceVariant: Color(0xFF262520),
    input: Color(0xFF2A2924),
    outline: Color(0xFF3D3B34),
    outlineSubtle: Color(0xFF302F2A),
    primary: Color(0xFFFF6B01),
    primaryBright: Color(0xFFFF7A1A),
    primaryDeep: Color(0xFFFF8A33),
    primaryStrong: Color(0xFFFF6B01),
    primaryText: Color(0xFFFF8A33),
    primarySoft: Color(0xFF2A2924),
    primarySoftPressed: Color(0xFF373631),
    primarySoftSelected: Color(0xFF332A21),
    onPrimary: Color(0xFF171813),
    textPrimary: Color(0xFFF6F4EC),
    textSecondary: Color(0xFFB8B5AA),
    textMuted: Color(0xFF9D9D94),
    textDisabled: Color(0xFF77746C),
    pageGradientTop: Color(0xFF171813),
    pageGradientMiddle: Color(0xFF171813),
    pageGradientBottom: Color(0xFF171813),
    navBackground: Color(0xFF24231F),
    navIndicator: Color(0xFF2A2924),
    shadow: Color(0xFF000000),
  );

  static FitLogColors byKey(FitLogThemeKey key) {
    switch (key) {
      case FitLogThemeKey.green:
        return green;
      case FitLogThemeKey.blue:
        return blue;
      case FitLogThemeKey.blackOrange:
        return blackOrange;
    }
  }
}

extension FitLogThemeDataX on ThemeData {
  FitLogColors get fitLogColors =>
      extension<FitLogColors>() ?? FitLogPalettes.green;
}

extension FitLogBuildContextThemeX on BuildContext {
  FitLogColors get fitLogColors => Theme.of(this).fitLogColors;
}
