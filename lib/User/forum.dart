import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumPage extends StatefulWidget {
  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Define theme colors
  final Color primaryColor = const Color(0xFF416d6d);
  final Color secondaryColor = const Color(0xFF608e8e);
  final Color backgroundColor = const Color(0xFFc5d0d3);

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _addPost() async {
    if (_postController.text
        .trim()
        .isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('forums').add({
        'content': _postController.text.trim(),
        'likes': [],
        'comments': [],
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser!.uid,
      });
      _postController.clear();
    } catch (e) {
      print("Error adding post: $e");
    }
  }

  Future<void> _toggleLike(String postId, List<String> likes,
      String currentUserId) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('forums').doc(
          postId);

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

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('forums')
          .doc(postId)
          .delete();
    } catch (e) {
      print("Error deleting post: $e");
    }
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

  Future<void> _deleteComment(String postId,
      Map<String, dynamic> comment) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('forums').doc(
          postId);
      await postRef.update({
        'comments': FieldValue.arrayRemove([comment]),
      });
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }

  // Method to confirm post deletion
  Future<void> _confirmDeletePost(String postId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(
              'Delete Post',
              style: TextStyle(
                  color: primaryColor, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete this post?',
              style: TextStyle(color: secondaryColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: primaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                ),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      _deletePost(postId);
    }
  }

// Method to confirm comment deletion
  Future<void> _confirmDeleteComment(String postId,
      Map<String, dynamic> comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(
              'Delete Comment',
              style: TextStyle(
                  color: primaryColor, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete this comment?',
              style: TextStyle(color: secondaryColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: primaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                ),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      _deleteComment(postId, comment);
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
            color: active ? secondaryColor : secondaryColor,
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

  Widget _buildForumPost(DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
    final likes = List<String>.from(data['likes'] ?? []);
    final currentUserId = _auth.currentUser!.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              data['content'] ?? '',
              style: TextStyle(
                fontSize: 16,
                color: primaryColor,
                height: 1.5,
              ),
            ),
          ),
          Divider(height: 1, color: backgroundColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  onTap: () => _toggleLike(post.id, likes, currentUserId),
                  icon: likes.contains(currentUserId)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  count: likes.length,
                  active: likes.contains(currentUserId),
                ),
                _buildActionButton(
                  onTap: () => _showCommentsPage(post.id),
                  icon: Icons.chat_bubble_outline,
                  count: comments.length,
                  active: false,
                ),
                if (data['userId'] == currentUserId)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: secondaryColor.withOpacity(0.7)),
                    onPressed: () => _confirmDeletePost(post.id),

                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 2,
        centerTitle: true,
        title: Text(
          'Forum',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _postController,
                    style: TextStyle(color: primaryColor),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      hintStyle: TextStyle(
                          color: secondaryColor.withOpacity(0.7)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                ElevatedButton(
                  onPressed: _addPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forums')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return Center(
                    child: Text(
                      "No posts yet. Be the first to share!",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                      ),
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

  void _showCommentsPage(String postId) {
    final TextEditingController _commentController = TextEditingController();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            elevation: 2,
            centerTitle: true,
            title: const Text(
              'Comments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
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
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    }

                    final comments = List<Map<String, dynamic>>.from(
                        snapshot.data!['comments'] ?? []);

                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments yet. Start the conversation!',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    // Fetch lawyer profile photos for comments dynamically
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _enrichCommentsWithProfilePhoto(comments),
                      builder: (context, enrichedSnapshot) {
                        if (!enrichedSnapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(color: primaryColor),
                          );
                        }

                        final enrichedComments = enrichedSnapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: enrichedComments.length,
                          itemBuilder: (context, index) {
                            final comment = enrichedComments[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: backgroundColor,
                                    backgroundImage: (comment['userType'] == 'Lawyer' &&
                                        comment['profilephotourl'] != null &&
                                        comment['profilephotourl'].isNotEmpty)
                                        ? NetworkImage(comment['profilephotourl'])
                                        : null,
                                    child: (comment['userType'] != 'Lawyer' ||
                                        comment['profilephotourl'] == null ||
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
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              comment['userType'] == 'Lawyer'
                                                  ? comment['userName'] ??
                                                  'Lawyer'
                                                  : 'Anonymous',
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (comment['userId'] ==
                                                _auth.currentUser!.uid)
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: secondaryColor
                                                      .withOpacity(0.7),
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    _confirmDeleteComment(
                                                        postId, comment),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          comment['comment'] ?? '',
                                          style: TextStyle(
                                            color: primaryColor.withOpacity(0.8),
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
                  color: secondaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
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
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(
                              color: secondaryColor.withOpacity(0.7)),
                          filled: true,
                          fillColor: backgroundColor.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  Future<List<Map<String, dynamic>>> _enrichCommentsWithProfilePhoto(
      List<Map<String, dynamic>> comments) async {
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

}


