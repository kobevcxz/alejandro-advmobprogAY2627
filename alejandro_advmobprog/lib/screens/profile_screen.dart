import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  late User _user;

  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final savedUser = await _userService.getUserData();

    if (!mounted) return;

    setState(() {
      if (savedUser != null) {
        _user = savedUser;
      }

      _isLoading = false;
    });
  }

  Future<void> _updateUsername() async {
    final controller = TextEditingController(text: _user.username);

    final username = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Username'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New Username',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (username == null || username.isEmpty) {
      return;
    }

    if (username.length < 3) {
      _showMessage(
        'Username must contain at least 3 characters.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final updatedUser = await _userService.updateUsername(username: username);

      if (!mounted) return;

      setState(() {
        _user = updatedUser;
      });

      _showMessage('Username updated successfully.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(_getErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, {
                  'current': currentPasswordController.text,
                  'new': newPasswordController.text,
                  'confirm': confirmPasswordController.text,
                });
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (result == null) {
      return;
    }

    final currentPassword = result['current'] ?? '';

    final newPassword = result['new'] ?? '';

    final confirmPassword = result['confirm'] ?? '';

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please complete all password fields.', isError: true);
      return;
    }

    if (newPassword.length < 8) {
      _showMessage(
        'New password must contain at least 8 characters.',
        isError: true,
      );
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(newPassword) ||
        !RegExp(r'[a-z]').hasMatch(newPassword) ||
        !RegExp(r'[0-9]').hasMatch(newPassword)) {
      _showMessage(
        'Use an uppercase letter, lowercase letter, and number.',
        isError: true,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('The new passwords do not match.', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        email: _user.email,
      );

      if (!mounted) return;

      _showMessage('Password changed successfully.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(_getErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. Enter your password to continue.',
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, passwordController.text);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();

    if (password == null || password.isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _userService.deleteAccount(email: _user.email, password: password);

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (error) {
      if (!mounted) return;

      _showMessage(_getErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _userService.logout();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (error) {
      if (!mounted) return;

      _showMessage(_getErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _getErrorMessage(Object error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
          return 'The current password is incorrect.';
        case 'weak-password':
          return 'Please use a stronger password.';
        case 'requires-recent-login':
          return 'Please log in again before continuing.';
        case 'network-request-failed':
          return 'Please check your internet connection.';
        default:
          return error.message ?? 'The operation could not be completed.';
      }
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = Colors.lightBlue.shade600;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadUser,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 30.h),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 24.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 105.w,
                        height: 105.w,
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                        ),
                        child: ClipOval(
                          child: _user.image.isNotEmpty
                              ? Image.network(
                                  _user.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) {
                                    return _avatar(primaryColor);
                                  },
                                )
                              : _avatar(primaryColor),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        _user.fullName.isEmpty
                            ? _user.username
                            : _user.fullName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        '@${_user.username}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      _information(
                        Icons.email_outlined,
                        'Email',
                        _user.email,
                        primaryColor,
                      ),
                      _divider(),
                      if (_user.isFirebase) ...[
                        _information(
                          Icons.cake_outlined,
                          'Age',
                          _user.age == 0
                              ? 'Not available'
                              : _user.age.toString(),
                          primaryColor,
                        ),
                        _divider(),
                        _information(
                          Icons.phone_outlined,
                          'Contact Number',
                          _user.contactNo,
                          primaryColor,
                        ),
                        _divider(),
                      ] else ...[
                        _information(
                          Icons.person_outline,
                          'Gender',
                          _capitalize(_user.gender),
                          primaryColor,
                        ),
                        _divider(),
                        _information(
                          Icons.badge_outlined,
                          'User ID',
                          '#${_user.id}',
                          primaryColor,
                        ),
                        _divider(),
                      ],
                      _information(
                        Icons.login_outlined,
                        'Login Type',
                        _user.isFirebase ? 'Firebase' : 'DummyJSON',
                        primaryColor,
                      ),
                    ],
                  ),
                ),
                if (_user.isFirebase) ...[
                  SizedBox(height: 18.h),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.edit_outlined,
                            color: primaryColor,
                          ),
                          title: const Text('Update Username'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _isProcessing ? null : _updateUsername,
                        ),
                        _divider(),
                        ListTile(
                          leading: Icon(
                            Icons.lock_reset_outlined,
                            color: primaryColor,
                          ),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _isProcessing ? null : _changePassword,
                        ),
                        _divider(),
                        ListTile(
                          leading: Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red.shade700,
                          ),
                          title: Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                          onTap: _isProcessing ? null : _deleteAccount,
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 22.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _avatar(Color color) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Icon(Icons.person, size: 58.sp, color: color),
    );
  }

  Widget _information(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 21.sp, color: color),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 68.w,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return 'Not available';
    }

    return '${value[0].toUpperCase()}'
        '${value.substring(1)}';
  }
}
