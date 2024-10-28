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

  /// Emits an event with the given name and data.
  void emit(EventType event, dynamic data) {
    _controller.sink.add({event: data});
  }

  /// Listens to specific events by name.
  Stream<dynamic> on(EventType event) {
    return _controller.stream
        .where((eventMap) => eventMap.containsKey(event))
        .map((eventMap) => eventMap[event]);
  }
  /// Stops listening to the events.
  void off(EventType event, void Function(dynamic) listener) {
    _controller.stream
        .where((eventMap) => eventMap.containsKey(event))
        .listen(listener)
        .cancel();
  }
  /// Closes the stream (cleanup).
  void dispose() {
    _controller.close();
  }
}
