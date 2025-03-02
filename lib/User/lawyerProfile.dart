import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LawyerProfile extends StatelessWidget {
  final Map<String, dynamic> lawyer;

  LawyerProfile({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF416d6d);
    final Color secondaryColor = const Color(0xFF608e8e);
    final Color backgroundColor = const Color(0xFFf5f7f7); // Lighter background

    return Scaffold(
      appBar: AppBar(
        title: Text(lawyer['name']),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section with Gradient Background
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: lawyer['profilephotourl'].isNotEmpty
                          ? NetworkImage(lawyer['profilephotourl'])
                          : null,
                      child: lawyer['profilephotourl'].isEmpty
                          ? Icon(Icons.person, size: 60, color: primaryColor)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lawyer['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lawyer['specialization'],
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatCard('Experience', '${lawyer['experience']} years'),
                        _buildStatCard('Rating', lawyer['avgRating'].toStringAsFixed(1)),
                        _buildStatCard('Reviews', lawyer['noOfReviews'].toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Details Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    title: 'Contact Information',
                    content: Column(
                      children: [
                        _buildDetailRow(Icons.email, lawyer['email']),
                        _buildDetailRow(Icons.location_on, lawyer['place']),
                        _buildDetailRow(
                          Icons.circle,
                          lawyer['availability'] ? 'Available Now' : 'Offline',
                          color: lawyer['availability'] ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reviews Section
                  _buildReviewsSection(),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [


                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? const Color(0xFF416d6d)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return _buildInfoCard(
      title: 'Reviews',
      content: Column(
        children: [
          // Review Statistics
          Row(
            children: [
              Text(
                lawyer['avgRating'].toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        size: 20,
                        color: index < lawyer['avgRating'].floor()
                            ? Colors.amber
                            : Colors.grey.shade300,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lawyer['noOfReviews']} reviews',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          // Individual Reviews
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lawyer') // Corrected collection name
                .doc(lawyer['id']) // Access the lawyer document using the ID
                .collection('reviews') // Access the 'reviews' subcollection
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Something went wrong');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No reviews yet');
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> review = doc.data() as Map<String, dynamic>;
                  return _buildReviewCard(review);
                }).toList(),
              );
            },
          ),

        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('user') // Replace with the actual user collection name
          .doc(review['userId']) // Fetch user document using userId
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('User not found');
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userName = userData['name'] ?? 'Unknown';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF416d6d),
                    child: Text(
                      userName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              size: 16,
                              color: index < review['rating']
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(review['timestamp']),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (review['comment'] != null && review['comment'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  review['comment'],
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        );
      },
    );
  }


  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}