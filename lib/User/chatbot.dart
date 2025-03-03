import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  User? _currentUser;
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> messages = [];
  bool _isListening = false;
  bool _isTyping = false;
  bool _isSpeaking = false;
  double _buttonSize = 56.0;

  // Backend API URL
  // Backend API URLs
  final String ipcApiUrl = "https://chaithanyashaji-lawapi.hf.space/chat"; // IPC
  final String bnsApiUrl = "https://chaithanyashaji21-bnsapi.hf.space/chat"; // BNS
  late String apiUrl; // Current selected API URL


  // Translation API
  final String translateApiUrl = "https://google-api31.p.rapidapi.com/gtranslate";
  final String rapidApiKey = "2d90bd2d4amshf5efa5cbcfb2acfp106a8ejsnac5f7aa5b0ff";

  // Supported Languages
  String selectedLanguage = "en";
  // Supported languages with native names
  final Map<String, String> languages = {
    "en": "English", // English
    "hi": "हिंदी", // Hindi
    "ml": "മലയാളം", // Malayalam
    "ta": "தமிழ்", // Tamil
    "te": "తెలుగు", // Telugu
    "kn": "ಕನ್ನಡ", // Kannada
    "mr": "मराठी", // Marathi
    "gu": "ગુજરાતી", // Gujarati
    "pa": "ਪੰਜਾਬੀ", // Punjabi
    "bn": "বাংলা", // Bengali
    "ur": "اردو", // Urdu
  };

  String selectedSource = "IPC"; // Default source is IPC
  final List<String> lawSources = ["IPC", "BNS"];
  // Initialize TTS
  @override
  void initState() {
    super.initState();
    apiUrl = ipcApiUrl; // Set default API URL to IPC
    _initializeTTS();
    _loadCurrentUser();

  }

  Future<void> _clearChat() async {
    if (_currentUser == null) {
      print("Error: No user is logged in.");
      return;
    }

    try {
      // Get the user's messages collection
      final messagesRef = _firestore
          .collection('aiChats')
          .doc(_currentUser!.uid)
          .collection('messages');

      // Fetch all message documents
      final querySnapshot = await messagesRef.get();

      // Batch delete all documents in the messages collection
      WriteBatch batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Clear the local messages list
      setState(() {
        messages.clear();
      });

      print("Chat cleared successfully.");
    } catch (e) {
      print("Error clearing chat: $e");
    }
  }

  Widget _typingIndicator() {
    return _isTyping
        ? Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF416d6d).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, double value, child) {
                    // Create a pulsing effect that's slightly offset for each dot
                    final pulseValue = sin(value * 2 * 3.14159 + (index * 1.0));
                    final size = 8.0 + (pulseValue + 1) * 1.5;
                    final opacity = 0.5 + (pulseValue + 1) * 0.25;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: const Color(0xFF416d6d).withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    )
        : SizedBox.shrink();
  }



  Future<void> _loadCurrentUser() async {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });

    if (_currentUser != null) {
      print("Current user loaded: ${_currentUser!.uid}");
      await _fetchUserChats();
    } else {
      print("No user is currently signed in.");
    }
  }


  Future<void> _fetchUserChats() async {
    if (_currentUser == null) {
      print("Error: No user is logged in.");
      return;
    }

    try {
      // Fetch messages for the logged-in user
      _firestore
          .collection('aiChats')
          .doc(_currentUser!.uid)
          .collection('messages')
          .orderBy('timestamp', descending: false) // Oldest to newest
          .snapshots()
          .listen((snapshot) {
        setState(() {
          messages = snapshot.docs.map((doc) {
            return {
              'message': doc['message'],
              'isUserMessage': doc['isUserMessage'],
              'timestamp': doc['timestamp']?.toDate() ?? DateTime.now(), // Handle null timestamp
            };
          }).toList();

          // Scroll to the bottom of the chat
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        });
      });
    } catch (e) {
      print("Error fetching chats: $e");
    }
  }



  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }




  Future<void> _initializeTTS() async {
    _flutterTts.setLanguage(selectedLanguage); // Default language
    _flutterTts.setSpeechRate(0.5); // Adjust the speech rate for clarity
    _flutterTts.setPitch(1.0); // Adjust the pitch for natural sound
  }

  // Translate text using Google Translate API
  Future<String> translateText(String text, String sourceLang, String targetLang) async {
    try {
      final response = await http.post(
        Uri.parse(translateApiUrl),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "X-RapidAPI-Key": rapidApiKey,
        },
        body: jsonEncode({
          "text": text,
          "from_lang": sourceLang,
          "to": targetLang,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['translated_text'];
      } else {
        return "Translation failed: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }


  // Send a message and handle multilingual processing
  // Send a message and handle multilingual processing
  Future<void> sendMessage(String userMessage) async {
    print("Original Message: $userMessage");
    print("Selected Language: $selectedLanguage");

    // Translate the user's message to English
    final translatedMessage = await translateText(userMessage, selectedLanguage, "en");

    print("Translated Message (to English): $translatedMessage");

    if (_currentUser == null) {
      print("Error: User not logged in.");
      return;
    }

    // Save the user's original message to Firestore
    _saveMessageToFirestore(userMessage, true);

    setState(() {
      messages.add({
        'message': userMessage,
        'isUserMessage': true,
      });
      _isTyping = true; // Start typing animation
    });

    _scrollToBottom();

    try {
      // Send the translated message to the backend API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: utf8.encode(jsonEncode({"question": translatedMessage})), // Use the translated message
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final botMessage = data['answer'];
        print("Response from API: $botMessage");

        // Translate the bot's response back to the user's selected language
        final translatedBotMessage = await translateText(botMessage, "en", selectedLanguage);
        print("Translated Bot Response: $translatedBotMessage");

        // Save the bot's response to Firestore
        _saveMessageToFirestore(translatedBotMessage, false);

        setState(() {
          messages.add({
            'message': translatedBotMessage,
            'isUserMessage': false,
          });
          _isTyping = false; // Stop typing animation
        });

        _scrollToBottom();
      } else {
        print("Error: API returned status code ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending message: $e");
      setState(() {
        _isTyping = false;
      });
    }
  }



  Future<void> _saveMessageToFirestore(String message, bool isUserMessage) async {
    try {
      // Get the current user's ID
      String userId = _currentUser!.uid;

      // Save the message to the Firestore
      await _firestore.collection('aiChats').doc(userId).set({
        'userId': userId, // Add the userId field in the parent document
      });

      // Add the message to the messages subcollection
      await _firestore
          .collection('aiChats')
          .doc(userId)
          .collection('messages')
          .add({
        'message': utf8.decode(utf8.encode(message)),
        'isUserMessage': isUserMessage,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving message to Firestore: $e');
    }
  }





  // Start listening for speech input
  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print("Speech status: $status"),
      onError: (error) => print("Speech error: $error"),
    );

    if (available) {
      setState(() {
        _isListening = true;
        _buttonSize = 70.0; // Increase size when recording starts
      });
      _speech.listen(onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      });
    }
  }

// Stop listening for speech input
  void _stopListening() {
    setState(() {
      _isListening = false;
      _buttonSize = 56.0; // Reset to default size when recording stops
    });
    _speech.stop();
  }


  // Speak the bot's response
  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage(selectedLanguage);
    setState(() {
      _isSpeaking = true;
    });
    await _flutterTts.speak(text);
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // Pause or stop speaking
  Future<void> _pauseSpeaking() async {
    await _flutterTts.pause();
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF416d6d),
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Handle back navigation
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space elements
          children: [
            // IPC/BNS Selection Dropdown
            DropdownButton<String>(
              dropdownColor: const Color(0xFF416d6d),
              value: selectedSource,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.library_books,
                color: Color(0xFFc5d0d3),
                size: 20,
              ),
              onChanged: (String? newSource) {
                if (newSource != null) {
                  setState(() {
                    selectedSource = newSource;
                    apiUrl = selectedSource == "IPC" ? ipcApiUrl : bnsApiUrl;
                  });
                }
              },
              items: lawSources.map((source) {
                return DropdownMenuItem<String>(
                  value: source,
                  child: Text(
                    source,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            // Center Logo
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Image.asset(
                'assets/whitelogo.png',
                height: 70,
                fit: BoxFit.contain,
              ),
            ),
            // Language Selection Dropdown
            DropdownButton<String>(
              dropdownColor: const Color(0xFF416d6d),
              value: selectedLanguage,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.language,
                color: Color(0xFFc5d0d3),
                size: 20,
              ),
              onChanged: (String? newLanguage) {
                if (newLanguage != null) {
                  setState(() {
                    selectedLanguage = newLanguage;
                    _flutterTts.setLanguage(newLanguage);
                  });
                }
              },
              items: languages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'deleteChat') {
                bool? confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete Chat"),
                    content: const Text("Are you sure you want to delete the chat?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _clearChat();
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'deleteChat',
                child: Text("Delete Chat"),
              ),
            ],
          ),
        ],
      ),







      body:DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Roboto', color: Colors.black),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length+1,
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return _typingIndicator(); // Show typing animation
                  }
                  final message = messages[index];
                  return Align(
                    alignment: message['isUserMessage']
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message['isUserMessage']
                              ? const Color(0xFF416d6d).withOpacity(0.8)
                              : const Color(0xFF608e8e).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            if (!message['isUserMessage'])
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () => _speak(message['message']),
                                    icon: const Icon(Icons.volume_up, color: Colors.white),
                                    tooltip: "Read Out",
                                  ),
                                  if (_isSpeaking)
                                    IconButton(
                                      onPressed: _pauseSpeaking,
                                      icon: const Icon(Icons.pause, color: Colors.white),
                                      tooltip: "Pause",
                                    ),
                                  IconButton(
                                    onPressed: _stopSpeaking,
                                    icon: const Icon(Icons.stop, color: Colors.white),
                                    tooltip: "Stop",
                                  ),
                                ],
                              ),
                            const SizedBox(height: 4),
                            if (message['timestamp'] != null)
                              Text(
                                DateFormat('hh:mm a').format(message['timestamp']),
                                style: TextStyle(fontSize: 10, color: Colors.grey[300]),
                              ),

                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF416d6d),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _buttonSize,
                      height: _buttonSize,
                      decoration: BoxDecoration(
                        color: _isListening ? const Color(0xFF608e8e) : const Color(0xFF416d6d),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: const Color(0xFFc5d0d3),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Color(0xFFc5d0d3)),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(color: Color(0xFFc5d0d3)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      if (_controller.text.isNotEmpty) {
                        sendMessage(_controller.text);
                        _controller.clear();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF608e8e),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Color(0xFFc5d0d3),
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