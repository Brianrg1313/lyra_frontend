class ClientModel {
  final String name;
  final String lastName;
  final String username;
  final String email;
  final String? sex;
  final String? picture;
  final DateTime? birthday;

  const ClientModel({
    required this.name,
    required this.lastName,
    required this.username,
    required this.email,
    this.sex,
    this.picture,
    this.birthday,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      name: json["name"] ?? "",
      lastName: json["last_name"] ?? "",
      username: json["username"] ?? "",
      email: json["email"] ?? "",
      sex: json["sex"],
      picture: json["picture"],
      birthday: json["birthday"] != null ? DateTime.tryParse(json["birthday"]) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "last_name": lastName,
      "username": username,
      "email": email,
      "sex": sex,
      "picture": picture,
      "birthday": birthday?.toIso8601String(),
    };
  }

  String get fullName => "$name $lastName";

  ClientModel copyWith({
    String? name,
    String? lastName,
    String? username,
    String? email,
    String? sex,
    String? picture,
    DateTime? birthday,
  }) {
    return ClientModel(
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      sex: sex ?? this.sex,
      picture: picture ?? this.picture,
      birthday: birthday ?? this.birthday,
    );
  }
}
