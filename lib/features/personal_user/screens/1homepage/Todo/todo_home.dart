// import 'package:Todo/models/task.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:mindsarthi/features/personal_user/screens/1homepage/Todo/data/database.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Todo/util/analytics_helper.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Todo/util/dialog_box.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Todo/util/progress_card.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Todo/util/todo_tile.dart';
import 'widgets/insights_screen.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    ['Read Existing Novels in Lib', false],
    ['Home Chores', false],
    ['CAT prep', false],
    ['Watch Movies', false],
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
      backgroundColor:
          Colors.transparent, // Make scaffold background transparent
      appBar: AppBar(
        title: const Text('Todo App'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8E2DE2), // Purple
                Color.fromARGB(255, 33, 51, 243), // Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Colors.deepOrangeAccent,),
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
        backgroundColor: Colors.transparent,
        elevation: 0, // Remove shadow
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 244, 197, 213), // Your main color
              Color.fromARGB(255, 255, 240, 245), // A lighter, soft pink
              Color.fromARGB(
                255,
                222,
                160,
                200,
              ), // A gentle purple-pink for depth
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                      // Add a scrollbar to the ListView
                      child: Scrollbar(
                        thumbVisibility: true, // Show scrollbar thumb
                        thickness: 8, // Thickness of the scrollbar thumb
                        interactive:
                            true, // Allow interaction with the scrollbar
                        radius: Radius.circular(
                          10,
                        ), // Rounded corners for the scrollbar thumb

                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: db.toDoList.length,
                          itemBuilder: (context, index) {
                            // Define two sets of gradient colors for alternation
                            final List<Color> gradient1 = [
                              const Color.fromARGB(255, 249, 124, 151),
                              const Color.fromARGB(255, 248, 164, 116),
                            ];
                            final List<Color> gradient2 = [
                              const Color.fromARGB(255, 252, 149, 195),
                              const Color.fromARGB(255, 248, 94, 150),
                            ];

                            final List<Color> selectedGradient = index % 2 == 0
                                ? gradient1
                                : gradient2;

                            final borderRadius = BorderRadius.circular(32);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ), // <-- OUTSIDE Dismissible
                              child: ClipRRect(
                                borderRadius: borderRadius,
                                child: Dismissible(
                                  key: ValueKey(
                                    db.toDoList[index][0] + index.toString(),
                                  ),
                                  direction: DismissDirection.horizontal,
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          selectedGradient[0], // tile left color
                                          selectedGradient[1], // tile right color
                                          Color.lerp(
                                            selectedGradient[1],
                                            Color(0xFF8E2DE2),
                                            0.5,
                                          )!, // blend color
                                          const Color(
                                            0xFF8E2DE2,
                                          ), // edit button color
                                        ],
                                        stops: [0.0, 0.7, 0.85, 1.0],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: borderRadius,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: const [
                                        SizedBox(width: 24),
                                        Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Edit",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerRight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          selectedGradient[1], // tile right color
                                          selectedGradient[0], // tile left color
                                          Color.lerp(
                                            selectedGradient[0],
                                            Color(0xFFE53935),
                                            0.5,
                                          )!, // blend color
                                          const Color(
                                            0xFFE53935,
                                          ), // delete button color
                                        ],
                                        stops: [0.0, 0.7, 0.85, 1.0],
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft,
                                      ),
                                      borderRadius: borderRadius,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: const [
                                        Text(
                                          "Delete",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                        SizedBox(width: 24),
                                      ],
                                    ),
                                  ),
                                  onDismissed: (direction) {
                                    if (direction ==
                                        DismissDirection.endToStart) {
                                      deleteTask(context, index);
                                    } else if (direction ==
                                        DismissDirection.startToEnd) {
                                      editTask(index);
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: selectedGradient,
                                        stops: [0.0, 1.0],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: borderRadius,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: Offset(0, 6),
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: TodoTile(
                                      taskName: db.toDoList[index][0],
                                      taskCompleted: db.toDoList[index][1],
                                      onChanged: (value) {
                                        checkboxChanged(value, index);
                                      },
                                      deleteFunction: (context) =>
                                          deleteTask(context, index),
                                      containerColor: Colors.transparent,
                                      onEdit: () => editTask(index),
                                      task: db.toDoList[index], // Just pass the list
                                    ),
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
                      backgroundColor: const Color.fromARGB(255, 204, 53, 189),
                      foregroundColor: Colors.black,
                      child: Icon(Icons.add, color: Colors.black),
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
                      backgroundColor: const Color.fromARGB(255, 204, 53, 189),
                      foregroundColor: Colors.black,
                      child: Icon(Icons.add, color: Colors.black),
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
