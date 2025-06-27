import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ToDoDataBase {
  List<Map<String, dynamic>> toDoList = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Load data from Firestore sub-collection
  Future<void> loadData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .get();

      toDoList = snapshot.docs.map((doc) {
        return {
          'taskName': doc['taskName'] ?? '',
          'completed': doc['completed'] ?? false,
          'docId': doc.id,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  // Add a new task
  Future<void> addTask(String taskName) async {
    final user = _auth.currentUser;
    if (user == null || taskName.isEmpty) return;

    try {
      DocumentReference docRef = await _firestore
          .collection("users")
          .doc(user.uid)
          .collection('goals')
          .add({'taskName': taskName, 'completed': false});

      toDoList.add({
        'taskName': taskName,
        'completed': false,
        'docId': docRef.id,
      });
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  // Update an existing task
  Future<void> updateTask(int index, bool completed) async {
    final user = _auth.currentUser;
    if (user == null || index < 0 || index >= toDoList.length) return;

    try {
      String docId = toDoList[index]['docId'];
      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection('goals')
          .doc(docId)
          .update({'completed': completed});

      toDoList[index]['completed'] = completed;
    } catch (e) {
      debugPrint('Error updating task: $e');
    }
  }

  // Delete a task
  Future<void> deleteTask(int index) async {
    final user = _auth.currentUser;
    if (user == null || index < 0 || index >= toDoList.length) return;

    try {
      String docId = toDoList[index]['docId'];
      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection('goals')
          .doc(docId)
          .delete();

      toDoList.removeAt(index);
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  // Get tasks as a real-time stream
  Stream<List<Map<String, dynamic>>> getTasksStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection("users")
        .doc(user.uid)
        .collection('goals')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                'taskName': doc['taskName'] ?? '',
                'completed': doc['completed'] ?? false,
                'docId': doc.id,
              };
            }).toList());
  }
}
