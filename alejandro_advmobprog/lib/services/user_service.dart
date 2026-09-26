import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  static const String _userDataKey = 'userData';

  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  firebase_auth.User? get currentFirebaseUser {
    return _firebaseAuth.currentUser;
  }

  Stream<firebase_auth.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  Future<User> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    final Map<String, dynamic> responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final user = User.fromJson({...responseData, 'loginType': 'dummyjson'});

      await saveUserData(user);

      return user;
    }

    throw Exception(
      responseData['message'] ?? 'Unable to sign in. Please try again.',
    );
  }

  Future<User> signIn({required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Unable to retrieve the Firebase user.');
    }

    final user = await _getFirebaseUserData(firebaseUser);

    await saveUserData(user);

    return user;
  }

  Future<User> createAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Unable to create the Firebase account.');
    }

    await firebaseUser.updateDisplayName(username.trim());

    final userData = {
      'firebaseUid': firebaseUser.uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'age': age,
      'contactNo': contactNo.trim(),
      'username': username.trim(),
      'email': email.trim(),
      'gender': '',
      'image': '',
      'loginType': 'firebase',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

    final user = User(
      id: 0,
      firebaseUid: firebaseUser.uid,
      username: username.trim(),
      email: email.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      age: age,
      contactNo: contactNo.trim(),
      loginType: 'firebase',
    );

    await saveUserData(user);

    return user;
  }

  Future<void> saveUserData(User user) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_userDataKey, jsonEncode(user.toJson()));
  }

  Future<User?> _getSavedUserData() async {
    final preferences = await SharedPreferences.getInstance();

    final savedUser = preferences.getString(_userDataKey);

    if (savedUser == null || savedUser.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> userData = jsonDecode(savedUser);

      return User.fromJson(userData);
    } catch (_) {
      await preferences.remove(_userDataKey);
      return null;
    }
  }

  Future<User?> getUserData() async {
    final savedUser = await _getSavedUserData();

    if (savedUser == null) {
      return null;
    }

    if (savedUser.isFirebase) {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        return null;
      }

      try {
        final updatedUser = await _getFirebaseUserData(firebaseUser);

        await saveUserData(updatedUser);

        return updatedUser;
      } catch (_) {
        return savedUser;
      }
    }

    return savedUser;
  }

  Future<User> _getFirebaseUserData(firebase_auth.User firebaseUser) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    final data = snapshot.data() ?? {};

    return User.fromJson({
      ...data,
      'id': 0,
      'firebaseUid': firebaseUser.uid,
      'username': data['username'] ?? firebaseUser.displayName ?? '',
      'email': firebaseUser.email ?? data['email'] ?? '',
      'image': firebaseUser.photoURL ?? data['image'] ?? '',
      'loginType': 'firebase',
    });
  }

  Future<bool> isLoggedIn() async {
    final savedUser = await _getSavedUserData();

    if (savedUser == null) {
      return false;
    }

    if (savedUser.isFirebase) {
      return _firebaseAuth.currentUser != null;
    }

    return savedUser.accessToken.isNotEmpty;
  }

  Future<User> updateUsername({required String username}) async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      throw Exception('No Firebase user is signed in.');
    }

    await firebaseUser.updateDisplayName(username.trim());

    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'username': username.trim(),
    }, SetOptions(merge: true));

    final updatedUser = await _getFirebaseUserData(firebaseUser);

    await saveUserData(updatedUser);

    return updatedUser;
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      throw Exception('No Firebase user is signed in.');
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email.trim(),
      password: currentPassword,
    );

    await firebaseUser.reauthenticateWithCredential(credential);

    await firebaseUser.updatePassword(newPassword);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      throw Exception('No Firebase user is signed in.');
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );

    await firebaseUser.reauthenticateWithCredential(credential);

    await _firestore.collection('users').doc(firebaseUser.uid).delete();

    await firebaseUser.delete();

    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_userDataKey);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_userDataKey);
  }

  Future<void> logout() async {
    await signOut();
  }
}
