import 'package:flutter/foundation.dart';
import 'package:poteu/domain/entities/regulation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';

class ActiveRegulationService extends ChangeNotifier {
  static final ActiveRegulationService _instance =
      ActiveRegulationService._internal();
  factory ActiveRegulationService() => _instance;
  ActiveRegulationService._internal();

  static const String _keyId = 'active_regulation_id';
  static const String _keyName = 'active_regulation_name';
  static const String _keyAbbr = 'active_regulation_abbr';
  static const String _keySourceName = 'active_regulation_source_name';
  static const String _keySourceUrl = 'active_regulation_source_url';

  late SharedPreferences _prefs;

  late int _currentRegulationId;
  late String _currentAppName;
  late String _currentAbbreviation;
  late String _currentSourceName;
  late String _currentSourceUrl;

  int get currentRegulationId => _currentRegulationId;
  String get currentAppName => _currentAppName;
  String get currentAbbreviation => _currentAbbreviation;
  String get currentSourceName => _currentSourceName;
  String get currentSourceUrl => _currentSourceUrl;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Load from prefs or use default from AppConfig
    _currentRegulationId =
        _prefs.getInt(_keyId) ?? AppConfig.instance.regulationId;
    _currentAppName = _prefs.getString(_keyName) ?? AppConfig.instance.appName;
    _currentAbbreviation =
        _prefs.getString(_keyAbbr) ?? AppConfig.instance.appName; // Fallback
    _currentSourceName =
        _prefs.getString(_keySourceName) ?? AppConfig.instance.sourceName;
    _currentSourceUrl =
        _prefs.getString(_keySourceUrl) ?? AppConfig.instance.source;

    // This is the first notification
    notifyListeners();
  }

  Future<void> setActiveRegulation(Regulation newRegulation) async {
    _currentRegulationId = newRegulation.id;
    _currentAppName = newRegulation.description; // Abbreviation is used as AppName
    _currentAbbreviation = newRegulation.description;

    // For now, source information is not available in the cloud data.
    // We will persist the new ID and names, but source info will remain from the initial flavor.
    // This could be enhanced by adding more data to `rules.parquet`.

    await _prefs.setInt(_keyId, _currentRegulationId);
    await _prefs.setString(_keyName, _currentAppName);
    await _prefs.setString(_keyAbbr, _currentAbbreviation);

    notifyListeners();
  }

  bool isDefault() {
    return _currentRegulationId == AppConfig.instance.regulationId;
  }
}
