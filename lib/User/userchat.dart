import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'lawyerchat.dart';

class UserChat extends StatelessWidget {
  const UserChat({Key? key}) : super(key: key);

  // [Previous helper methods remain the same]

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;

    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3),
      appBar: AppBar(
        title: Text(
          "Recent Chats",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF416d6d),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserEmail)
            .snapshots(),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF416d6d)),
              ),
            );
          }
          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Color(0xFF416d6d).withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No recent conversations',
                    style: TextStyle(
                      color: Color(0xFF416d6d),
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            );
          }

          final chatDocs = chatSnapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: chatDocs.length,
            separatorBuilder: (context, index) =>Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: Color(0xff608e8e).withOpacity(0.4), // Green partition line
                thickness: 1, // Line thickness
                height: 1, // Spacing between tiles
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
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
            color: Colors.white, // Tile background is now white
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1), // Subtle shadow
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'profile_$chatId',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFc5d0d3), // Light grey background
                    child: ClipOval(
                      child: otherParticipantProfilePic.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: otherParticipantProfilePic,
                        fit: BoxFit.cover,
                        width: 56,
                        height: 56,
                        placeholder: (context, url) =>
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF416d6d)), // Progress indicator color
                            ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          size: 32,
                          color: Color(0xFF416d6d), // Icon color
                        ),
                      )
                          : Center(
                        child: Text(
                          otherParticipantName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF416d6d), // Initial text in dark green
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
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
                          color: Color(0xFF416d6d), // Name in dark green
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF608e8e), // Subtle green for message
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTimestamp(lastMessageTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF608e8e), // Subtle green for timestamp
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      _getMessageStatusIcon(lastMessageStatus),
                      color: Color(0xFF416d6d), // Dark green for status icon
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fade(duration: 200.ms).slideX(begin: -0.1),
      ),
    );
  }


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

}