import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerListPage extends StatefulWidget {
  @override
  _LawyerListPageState createState() => _LawyerListPageState();
}

class _LawyerListPageState extends State<LawyerListPage> {
  final Color primaryColor = const Color(0xFF416d6d);
  final Color secondaryColor = const Color(0xFF608e8e);
  final Color backgroundColor = const Color(0xFFc5d0d3);

  Map<String, bool> isExpandedMap = {}; // Tracks expanded state for each lawyer
  List<Map<String, dynamic>> lawyerList = []; // Local cache for lawyer data
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLawyers();
  }

  Future<void> _fetchLawyers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('lawyer').get();
      final List<Map<String, dynamic>> loadedLawyers = snapshot.docs.map((doc) {
        isExpandedMap[doc.id] = false; // Initialize expanded state for each lawyer
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      setState(() {
        lawyerList = loadedLawyers;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching lawyers: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Lawyer Lists',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(color: primaryColor),
      )
          : lawyerList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 100, color: primaryColor),
            Text(
              'No lawyers found',
              style: TextStyle(color: primaryColor, fontSize: 18),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lawyerList.length,
        itemBuilder: (context, index) {
          final lawyer = lawyerList[index];
          final lawyerId = lawyer['id'];
          final isExpanded = isExpandedMap[lawyerId] ?? false;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: secondaryColor.withOpacity(0.3),
                      backgroundImage: lawyer['profilephotourl'] != null
                          ? NetworkImage(lawyer['profilephotourl'])
                          : null,
                      child: lawyer['profilephotourl'] == null
                          ? Icon(Icons.person, size: 30, color: primaryColor)
                          : null,
                    ),
                    title: Text(
                      lawyer['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    subtitle: Text(
                      lawyer['place'] ?? 'Unknown place',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
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
                  if (isExpanded) _buildExpandedDetails(lawyer, lawyerId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandedDetails(Map<String, dynamic> lawyer, String lawyerId) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Specialization', lawyer['specialization'] ?? 'Unknown'),
          const SizedBox(height: 8),
          _buildDetailRow('Status', lawyer['status'] ?? 'Pending'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showStatusBottomSheet(context, lawyerId, lawyer['status']),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Change Status',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  void _showStatusBottomSheet(BuildContext context, String lawyerId, String? currentStatus) {
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
              Text(
                'Update Lawyer Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Pending', 'Approved', 'Rejected'].map((status) {
                  return ElevatedButton(
                    onPressed: () {
                      _updateLawyerStatus(lawyerId, status);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == currentStatus ? primaryColor : secondaryColor,
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white),
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

  Future<void> _updateLawyerStatus(String lawyerId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('lawyer').doc(lawyerId).update({
        'status': newStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error updating lawyer status: $e');
    }
  }
}
