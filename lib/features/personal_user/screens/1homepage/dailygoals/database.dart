import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/task.dart';

class ToDoDataBase {
  List<Task> toDoList = [];

  // Reference our boxes
  final _tasksBox = Hive.box<Task>('tasksBox');
  final _myBox = Hive.box('mybox');

  // Run this method if this is the first time ever opening the app
  void createInitialData() {
    final now = DateTime.now();
    toDoList = [
      Task(
        title: 'Morning Meditation',
        isCompleted: false,
        date: now,
        category: 'Mindfulness',
      ),
      Task(
        title: 'Read a book/novel',
        isCompleted: false,
        date: now,
        category: 'Self-Care',
      ),
      Task(
        title: 'Drink 8 glasses of water',
        isCompleted: false,
        date: now,
        category: 'Health',
      ),
      Task(
        title: 'Write in daily journal',
        isCompleted: false,
        date: now,
        category: 'Mindfulness',
      ),
    ];
    updateDataBase();
  }

  // Load the data from the database
  void loadData() {
    if (_tasksBox.isNotEmpty) {
      toDoList = _tasksBox.values.toList();
    } else {
      // Check if there is old data to migrate
      final oldList = _myBox.get('TODOLIST');
      if (oldList != null && oldList is List && oldList.isNotEmpty) {
        final now = DateTime.now();
        for (var item in oldList) {
          if (item is List && item.length >= 2) {
            final title = item[0]?.toString() ?? '';
            final isCompleted = item[1] == true;
            final task = Task(
              title: title,
              isCompleted: isCompleted,
              date: now,
              category: 'Personal',
            );
            toDoList.add(task);
          }
        }
        updateDataBase();
        // Clean up legacy key so migration only runs once
        _myBox.delete('TODOLIST');
      } else {
        createInitialData();
      }
    }
  }

  // Update the database 
  void updateDataBase() {
    _tasksBox.clear();
    _tasksBox.addAll(toDoList);
  }
}
