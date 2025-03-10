import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerifyLawyer extends StatefulWidget {
  @override
  _VerifyLawyerState createState() => _VerifyLawyerState();
}

class _VerifyLawyerState extends State<VerifyLawyer> {
  final Color primaryColor = const Color(0xFF416d6d);
  final Color secondaryColor = const Color(0xFF608e8e);
  final Color backgroundColor = const Color(0xFFc5d0d3);

  String selectedStatus = 'Pending'; // Default filter for status
  Map<String, bool> isExpandedMap = {}; // Tracks expanded state for each lawyer

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Lawyers',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      backgroundColor: backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lawyer')
            .where('status', isEqualTo: selectedStatus)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No lawyers found with status "$selectedStatus".',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            );
          }

          final lawyers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lawyers.length,
            itemBuilder: (context, index) {
              final lawyer = lawyers[index];
              final lawyerId = lawyer.id;
              final lawyerData = lawyer.data() as Map<String, dynamic>;

              final isExpanded = isExpandedMap[lawyerId] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          _showFullImage(context, lawyerData['profilephotourl']);
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: secondaryColor.withOpacity(0.3),
                          backgroundImage: lawyerData['profilephotourl'] != null
                              ? NetworkImage(lawyerData['profilephotourl'])
                              : null,
                          child: lawyerData['profilephotourl'] == null
                              ? Icon(Icons.person, size: 30, color: primaryColor)
                              : null,
                        ),
                      ),
                      title: Text(
                        lawyerData['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      subtitle: Text(
                        lawyerData['place'] ?? 'Unknown place',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryColor,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isExpanded
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: primaryColor,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            isExpandedMap[lawyerId] = !isExpanded;
                          });
                        },
                      ),
                    ),
                    if (isExpanded) _buildLawyerDetails(lawyerData, lawyerId),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLawyerDetails(Map<String, dynamic> lawyerData, String lawyerId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enrollment Number: ${lawyerData['enrollmentnumber'] ?? 'N/A'}',
            style: TextStyle(fontSize: 14, color: primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Specialization: ${lawyerData['specialization'] ?? 'Unknown'}',
            style: TextStyle(fontSize: 14, color: primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Email: ${lawyerData['email'] ?? 'Unknown'}',
            style: TextStyle(fontSize: 14, color: primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${lawyerData['status'] ?? 'Pending'}',
            style: TextStyle(fontSize: 14, color: primaryColor),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              _showFullImage(context, lawyerData['idproofurl']);
            },
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor),
                borderRadius: BorderRadius.circular(12),
                image: lawyerData['idproofurl'] != null
                    ? DecorationImage(
                  image: NetworkImage(lawyerData['idproofurl']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: lawyerData['idproofurl'] == null
                  ? Center(
                child: Text(
                  'No ID Photo Available',
                  style: TextStyle(fontSize: 14, color: primaryColor),
                ),
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusButton(context, lawyerId, 'Approve'),
              _buildStatusButton(context, lawyerId, 'Reject'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context, String lawyerId, String status) {
    return ElevatedButton(
      onPressed: () async {
        final confirmed = await _showConfirmationDialog(context, status);
        if (confirmed == true) {
          await _updateLawyerStatus(lawyerId, status);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: status == 'Approve'
            ? const Color(0xff416d6d) // Greenish color for Approved
            : status == 'Reject'
            ? Colors.red // Red for Rejected
            : Colors.grey, // Default color for other statuses
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      child: Text(
        status,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, String status) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Confirm Action',
            style: TextStyle(color: primaryColor),
          ),
          content: Text('Are you sure you want to $status this lawyer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: secondaryColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'Approved' ? primaryColor : secondaryColor,
              ),
              child: Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateLawyerStatus(String lawyerId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('lawyer')
          .doc(lawyerId)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lawyer $status successfully.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update status. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: secondaryColor,
        ),
      );
    }
  }

  void _showFullImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(imageUrl),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close', style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
      ),
    );
  }
}
