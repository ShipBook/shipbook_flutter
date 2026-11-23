import 'package:flutter/widgets.dart';

import 'log_manager.dart';
import 'models/app_event.dart';

class EventManager with WidgetsBindingObserver {
  static final EventManager _instance = EventManager._internal();
  factory EventManager() => _instance;
  EventManager._internal();

  bool _observing = false;
  String? _state;

  void enableAppState() {
    if (_observing) return;
    _observing = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void removeAppState() {
    if (!_observing) return;
    _observing = false;
    _state = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The other SDKs send three states; Flutter's hidden, paused and detached are all the app out of sight.
    final name = switch (state) {
      AppLifecycleState.resumed => 'active',
      AppLifecycleState.inactive => 'inactive',
      AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached => 'background',
    };
    if (name == _state) return;
    _state = name;

    final size = WidgetsBinding.instance.platformDispatcher.views.firstOrNull?.physicalSize;
    final orientation = size == null ? 'unknown' : size.height >= size.width ? 'portrait' : 'landscape';
    LogManager().push(AppEvent('change', name, orientation));
  }
}
