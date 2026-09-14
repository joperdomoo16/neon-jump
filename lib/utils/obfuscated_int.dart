import 'dart:math';

class ObfuscatedInt {
  late int _value;
  late int _key;

  ObfuscatedInt(int initialValue) {
    _key = Random().nextInt(999999) + 100000;
    _value = initialValue ^ _key;
  }

  int get value => _value ^ _key;

  set value(int newValue) {
    _key = Random().nextInt(999999) + 100000; // rotate key on write
    _value = newValue ^ _key;
  }
}
