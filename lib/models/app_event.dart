import 'base_event.dart';
import 'base_log.dart';
import 'common_types.dart';

class AppEvent extends BaseEvent {
  final String event;
  final String state;
  final String orientation;

  AppEvent(this.event, this.state, this.orientation, [Json? json]) : super(LogType.appEvent, json);

  @override
  factory AppEvent.fromJson(Json json) {
    return AppEvent(json['event'], json['state'], json['orientation'], json);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['event'] = event;
    json['state'] = state;
    json['orientation'] = orientation;
    return json;
  }
}
