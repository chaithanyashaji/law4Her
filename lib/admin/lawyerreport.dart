import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerReportsPage extends StatefulWidget {
  @override
  _LawyerReportsPageState createState() => _LawyerReportsPageState();
}

class _LawyerReportsPageState extends State<LawyerReportsPage> {
  final Color primaryColor = const Color(0xFF416d6d);
  final Color secondaryColor = const Color(0xFF608e8e);
  final Color backgroundColor = const Color(0xFFc5d0d3);
  final Color actionColor = const Color(0xFF608e8e);

  Map<String, bool> isExpandedMap = {}; // Tracks expanded state for each report
  List<Map<String, dynamic>> reportsWithLawyerData = []; // Combines reports with lawyer data

  @override
  void initState() {
    super.initState();
    _fetchReportsWithLawyerData();
  }

  Future<void> _fetchReportsWithLawyerData() async {
    try {
      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('lawyerreports')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> combinedData = [];

      for (var reportDoc in reportsSnapshot.docs) {
        final report = reportDoc.data();
        final lawyerSnapshot = await FirebaseFirestore.instance
            .collection('lawyer')
            .doc(report['lawyerId'])
            .get();

        if (lawyerSnapshot.exists) {
          combinedData.add({
            'reportId': reportDoc.id,
            'reportData': report,
            'lawyerData': lawyerSnapshot.data(),
          });
        }
      }

      setState(() {
        reportsWithLawyerData = combinedData;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Lawyer Reports',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: reportsWithLawyerData.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_off, color: primaryColor, size: 100),
            const SizedBox(height: 20),
            Text(
              'No Lawyer Reports',
              style: TextStyle(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reportsWithLawyerData.length,
        itemBuilder: (context, index) {
          final report = reportsWithLawyerData[index];
          return _buildReportItem(
            context,
            report['reportData'],
            report['lawyerData'],
            report['reportId'],
          );
        },
      ),
    );
  }

  Widget _buildReportItem(BuildContext context, Map<String, dynamic> report, Map<String, dynamic> lawyer, String reportId) {
    final lawyerId = report['lawyerId'];
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
                _showFullImage(context, lawyer['profilephotourl']);
              },
              child: CircleAvatar(
                radius: 30,
                backgroundColor: secondaryColor.withOpacity(0.3),
                backgroundImage: lawyer['profilephotourl'] != null
                    ? NetworkImage(lawyer['profilephotourl'])
                    : null,
                child: lawyer['profilephotourl'] == null
                    ? Icon(Icons.person, color: primaryColor)
                    : null,
              ),
            ),
            title: Text(
              lawyer['name'] ?? 'Unknown Lawyer',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              lawyer['place'] ?? 'Unknown Location',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 14,
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
          if (isExpanded) _buildReportDetails(context, lawyer, report, reportId),
        ],
      ),
    );
  }

  Widget _buildReportDetails(
      BuildContext context, Map<String, dynamic> lawyer, Map<String, dynamic> report, String reportId) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Specialization', lawyer['specialization'] ?? 'Unknown'),
          const SizedBox(height: 8),
          _buildInfoRow('Bar ID', lawyer['barid'] ?? 'N/A'),
          const SizedBox(height: 16),
          Text(
            'Reason for Report:',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report['reason'] ?? 'No reason provided',
            style: TextStyle(color: secondaryColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _confirmRejectLawyer(context, report['lawyerId'], reportId),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: Text(
                  'Reject Lawyer',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRejectLawyer(BuildContext context, String lawyerId, String reportId) async {
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Rejection', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Text('Reject this lawyer?', style: TextStyle(color: primaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: secondaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            child: Text(
              'Reject',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldReject == true) {
      _rejectLawyer(context, lawyerId, reportId);
    }
  }

  Future<void> _rejectLawyer(BuildContext context, String lawyerId, String reportId) async {
    try {
      await FirebaseFirestore.instance.collection('lawyer').doc(lawyerId).update({
        'status': 'Rejected',
      });

      await FirebaseFirestore.instance.collection('lawyerreports').doc(reportId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lawyer rejected successfully'),
          backgroundColor: primaryColor,
        ),
      );

      // Refresh data
      _fetchReportsWithLawyerData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejection failed'),
          backgroundColor: actionColor,
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
