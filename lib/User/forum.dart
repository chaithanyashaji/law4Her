import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class ForumPage extends StatefulWidget {
  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Keep existing color theme
  final Color primaryColor = const Color(0xFF416d6d);
  final Color secondaryColor = const Color(0xFF608e8e);
  final Color backgroundColor = const Color(0xFFc5d0d3);
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";


  void _filterPosts() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
    });
  }


  Future<void> _sendReport(String postId, String reportedUserId,
      String reason) async {
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
      await FirebaseFirestore.instance.collection('forumreports').add({
        'reporterId': currentUser.uid,
        // The user reporting the post
        'reportedUserId': reportedUserId,
        // The owner of the forum post being reported
        'postId': postId,
        // ID of the reported forum post
        'reason': reason,
        // Reason for reporting
        'status': 'pending',
        // Default status of the report
        'timestamp': FieldValue.serverTimestamp(),
        // Time of report submission
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report submitted successfully.'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to submit report. Please try again.'),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  Future<void> _sendCommentReport(String postId, String reportedUserId, String reason) async {
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
        'reporterId': currentUser.uid, // The user reporting the comment
        'reportedUserId': reportedUserId, // The owner of the reported comment
        'postId': postId, // The ID of the post where the comment was made
        'reason': reason, // Reason for reporting
        'status': 'pending', // Default status of the report
        'timestamp': FieldValue.serverTimestamp(), // Report submission time
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

  String formatDateTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(dateTime); // Show only time (e.g., 2:30 PM)
    } else if (difference.inDays == 1) {
      return "Yesterday"; // Show 'Yesterday'
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(dateTime); // Show day name (e.g., Mon, Tue)
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime); // Show full date (e.g., 12/03/2024)
    }
  }




  // Standardized styles
  final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Forum',
          style: TextStyle(
            color: Colors.white,
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
        children: [Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: "Search posts...",
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
          _buildPostComposer(),
          // Expanded Posts List
          Expanded(child: _buildPostsList()),


        ],
      ),
    );
  }

  Widget _buildPostComposer() {
    return Container(
      margin: const EdgeInsets.only(top: 26, bottom: 26, left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration.copyWith(
        color: Colors.white.withOpacity(0.95),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Post',
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _postController,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    hintStyle: TextStyle(
                      color: secondaryColor.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: backgroundColor.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Space between the TextFormField and button
              ElevatedButton(
                onPressed: _addPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send_rounded, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('forums')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          );
        }

        // Get all posts
        final posts = snapshot.data!.docs;

        // Apply search filter
        final filteredPosts = posts.where((post) {
          final postText = post['content'].toString().toLowerCase();
          return postText.contains(searchQuery);
        }).toList();

        // If no results after filtering
        if (filteredPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 64,
                  color: primaryColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isEmpty
                      ? "No posts yet. Start the conversation!"
                      : "No matching posts found.",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) => _buildForumPost(filteredPosts[index]),
        );
      },
    );
  }


  Widget _buildForumPost(DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;

    // Fetch timestamp
    final Timestamp? timestamp = data['timestamp'];
    String formattedTime = 'Time not available';

    if (timestamp != null) {
      DateTime postDate = timestamp.toDate();
      DateTime now = DateTime.now();

      if (postDate.year == now.year &&
          postDate.month == now.month &&
          postDate.day == now.day) {
        formattedTime = DateFormat.jm().format(postDate); // "2:30 PM"
      } else if (postDate.year == now.year) {
        formattedTime = DateFormat('MMM d').format(postDate); // "Apr 1"
      } else {
        formattedTime = DateFormat('yMMM').format(postDate); // "Apr 2024"
      }
    }

    print("Post ID: ${post.id}, Timestamp: $timestamp, Formatted Time: $formattedTime"); // Debugging log

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display timestamp here
                Text(
                  formattedTime,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  data['content'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor.withOpacity(0.9),
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String postId, String reportedUserId,
      String reportedUserName) {
    final TextEditingController _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Report Post", style: TextStyle(color: primaryColor),),
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
                  _sendReport(postId, reportedUserId,
                      reason); // Pass all three arguments
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Please provide a reason for reporting.'),
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
  Future<void> _addPost() async {
    if (_postController.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('forums').add({
        'content': _postController.text.trim(),
        'thumbsUp': [],
        'thumbsDown': [],
        'comments': [],
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser!.uid,
      });
      _postController.clear();
    } catch (e) {
      print("Error adding post: $e");
    }
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required int count,
    required bool active,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: active ? primaryColor : secondaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: secondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleThumbs(String postId, List<String> thumbsUp, List<String> thumbsDown, String currentUserId, bool isThumbsUp) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('forums').doc(postId);

      if (isThumbsUp) {
        if (thumbsUp.contains(currentUserId)) {
          await postRef.update({
            'thumbsUp': FieldValue.arrayRemove([currentUserId]),
          });
        } else {
          await postRef.update({
            'thumbsUp': FieldValue.arrayUnion([currentUserId]),
            'thumbsDown': FieldValue.arrayRemove([currentUserId]), // Remove from thumbsDown if already there
          });
        }
      } else {
        if (thumbsDown.contains(currentUserId)) {
          await postRef.update({
            'thumbsDown': FieldValue.arrayRemove([currentUserId]),
          });
        } else {
          await postRef.update({
            'thumbsDown': FieldValue.arrayUnion([currentUserId]),
            'thumbsUp': FieldValue.arrayRemove([currentUserId]), // Remove from thumbsUp if already there
          });
        }
      }

    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  Future<void> _confirmDeletePost(String postId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Post',
          style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(color: secondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
            child: Text('Delete', style: TextStyle(color: Color(0XFFC5D0D3))),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _deletePost(postId);
    }
  }

  void _showCommentsPage(String postId) {
    final TextEditingController _commentController = TextEditingController();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            Scaffold(
              appBar: AppBar(
                backgroundColor: primaryColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  'Comments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                shape: RoundedRectangleBorder(
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
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                                color: primaryColor),
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
                                SizedBox(height: 16),
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
                                child: CircularProgressIndicator(
                                    color: primaryColor),
                              );
                            }

                            final enrichedComments = enrichedSnapshot.data!;

                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: enrichedComments.length,
                              separatorBuilder: (context, index) =>
                                  Divider(
                                    color: Colors.grey.shade300,
                                    height: 16,
                                  ),
                              itemBuilder: (context, index) {
                                final comment = enrichedComments[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: backgroundColor,
                                        backgroundImage: (comment['userType'] ==
                                            'Lawyer' &&
                                            comment['profilephotourl'] !=
                                                null &&
                                            comment['profilephotourl']
                                                .isNotEmpty)
                                            ? NetworkImage(
                                            comment['profilephotourl'])
                                            : null,
                                        child: (comment['userType'] !=
                                            'Lawyer' ||
                                            comment['profilephotourl'] ==
                                                null ||
                                            comment['profilephotourl'].isEmpty)
                                            ? Icon(
                                          Icons.person,
                                          color: primaryColor,
                                          size: 24,
                                        )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Text(
                                                  comment['userType'] ==
                                                      'Lawyer'
                                                      ? comment['userName'] ??
                                                      'Lawyer'
                                                      : 'Anonymous',
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    if (comment['userId'] ==
                                                        _auth.currentUser!.uid)
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.delete_outline,
                                                          color: secondaryColor,
                                                          size: 20,
                                                        ),
                                                        onPressed: () =>
                                                            _confirmDeleteComment(
                                                                postId,
                                                                comment),
                                                      ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.report_outlined,
                                                        color: secondaryColor.withOpacity(0.7),
                                                      ),
                                                      onPressed: () => _showCommentReportDialog(
                                                        postId,
                                                        comment['userId'],
                                                        comment['userName'] ?? 'User',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              comment['comment'] ?? '',
                                              style: TextStyle(
                                                color: primaryColor.withOpacity(
                                                    0.8),
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
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
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          backgroundColor: primaryColor,
                          child: IconButton(
                            icon: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () async {
                              if (_commentController.text.trim().isNotEmpty) {
                                final newComment = {
                                  'userType': 'Anonymous',
                                  'comment': _commentController.text.trim(),
                                  'userId': _auth.currentUser!.uid,
                                };
                                await _addComment(postId, newComment);
                                _commentController.clear();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _addComment(String postId,
      Map<String, dynamic> newComment) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('forums').doc(
          postId);
      await postRef.update({
        'comments': FieldValue.arrayUnion([newComment]),
      });
    } catch (e) {
      print("Error adding comment: $e");
    }
  }






  Future<void> _confirmDeleteComment(String postId, Map<String, dynamic> comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Comment',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: secondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
            child: Text('Delete', style: TextStyle(color: Color(0XFFC5D0D3))),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _deleteComment(postId, comment);
    }
  }

  Future<List<Map<String, dynamic>>> _enrichCommentsWithProfilePhoto(List<Map<String, dynamic>> comments) async {
    final lawyersRef = FirebaseFirestore.instance.collection('lawyer');

    for (var comment in comments) {
      if (comment['userType'] == 'Lawyer') {
        try {
          final lawyerDoc = await lawyersRef.doc(comment['userId']).get();
          if (lawyerDoc.exists) {
            comment['profilephotourl'] = lawyerDoc['profilephotourl'] ?? '';
          }
        } catch (e) {
          print('Error fetching lawyer profile: $e');
        }
      }
    }
    return comments;
  }

  void _showCommentReportDialog(String postId, String reportedUserId, String reportedUserName) {
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
                  _sendCommentReport(postId, reportedUserId, reason);
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




  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('forums').doc(postId).delete();
      print('Post deleted successfully');
    } catch (e) {
      print('Error deleting post: $e');
    }
  }
  Future<void> _deleteComment(String postId, Map<String, dynamic> comment) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('forums').doc(postId);

      await postRef.update({
        'comments': FieldValue.arrayRemove([comment])
      });

      print('Comment deleted successfully');
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

}

