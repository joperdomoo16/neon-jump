import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageRepository {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readString(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> saveInt(String key, int value) async {
    await _secureStorage.write(key: key, value: value.toString());
  }

  Future<int?> readInt(String key) async {
    final str = await _secureStorage.read(key: key);
    if (str != null) return int.tryParse(str);
    return null;
  }

  Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }

  /// Read multiple keys concurrently for faster initialization
  Future<Map<String, String?>> readAll(List<String> keys) async {
    final futures = keys.map((key) => _secureStorage.read(key: key));
    final results = await Future.wait(futures);
    return Map.fromIterables(keys, results);
  }
}
