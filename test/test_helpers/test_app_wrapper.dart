import 'package:flutter/material.dart';
import 'package:poteu/app/theme/dynamic_theme.dart';
import 'package:poteu/domain/entities/settings.dart';

/// Wrapper for widget tests that provides MaterialApp and theme
class TestAppWrapper extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final Settings? settings;
  final RouteFactory? onGenerateRoute;

  const TestAppWrapper({
    Key? key,
    required this.child,
    this.isDarkMode = false,
    this.settings,
    this.onGenerateRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final testSettings = settings ?? Settings.defaultSettings();
    final lightTheme = DynamicTheme.getLight(testSettings);
    final darkTheme = DynamicTheme.getDark(testSettings);

    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(1080, 1920),
          devicePixelRatio: 1.0,
          padding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
          systemGestureInsets: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
        ),
        child: Material(
          child: child,
        ),
      ),
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
