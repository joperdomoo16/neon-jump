import 'dart:math';

class ObfuscatedInt {
  static final Random _secureRandom = Random.secure();
  late int _value;
  late int _key;

  ObfuscatedInt(int initialValue) {
    _key = _secureRandom.nextInt(900000) + 100000;
    _value = initialValue ^ _key;
  }

  int get value => _value ^ _key;

  set value(int newValue) {
    _key = _secureRandom.nextInt(900000) + 100000;
    _value = newValue ^ _key;
  }
}
