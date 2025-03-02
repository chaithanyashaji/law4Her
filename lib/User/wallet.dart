import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class WalletPage extends StatefulWidget {
  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Razorpay _razorpay;
  int _rechargeAmount = 0;
  Stream<DocumentSnapshot>? _walletStream;
  Stream<QuerySnapshot>? _transactionsStream;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _initializeStreams();
  }

  void _initializeStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _walletStream = FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .snapshots();

      _transactionsStream = FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Update wallet balance
        await FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .update({
          'wallet': FieldValue.increment(_rechargeAmount),
        });

        // Add transaction record
        await FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .collection('transactions')
            .add({
          'amount': _rechargeAmount,
          'timestamp': FieldValue.serverTimestamp(),
          'transactionId': response.paymentId,
          'status': 'Success',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("₹$_rechargeAmount added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update wallet: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${response.message}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External wallet: ${response.walletName}"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _initiatePayment(int amount) async {
    _rechargeAmount = amount;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User is not logged in"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Initialize default contact and email
    String contact = '0000000000'; // Default contact number
    String email = user.email ?? 'email@example.com'; // Default email

    try {
      // Fetch user details from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        contact = userData['mobilenumber'] ?? contact;
        email = userData['email'] ?? email;
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }

    var options = {
      'key': 'rzp_test_hTDVfoNxgYw0In', // Replace with your Razorpay key
      'amount': amount * 100, // Amount in paise
      'name': 'Law4Her',
      'description': 'Wallet Recharge',
      'prefill': {
        'contact': contact,
        'email': email,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error initiating payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error initiating payment: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Wallet",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF416d6d),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFc5d0d3),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _walletStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final walletBalance =
          snapshot.hasData ? (snapshot.data?['wallet'] ?? 0) : 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Wallet balance section
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF416d6d),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Current Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹$walletBalance',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Quick recharge section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quick Recharge",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44404d),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          final amount = (index + 1) * 100;
                          return ElevatedButton(
                            onPressed: () => _initiatePayment(amount),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF416d6d),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              "₹$amount",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Transaction history section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Transaction History",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44404d),
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: _transactionsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "Error: ${snapshot.error}",
                                style: TextStyle(color: Colors.red),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Text(
                              "No transactions yet.",
                              style: TextStyle(color: Color(0xFF44404d)),
                            );
                          }

                          final transactions = snapshot.data!.docs;

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final transaction =
                              transactions[index].data() as Map<String, dynamic>;
                              final amount = transaction['amount'] ?? 0;
                              final status = transaction['status'] ?? 'Unknown';
                              final timestamp =
                                  transaction['timestamp']?.toDate() ?? DateTime.now();

                              return ListTile(
                                title: Text(
                                  "₹$amount",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF44404d),
                                  ),
                                ),
                                subtitle: Text(
                                  "${timestamp.day}/${timestamp.month}/${timestamp.year} - $status",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: Icon(
                                  status == 'Success'
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: status == 'Success' ? Colors.green : Colors.red,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}
