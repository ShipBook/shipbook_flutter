import '../response/config_response.dart';

import '../../inner_log.dart';
import 'base_appender.dart';

class SBCloudAppender implements BaseAppender {
  @override
  final String name;
  SBCloudAppender(this.name, JsonMap? config){
    innerLog.i('SBCloudAppender created');
  }  

  @override
  void update(JsonMap? config) {
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