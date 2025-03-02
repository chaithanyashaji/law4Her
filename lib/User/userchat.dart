import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:typed_data';
import 'lawyerchat.dart'; // Import your ChatWithLawyer page

class UserChat extends StatelessWidget {
  const UserChat({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _getLawyerDetails(String email) async {
    try {
      final lawyerDoc = await FirebaseFirestore.instance
          .collection('lawyer')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (lawyerDoc.docs.isNotEmpty) {
        final lawyerData = lawyerDoc.docs.first.data();
        return {
          'name': lawyerData['name'] ?? email,
          'profilephotourl': lawyerData['profilephotourl'] ?? '',
        };
      } else {
        return {
          'name': email,
          'profilephotourl': '',
        };
      }
    } catch (e) {
      debugPrint('Error fetching lawyer details: $e');
      return {
        'name': email,
        'profilephotourl': '',
      };
    }
  }

  String _decryptMessage(String encryptedText, String chatId) {
    try {
      final sessionKeyBytes =
      Uint8List.fromList(sha256.convert(utf8.encode(chatId)).bytes);
      final sessionKey = encrypt.Key(sessionKeyBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(sessionKey, mode: encrypt.AESMode.gcm));

      final parts = encryptedText.split(':');
      if (parts.length != 2) throw FormatException("Invalid encrypted message format");

      final ciphertext = parts[0];
      final iv = encrypt.IV.fromBase64(parts[1]);

      return encrypter.decrypt64(ciphertext, iv: iv);
    } catch (e) {
      debugPrint("Decryption error: $e");
      return "[Error decrypting message]";
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    if (now.difference(timestamp).inDays == 0) {
      return "Today, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
    } else if (now.difference(timestamp).inDays == 1) {
      return "Yesterday, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
    } else {
      return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
    }
  }

  IconData _getMessageStatusIcon(String status) {
    switch (status) {
      case 'read':
        return Icons.done_all;
      case 'delivered':
        return Icons.done_all;
      case 'sent':
        return Icons.check;
      default:
        return Icons.access_time; // Default for pending
    }
  }

  Color _getMessageStatusColor(String status) {
    switch (status) {
      case 'read':
        return const Color(0xffe7a443); // Gold for read messages
      case 'delivered':
        return Colors.white70;
      case 'sent':
        return Colors.white70;
      default:
        return Colors.grey; // Grey for pending
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;

    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3),
      appBar: AppBar(
        title: const Text(
          "Recent Chats",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF416d6d),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserEmail)
            .snapshots(),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No recent chats available',
                style: TextStyle(color: Color(0xFF416d6d)),
              ),
            );
          }

          final chatDocs = chatSnapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chat = chatDocs[index];
              final participants = List<String>.from(chat['participants']);
              final otherParticipantEmail =
              participants.firstWhere((email) => email != currentUserEmail);

              return FutureBuilder<Map<String, dynamic>>(
                future: _getLawyerDetails(otherParticipantEmail),
                builder: (context, userSnapshot) {
                  final lawyerDetails = userSnapshot.data ?? {
                    'name': "Loading...",
                    'profilephotourl': "",
                  };
                  final lawyerName = lawyerDetails['name'];
                  final profilePhotoUrl = lawyerDetails['profilephotourl'];

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chat.id)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, messageSnapshot) {
                      if (!messageSnapshot.hasData ||
                          messageSnapshot.data!.docs.isEmpty) {
                        return _buildChatTile(
                          context: context,
                          otherParticipantName: lawyerName,
                          otherParticipantProfilePic: profilePhotoUrl,
                          lastMessage: "No messages yet",
                          lastMessageStatus: "",
                          lastMessageTime: DateTime.now(),
                          chatId: chat.id,
                        );
                      }

                      final lastMessageDoc = messageSnapshot.data!.docs.first;
                      final lastMessageData =
                      lastMessageDoc.data() as Map<String, dynamic>;
                      final encryptedMessage =
                          lastMessageData['text'] ?? '';
                      final lastMessage =
                      _decryptMessage(encryptedMessage, chat.id);
                      final lastMessageTime =
                          (lastMessageData['timestamp'] as Timestamp?)?.toDate() ??
                              DateTime.now();
                      final lastMessageStatus =
                          lastMessageData['status'] ?? 'sent';

                      return _buildChatTile(
                        context: context,
                        otherParticipantName: lawyerName,
                        otherParticipantProfilePic: profilePhotoUrl,
                        lastMessage: lastMessage,
                        lastMessageStatus: lastMessageStatus,
                        lastMessageTime: lastMessageTime,
                        chatId: chat.id,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile({
    required BuildContext context,
    required String otherParticipantName,
    required String otherParticipantProfilePic,
    required String lastMessage,
    required String lastMessageStatus,
    required DateTime lastMessageTime,
    required String chatId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatWithLawyer(
                chatId: chatId,
                lawyerName: otherParticipantName,
                lawyerId: chatId,
                lawyerEmail: FirebaseAuth.instance.currentUser!.email!,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF608e8e),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF416d6d),
                backgroundImage: otherParticipantProfilePic.isNotEmpty
                    ? NetworkImage(otherParticipantProfilePic)
                    : null,
                child: otherParticipantProfilePic.isEmpty
                    ? Text(
                  otherParticipantName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherParticipantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getMessageStatusIcon(lastMessageStatus),
                          color: _getMessageStatusColor(lastMessageStatus),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimestamp(lastMessageTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
