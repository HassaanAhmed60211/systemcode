class UserModel {
  final String userid;
  final String username;
  final String email;
  final String age;
  final String gender;

  UserModel({
    required this.userid,
    required this.username,
    required this.email,
    required this.age,
    required this.gender,
  });

  Map<String, dynamic> toMap() {
    return {
      'userid': userid,
      'username': username,
      'email': email,
      'age': age,
      'gender': gender,
    };
  }
}
