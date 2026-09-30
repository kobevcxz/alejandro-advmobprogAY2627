import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final currentUserId = _firebaseAuth.currentUser?.uid;

    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((document) => document.id != currentUserId)
          .map((document) {
            final data = document.data();

            return {...data, 'uid': document.id};
          })
          .toList();
    });
  }

  Stream<Map<String, Map<String, dynamic>>> getChatSummariesStream() {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      return Stream.value(<String, Map<String, dynamic>>{});
    }

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
          final summaries = <String, Map<String, dynamic>>{};

          for (final document in snapshot.docs) {
            final data = document.data();
            final participantsData = data['participants'];
            final countsData = data['unreadCounts'];
            final lastMessageAtData = data['lastMessageAt'];

            if (participantsData is! List) {
              continue;
            }

            final participants = participantsData
                .map((participant) => participant.toString())
                .toList();

            String otherUserId = '';

            for (final participantId in participants) {
              if (participantId != user.uid) {
                otherUserId = participantId;
                break;
              }
            }

            if (otherUserId.isEmpty) {
              continue;
            }

            int unreadCount = 0;

            if (countsData is Map) {
              final currentUserCount = countsData[user.uid];

              if (currentUserCount is num) {
                unreadCount = currentUserCount.toInt();
              }
            }

            int lastMessageAt = 0;

            if (lastMessageAtData is Timestamp) {
              lastMessageAt = lastMessageAtData.millisecondsSinceEpoch;
            }

            summaries[otherUserId] = {
              'unreadCount': unreadCount,
              'lastMessage': data['lastMessage']?.toString() ?? '',
              'lastMessageAt': lastMessageAt,
              'lastSenderId': data['lastSenderId']?.toString() ?? '',
            };
          }

          return summaries;
        });
  }

  Future<void> createChatRoom({required String otherUserId}) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final participantIds = [user.uid, otherUserId]..sort();
    final chatRoomId = _createChatRoomId(user.uid, otherUserId);

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': participantIds,
      'unreadCounts': {
        user.uid: FieldValue.increment(0),
        otherUserId: FieldValue.increment(0),
      },
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final trimmedMessage = message.trim();

    if (trimmedMessage.isEmpty) {
      return;
    }

    final participantIds = [user.uid, receiverId]..sort();
    final chatRoomId = _createChatRoomId(user.uid, receiverId);

    final chatRoomReference = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId);

    final messageReference = chatRoomReference.collection('messages').doc();

    final newMessage = MessageModel(
      id: messageReference.id,
      senderId: user.uid,
      senderEmail: user.email ?? '',
      receiverId: receiverId,
      message: trimmedMessage,
      timestamp: Timestamp.now(),
      status: 'delivered',
    );

    final batch = _firestore.batch();

    batch.update(chatRoomReference, {
      'participants': participantIds,
      'lastMessage': trimmedMessage,
      'lastMessageAt': newMessage.timestamp,
      'lastSenderId': user.uid,
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    batch.set(messageReference, newMessage.toMap());

    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream({
    required String otherUserId,
  }) {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final chatRoomId = _createChatRoomId(user.uid, otherUserId);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots(includeMetadataChanges: true);
  }

  Future<void> markMessagesAsSeen({required String otherUserId}) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      return;
    }

    final chatRoomId = _createChatRoomId(user.uid, otherUserId);

    final chatRoomReference = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId);

    final snapshot = await chatRoomReference
        .collection('messages')
        .where('receiverId', isEqualTo: user.uid)
        .get();

    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      final data = document.data();
      final senderId = data['senderId']?.toString() ?? '';
      final status = data['status']?.toString() ?? '';

      if (senderId == otherUserId && status != 'seen') {
        batch.update(document.reference, {'status': 'seen'});
      }
    }

    batch.update(chatRoomReference, {'unreadCounts.${user.uid}': 0});

    await batch.commit();
  }

  String _createChatRoomId(String firstUserId, String secondUserId) {
    final userIds = [firstUserId, secondUserId]..sort();

    return userIds.join('_');
  }
}
