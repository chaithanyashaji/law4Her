import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class ChatWithUser extends StatefulWidget {
  final String chatId;
  final String otherParticipantId;
  final String otherParticipantName;

  ChatWithUser({
    required this.chatId,
    required this.otherParticipantId,
    required this.otherParticipantName,
  });

  @override
  _ChatWithUserState createState() => _ChatWithUserState();
}

class _ChatWithUserState extends State<ChatWithUser> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late final encrypt.Encrypter _encrypter;
  late final encrypt.Key _sessionKey;

  Timer? _localTimer;
  final ValueNotifier<int> _chatDuration = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _initializeEncryption();
    _initializeTimer();
    _listenForDeliveredMessages();
    // Ensure messages are marked as read when the chat is opened
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    _messageController.dispose();
    _chatDuration.dispose();
    super.dispose();
  }

  void _initializeEncryption() {
    final keyBytes = Uint8List.fromList(sha256.convert(utf8.encode(widget.chatId)).bytes);
    _sessionKey = encrypt.Key(keyBytes);
    _encrypter = encrypt.Encrypter(encrypt.AES(_sessionKey, mode: encrypt.AESMode.gcm));
  }

  String _encryptMessage(String plainText) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return '${encrypted.base64}:${iv.base64}';
  }

  String _decryptMessage(String encryptedText) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) throw FormatException("Invalid encrypted message format");

      final ciphertext = parts[0];
      final iv = encrypt.IV.fromBase64(parts[1]);
      return _encrypter.decrypt64(ciphertext, iv: iv);
    } catch (e) {
      debugPrint("Decryption error: $e");
      return "[Error decoding message]";
    }
  }

  void _listenForDeliveredMessages() {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');

    // Update status to 'delivered' for messages sent to the current lawyer
    messagesRef
        .where('receiverId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('status', isEqualTo: 'sent')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'status': 'delivered'});
        debugPrint("Message ID ${doc.id} status updated to 'delivered'");
      }
    });
  }



  void _markMessagesAsRead(String messageId) async {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');

    try {
      // Mark the specific message as read
      await messagesRef.doc(messageId).update({'status': 'read'});
      debugPrint("Message ID $messageId marked as read");
    } catch (e) {
      debugPrint("Failed to mark message as read: $e");
    }
  }



  Future<void> _initializeTimer() async {
    final chatSessionRef = FirebaseFirestore.instance.collection('chatSessions').doc(widget.chatId);

    chatSessionRef.snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          final chatEnded = data['chatEnded'] ?? false;
          if (chatEnded) {
            _localTimer?.cancel();
            _chatDuration.value = 0;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Chat has ended.")),
            );
            return;
          }

          final startTime = (data['startTime'] as Timestamp?)?.toDate();
          if (startTime != null) {
            _localTimer?.cancel(); // Avoid duplicate timers
            _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              final duration = DateTime.now().difference(startTime).inSeconds;
              _chatDuration.value = duration;
            });
          }
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      final encryptedMessage = _encryptMessage(messageText);
      final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final chatDoc = await transaction.get(chatDocRef);

        if (!chatDoc.exists) {
          transaction.set(chatDocRef, {
            'participants': [currentUser!.email, widget.otherParticipantId],
            'lastMessage': encryptedMessage,
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(chatDocRef, {
            'lastMessage': encryptedMessage,
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
        }

        final messageRef = chatDocRef.collection('messages').doc();
        transaction.set(messageRef, {
          'text': encryptedMessage,
          'senderId': currentUser!.uid,
          'receiverId': widget.otherParticipantId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'sent',
        });
      });

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  String formatDateHeader(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (DateFormat('yyyyMMdd').format(date) == DateFormat('yyyyMMdd').format(today)) {
      return "Today";
    } else if (DateFormat('yyyyMMdd').format(date) == DateFormat('yyyyMMdd').format(yesterday)) {
      return "Yesterday";
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Widget chatBubble(String message, bool isUserMessage, DateTime? timestamp, String status) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65, // Limit bubble width to 75% of screen width
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUserMessage ? const Color(0xFF416d6d) : const Color(0xFF608e8e), // Existing colors
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUserMessage ? 12 : 0),
            topRight: Radius.circular(isUserMessage ? 0 : 12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timestamp != null
                      ? "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}"
                      : "Sending...",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                if (isUserMessage)
                  Icon(
                    status == 'read'
                        ? Icons.done_all
                        : status == 'delivered'
                        ? Icons.done_all
                        : status == 'sent'
                        ? Icons.check
                        : Icons.access_time,
                    color: status == 'read' ? Color(0xffe7a443) : Colors.white70,
                    size: 16,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF416d6d),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.otherParticipantName),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('chatSessions').doc(widget.chatId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final data = snapshot.data!.data(); // Get the data

                  if (data is Map<String, dynamic>) { // Ensure it's a Map before accessing
                    final chatEnded = data['chatEnded'] ?? false;
                    if (chatEnded) {
                      return const Text(
                        'Chat Ended',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      );
                    }
                  }
                }
                return ValueListenableBuilder<int>(
                  valueListenable: _chatDuration,
                  builder: (context, duration, child) {
                    final minutes = duration ~/ 60;
                    final seconds = duration % 60;
                    return Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const EncryptedIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;
                DateTime? lastDate;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isUserMessage = message['senderId'] == currentUser!.uid;

                    final messageId = messages[index].id; // Get the unique message ID
                    final messageTimestamp = (message['timestamp'] as Timestamp?)?.toDate();

                    // Mark messages sent to the lawyer as read when displayed
                    if (!isUserMessage && message['status'] == 'delivered') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markMessagesAsRead(messageId);
                      });
                    }

                    Widget dateHeader = const SizedBox.shrink();
                    if (messageTimestamp != null &&
                        (lastDate == null ||
                            !isSameDate(messageTimestamp, lastDate!))) {
                      dateHeader = Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            formatDateHeader(messageTimestamp),
                            style: const TextStyle(
                              color: Color(0xFF416d6d),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                      lastDate = messageTimestamp;
                    }

                    String displayText = _decryptMessage(message['text']);

                    return Column(
                      children: [
                        dateHeader,
                        chatBubble(
                          displayText,
                          isUserMessage,
                          messageTimestamp,
                          message['status'] ?? 'sent',
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF608e8e),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _sendMessage,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF416d6d),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
class EncryptedIndicator extends StatelessWidget {
  const EncryptedIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add padding
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF608e8e), // Background color
          borderRadius: BorderRadius.circular(10), // Rounded corners for better aesthetics
        ),
        padding: const EdgeInsets.all(8.0), // Inner padding for content
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              "Messages are end-to-end encrypted.",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}