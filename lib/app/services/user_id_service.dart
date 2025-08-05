import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;

class UserIdService {
  static const _key = 'unique_user_id_v1';
  String? _cachedUserId;

  Future<String> getUserId() async {
    // Если ID уже в кэше, возвращаем его
    if (_cachedUserId != null) {
      return _cachedUserId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_key);

    // Если ID не найден в SharedPreferences, значит это первый запуск
    if (userId == null) {
      // Генерируем новый UUID (версия 4)
      userId = const Uuid().v4();
      // Сохраняем его для всех последующих запусков
      await prefs.setString(_key, userId);
      dev.log('Generated new unique_user_id: $userId');
    } else {
      dev.log('Loaded existing unique_user_id: $userId');
    }

    // Кэшируем ID в памяти для быстрых последующих вызовов
    _cachedUserId = userId;
    return userId;
  }
}
