import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/backup/secure_backup_keys.dart';

const _pinStorageKey = pinPrefKey;

class PinLockState {
  final bool isLoaded;
  final bool hasPin;
  final bool isUnlocked;
  final String? storedPin;

  const PinLockState({
    this.isLoaded = false,
    this.hasPin = false,
    this.isUnlocked = true,
    this.storedPin,
  });

  PinLockState copyWith({
    bool? isLoaded,
    bool? hasPin,
    bool? isUnlocked,
    String? storedPin,
    bool clearPin = false,
  }) {
    return PinLockState(
      isLoaded: isLoaded ?? this.isLoaded,
      hasPin: hasPin ?? this.hasPin,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      storedPin: clearPin ? null : (storedPin ?? this.storedPin),
    );
  }
}

final pinLockProvider =
    StateNotifierProvider<PinLockNotifier, PinLockState>((ref) {
  return PinLockNotifier();
});

class PinLockNotifier extends StateNotifier<PinLockState> {
  final FlutterSecureStorage _storage;

  PinLockNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const PinLockState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final pin = await _storage.read(key: _pinStorageKey);
      final hasPin = pin != null && pin.length == 4;
      state = PinLockState(
        isLoaded: true,
        hasPin: hasPin,
        isUnlocked: !hasPin,
        storedPin: hasPin ? pin : null,
      );
    } catch (_) {
      state = const PinLockState(
        isLoaded: true,
        hasPin: false,
        isUnlocked: true,
      );
    }
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinStorageKey, value: pin);
    state = PinLockState(
      isLoaded: true,
      hasPin: true,
      isUnlocked: true,
      storedPin: pin,
    );
  }

  Future<void> disablePin() async {
    await _storage.delete(key: _pinStorageKey);
    state = const PinLockState(
      isLoaded: true,
      hasPin: false,
      isUnlocked: true,
      storedPin: null,
    );
  }

  bool verifyPin(String input) {
    if (state.storedPin == input) {
      state = state.copyWith(isUnlocked: true);
      return true;
    }
    return false;
  }

  void lock() {
    if (state.hasPin) {
      state = state.copyWith(isUnlocked: false);
    }
  }
}
