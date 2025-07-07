import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseTestHelper {
  static bool _initialized = false;

  static Future<void> initializeForTesting() async {
    if (_initialized) return;

    // Initialize FFI for sqflite
    sqfliteFfiInit();

    // Set global factory
    databaseFactory = databaseFactoryFfi;

    _initialized = true;
  }

  static Future<void> cleanup() async {
    if (!_initialized) return;

    try {
      await databaseFactory.deleteDatabase('test.db');
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
