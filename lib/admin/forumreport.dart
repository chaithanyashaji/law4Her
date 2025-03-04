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

  Map<String, bool> isExpandedMap = {};
  List<Map<String, dynamic>> forumReports = [];
  List<Map<String, dynamic>> commentReports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final forumReportsSnapshot = await FirebaseFirestore.instance
          .collection('forumreports')
          .orderBy('timestamp', descending: true)
          .get();

      final commentReportsSnapshot = await FirebaseFirestore.instance
          .collection('commentreports')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedForumReports = [];
      final List<Map<String, dynamic>> loadedCommentReports = [];

      for (var reportDoc in forumReportsSnapshot.docs) {
        final report = reportDoc.data();
        final postSnapshot = await FirebaseFirestore.instance
            .collection('forums')
            .doc(report['postId'])
            .get();

        if (postSnapshot.exists) {
          final post = postSnapshot.data();
          loadedForumReports.add({
            'reportId': reportDoc.id,
            'reportData': report,
            'postId': report['postId'],
            'postData': post,
          });
        }
      }

      for (var reportDoc in commentReportsSnapshot.docs) {
        final report = reportDoc.data();
        final postId = report['postId']; // Get the post ID where the comment exists
        final commentId = report['commentId'];

        final commentSnapshot = await FirebaseFirestore.instance
            .collection('forums')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .get();

        if (commentSnapshot.exists) {
          final comment = commentSnapshot.data();
          loadedCommentReports.add({
            'reportId': reportDoc.id,
            'reportData': report,
            'postId': postId,  // Store postId for deletion
            'commentId': commentId,
            'commentData': comment,
          });
        }
      }

      setState(() {
        forumReports = loadedForumReports;
        commentReports = loadedCommentReports;
      });
    } catch (e) {
      print('Error loading reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Reports',
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
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Forum Reports'),
              Tab(text: 'Comment Reports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReportList(forumReports, true),
            _buildReportList(commentReports, false),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList(List<Map<String, dynamic>> reports, bool isForum) {
    return reports.isEmpty
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
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(context, report, isForum);
      },
    );
  }

  Widget _buildReportCard(
      BuildContext context, Map<String, dynamic> report, bool isForum) {
    final isExpanded = isExpandedMap[report['reportId']] ?? false;
    final reportData = report['reportData'] ?? {};
    final content = report[isForum ? 'postData' : 'commentData']?['content'] ?? 'No content available';

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
            child: _buildSectionTitle(isForum ? "Post Content" : "Comment Content"),
          ),
          ListTile(
            title: Text(
              isExpanded ? content : '${_truncateContent(content)}...',
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
          if (isExpanded) _buildExpandedDetails(context, report, isForum),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(
      BuildContext context, Map<String, dynamic> report, bool isForum) {
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
            onPressed: () => _confirmDelete(
              context,
              report['postId'],
              report['commentId'] ?? report['postId'], // Handle both cases
              report['reportId'],
              isForum,
            ),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text(
              'Delete',
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

  Future<void> _confirmDelete(BuildContext context, String postId, String commentId, String reportId, bool isForum) async {
    final firestore = FirebaseFirestore.instance;

    if (isForum) {
      await firestore.collection('forums').doc(postId).delete();
      await firestore.collection('forumreports').doc(reportId).delete();
    } else {
      await firestore.collection('forums').doc(postId).collection('comments').doc(commentId).delete();
      await firestore.collection('commentreports').doc(reportId).delete();
    }

    _loadReports();
  }

  String _truncateContent(String content) {
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
}
