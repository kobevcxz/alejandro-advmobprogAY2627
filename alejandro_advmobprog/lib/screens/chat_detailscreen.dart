import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserEmail;

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserEmail,
  });

  @override
  State<ChatDetailScreen> createState() {
    return _ChatDetailScreenState();
  }
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream;

  bool _isSending = false;
  bool _isMarkingSeen = false;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();

    _messagesStream = _chatService.getMessagesStream(
      otherUserId: widget.otherUserId,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsSeen();
    });
  }

  Future<void> _markMessagesAsSeen() async {
    if (_isMarkingSeen) {
      return;
    }

    _isMarkingSeen = true;

    try {
      await _chatService.markMessagesAsSeen(otherUserId: widget.otherUserId);
    } finally {
      _isMarkingSeen = false;
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      await Future.wait([
        _chatService.sendMessage(
          receiverId: widget.otherUserId,
          message: message,
        ),
        Future<void>.delayed(const Duration(milliseconds: 500)),
      ]);

      if (!mounted) {
        return;
      }

      _messageFocusNode.requestFocus();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _messageController.text = message;
      _messageController.selection = TextSelection.collapsed(
        offset: message.length,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _formatTime(BuildContext context, Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(timestamp.toDate()));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUser?.uid ?? '';
    final primaryColor = Colors.lightBlue.shade600;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryColor.withValues(alpha: 0.15),
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.otherUserEmail,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.r),
                        child: Text(
                          'Unable to load messages.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  final documents = snapshot.data?.docs ?? [];

                  if (documents.isEmpty) {
                    _previousMessageCount = 0;

                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 58.sp,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              'Send a message to start the conversation.',
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

                  final hasUnseenMessages = documents.any((document) {
                    final data = document.data();

                    return data['receiverId'] == currentUserId &&
                        data['senderId'] == widget.otherUserId &&
                        data['status'] != 'seen';
                  });

                  if (hasUnseenMessages) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markMessagesAsSeen();
                    });
                  }

                  if (documents.length != _previousMessageCount) {
                    _previousMessageCount = documents.length;
                    _scrollToBottom();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 14.h,
                    ),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final document = documents[index];
                      final data = document.data();

                      final senderId = data['senderId']?.toString() ?? '';
                      final message = data['message']?.toString() ?? '';
                      final status = data['status']?.toString() ?? 'delivered';

                      final timestamp = data['timestamp'] is Timestamp
                          ? data['timestamp'] as Timestamp
                          : null;

                      final isCurrentUser = senderId == currentUserId;
                      final isPending = document.metadata.hasPendingWrites;

                      return _AnimatedMessageEntry(
                        key: ValueKey(document.id),
                        isCurrentUser: isCurrentUser,
                        child: Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                            ),
                            margin: EdgeInsets.only(bottom: 9.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? primaryColor
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(17.r),
                                topRight: Radius.circular(17.r),
                                bottomLeft: Radius.circular(
                                  isCurrentUser ? 17.r : 4.r,
                                ),
                                bottomRight: Radius.circular(
                                  isCurrentUser ? 4.r : 17.r,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(context, timestamp),
                                      style: TextStyle(
                                        color: isCurrentUser
                                            ? Colors.white70
                                            : Colors.grey.shade600,
                                        fontSize: 9.sp,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      SizedBox(width: 5.w),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        child: isPending
                                            ? Text(
                                                'Sending...',
                                                key: const ValueKey('sending'),
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 9.sp,
                                                ),
                                              )
                                            : Icon(
                                                status == 'seen'
                                                    ? Icons.done_all
                                                    : Icons.done,
                                                key: ValueKey(status),
                                                size: 14.sp,
                                                color: status == 'seen'
                                                    ? Colors.lightBlue.shade100
                                                    : Colors.white70,
                                              ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 11.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 46.w,
                    height: 46.w,
                    child: IconButton.filled(
                      onPressed: _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _isSending
                            ? SizedBox(
                                key: const ValueKey('sending'),
                                width: 19.w,
                                height: 19.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                key: ValueKey('send'),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMessageEntry extends StatefulWidget {
  final bool isCurrentUser;
  final Widget child;

  const _AnimatedMessageEntry({
    super.key,
    required this.isCurrentUser,
    required this.child,
  });

  @override
  State<_AnimatedMessageEntry> createState() {
    return _AnimatedMessageEntryState();
  }
}

class _AnimatedMessageEntryState extends State<_AnimatedMessageEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    final curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(curvedAnimation);

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isCurrentUser ? 0.08 : -0.08, 0),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
