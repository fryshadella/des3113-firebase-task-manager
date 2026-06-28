import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // READ - Get all tasks for current user (realtime stream)
  Stream<QuerySnapshot> getTasks() {
    return _db
        .collection(_collection)
        .where('uid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // CREATE - Add a new task
  Future<void> addTask(String title, String description) async {
    await _db.collection(_collection).add({
      'title': title.trim(),
      'description': description.trim(),
      'createdAt': Timestamp.now(),
      'uid': _uid,
      'isDone': false,
    });
  }

  // UPDATE - Edit an existing task
  Future<void> updateTask(String taskId, String title, String description) async {
    await _db.collection(_collection).doc(taskId).update({
      'title': title.trim(),
      'description': description.trim(),
    });
  }

  // TOGGLE - Mark task as done/undone
  Future<void> toggleDone(String taskId, bool currentStatus) async {
    await _db.collection(_collection).doc(taskId).update({
      'isDone': !currentStatus,
    });
  }

  // DELETE - Remove a task
  Future<void> deleteTask(String taskId) async {
    await _db.collection(_collection).doc(taskId).delete();
  }
}