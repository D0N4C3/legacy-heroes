import 'package:shared_preferences/shared_preferences.dart';

/// Local-first persistence (plan §11). Stores the serialized game state as a
/// single JSON string. Firestore cloud sync (plan §9) layers on top of this
/// later — the local save remains the source of truth for instant launch.
class SaveService {
  static const _key = 'legacy_heroes_save_v1';
  SharedPreferences? _prefs;

  Future<void> _ensure() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> save(String json) async {
    await _ensure();
    await _prefs!.setString(_key, json);
  }

  Future<String?> load() async {
    await _ensure();
    return _prefs!.getString(_key);
  }

  Future<void> clear() async {
    await _ensure();
    await _prefs!.remove(_key);
  }
}
