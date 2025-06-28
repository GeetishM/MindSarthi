import 'package:flutter/material.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/data/database.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/util/dialog_box.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/util/todo_tile.dart';


class TodaysGoals extends StatefulWidget {
  const TodaysGoals({Key? key}) : super(key: key);

  @override
  State<TodaysGoals> createState() => _TodaysGoalsState();
}

class _TodaysGoalsState extends State<TodaysGoals> {
  final ToDoDataBase db = ToDoDataBase();
  final TextEditingController _controller = TextEditingController();

  void createNewTask() {
    showDialog(
      context: context,
      builder: (context) => DialogBox(
        controller: _controller,
        onSave: () {
          db.addTask(_controller.text);
          setState(() {});
          _controller.clear();
          Navigator.of(context).pop();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Goals")),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.getTasksStream(),
        builder: (context, snapshot) => snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final task = snapshot.data![index];
                  return ToDoTile(
                    taskName: task['taskName'],
                    taskCompleted: task['completed'],
                    onChanged: (value) => db.updateTask(index, value!),
                    deleteFunction: (context) => db.deleteTask(index),
                  );
                },
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
