import '../response/config_response.dart';
import 'base_appender.dart';

class SBCloudAppender implements BaseAppender {
  @override
  final String name;
  final String? pattern;
  SBCloudAppender(this.name, ConfigResponse? config) : pattern = config?.appenders.firstWhere((element) => element.name == name).config?['pattern'];

  @override
  void update(ConfigResponse? config) {
    // Do nothing
  }

  @override
  void push(log) {    
    // Do nothing
  }

  @override
  void flush() {
    // Do nothing
  }

  @override
  void destructor() {
    // Do nothing
  }
}