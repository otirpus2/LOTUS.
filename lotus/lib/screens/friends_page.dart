import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  final Color primaryColor = const Color(0xFF5B4CF0);
  final Color backgroundColor = const Color(0xFFF5F7FF);
  final Color accentColor = const Color(0xFFEEF2FF);

  List friends = [];
  List requests = [];

  bool isLoadingFriends = true;
  bool isLoadingRequests = true;

  final TextEditingController studentIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchFriends();
    fetchRequests();
  }

  String get currentUserId => supabase.auth.currentUser!.id;

  Future<void> fetchFriends() async {
    setState(() => isLoadingFriends = true);
    try {
      final data = await supabase
          .from('friendships')
          .select('*, sender:sender_id(*), receiver:receiver_id(*)')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .eq('status', 'accepted');
      setState(() => friends = data);
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() => isLoadingFriends = false);
  }

  Future<void> fetchRequests() async {
    setState(() => isLoadingRequests = true);
    try {
      final data = await supabase
          .from('friendships')
          .select('*, sender:sender_id(*)')
          .eq('receiver_id', currentUserId)
          .eq('status', 'pending');
      setState(() => requests = data);
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() => isLoadingRequests = false);
  }

  Future<void> sendFriendRequest() async {
    final studentId = studentIdController.text.trim();
    if (studentId.isEmpty) return;

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      if (profile == null) {
        showSnackBar('Student not found');
        return;
      }

      final targetId = profile['id'];
      if (targetId == currentUserId) {
        showSnackBar('You cannot add yourself');
        return;
      }

      final existing = await supabase
          .from('friendships')
          .select()
          .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$targetId),and(sender_id.eq.$targetId,receiver_id.eq.$currentUserId)')
          .maybeSingle();

      if (existing != null) {
        showSnackBar('Friendship already exists or pending');
        return;
      }

      await supabase.from('friendships').insert({
        'sender_id': currentUserId,
        'receiver_id': targetId,
        'status': 'pending',
      });

      studentIdController.clear();
      showSnackBar('Friend request sent');
    } catch (e) {
      showSnackBar(e.toString());
    }
  }

  Future<void> acceptRequest(String friendshipId) async {
    try {
      await supabase
          .from('friendships')
          .update({'status': 'accepted'}).eq('id', friendshipId);
      showSnackBar('Friend request accepted');
      fetchFriends();
      fetchRequests();
    } catch (e) {
      showSnackBar(e.toString());
    }
  }

  Future<void> rejectRequest(String friendshipId) async {
    try {
      await supabase.from('friendships').delete().eq('id', friendshipId);
      showSnackBar('Friend request rejected');
      fetchRequests();
    } catch (e) {
      showSnackBar(e.toString());
    }
  }

  Future<void> removeFriend(String friendshipId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Remove Friend', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to remove this friend?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      await supabase.from('friendships').delete().eq('id', friendshipId);
      
      // Update local state immediately to ensure UI doesn't flicker or show old data
      setState(() {
        friends.removeWhere((f) => f['id'] == friendshipId);
      });

      showSnackBar('Friend removed');
      fetchFriends(); // Fetch from server to stay in sync
    } catch (e) {
      showSnackBar(e.toString());
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: primaryColor,
      ),
    );
  }

  Widget buildFriendTile(dynamic friendship) {
    final sender = friendship['sender'];
    final receiver = friendship['receiver'];
    final friend = sender['id'] == currentUserId ? receiver : sender;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: primaryColor,
            child: Text(
              (friend['username'] ?? friend['full_name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['username'] ?? friend['full_name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  friend['student_id'] ?? '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.chat_bubble_outline, color: primaryColor, size: 22),
          ),
          IconButton(
            onPressed: () => removeFriend(friendship['id']),
            icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent, size: 22),
          ),
        ],
      ),
    );
  }

  Widget buildRequestTile(dynamic request) {
    final sender = request['sender'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor,
                child: Text(
                  (sender['username'] ?? sender['full_name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sender['username'] ?? sender['full_name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      sender['student_id'] ?? '',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => acceptRequest(request['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => rejectRequest(request['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Friends',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'My Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Add New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: isLoadingFriends
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : friends.isEmpty
                ? const Center(child: Text('No friends yet', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) => buildFriendTile(friends[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isLoadingRequests
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : requests.isEmpty
                ? const Center(child: Text('No incoming requests', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) => buildRequestTile(requests[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add a Friend",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter the Student ID of the person you'd like to add.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: studentIdController,
                  decoration: InputDecoration(
                    hintText: 'Student ID',
                    prefixIcon: Icon(Icons.badge_outlined, color: primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: sendFriendRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                      shadowColor: primaryColor.withValues(alpha: 0.3),
                    ),
                    child: const Text(
                      'Send Friend Request',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}
