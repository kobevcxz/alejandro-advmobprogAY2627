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

  Future<void> createChatRoom({required String otherUserId}) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final participantIds = [user.uid, otherUserId]..sort();

    final chatRoomId = _createChatRoomId(user.uid, otherUserId);

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': participantIds,
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

    batch.set(chatRoomReference, {
      'participants': participantIds,
      'lastMessage': trimmedMessage,
      'lastMessageAt': newMessage.timestamp,
      'lastSenderId': user.uid,
    }, SetOptions(merge: true));

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

    final snapshot = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: user.uid)
        .get();

    final batch = _firestore.batch();
    bool hasUpdates = false;

    for (final document in snapshot.docs) {
      final data = document.data();
      final senderId = data['senderId']?.toString() ?? '';
      final status = data['status']?.toString() ?? '';

      if (senderId == otherUserId && status != 'seen') {
        batch.update(document.reference, {'status': 'seen'});

        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  String _createChatRoomId(String firstUserId, String secondUserId) {
    final userIds = [firstUserId, secondUserId]..sort();

    return userIds.join('_');
  }
}
