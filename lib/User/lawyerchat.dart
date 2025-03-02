import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatWithLawyer extends StatefulWidget {
  final String chatId;
  final String lawyerName;
  final String lawyerId;
  final String lawyerEmail;

  ChatWithLawyer({
    required this.chatId,
    required this.lawyerName,
    required this.lawyerId,
    required this.lawyerEmail,
  });

  @override
  _ChatWithLawyerState createState() => _ChatWithLawyerState();
}

class _ChatWithLawyerState extends State<ChatWithLawyer> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late final String chatId;
  late final encrypt.Encrypter _encrypter;
  late final encrypt.Key _sessionKey;


  Timer? _deductionTimer;
  Timer? _durationTimer;
  Timer? _timeoutTimer;
  final ValueNotifier<int> _chatDuration = ValueNotifier<int>(0);
  bool _isDeducting = false;
  bool _chatEnded = false;
  bool _waitingForLawyerMessage = false;

  @override
  void initState() {
    super.initState();
    chatId = widget.chatId.isNotEmpty ? widget.chatId : _getChatId();
    _initializeEncryption();
    _listenForDeliveredMessages();
    _checkChatStatusAndInitialize();
  }

  Future<void> _checkChatStatusAndInitialize() async {
    final chatSessionRef = FirebaseFirestore.instance.collection('chatSessions').doc(chatId);

    final snapshot = await chatSessionRef.get();
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data?['chatEnded'] == true) {
        setState(() {
          _chatEnded = true;
        });
      } else {
        _initializeChat();
        _startDeductionTimer();
        _startDurationTimer();
        _startTimeoutLogic();
      }
    } else {
      // If no session exists, create a new session
      await chatSessionRef.set({
        'startTime': FieldValue.serverTimestamp(),
        'chatEnded': false,
        'status': 'active',
      });
      _initializeChat();
      _startDeductionTimer();
      _startDurationTimer();
      _startTimeoutLogic();
    }
  }



  @override
  void dispose() {
    _deductionTimer?.cancel();
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();
    _messageController.dispose();
    _chatDuration.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final snapshot = await chatRef.get();
    if (!snapshot.exists) {
      await chatRef.set({
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lawyerId': widget.lawyerId,
        'lawyerName': widget.lawyerName,
        'participants': [
          currentUser!.email,
          widget.lawyerEmail,
        ],
        'status': 'pending', // Initial status
      });
    }
  }

  String _getChatId() {
    final ids = [currentUser!.uid, widget.lawyerId];
    ids.sort();
    return ids.join('_');
  }

  void _startDeductionTimer() {
    if (_chatEnded) return;

    _deductionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isDeducting || _chatEnded) {
        debugPrint("Deduction skipped: Either already deducting or chat has ended.");
        return;
      }
      _deductFromWallet();
    });
  }

  void _startDurationTimer() async {
    if (_chatEnded) return;

    final chatSessionRef = FirebaseFirestore.instance.collection('chatSessions').doc(chatId);
    final snapshot = await chatSessionRef.get();

    if (snapshot.exists) {
      final startTime = (snapshot.data()?['startTime'] as Timestamp?)?.toDate();
      if (startTime != null) {
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_chatEnded) {
            timer.cancel();
            return;
          }
          final duration = DateTime.now().difference(startTime).inSeconds;
          _chatDuration.value = duration;
        });
      }
    }
  }

  void _startTimeoutLogic() {
    if (_chatEnded) return;

    _timeoutTimer = Timer(const Duration(minutes: 10), () async {
      if (_chatEnded) return;

      final chatSessionRef = FirebaseFirestore.instance.collection('chatSessions').doc(chatId);
      final snapshot = await chatSessionRef.get();

      if (snapshot.exists && snapshot.data()?['status'] == 'pending') {
        await chatSessionRef.update({'status': 'closed'});
        await _refundUser();
        _endChat();
      }
    });
  }



  Future<void> _restartChat() async {
    if (!_chatEnded) return;

    final chatSessionRef = FirebaseFirestore.instance.collection('chatSessions').doc(chatId);

    try {
      await chatSessionRef.set({
        'startTime': FieldValue.serverTimestamp(),
        'chatEnded': false,
        'status': 'active',
      });

      setState(() {
        _chatEnded = false;
        _chatDuration.value = 0;
        _waitingForLawyerMessage = true;
      });

      // Wait for the lawyer's first message before starting timers
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat restarted. Waiting for the lawyer to send a message.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to restart chat: $e")),
      );
    }
  }




  Future<void> _endChat() async {
    if (chatId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat ID is missing. Unable to end chat.")),
      );
      return;
    }

    final chatSessionRef = FirebaseFirestore.instance.collection('chatSessions').doc(chatId);
    try {
      await chatSessionRef.update({
        'chatEnded': true,
      });

      // Stop all timers immediately
      _deductionTimer?.cancel();
      _durationTimer?.cancel();
      _timeoutTimer?.cancel();

      // Reset chat-related states
      setState(() {
        _chatEnded = true;
        _chatDuration.value = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat has ended.")),
      );

      // Display review form
      _showReviewForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to end chat: $e")),
      );
    }
  }



  Future<void> _refundUser() async {
    final userRef = FirebaseFirestore.instance.collection('user').doc(currentUser!.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        final walletBalance = userDoc['wallet'] ?? 0;
        transaction.update(userRef, {'wallet': walletBalance + 10});
        debugPrint("Refunded 10 to user's wallet. New balance: ${walletBalance + 10}");
      });
    } catch (e) {
      debugPrint("Error during refund: $e");
    }
  }





  String _formatChatDuration(int durationInSeconds) {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _deductFromWallet() async {
    _isDeducting = true;
    try {
      final userRef = FirebaseFirestore.instance.collection('user').doc(currentUser!.uid);
      final lawyerRef = FirebaseFirestore.instance.collection('lawyer').doc(widget.lawyerId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Read the user's wallet balance
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception("User document does not exist.");
        }

        final walletBalance = userDoc['wallet'] ?? 0;

        // Read the lawyer's service details
        final lawyerDoc = await transaction.get(lawyerRef);
        if (!lawyerDoc.exists) {
          throw Exception("Lawyer document does not exist.");
        }

        final serviceType = lawyerDoc['serviceType'] ?? 'Paid Service';
        // Default rate if not specified

        if (serviceType == 'Free Service') {
          debugPrint("No deduction for free service.");
          return; // Skip deduction for free services
        }

        // Access the rate only if the service is Paid
        final rate = lawyerDoc['rate'] ?? 10; // Default rate if not specified

        // Check wallet balance
        if (walletBalance < rate) {
          debugPrint("Insufficient wallet balance. Ending chat.");
          await _endChat(); // End the chat if balance is insufficient
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Insufficient wallet balance. Chat ended.")),
          );
          return;
        }

        // Read the lawyer's earnings
        final currentEarnings = lawyerDoc['earnings'] ?? 0;

        // Deduct the rate from the user's wallet
        transaction.update(userRef, {'wallet': walletBalance - rate});
        debugPrint("$rate deducted from wallet. Remaining balance: ${walletBalance - rate}");

        // Add the rate to the lawyer's earnings
        transaction.update(lawyerRef, {'earnings': currentEarnings + rate});
        debugPrint("$rate added to lawyer's earnings. New earnings: ${currentEarnings + rate}");
      });

      debugPrint("Transaction completed successfully.");
    } catch (e) {
      debugPrint("Error during wallet deduction: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      _isDeducting = false;
    }
  }



  // Flag to track state

  void _listenForDeliveredMessages() {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    // Mark messages sent by the lawyer as delivered
    messagesRef
        .where('receiverId', isEqualTo: currentUser!.uid)
        .where('status', isEqualTo: 'sent')
        .snapshots()
        .listen((snapshot) async {
      for (var doc in snapshot.docs) {
        doc.reference.update({'status': 'delivered'});

        if (_waitingForLawyerMessage) {
          final chatSessionRef = FirebaseFirestore.instance.collection('chatSessions').doc(chatId);
          await chatSessionRef.update({'startTime': FieldValue.serverTimestamp()});
          // Start timers when the lawyer sends the first message
          _waitingForLawyerMessage = false;
          _chatDuration.value = 0;
          _startDeductionTimer();
          _startDurationTimer();
          _startTimeoutLogic();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lawyer has sent a message. Timers started.")),
          );
        }
      }
    });

    // Mark messages sent by the user to the lawyer as delivered
    messagesRef
        .where('receiverId', isEqualTo: widget.lawyerId)
        .where('status', isEqualTo: 'sent')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'status': 'delivered'});
      }
    });
  }


  void _initializeEncryption() {
    // Ensure the session key is derived consistently
    final keyBytes = Uint8List.fromList(sha256.convert(utf8.encode(chatId)).bytes.sublist(0, 32));
    _sessionKey = encrypt.Key(keyBytes);
    _encrypter = encrypt.Encrypter(encrypt.AES(_sessionKey, mode: encrypt.AESMode.gcm));
  }

  String _encryptMessage(String plainText) {
    final iv = encrypt.IV.fromSecureRandom(16); // Generate a new IV
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return '${encrypted.base64}:${iv.base64}'; // Store both the encrypted text and IV
  }

  String _decryptMessage(String encryptedText) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) throw FormatException("Invalid encrypted message format");
      final ciphertext = parts[0];
      final iv = encrypt.IV.fromBase64(parts[1]);
      return _encrypter.decrypt64(ciphertext, iv: iv); // Decrypt using the same IV
    } catch (e) {
      return "[Error decoding message]"; // Handle decryption errors gracefully
    }
  }


  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    try {
      await messageRef.set({
        'text': _encryptMessage(messageText),
        'senderId': currentUser!.uid,
        'receiverId': widget.lawyerId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
      });
      _messageController.clear();
    } catch (e) {
      await messageRef.set({
        'text': _encryptMessage(messageText),
        'senderId': currentUser!.uid,
        'receiverId': widget.lawyerId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Message failed to send. Retrying...")),
      );

      // Retry mechanism
      Future.delayed(Duration(seconds: 5), () async {
        try {
          await messageRef.update({'status': 'sent'});
        } catch (e) {
          // Optionally, notify the user if retries keep failing.
        }
      });
    }
  }



  void _markMessagesAsRead(String messageId) async {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    try {
      // Mark the specific message as read when the user views it
      await messagesRef.doc(messageId).update({'status': 'read'});
      debugPrint("Message ID $messageId marked as read");
    } catch (e) {
      debugPrint("Failed to mark message as read: $e");
    }
  }




  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return "Today";
    } else if (messageDate == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }


  void _showReviewForm() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _commentController = TextEditingController();
        double _rating = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Rate Lawyer"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Please rate the lawyer and provide a comment."),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        child: Icon(
                          _rating > index ? Icons.star : Icons.star_border,
                          color: _rating > index ? const Color(0xFF416d6d) : const Color(0xFF608e8e),
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Write a comment (optional)...",
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _submitReview(_rating, _commentController.text.trim());
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF416d6d),
                  ),
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview(double rating, String comment) async {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rating is required.")),
      );
      return;
    }

    try {
      final lawyerRef = FirebaseFirestore.instance.collection('lawyer').doc(widget.lawyerId);

      // Add the new review to the 'reviews' subcollection
      await lawyerRef.collection('reviews').add({
        'rating': rating,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser!.uid,
      });

      // Calculate the new average dynamically
      final reviewsSnapshot = await lawyerRef.collection('reviews').get();
      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0.0;
        for (var doc in reviewsSnapshot.docs) {
          final reviewData = doc.data();
          totalRating += reviewData['rating'] ?? 0.0;
        }

        final newAvgRating = totalRating / reviewsSnapshot.docs.length;
        final totalReviews = reviewsSnapshot.docs.length;

        // Update the lawyer document with the new average and total reviews
        await lawyerRef.update({
          'avgRating': newAvgRating,
          'noOfReviews': totalReviews,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit review: $e")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF416d6d),
        title: Row(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lawyer')
                  .doc(widget.lawyerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Loading state: show a placeholder avatar with a progress indicator
                  return const CircleAvatar(
                    backgroundColor: Color(0xFF608e8e),
                    child: CircularProgressIndicator(color: Colors.white),
                    radius: 18,
                  );
                }
                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  // Error or no data: show a default person icon
                  return const CircleAvatar(
                    backgroundColor: Color(0xFF608e8e),
                    child: Icon(Icons.person, color: Colors.white),
                    radius: 18,
                  );
                }

                // Data fetched successfully
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final profilePhotoUrl = data['profilephotourl'] ?? '';

                return CircleAvatar(
                  backgroundImage:
                  profilePhotoUrl.isNotEmpty ? NetworkImage(profilePhotoUrl) : null,
                  radius: 18,
                  child: profilePhotoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                  backgroundColor: const Color(0xFF608e8e),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lawyerName,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _chatDuration,
                    builder: (context, duration, child) {
                      return Text(
                        _formatChatDuration(duration),
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      );
                    },
                  ),

                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _chatEnded ? _restartChat : _endChat,
            child: Text(
              _chatEnded ? "Restart Chat" : "End Chat",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          const EncryptedIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
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
                    final messageId = messages[index].id;
                    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();

                    // Call _markMessagesAsRead with the messageId when a non-user message is displayed
                    if (!isUserMessage && message['status'] == 'delivered') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markMessagesAsRead(messageId); // Pass the messageId as an argument
                      });
                    }

                    Widget dateHeader = const SizedBox.shrink();
                    if (timestamp != null &&
                        (lastDate == null ||
                            lastDate!.day != timestamp.day ||
                            lastDate!.month != timestamp.month ||
                            lastDate!.year != timestamp.year)) {
                      dateHeader = Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            _formatDateHeader(timestamp),
                            style: const TextStyle(
                              color: Color(0xFF416d6d),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                      lastDate = timestamp;
                    }

                    String displayText;
                    try {
                      displayText = _decryptMessage(message['text']); // Decrypting the message
                    } catch (e) {
                      displayText = "[Error decoding message]"; // Fallback if decryption fails
                    }

                    return Column(
                      crossAxisAlignment:
                      isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        dateHeader,
                        Align(
                          alignment: isUserMessage
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75, // Limit width to 75% of screen
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUserMessage
                                  ? const Color(0xFF416d6d) // User message color
                                  : const Color(0xFF608e8e), // Other message color
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
                                  displayText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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
                                        _getMessageStatusIcon(message['status']),
                                        color: _getMessageStatusColor(message['status']),
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        fillColor: const Color(0xFF608e8e),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF416d6d),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage, // Use the method directly
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

  IconData _getMessageStatusIcon(String status) {
    switch (status) {
      case 'sent':
        return Icons.check;
      case 'delivered':
        return Icons.done_all;
      case 'read':
        return Icons.done_all;
      default:
        return Icons.access_time;
    }
  }

  Color _getMessageStatusColor(String status) {
    switch (status) {
      case 'read':
        return Color(0xff70abab);
      case 'delivered':
      case 'sent':
        return Colors.white70;
      default:
        return Colors.white70;
    }
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
