class UserModel {
  final String id;
  final String email;
  final String? displayName;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    email: json['email'],
    displayName: json['displayName'],
  );
}
