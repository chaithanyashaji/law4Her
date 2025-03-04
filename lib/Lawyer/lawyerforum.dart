import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LawyerForumPage extends StatefulWidget {
  @override
  _LawyerForumPageState createState() => _LawyerForumPageState();
}

class _LawyerForumPageState extends State<LawyerForumPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Define theme colors
  final Color primaryColor = const Color(0xFF416d6d); // Primary color
  final Color secondaryColor = const Color(0xFF608e8e); // Secondary color
  final Color backgroundColor = const Color(0xFFc5d0d3); // Background color



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Lawyer Forum',
          style: TextStyle(color: Colors.white,
              fontSize: 22,
              fontWeight:FontWeight.w600,
              letterSpacing: 0.5),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forums')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      "No posts available.",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildForumPost(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumPost(DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
    final likes = List<String>.from(data['likes'] ?? []);
    final dislikes = List<String>.from(data['dislikes'] ?? []);
    final currentUserId = _auth.currentUser!.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['content'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF416d6d),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF416d6d), thickness: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _toggleLike(post.id, likes, dislikes, currentUserId),
    child: Row(
                  children: [
                    Icon(
                      likes.contains(currentUserId)
                          ? Icons.thumb_up
                          : Icons.thumb_up_off_alt,
                      size: 20,
                      color: primaryColor,
                    ),



                    const SizedBox(width: 5),
                    Text(
                      '${likes.length}',
                      style: const TextStyle(color: Color(0xFF416d6d), fontSize: 14),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleDislike(post.id, dislikes, likes, currentUserId),
    child: Row(
                  children: [
                    Icon(
                      dislikes.contains(currentUserId)
                          ? Icons.thumb_down
                          : Icons.thumb_down_off_alt,
                      size: 20,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${dislikes.length}',
                      style: const TextStyle(color: Color(0xFF416d6d), fontSize: 14),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showCommentsPage(post.id),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: Color(0xFF416d6d),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${comments.length}',
                      style: const TextStyle(color: Color(0xFF416d6d), fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.report_outlined,
                  color: secondaryColor, // Updated report icon color
                ),
                onPressed: () => _showReportDialog(post.id, data['userId']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(String postId, List<String> likes, List<String> dislikes, String currentUserId) async {
    final postRef = FirebaseFirestore.instance.collection('forums').doc(postId);

    if (likes.contains(currentUserId)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUserId]),
        'dislikes': FieldValue.arrayRemove([currentUserId]), // Remove dislike if present
      });
    }
  }
  Future<void> _toggleDislike(String postId, List<String> dislikes, List<String> likes, String currentUserId) async {
    final postRef = FirebaseFirestore.instance.collection('forums').doc(postId);

    if (dislikes.contains(currentUserId)) {
      await postRef.update({
        'dislikes': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      await postRef.update({
        'dislikes': FieldValue.arrayUnion([currentUserId]),
        'likes': FieldValue.arrayRemove([currentUserId]), // Remove like if present
      });
    }
  }


  void _showCommentsPage(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(postId: postId),
      ),
    );
  }

  void _showReportDialog(String postId, String reportedUserId) {
    final TextEditingController _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Report Post",
            style: TextStyle(color: Color(0xFF416d6d)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Provide a reason for reporting this post.",
                style: TextStyle(color: Color(0xFF416d6d)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF416d6d))),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = _reasonController.text.trim();
                if (reason.isNotEmpty) {
                  await _submitReport(postId, reportedUserId, reason);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReport(
      String postId, String reportedUserId, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('forumreports').add({
        'postId': postId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Report submitted successfully."),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print("Error submitting report: $e");
    }
  }
}


class CommentsPage extends StatelessWidget {
  final String postId;

  CommentsPage({required this.postId});

  final Color primaryColor = const Color(0xFF416d6d);
  final Color secondaryColor = const Color(0xFF608e8e);
  final Color backgroundColor = const Color(0xFFc5d0d3);


  @override
  Widget build(BuildContext context) {
    final TextEditingController _commentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Comments',
          style: TextStyle(color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,

          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forums')
                  .doc(postId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final comments = List<Map<String, dynamic>>.from(
                    snapshot.data!['comments'] ?? []);

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: primaryColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Be the first to start the conversation!',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _enrichCommentsWithProfilePhoto(comments),
                  builder: (context, enrichedSnapshot) {
                    if (!enrichedSnapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    }

                    final enrichedComments = enrichedSnapshot.data!;

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: enrichedComments.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade300,
                        height: 16,
                      ),
                      itemBuilder: (context, index) {
                        final comment = enrichedComments[index];
                        return _buildCommentCard(comment, postId, context); // Pass context here
                      },
                    );

                  },
                );
              },
            ),
          ),
          // Comment Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _commentController,
                    style: TextStyle(color: primaryColor),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: TextStyle(
                        color: secondaryColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () async {
                      if (_commentController.text.trim().isNotEmpty) {
                        final currentUser = FirebaseAuth.instance.currentUser;

                        if (currentUser != null) {
                          final newComment = {
                            'userName': currentUser.displayName ?? 'Anonymous',
                            'userType': 'User',
                            'comment': _commentController.text.trim(),
                            'userId': currentUser.uid,
                          };

                          await FirebaseFirestore.instance
                              .collection('forums')
                              .doc(postId)
                              .update({
                            'comments': FieldValue.arrayUnion([newComment]),
                          });

                          _commentController.clear();
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }


  Widget _buildCommentCard(Map<String, dynamic> comment, String postId, BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: backgroundColor,
            backgroundImage: (comment['userType'] == 'Lawyer' &&
                comment.containsKey('profilePhotoUrl') &&
                comment['profilePhotoUrl'] != null)
                ? NetworkImage(comment['profilePhotoUrl'])
                : null,
            child: (comment['userType'] != 'Lawyer' ||
                comment['profilePhotoUrl'] == null)
                ? Icon(Icons.person, color: primaryColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment['userName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF414d6d),
                      ),
                    ),
                    Row(
                      children: [
                        if (comment['userId'] == currentUserId)
                          IconButton(
                            icon: Icon(Icons.delete_outline, color:secondaryColor),
                            onPressed: () => _confirmDeleteComment(context, postId, comment),
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.report_outlined,
                            color: secondaryColor.withOpacity(0.7),
                          ),
                          onPressed: () => _showCommentReportDialog(
                            context,
                            postId,
                            comment['userId'],
                            comment['userName'] ?? 'User',
                          ),
                        ),
                      ],
                    )

                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['comment'] ?? '',
                  style: const TextStyle(color: Color(0xFF414d6d)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }




  Future<List<Map<String, dynamic>>> _enrichCommentsWithProfilePhoto(
      List<Map<String, dynamic>> comments) async {
    final lawyersRef = FirebaseFirestore.instance.collection('lawyer');

    for (var comment in comments) {
      if (comment['userType'] == 'Lawyer') {
        try {
          final lawyerDoc = await lawyersRef.doc(comment['userId']).get();
          if (lawyerDoc.exists) {
            comment['profilePhotoUrl'] = lawyerDoc['profilephotourl'] ?? '';
          }
        } catch (e) {
          print('Error fetching lawyer profile: $e');
        }
      }
    }
    return comments;
  }


  void _showCommentReportDialog(
      BuildContext context, String postId, String reportedUserId, String reportedUserName) {
    final TextEditingController _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Report Comment", style: TextStyle(color: primaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  _sendCommentReport(context,postId, reportedUserId, reason);
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

  Future<void> _sendCommentReport(
      BuildContext context, String postId, String reportedUserId, String reason) async {
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
      await FirebaseFirestore.instance.collection('commentreports').add({
        'reporterId': currentUser.uid,
        'reportedUserId': reportedUserId,
        'postId': postId,
        'reason': reason,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Comment report submitted successfully.'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error submitting comment report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to submit report. Please try again.'),
          backgroundColor: primaryColor,
        ),
      );
    }
  }


  void _confirmDeleteComment(
      BuildContext context, String postId, Map<String, dynamic> comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Comment',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance
          .collection('forums')
          .doc(postId)
          .update({
        'comments': FieldValue.arrayRemove([comment]),
      });
    }
  }
}