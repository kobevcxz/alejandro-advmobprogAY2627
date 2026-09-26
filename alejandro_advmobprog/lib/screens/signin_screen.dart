import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _loginType = 'dummyjson';

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _loginType == 'firebase'
          ? await _userService.signIn(
              email: _usernameController.text.trim(),
              password: _passwordController.text,
            )
          : await _userService.loginUser(
              _usernameController.text.trim(),
              _passwordController.text,
            );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home', arguments: user);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(error)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'Incorrect email address or password.';
        case 'user-disabled':
          return 'This Firebase account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Please check your internet connection.';
        default:
          return error.message ?? 'Firebase login failed.';
      }
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryBlue = Colors.lightBlue.shade600;
    final Color accentGold = Colors.amber.shade700;
    final bool isFirebase = _loginType == 'firebase';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/nudexchange_logo.png',
                    width: 150.w,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Sign in to continue shopping',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'dummyjson',
                        label: Text('DummyJSON'),
                        icon: Icon(Icons.api),
                      ),
                      ButtonSegment<String>(
                        value: 'firebase',
                        label: Text('Firebase'),
                        icon: Icon(Icons.local_fire_department),
                      ),
                    ],
                    selected: {_loginType},
                    onSelectionChanged: _isLoading
                        ? null
                        : (selection) {
                            setState(() {
                              _loginType = selection.first;
                              _usernameController.clear();
                              _passwordController.clear();
                              _formKey.currentState?.reset();
                            });
                          },
                  ),
                  SizedBox(height: 24.h),
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: isFirebase
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: isFirebase ? 'Email Address' : 'Username',
                      hintText: isFirebase
                          ? 'Enter your email address'
                          : 'Enter your username',
                      prefixIcon: Icon(
                        isFirebase
                            ? Icons.email_outlined
                            : Icons.person_outline,
                        color: primaryBlue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isFirebase
                            ? 'Please enter your email address'
                            : 'Please enter your username';
                      }

                      if (isFirebase &&
                          !RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }

                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline, color: primaryBlue),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }

                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryBlue.withValues(
                          alpha: 0.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 22.w,
                              height: 22.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: accentGold,
                              ),
                            )
                          : Text(
                              isFirebase
                                  ? 'Sign In with Firebase'
                                  : 'Sign In with DummyJSON',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (isFirebase) ...[
                    SizedBox(height: 14.h),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushNamed(context, '/signup');
                            },
                      child: const Text('No account yet? Create Account'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
