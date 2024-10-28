class EventManager {

  

  static final EventManager _instance = EventManager._internal();
  factory EventManager() => _instance;
  EventManager._internal();

  void enableAppState() {
    // print('event loggint enabled');

  }
}