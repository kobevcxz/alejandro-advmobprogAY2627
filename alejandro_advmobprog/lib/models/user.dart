class User {
  final int id;
  final String firebaseUid;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final int age;
  final String contactNo;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;
  final String loginType;

  const User({
    required this.id,
    this.firebaseUid = '',
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.age = 0,
    this.contactNo = '',
    this.gender = '',
    this.image = '',
    this.accessToken = '',
    this.refreshToken = '',
    this.loginType = 'dummyjson',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final dynamic ageValue = json['age'];

    final int parsedAge = ageValue is num
        ? ageValue.toInt()
        : int.tryParse(ageValue?.toString() ?? '') ?? 0;

    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firebaseUid:
          json['firebaseUid']?.toString() ?? json['uid']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email:
          json['email']?.toString() ?? json['emailAddress']?.toString() ?? '',
      firstName:
          json['firstName']?.toString() ?? json['fName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? json['lName']?.toString() ?? '',
      age: parsedAge,
      contactNo: json['contactNo']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      accessToken:
          json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      loginType: json['loginType']?.toString() ?? 'dummyjson',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'contactNo': contactNo,
      'gender': gender,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'loginType': loginType,
    };
  }

  String get fullName => '$firstName $lastName'.trim();

  bool get isFirebase => loginType == 'firebase';

  bool get isDummyJson => loginType == 'dummyjson';
}
