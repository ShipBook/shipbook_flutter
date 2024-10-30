import 'base_log.dart';
import 'common_types.dart';

import 'base_event.dart';

class ScreenEvent extends BaseEvent {
  final String name;

  ScreenEvent(this.name) : super(LogType.screenEvent);

  @override
  factory ScreenEvent.fromJson(Json json) {
    return ScreenEvent(json['name']);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['name'] = name;
    return json;
  }
}