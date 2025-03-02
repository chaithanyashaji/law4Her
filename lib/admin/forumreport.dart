import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForumReportsPage extends StatefulWidget {
  @override
  _ForumReportsPageState createState() => _ForumReportsPageState();
}

class _ForumReportsPageState extends State<ForumReportsPage> {
  final Color primaryColor = const Color(0xFF416d6d);
  final Color secondaryColor = const Color(0xFF608e8e);
  final Color backgroundColor = const Color(0xFFc5d0d3);

  Map<String, bool> isExpandedMap = {}; // Tracks expanded state for each report
  List<Map<String, dynamic>> combinedReports = []; // List to hold reports with post data

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      // Fetch all reports
      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('forumreports')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedReports = [];

      for (var reportDoc in reportsSnapshot.docs) {
        final report = reportDoc.data();
        final postSnapshot = await FirebaseFirestore.instance
            .collection('forums')
            .doc(report['postId'])
            .get();

        if (postSnapshot.exists) {
          final post = postSnapshot.data();
          loadedReports.add({
            'reportId': reportDoc.id,
            'reportData': report,
            'postId': report['postId'],
            'postData': post,
          });
        }
      }

      setState(() {
        combinedReports = loadedReports;
      });
    } catch (e) {
      print('Error loading reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Forum Reports',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 5,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: combinedReports.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_problem, color: primaryColor, size: 50),
            const SizedBox(height: 10),
            Text(
              'No reports available.',
              style: TextStyle(
                fontSize: 18,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: combinedReports.length,
        itemBuilder: (context, index) {
          final report = combinedReports[index];
          return _buildReportCard(context, report);
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    final isExpanded = isExpandedMap[report['reportId']] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSectionTitle("Post Content"),
          ),
          ListTile(
            title: Text(
              isExpanded
                  ? '${report['postData']['content'] ?? 'No content available'}'
                  : '${_truncateContent(report['postData']['content'] ?? 'No content available')}...',
              style: TextStyle(
                fontSize: 14,
                color: primaryColor,
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
                  isExpandedMap[report['reportId']] = !isExpanded;
                });
              },
            ),
          ),
          if (isExpanded) _buildExpandedDetails(context, report),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(BuildContext context, Map<String, dynamic> report) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionTitle('Reason for Report:'),
          const SizedBox(height: 8),
          Text(
            report['reportData']['reason'] ?? 'No reason provided',
            style: TextStyle(fontSize: 14, color: secondaryColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _confirmDeletePost(
              context,
              report['postId'],
              report['reportId'],
            ),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text(
              'Delete Post',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateContent(String content) {
    // Truncate content to the first 30 characters
    return content.length > 30 ? content.substring(0, 30) : content;
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
  }

  Future<void> _confirmDeletePost(BuildContext context, String postId, String reportId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Confirm Delete', style: TextStyle(color: primaryColor)),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: secondaryColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _deletePost(postId, reportId);
    }
  }

  Future<void> _deletePost(String postId, String reportId) async {
    try {
      await FirebaseFirestore.instance.collection('forums').doc(postId).delete();
      await FirebaseFirestore.instance.collection('forumreports').doc(reportId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post deleted successfully.', style: TextStyle(color: Colors.white)),
          backgroundColor: primaryColor,
        ),
      );

      // Reload reports after deletion
      _loadReports();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post. Please try again.', style: TextStyle(color: Colors.white)),
          backgroundColor: secondaryColor,
        ),
      );
    }
  }
}
