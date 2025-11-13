class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String mobile;
  final int createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.mobile,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'mobile': mobile,
        'createdAt': createdAt,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      mobile: map['mobile'] ?? '',
      createdAt: map['createdAt'] ?? 0,
    );
  }
}
