import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageLawyerPayments extends StatefulWidget {
  @override
  _ManageLawyerPaymentsState createState() => _ManageLawyerPaymentsState();
}

class _ManageLawyerPaymentsState extends State<ManageLawyerPayments> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lawyer Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF416d6d),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('lawyer').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: const Color(0xFF416d6d)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final lawyers = snapshot.data!.docs
              .where((doc) => (doc.data() as Map<String, dynamic>)['earnings'] > 0.0)
              .toList();

          if (lawyers.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lawyers.length,
            itemBuilder: (context, index) {
              final lawyer = lawyers[index];
              final lawyerData = lawyer.data() as Map<String, dynamic>;
              final lawyerId = lawyer.id;

              return _buildLawyerCard(context, lawyerId, lawyerData);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.payment, size: 100, color: Color(0xFF416d6d)),
          SizedBox(height: 16),
          Text(
            'No payments to make',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF416d6d)),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerCard(BuildContext context, String lawyerId, Map<String, dynamic> lawyerData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF416d6d).withOpacity(0.1),
                  backgroundImage: lawyerData['profilephotourl'] != null
                      ? NetworkImage(lawyerData['profilephotourl'])
                      : null,
                  child: lawyerData['profilephotourl'] == null
                      ? Icon(Icons.person, size: 30, color: const Color(0xFF416d6d))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyerData['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF416d6d),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Earnings: ₹${lawyerData['earnings'] ?? 0.0}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Status:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF416d6d),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showPaymentStatusBottomSheet(context, lawyerId, lawyerData),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF608e8e).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Select Status',
                          style: TextStyle(fontSize: 14, color: Color(0xFF416d6d)),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_drop_down, color: Color(0xFF416d6d)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentStatusBottomSheet(BuildContext context, String lawyerId, Map<String, dynamic> lawyerData) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Payment Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF416d6d),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Payment Success', 'Payment Failed'].map((status) {
                  return Flexible(
                    child: ElevatedButton(
                      onPressed: () {
                        _updatePaymentStatus(lawyerId, lawyerData, status);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'Payment Success'
                            ? const Color(0xFF416d6d)
                            : const Color(0xFF608e8e),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          status,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updatePaymentStatus(String lawyerId, Map<String, dynamic> lawyerData, String newStatus) async {
    try {
      final earnings = lawyerData['earnings'] ?? 0.0;

      if (newStatus == 'Payment Success') {
        final transactionData = {
          'amount': earnings,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Payment Success',
        };

        // Add to transactions subcollection
        await _firestore
            .collection('lawyer')
            .doc(lawyerId)
            .collection('transactions')
            .add(transactionData);

        // Reset earnings
        await _firestore.collection('lawyer').doc(lawyerId).update({
          'earnings': 0.0,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$newStatus for ${lawyerData['name']}'),
          backgroundColor: const Color(0xFF416d6d),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating payment status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
