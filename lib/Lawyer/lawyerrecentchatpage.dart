import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'chat.dart'; // Import ChatWithUser page

class LawyerRecentChatsPage extends StatelessWidget {
  // Color Palette
  final Color primaryColor = const Color(0xFF416d6d);
  final Color secondaryColor = const Color(0xFF608e8e);
  final Color backgroundColor = const Color(0xFFc5d0d3);

  Future<Map<String, String>> _getUserDetails(String email) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        final data = userDoc.docs.first.data();
        return {
          'name': data['name'] ?? email, // Fallback to email for name
          'userId': userDoc.docs.first.id, // Fetch the userId (document ID)
        };
      } else {
        return {
          'name': email,
          'userId': '', // No userId found
        };
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      return {
        'name': email,
        'userId': '', // No userId on error
      };
    }
  }

  String _decryptMessage(String encryptedText, String chatId) {
    try {
      final sessionKeyBytes = Uint8List.fromList(sha256.convert(utf8.encode(chatId)).bytes);
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

  Future<void> _acceptRequest(String requestId, Map<String, dynamic> requestData) async {
    try {
      await FirebaseFirestore.instance
          .collection('chatRequests')
          .doc(requestId)
          .update({'status': 'accepted'});

      debugPrint('Request accepted successfully');
    } catch (e) {
      debugPrint('Error accepting request: $e');
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chatRequests')
          .doc(requestId)
          .update({'status': 'rejected'});

      debugPrint('Request rejected successfully');
    } catch (e) {
      debugPrint('Error rejecting request: $e');
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
        return Color(0xffe7a443);
      case 'delivered':
        return Colors.white70;
      case 'sent':
        return Colors.white70;
      default:
        return Colors.grey;
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

  Widget _buildChatTile({
    required BuildContext context, // Added context as a parameter
    required String otherParticipantName,
    required String otherParticipantId,
    required String lastMessage,
    required String lastMessageStatus,
    required DateTime lastMessageTime,
    required String chatId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: GestureDetector(
        onTap: () {
          // Navigate to ChatWithUser
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatWithUser(
                chatId: chatId,
                otherParticipantId: otherParticipantId,
                otherParticipantName: otherParticipantName,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor,
                child: Center(
                  child: Text(
                    otherParticipantName.isNotEmpty
                        ? otherParticipantName[0].toUpperCase()
                        : "?",
                    style: const TextStyle(color: Colors.white),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                            ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Recent Chats & Requests",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRequests')
                  .where('lawyerEmail', isEqualTo: currentUserEmail)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No pending requests',
                      style: TextStyle(color: primaryColor),
                    ),
                  );
                }

                final requestDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: requestDocs.length,
                  itemBuilder: (context, index) {
                    final request = requestDocs[index];
                    final requestData = request.data() as Map<String, dynamic>;
                    final requesterName = requestData['requesterName'] ?? "Unknown";

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: secondaryColor,
                              child: Center(
                                child: Text(
                                  requesterName.isNotEmpty
                                      ? requesterName[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    requesterName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Wants to start a chat",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _acceptRequest(request.id, requestData),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Accept"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _rejectRequest(request.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Reject"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.grey),
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUserEmail)
                  .snapshots(),
              builder: (context, chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No recent chats available',
                      style: TextStyle(color: primaryColor),
                    ),
                  );
                }

                final chatDocs = chatSnapshot.data!.docs;

                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chat = chatDocs[index];
                    final participants = List<String>.from(chat['participants']);
                    final otherParticipantEmail = participants.firstWhere(
                            (email) => email != currentUserEmail);

                    return FutureBuilder<Map<String, String>>(
                      future: _getUserDetails(otherParticipantEmail),
                      builder: (context, userSnapshot) {
                        final otherParticipantName =
                            userSnapshot.data?['name'] ?? "Loading...";
                        final otherParticipantId = userSnapshot.data?['userId'] ?? "";

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
                                otherParticipantName: otherParticipantName,
                                otherParticipantId: otherParticipantId,
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
                              context: context, // Pass context here
                              otherParticipantName: otherParticipantName,
                              otherParticipantId: otherParticipantId,
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
          ),
        ],
      ),
    );
  }
}