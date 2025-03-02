import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:law4her/User/lawyerchat.dart';
import 'lawyerProfile.dart';// Import the ChatWithLawyer page

class LawyerConsultation extends StatefulWidget {
  @override
  _LawyerConsultationState createState() => _LawyerConsultationState();
}

class _LawyerConsultationState extends State<LawyerConsultation> {
  // Colors for theme
  final Color primaryColor = const Color(0xFF416d6d);
  final Color secondaryColor = const Color(0xFF608e8e);
  final Color backgroundColor = const Color(0xFFc5d0d3);


  // Controllers and state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _sortCriteria = 'rating'; // Default sorting criteria

  // Add this sorting logic
  List<QueryDocumentSnapshot<Object?>> _sortLawyers(
      List<QueryDocumentSnapshot<Object?>> lawyers, String criteria) {
    lawyers.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      if (criteria == 'free') {
        // Sort by free service first
        final serviceTypeA = dataA['serviceType'] ?? 'Paid Service';
        final serviceTypeB = dataB['serviceType'] ?? 'Paid Service';
        return serviceTypeA.compareTo(serviceTypeB); // 'Free Service' comes before 'Paid Service'
      } else if (criteria == 'rate_high_to_low') {
        // Sort by rate (highest to lowest)
        final rateA = dataA['rate'] ?? 0;
        final rateB = dataB['rate'] ?? 0;
        return rateB.compareTo(rateA);
      } else if (criteria == 'rate_low_to_high') {
        // Sort by rate (lowest to highest)
        final rateA = dataA['rate'] ?? 0;
        final rateB = dataB['rate'] ?? 0;
        return rateA.compareTo(rateB);
      } else if (criteria == 'rating') {
        // Default sorting by rating
        return (dataB['avgRating'] ?? 0.0).compareTo(dataA['avgRating'] ?? 0.0);
      }
      return 0; // Default case
    });
    return lawyers;
  }

  // Stream to get chat request status
  Stream<String> _getRequestStatus(String lawyerId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value('none');

    return FirebaseFirestore.instance
        .collection('chatRequests')
        .where('requesterId', isEqualTo: currentUser.uid)
        .where('lawyerId', isEqualTo: lawyerId)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['status'] ?? 'none';
      } else {
        return 'none';
      }
    });
  }

  // Function to get Chat ID
  Future<String> _getChatId(String lawyerId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return '';

    final querySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.email)
        .get();

    for (var chat in querySnapshot.docs) {
      final participants = List<String>.from(chat['participants']);
      if (participants.contains(lawyerId)) {
        return chat.id; // Return the chat ID if it matches the lawyer
      }
    }
    return '';
  }

  // Function to send chat request
  Future<void> _sendChatRequest(String lawyerId, String lawyerName, String lawyerEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to send a chat request.'),
          backgroundColor: primaryColor,
        ),
      );
      return;
    }

    try {
      // Fetch the name of the current user from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('user').doc(currentUser.uid).get();

      if (!userDoc.exists || !userDoc.data()!.containsKey('name')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to retrieve your name. Please update your profile.'),
            backgroundColor: primaryColor,
          ),
        );
        return;
      }

      final requesterName = userDoc['name']; // Get the 'name' field from Firestore

      // Add the chat request to Firestore
      await FirebaseFirestore.instance.collection('chatRequests').add({
        'requesterId': currentUser.uid,
        'requesterName': requesterName,
        'requesterEmail': currentUser.email,
        'lawyerId': lawyerId,
        'lawyerName': lawyerName,
        'lawyerEmail': lawyerEmail,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chat request sent successfully.'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error sending chat request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send chat request. Please try again.'),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  // Function to send report
  Future<void> _sendReport(String lawyerId, String reason) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to report.'),
          backgroundColor: primaryColor,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': currentUser.uid,
        'lawyerId': lawyerId,
        'reason': reason,
        'status': 'pending', // Default status
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report submitted successfully.'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to submit report. Please try again.'),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  // Dialog to show report form
  void _showReportDialog(String lawyerId, String lawyerName) {
    final TextEditingController _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Report Lawyer"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Report lawyer: $lawyerName"),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: "Reason for reporting",
                  hintText: "Enter your reason...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = _reasonController.text.trim();
                if (reason.isNotEmpty) {
                  _sendReport(lawyerId, reason);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please provide a reason for reporting.'),
                      backgroundColor: primaryColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  // Star Rating Widget
  Widget buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: 14, color: Colors.amber);
        } else if (index == rating.floor() && rating % 1 > 0) {
          return Icon(Icons.star_half, size: 14, color: Colors.amber);
        }
        return Icon(Icons.star_border, size: 14, color: Colors.amber);
      }),
    );
  }

  // Dispose resources
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Main UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Find a Lawyer",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: backgroundColor,
      body: Column(
          children: [
      // Search bar
      Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or place or specialiazation',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),
            // Sorting dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child:Row(
                mainAxisAlignment: MainAxisAlignment.end,  // This will push everything to the right
                children: [

                     // Only right padding needed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 0.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF608e8e), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF608e8e),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sort_rounded,
                                  size: 20,
                                  color: const Color(0xFF416d6d),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: _sortCriteria,
                                  underline: const SizedBox.shrink(),
                                  isDense: true,
                                  borderRadius: BorderRadius.circular(8),
                                  elevation: 3,
                                  icon: Icon(
                                    Icons.expand_more_rounded,
                                    color: const Color(0xFF608e8e),
                                    size: 22,
                                  ),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _sortCriteria = value;
                                      });
                                    }
                                  },
                                  items: [
                                    DropdownMenuItem(
                                      key: const Key('rating'),
                                      value: 'rating',
                                      child: Text(
                                        "Rating",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: const Color(0xFF416d6d),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      key: const Key('experience'),
                                      value: 'experience',
                                      child: Text(
                                        "Experience",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: const Color(0xFF416d6d),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      key: const Key('free'),
                                      value: 'free',
                                      child: Text(
                                        "Free Services",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: const Color(0xFF416d6d),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      key: const Key('rate_high_to_low'),
                                      value: 'rate_high_to_low',
                                      child: Text(
                                        "Rate: High to Low",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: const Color(0xFF416d6d),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      key: const Key('rate_low_to_high'),
                                      value: 'rate_low_to_high',
                                      child: Text(
                                        "Rate: Low to High",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: const Color(0xFF416d6d),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                ],
              ),
            ),
    // List of lawyers
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('lawyer').snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(
    child: CircularProgressIndicator(color: primaryColor),
    );
    }
    if (snapshot.hasError) {
    return Center(
    child: Text(
    'Error loading lawyers',
    style: TextStyle(color: primaryColor),
    ),
    );
    }

    final lawyers = snapshot.data?.docs ?? [];
  final filteredLawyers = lawyers.where((lawyer) {
      final data = lawyer.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final place = (data['place'] ?? '').toString().toLowerCase();
      final specialization = (data['specialization'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) ||
          place.contains(_searchQuery) ||
          specialization.contains(_searchQuery);
    }).toList();

    if (filteredLawyers.isEmpty) {
      return Center(
        child: Text(
          'No lawyers match your search criteria',
          style: TextStyle(color: primaryColor),
        ),
      );
    }

    final sortedLawyers = _sortLawyers(filteredLawyers, _sortCriteria);

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedLawyers.length,
      itemBuilder: (context, index) {
        final data = sortedLawyers[index].data() as Map<String, dynamic>;
        final lawyerId = sortedLawyers[index].id;
        final lawyerName = data['name'] ?? 'Unknown';
        final lawyer = {
          'id': lawyerId,
          'name': data['name'] ?? 'Unknown',
          'specialization': data['specialization'] ?? 'General',
          'place': data['place'] ?? 'N/A',
          'email': data['email'] ?? '',
          'profilephotourl': data['profilephotourl'] ?? '',
          'availability': data['availability'] ?? false,
          'experience': data['experience'] ?? 0,
          'avgRating': (data['avgRating'] ?? 0.0).toDouble(),
          'noOfReviews': data['noOfReviews'] ?? 0,
          'serviceType':data['serviceType']??'',
          'rate':data['rate']??''
        };

        return StreamBuilder<String>(
          stream: _getRequestStatus(lawyerId),
          builder: (context, snapshot) {
            final status = snapshot.data ?? 'none';

            return GestureDetector(
                onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LawyerProfile(lawyer: lawyer),
                ),
              );
            },
            child:  Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: backgroundColor,
                      backgroundImage: lawyer['profilephotourl'].isNotEmpty
                          ? NetworkImage(lawyer['profilephotourl'])
                          : null,
                      child: lawyer['profilephotourl'].isEmpty
                          ? Icon(Icons.person, color: primaryColor, size: 25)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Lawyer Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lawyer['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: lawyer['availability']
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lawyer['availability'] ? "Online" : "Offline",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: lawyer['availability']
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lawyer['specialization'],
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lawyer['serviceType'] == "Paid Service"
                                ? "₹${lawyer['rate']}/min"
                                : "Free",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: lawyer['serviceType'] == "Paid Service"
                                  ? primaryColor
                                  : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  if (index < lawyer['avgRating'].floor()) {
                                    return Icon(Icons.star, size: 14, color: Colors.amber);
                                  } else if (index == lawyer['avgRating'].floor() &&
                                      lawyer['avgRating'] % 1 > 0) {
                                    return Icon(Icons.star_half,
                                        size: 14, color: Colors.amber);
                                  } else {
                                    return Icon(Icons.star_border,
                                        size: 14, color: Colors.amber);
                                  }
                                }),
                              ),
                              const SizedBox(width: 8),
              Text(
                "(${(lawyer['avgRating'] ?? 0.0).toStringAsFixed(1)} • ${(lawyer['noOfReviews'] ?? 0)} reviews)",
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryColor,
                ),
              ),

              ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 12, color: primaryColor),
                              const SizedBox(width: 2),
                              Text(
                                lawyer['place'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.work,
                                  size: 12, color: primaryColor),
                              const SizedBox(width: 2),
                              Text(
                                "${lawyer['experience']}y",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.report, size: 18),
                          color: const Color(0xFF416d6d),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () => _showReportDialog(lawyerId, lawyerName),
                        ),
                        const SizedBox(height: 4),
                        _buildActionButton(status, lawyer),
                      ],
                    ),
                  ],
                ),
              ),
            )
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

  // Action button for chat requests
  Widget _buildActionButton(String status, Map<String, dynamic> lawyer) {
    switch (status) {
      case 'none':
        return SizedBox(
          height: 28,
          child: ElevatedButton(
            onPressed: () => _sendChatRequest(
              lawyer['id'],
              lawyer['name'],
              lawyer['email'],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              "Request",
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        );

      case 'pending':
        return SizedBox(
          height: 28,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              "Pending",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );

      case 'accepted':
        return SizedBox(
          height: 28,
          child: ElevatedButton(
            onPressed: () async {
              final chatId = await _getChatId(lawyer['id']);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatWithLawyer(
                    chatId: chatId,
                    lawyerId: lawyer['id'],
                    lawyerName: lawyer['name'],
                    lawyerEmail: lawyer['email'],
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              "Chat",
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}


