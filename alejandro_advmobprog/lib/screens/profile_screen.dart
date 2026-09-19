import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';

// Enhancement 3:
// Displays the saved authenticated user's information.
class ProfileScreen extends StatelessWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out of your account?',
          ),
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
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    // Enhancement 1:
    // Remove the saved session when the user logs out.
    await UserService().logout();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryBlue = Colors.lightBlue.shade600;
    final Color accentGold = Colors.amber.shade700;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 30.h),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: primaryBlue.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 105.w,
                  height: 105.w,
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentGold,
                  ),
                  child: ClipOval(
                    child: user.image.isNotEmpty
                        ? Image.network(
                            user.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return _avatarPlaceholder(primaryBlue);
                            },
                          )
                        : _avatarPlaceholder(primaryBlue),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: accentGold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _profileInformation(
                  context: context,
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: user.email,
                  iconColor: primaryBlue,
                ),
                _divider(),
                _profileInformation(
                  context: context,
                  icon: Icons.person_outline,
                  title: 'Gender',
                  value: _capitalize(user.gender),
                  iconColor: primaryBlue,
                ),
                _divider(),
                _profileInformation(
                  context: context,
                  icon: Icons.badge_outlined,
                  title: 'User ID',
                  value: '#${user.id}',
                  iconColor: primaryBlue,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: Text(
                'Log Out',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(Color color) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Icon(Icons.person, size: 58.sp, color: color),
    );
  }

  Widget _profileInformation({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 21.sp, color: iconColor),
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

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
