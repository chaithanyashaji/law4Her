import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerEarningsPage extends StatefulWidget {
  @override
  _LawyerEarningsPageState createState() => _LawyerEarningsPageState();
}

class _LawyerEarningsPageState extends State<LawyerEarningsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? lawyerData;
  List<Map<String, dynamic>> paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchEarningsData();
  }

  Future<void> _fetchEarningsData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Fetch lawyer data
        final doc = await _firestore.collection('lawyer').doc(user.uid).get();

        // Fetch payment history from transactions subcollection
        final historySnapshot = await _firestore
            .collection('lawyer')
            .doc(user.uid)
            .collection('transactions')
            .orderBy('timestamp', descending: true)
            .get();

        List<Map<String, dynamic>> history = [];
        for (var doc in historySnapshot.docs) {
          history.add({
            'amount': doc['amount'] ?? 0.0,
            'timestamp': (doc['timestamp'] as Timestamp).toDate(),
            'status': doc['status'] ?? 'Unknown',
          });
        }

        setState(() {
          lawyerData = doc.data();
          paymentHistory = history;
        });
      } catch (e) {
        print("Error fetching earnings data: $e");
      }
    }
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Text(
          'Amount Credited: ₹${payment['amount']}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF416d6d),
          ),
        ),
        subtitle: Text(
          'Date: ${payment['timestamp'].toLocal().toString().split(' ')[0]}',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Earnings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xff416d6d),
        elevation: 5,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: lawyerData == null
          ? Center(
        child: CircularProgressIndicator(color: const Color(0xFF416d6d)),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Earnings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Earnings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF416d6d),
                    ),
                  ),
                  Text(
                    '₹${lawyerData!['earnings'] ?? 0.0}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF416d6d),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment History
            const Text(
              'Payment History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF416d6d),
              ),
            ),
            const SizedBox(height: 10),

            // Conditional Rendering for Payment History
            Expanded(
              child: paymentHistory.isEmpty
                  ? Center(
                child: Text(
                  'No payment history available.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: paymentHistory.length,
                itemBuilder: (context, index) {
                  return _buildPaymentCard(paymentHistory[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
