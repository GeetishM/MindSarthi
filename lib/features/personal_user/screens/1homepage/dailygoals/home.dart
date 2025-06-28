// import 'package:Todo/models/task.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/analytics_helper.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/database.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/dialog_box.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/insights_screen.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/progress_card.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/todo_tile.dart';


class TodaysGoals extends StatefulWidget {
  const TodaysGoals({super.key, required Box box});

  @override
  State<TodaysGoals> createState() => _TodaysGoalsState();
}

class _TodaysGoalsState extends State<TodaysGoals> {
  // reference the Hive box 
  final _myBox = Hive.box('mybox');
  ToDoDataBase db = ToDoDataBase();

  @override
  void initState() {
    // if this is the first time opening the app, create initial / default data
    if (_myBox.get('TODOLIST') == null) {
      db.createInitialData();
    } else {
      // there already exists data
      db.loadData(); // load existing data
    }
    // Load FAB position if saved
    final fabPos = _myBox.get('FAB_POSITION');
    if (fabPos != null && fabPos is List && fabPos.length == 2) {
      fabPosition = Offset(fabPos[0], fabPos[1]);
    }
    super.initState();
  }

  // text controller
  final _controller = TextEditingController();

 /* Hardcoded / initial list of todo tasks
  List toDoList = [
    ['Wake up', false],
    ['Drink Water', false],
  ];
 */ 

  // checkbox was tapped
  void checkboxChanged(bool? value, int index) {
    setState(() {
      db.toDoList[index][1] = !db.toDoList[index][1];
    });
    db.updateDataBase(); // update the database
  }

  // save new task
  void saveNewTask() {
    setState(() {
      db.toDoList.add([_controller.text, false]); // add new task to the list
      _controller.clear(); // clear the text field
    });
    Navigator.of(context).pop(); // close the dialog
    db.updateDataBase(); // update the database
  }

  // create a new task
  void createNewTask() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dialog",
      transitionDuration: Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => DialogBox(
        controller: _controller,
        onSave: saveNewTask,
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  // edit task
  void editTask(int index) {
    final editController = TextEditingController(text: db.toDoList[index][0]);
    showDialog(
      context: context,
      builder: (context) => DialogBox(
        controller: editController,
        onSave: () {
          setState(() {
            db.toDoList[index][0] = editController.text;
          });
          Navigator.of(context).pop();
          db.updateDataBase();
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // delete task
  void deleteTask(BuildContext context, int index) {
    setState(() {
      db.toDoList.removeAt(index);
    });
    db.updateDataBase(); // update the database
  }

  Offset fabPosition = Offset(300, 600);
  
  
  @override
  Widget build(BuildContext context) {
    // calculate completed tasks
    int completed = db.toDoList.where((task) => task[1] == true).length;
    int total = db.toDoList.length;

    // Get paddings and app bar height here
    final double fabSize = 56;
    final double margin = 16;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double appBarHeight = kToolbarHeight; // Default AppBar height

    final today = DateTime.now();
    final List<List<dynamic>> taskList = db.toDoList.cast<List<dynamic>>();
    final dailyTaskCount = AnalyticsHelper.dailyTaskCountFromDb(taskList, today);
    final percentCompleted = AnalyticsHelper.completedTaskCount(taskList) / (taskList.isEmpty ? 1 : taskList.length);
    final reschedules = 0; // Not tracked in List<List<dynamic>>
    final selfCareCount = 0; // Not tracked in List<List<dynamic>>

    return Scaffold(
      backgroundColor: Colors.grey.shade300, // Changed from gradient to white
      appBar: AppBar(
        title: const Text('Daily Goals'),
        // Comment out the gradient flexibleSpace
        // flexibleSpace: Container(
        //   decoration: const BoxDecoration(
        //     gradient: LinearGradient(
        //       colors: [
        //         Color(0xFF8E2DE2), // Purple
        //         Color.fromARGB(255, 33, 51, 243), // Blue
        //       ],
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //     ),
        //   ),
        // ),
        backgroundColor: Colors.deepPurpleAccent[200], // Use purple accent
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          // fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Colors.deepOrangeAccent),
            tooltip: 'Insights',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InsightsScreen(
                    dailyTaskCount: dailyTaskCount,
                    percentCompleted: percentCompleted,
                    reschedules: reschedules,
                    selfCareCount: selfCareCount,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // Changed from gradient to white
        // decoration: const BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [
        //       Color.fromARGB(255, 244, 197, 213),
        //       Color.fromARGB(255, 255, 240, 245),
        //       Color.fromARGB(255, 222, 160, 200),
        //     ],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        // ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate boundaries based on the available space
            final double minX = margin;
            final double maxX = constraints.maxWidth - fabSize - margin;
            final double minY = appBarHeight + topPadding + margin;
            final double maxY =
                constraints.maxHeight - fabSize - bottomPadding - margin;

            // Clamp the FAB position to always stay within bounds
            final Offset clampedFabPosition = Offset(
              fabPosition.dx.clamp(minX, maxX),
              fabPosition.dy.clamp(minY, maxY),
            );

            return Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ProgressCard(
                        completed: completed,
                        total: total,
                        title: "Daily Progress",
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        thickness: 8,
                        interactive: true,
                        radius: Radius.circular(10),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: db.toDoList.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.deepPurpleAccent[100]!,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08), // Softer shadow, similar to Insights
                                      blurRadius: 16, // More blur for card-like elevation
                                      offset: Offset(0, 6), // Slightly less offset for a subtle lift
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  leading: Checkbox(
                                    value: db.toDoList[index][1],
                                    onChanged: (value) {
                                      checkboxChanged(value, index);
                                    },
                                  ),
                                  title: Text(
                                    db.toDoList[index][0],
                                    style: TextStyle(
                                      decoration: db.toDoList[index][1]
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                        decorationThickness: 2,
                                      color: Colors.black87,
                                      fontSize: 18,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.deepPurpleAccent),
                                        onPressed: () => editTask(index),
                                        tooltip: "Edit",
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () => deleteTask(context, index),
                                        tooltip: "Delete",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                // Movable Floating Action Button
                Positioned(
                  left: clampedFabPosition.dx,
                  top: clampedFabPosition.dy,
                  child: Draggable(
                    feedback: FloatingActionButton(
                      onPressed: createNewTask,
                      backgroundColor: Colors.deepPurpleAccent[200], // Purple accent
                      foregroundColor: Colors.white,
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                    childWhenDragging: Container(),
                    onDragEnd: (details) {
                      final Offset localOffset =
                          details.offset -
                          Offset(0, MediaQuery.of(context).padding.top);

                      final double newX = localOffset.dx.clamp(minX, maxX);
                      final double newY = localOffset.dy.clamp(minY, maxY);

                      setState(() {
                        fabPosition = Offset(newX, newY);
                      });
                      // Save FAB position to Hive
                      _myBox.put('FAB_POSITION', [
                        fabPosition.dx,
                        fabPosition.dy,
                      ]);
                    },
                    child: FloatingActionButton(
                      onPressed: createNewTask,
                      backgroundColor: Colors.deepPurpleAccent[200], // Purple accent
                      foregroundColor: Colors.white,
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
