import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  late final Stream<List<Map<String, dynamic>>> _usersStream;

  late final Stream<Map<String, Map<String, dynamic>>> _chatSummariesStream;

  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _usersStream = _chatService.getUsersStream();
    _chatSummariesStream = _chatService.getChatSummariesStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getUserName(Map<String, dynamic> user) {
    final firstName = user['firstName']?.toString().trim() ?? '';
    final lastName = user['lastName']?.toString().trim() ?? '';
    final username = user['username']?.toString().trim() ?? '';

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    if (username.isNotEmpty) {
      return username;
    }

    return 'Unknown User';
  }

  bool _matchesSearch(Map<String, dynamic> user) {
    if (_searchText.isEmpty) {
      return true;
    }

    final name = _getUserName(user).toLowerCase();
    final username = user['username']?.toString().toLowerCase() ?? '';
    final email = user['email']?.toString().toLowerCase() ?? '';
    final search = _searchText.toLowerCase();

    return name.contains(search) ||
        username.contains(search) ||
        email.contains(search);
  }

  String _formatLastMessageTime(BuildContext context, int milliseconds) {
    if (milliseconds <= 0) {
      return '';
    }

    final messageDate = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final messageDay = DateTime(
      messageDate.year,
      messageDate.month,
      messageDate.day,
    );

    final difference = today.difference(messageDay).inDays;

    if (difference == 0) {
      return MaterialLocalizations.of(
        context,
      ).formatTimeOfDay(TimeOfDay.fromDateTime(messageDate));
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    if (messageDate.year == now.year) {
      return '${messageDate.month}/${messageDate.day}';
    }

    return '${messageDate.month}/${messageDate.day}/${messageDate.year}';
  }

  Future<void> _openChat({
    required String userId,
    required String userName,
    required String email,
  }) async {
    try {
      await _chatService.createChatRoom(otherUserId: userId);

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return ChatDetailScreen(
              otherUserId: userId,
              otherUserName: userName,
              otherUserEmail: email,
            );
          },
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTrailing({
    required int unreadCount,
    required int lastMessageAt,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (lastMessageAt > 0)
          Text(
            _formatLastMessageTime(context, lastMessageAt),
            style: TextStyle(
              color: unreadCount > 0 ? primaryColor : Colors.grey.shade500,
              fontSize: 10.sp,
              fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        if (lastMessageAt > 0) SizedBox(height: 7.h),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          child: unreadCount > 0
              ? Container(
                  key: const ValueKey('unread'),
                  constraints: BoxConstraints(minWidth: 25.w, minHeight: 25.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: unreadCount > 9 ? 7.w : 5.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Container(
                  key: const ValueKey('chat'),
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 17.sp,
                    color: primaryColor,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.lightBlue.shade600;
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 10.h),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchText = value.trim();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _searchText = '';
                        });
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: primaryColor.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<Map<String, Map<String, dynamic>>>(
            stream: _chatSummariesStream,
            builder: (context, summarySnapshot) {
              final summaries =
                  summarySnapshot.data ?? <String, Map<String, dynamic>>{};

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _usersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 54.sp,
                              color: Colors.red.shade400,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Unable to load users',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              'Please check your connection and Firestore rules.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  final users = (snapshot.data ?? [])
                      .where(_matchesSearch)
                      .toList();

                  users.sort((firstUser, secondUser) {
                    final firstUserId = firstUser['uid']?.toString() ?? '';

                    final secondUserId = secondUser['uid']?.toString() ?? '';

                    final firstSummary = summaries[firstUserId];

                    final secondSummary = summaries[secondUserId];

                    final firstMessageAt =
                        firstSummary?['lastMessageAt'] as int? ?? 0;

                    final secondMessageAt =
                        secondSummary?['lastMessageAt'] as int? ?? 0;

                    if (firstMessageAt != secondMessageAt) {
                      return secondMessageAt.compareTo(firstMessageAt);
                    }

                    return _getUserName(
                      firstUser,
                    ).compareTo(_getUserName(secondUser));
                  });

                  if (users.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _searchText.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.people_outline,
                              size: 58.sp,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              _searchText.isNotEmpty
                                  ? 'No matching users'
                                  : 'No other users found',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              _searchText.isNotEmpty
                                  ? 'Try searching with another name or email.'
                                  : 'Create another Firebase account to start chatting.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                    itemCount: users.length,
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 9.h);
                    },
                    itemBuilder: (context, index) {
                      final user = users[index];

                      final userId = user['uid']?.toString() ?? '';

                      final userName = _getUserName(user);

                      final username =
                          user['username']?.toString().trim() ?? '';

                      final email = user['email']?.toString().trim() ?? '';

                      final summary = summaries[userId];

                      final unreadCount = summary?['unreadCount'] as int? ?? 0;

                      final lastMessage =
                          summary?['lastMessage']?.toString() ?? '';

                      final lastMessageAt =
                          summary?['lastMessageAt'] as int? ?? 0;

                      final accountDetails = username.isNotEmpty
                          ? '@$username • $email'
                          : email;

                      final subtitle = lastMessage.isNotEmpty
                          ? lastMessage
                          : accountDetails;

                      return Material(
                        color: unreadCount > 0
                            ? primaryColor.withValues(alpha: 0.08)
                            : theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(15.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15.r),
                          onTap: userId.isEmpty
                              ? null
                              : () {
                                  _openChat(
                                    userId: userId,
                                    userName: userName,
                                    email: email,
                                  );
                                },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 13.h,
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 50.w,
                                      height: 50.w,
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(
                                          alpha: unreadCount > 0 ? 0.2 : 0.14,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        userName.isNotEmpty
                                            ? userName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 19.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: -1.w,
                                        top: -1.h,
                                        child: Container(
                                          width: 12.w,
                                          height: 12.w,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: theme.colorScheme.surface,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(width: 13.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: unreadCount > 0
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: unreadCount > 0
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: unreadCount > 0
                                              ? theme.colorScheme.onSurface
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                _buildTrailing(
                                  unreadCount: unreadCount,
                                  lastMessageAt: lastMessageAt,
                                  primaryColor: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
