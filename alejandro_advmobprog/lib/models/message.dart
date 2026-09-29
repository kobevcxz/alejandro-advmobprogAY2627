import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final String status;

  const MessageModel({
    this.id = '',
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.status = 'sent',
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return MessageModel(
      id: id,
      senderId: map['senderId']?.toString() ?? '',
      senderEmail: map['senderEmail']?.toString() ?? '',
      receiverId: map['receiverId']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? map['timestamp'] as Timestamp
          : Timestamp.now(),
      status: map['status']?.toString() ?? 'sent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'status': status,
    };
  }
}
