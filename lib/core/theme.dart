import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF0FBF4);
  static const green = Color(0xFF006F51);
  static const mint = Color(0xFFDCF8EB);
  static const pale = Color(0xFFE8F2EE);
  static const ink = Color(0xFF142033);
  static const muted = Color(0xFF718294);
  static const orange = Color(0xFFFF8740);
  static const blue = Color(0xFF2868D9);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        primary: AppColors.green,
        surface: Colors.white),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
          fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.ink),
      titleLarge: TextStyle(
          fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.ink),
    ),
    cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDCE5EE))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDCE5EE))),
    ),
  );
}

class WhiteCard extends StatelessWidget {
  const WhiteCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
            padding: padding,
            child: SizedBox(width: double.infinity, child: child)),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key, required this.text, required this.onPressed, this.icon});
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.arrow_forward, size: 20),
          label: Text(text,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13))),
        ),
      );
}
