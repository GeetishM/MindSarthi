import 'package:hive_flutter/hive_flutter.dart';

class ToDoDataBase {
    List toDoList = [];

    // Reference our box
    final _myBox = Hive.box('mybox');

    // Run this method if this is the first time ever opening the app
    void createInitialData() {
      toDoList = [
        ['Read Existing Novels in Lib', false],
        ['Home Chores', false],
        ['CAT prep', false],
        ['Watch Movies', false],
      ];
    }
    // Load the data from the database
    void loadData() {
      toDoList = _myBox.get('TODOLIST');
    }

    // Update the database 
    void updateDataBase() {
      _myBox.put('TODOLIST', toDoList);
    }
  }

