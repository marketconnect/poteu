import 'package:flutter/material.dart';
import '../../domain/entities/settings.dart';

class DynamicTheme {
  static ThemeData getLight(Settings settings) {
    return ThemeData(
      indicatorColor: const Color(0xFFe98c14),
      dividerTheme: const DividerThemeData(color: Color(0xFF303030)),
      dividerColor: Colors.transparent,
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFFfcfcfc),
        indicatorColor: const Color(0xFFfcedda),
        unselectedIconTheme: const IconThemeData(color: Color(0xFFa2a4a5)),
        selectedIconTheme: const IconThemeData(color: Color(0xFFe98c14)),
        unselectedLabelTextStyle: TextStyle(
          color: const Color(0xFF828282),
          fontWeight: FontWeight.bold,
          fontSize: settings.fontSize,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: Color(0xFFe98c14),
        ),
      ),
      focusColor: Colors.blueGrey[900],
      appBarTheme: AppBarTheme(
        elevation: 0,
        toolbarHeight: 74,
        backgroundColor: Colors.white,
        shadowColor: const Color.fromRGBO(0, 0, 0, .06),
        foregroundColor: const Color(0XFF747E8B),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: settings.fontSize + 2,
        ),
        toolbarTextStyle: TextStyle(
          color: const Color(0XFF747E8B),
          fontSize: settings.fontSize,
        ),
        iconTheme: const IconThemeData(
          size: 27,
          color: Colors.black,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFFfcfcfc),
      ),
      scaffoldBackgroundColor: Colors.white,
      shadowColor: const Color(0xFFe7e7e7),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: settings.fontSize + 1,
        ),
        displayMedium: TextStyle(
          color: Colors.black,
          backgroundColor: Colors.white,
          fontSize: settings.fontSize,
        ),
        bodyLarge: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: settings.fontSize,
        ),
        bodyMedium: TextStyle(
          color: Colors.black,
          fontSize: settings.fontSize - 1,
        ),
      ),
      iconTheme: const IconThemeData(
        size: 20,
        color: Color(0XFF447FEB),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: Color(0XFFf7f6fb),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: Color(0xFF969899),
      ),
    );
  }

  static ThemeData getDark(Settings settings) {
    return ThemeData(
      indicatorColor: const Color(0xFFf49315),
      dividerColor: Colors.transparent,
      focusColor: Colors.blueGrey[900],
      shadowColor: const Color(0xFF353535),
      appBarTheme: AppBarTheme(
        elevation: 0,
        toolbarHeight: 74,
        backgroundColor: Colors.black,
        shadowColor: const Color(0xFF242424),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: settings.fontSize + 2,
        ),
        toolbarTextStyle: TextStyle(
          color: Colors.white,
          fontSize: settings.fontSize,
        ),
        iconTheme: const IconThemeData(
          size: 27,
          color: Colors.white,
        ),
        foregroundColor: const Color(0XFF747E8B),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF25292a),
        indicatorColor: const Color(0xFF654a23),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF5f6262)),
        selectedIconTheme: const IconThemeData(color: Color(0xFFf49315)),
        unselectedLabelTextStyle: TextStyle(
          color: const Color(0xFFc6c7c7),
          fontSize: settings.fontSize,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: Color(0xFFf49315),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF25292a),
      ),
      scaffoldBackgroundColor: const Color(0xFF0b0b0b),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: settings.fontSize + 1,
        ),
        displayMedium: TextStyle(
          color: const Color(0xFFfdfdfd),
          backgroundColor: const Color(0xFF272727),
          fontSize: settings.fontSize,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: settings.fontSize,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontSize: settings.fontSize - 1,
        ),
      ),
      iconTheme: const IconThemeData(
        size: 20,
        color: Colors.white,
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: Color(0xFF969899),
      ),
    );
  }
}
