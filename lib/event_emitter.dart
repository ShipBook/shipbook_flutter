import 'dart:async';

enum EventType {
  configChange,
  connected,
  userChange,
}

class EventEmitter {
  // Private constructor.
  EventEmitter._internal();

  // The single instance of the class.
  static final EventEmitter _instance = EventEmitter._internal();

  // Factory constructor that returns the same instance every time.
  factory EventEmitter() => _instance;

  // StreamController to manage events.
  final StreamController<Map<EventType, dynamic>> _controller =
      StreamController<Map<EventType, dynamic>>.broadcast();

   // Map to track listeners and their subscriptions.
  final Map<EventType, List<MapEntry<Function, StreamSubscription>>> _listeners = {};


  /// Emits an event with the given name and data.
  void emit(EventType event, dynamic data) {
    _controller.sink.add({event: data});
  }

  /// Listens to specific events by name.
  void on(EventType event, void Function(dynamic) listener) {
    final subscription = _controller.stream
        .where((eventMap) => eventMap.containsKey(event))
        .map((eventMap) => eventMap[event])
        .listen(listener);

    _listeners.putIfAbsent(event, () => []).add(MapEntry(listener, subscription));
  }

  /// Stops listening to the events.
  void off(EventType event, void Function(dynamic) listener) {
    if (_listeners.containsKey(event)) {
      _listeners[event]?.removeWhere((entry) {
        if (entry.key == listener) {
          entry.value.cancel();
          return true;
        }
        return false;
      });
    }
  }

  /// Closes the stream (cleanup).
  void dispose() {
    _controller.close();
    _listeners.forEach((event, entries) {
      for (var entry in entries) {
        entry.value.cancel();
      }
    });
    _listeners.clear();
  }
}