import 'dart:async';

class DatabaseOpenGate {
  static Future<void> _pending = Future<void>.value();

  static Future<void> get ready => _pending;

  /// Holds new database opens until [action] finishes.
  /// In-flight work that already passed [ready] is not cancelled.
  static Future<T> exclusive<T>(Future<T> Function() action) {
    final previous = _pending;
    final done = Completer<void>();
    _pending = done.future;
    return previous.then((_) => action()).whenComplete(done.complete);
  }
}
