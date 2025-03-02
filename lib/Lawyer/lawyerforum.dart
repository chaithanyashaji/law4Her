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
  final Color primaryColor = const Color(0xFF1e1e2a); // Dark theme primary color
  final Color secondaryColor = const Color(0xFF7d444f); // Secondary color
  final Color backgroundColor = const Color(0xFF44404d); // Background color

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e1e2a), // Dark background
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text(
          'Lawyer Forum',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color(0xFF1e1e2a),
      body: Column(
        children: [
          // Forum Posts Section
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

  // Build Forum Post Widget
  Widget _buildForumPost(DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
    final likes = List<String>.from(data['likes'] ?? []);
    final currentUserId = _auth.currentUser!.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF44404d),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF44404d)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Content
          Text(
            data['content'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF1e1e2a), thickness: 1),
          const SizedBox(height: 8),
          // Like and Comment Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _toggleLike(post.id, likes, currentUserId),
                child: Row(
                  children: [
                    Icon(
                      likes.contains(currentUserId)
                          ? Icons.thumb_up
                          : Icons.thumb_up_alt_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${likes.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${comments.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (data['userId'] == currentUserId)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeletePost(post.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Confirm Delete Post
  Future<void> _confirmDeletePost(String postId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: const Text(
          'Delete Post',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: secondaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _deletePost(postId);
    }
  }

  // Delete Post
  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('forums').doc(postId).delete();
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  // Toggle Like
  Future<void> _toggleLike(
      String postId, List<String> likes, String currentUserId) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('forums').doc(postId);

      if (likes.contains(currentUserId)) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([currentUserId]),
        });
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  // Show Comments Page
  void _showCommentsPage(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(postId: postId),
      ),
    );
  }
}

class CommentsPage extends StatelessWidget {
  final String postId;

  CommentsPage({required this.postId});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _commentController = TextEditingController();
    final FirebaseAuth _auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e1e2a),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text(
          'Comments',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color(0xFF1e1e2a),
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

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _buildCommentCard(comment);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: const TextStyle(color: Color(0xFF7b7794)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: Color(0xFF44404d)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: Color(0xFF44404d)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final user = _auth.currentUser;

                    if (user == null) return;

                    final lawyerDoc = await FirebaseFirestore.instance
                        .collection('lawyer')
                        .doc(user.uid)
                        .get();

                    final name = lawyerDoc.exists
                        ? lawyerDoc['name'] ?? 'Lawyer'
                        : 'Lawyer';

                    final newComment = {
                      'userName': name,
                      'userType': 'Lawyer',
                      'comment': _commentController.text.trim(),
                      'userId': user.uid,
                    };

                    if (_commentController.text.trim().isNotEmpty) {
                      _commentController.clear();
                      await FirebaseFirestore.instance
                          .collection('forums')
                          .doc(postId)
                          .update({
                        'comments': FieldValue.arrayUnion([newComment]),
                      });
                    }
                  },
                  child: const Text(
                    'Comment',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF44404d),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF44404d),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFF44404d)),
      ),
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
                  color: Colors.white,
                ),
              ),
              if (comment['userId'] == FirebaseAuth.instance.currentUser!.uid)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('forums')
                        .doc(postId)
                        .update({
                      'comments': FieldValue.arrayRemove([comment]),
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment['comment'] ?? '',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}