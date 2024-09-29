class Log {
  final String tag;
  
  Log(this.tag)  {
    print("Shipbook: $tag");
  }
  // static e(String message){
  //   print("Shipbook: $message");
  // }
  // static w(String message){
  //   print("Shipbook: $message");
  // }
  // static i(String message){
  //   print("Shipbook: $message");
  // }
  // static d(String message){
  //   print("Shipbook: $message");
  // }
  // static v(String message){
  //   print("Shipbook: $message");
  // }

  e(String message){
    print("Shipbook: $tag $message");
  }
  w(String message){
    print("Shipbook: $message");
  }
  i(String message){
    print("Shipbook: $message");
  }
  d(String message){
    print("Shipbook: $message");
  }
  v(String message){
    print("Shipbook: $message");
  }
}