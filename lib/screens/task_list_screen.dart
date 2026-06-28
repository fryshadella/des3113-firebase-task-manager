import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'login_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _taskService = TaskService();
  final _authService = AuthService();
  String _filter = 'all'; // all, pending, done

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _deleteTask(String taskId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _taskService.deleteTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'User';
    final avatarLetter = email[0].toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFF),

      // SIDEBAR DRAWER
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 28, left: 24, right: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: Text(avatarLetter, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFF5F5FF), borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.email_outlined, color: Color(0xFF6C63FF)),
                    title: const Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(email, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: _taskService.getTasks(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  final total = docs.length;
                  final done = docs.where((d) => (d.data() as Map)['isDone'] == true).length;
                  final pending = total - done;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFFF5F5FF), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.task_alt, color: Color(0xFF6C63FF)),
                            title: const Text('Total Tasks', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            subtitle: Text('$total tasks', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          ListTile(
                            leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                            title: const Text('Completed', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            subtitle: Text('$done tasks', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          ListTile(
                            leading: const Icon(Icons.pending_outlined, color: Colors.orange),
                            title: const Text('Pending', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            subtitle: Text('$pending tasks', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('My Task Manager v1.0', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        title: const Text('My Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: _logout),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _taskService.getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          final allTasks = snapshot.data?.docs ?? [];
          final total = allTasks.length;
          final done = allTasks.where((d) => (d.data() as Map)['isDone'] == true).length;
          final pending = total - done;

          // Filter tasks
          final filteredTasks = allTasks.where((doc) {
            final isDone = (doc.data() as Map)['isDone'] == true;
            if (_filter == 'done') return isDone;
            if (_filter == 'pending') return !isDone;
            return true;
          }).toList();

          return Column(
            children: [
              // DASHBOARD CARDS
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👋 Hello, ${email.split('@')[0]}!',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Here is your task summary', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _summaryCard('Total', total, Icons.list_alt_rounded, Colors.white, const Color(0xFF6C63FF)),
                        const SizedBox(width: 10),
                        _summaryCard('Done', done, Icons.check_circle_rounded, Colors.green, Colors.white),
                        const SizedBox(width: 10),
                        _summaryCard('Pending', pending, Icons.pending_rounded, Colors.orange, Colors.white),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // FILTER TABS
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _filterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _filterChip('Done', 'done'),
                  ],
                ),
              ),

              // TASK LIST
              Expanded(
                child: filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              _filter == 'done' ? 'No completed tasks yet!' : _filter == 'pending' ? 'No pending tasks!' : 'No tasks yet!',
                              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                            ),
                            if (_filter == 'all') Text('Tap + to add your first task', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final doc = filteredTasks[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final title = data['title'] ?? '';
                          final description = data['description'] ?? '';
                          final isDone = data['isDone'] == true;
                          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isDone ? Border.all(color: Colors.green.withOpacity(0.3), width: 1.5) : null,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: GestureDetector(
                                onTap: () => _taskService.toggleDone(doc.id, isDone),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDone ? Colors.green.withOpacity(0.1) : const Color(0xFF6C63FF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                    color: isDone ? Colors.green : const Color(0xFF6C63FF),
                                  ),
                                ),
                              ),
                              title: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  color: isDone ? Colors.grey : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        description,
                                        style: TextStyle(
                                          color: Colors.grey,
                                          decoration: isDone ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (isDone)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text('✓ Completed', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500)),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text('⏳ Pending', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500)),
                                        ),
                                      if (createdAt != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isDone)
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF6C63FF)),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditTaskScreen(taskId: doc.id, currentTitle: title, currentDescription: description),
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteTask(doc.id, title),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen())),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _summaryCard(String label, int count, IconData icon, Color iconColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bgColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: iconColor)),
            Text(label, style: TextStyle(fontSize: 11, color: iconColor.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFFF0EFFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}