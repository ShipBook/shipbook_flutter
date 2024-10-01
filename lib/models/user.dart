import 'response/config_response.dart';

class User {
  String userId;
  String? userName;
  String? fullName;
  String? email;
  String? phoneNumber;
  Object? additionalInfo;

  User({
    required this.userId,
    this.userName,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.additionalInfo,
  });

  // Create a User object from a JSON map
  factory User.fromJsonMap(JsonMap jsonMap) {
    return User(
      userId: jsonMap['userId'],
      userName: jsonMap['userName'],
      fullName: jsonMap['fullName'],
      email: jsonMap['email'],
      phoneNumber: jsonMap['phoneNumber'],
      additionalInfo: jsonMap['additionalInfo'],
    );
  }

  // Create a JSON map from a User object
  JsonMap toJsonMap() {
    return {
      'userId': userId,
      'userName': userName,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'additionalInfo': additionalInfo,
    };
  }
}