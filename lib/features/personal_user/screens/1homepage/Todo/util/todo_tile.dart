import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
// import 'package:Todo/models/task.dart';

class TodoTile extends StatelessWidget {
  final String taskName;
  final bool taskCompleted;
  final Function(bool?) onChanged;
  final Function(BuildContext) deleteFunction;
  final Color containerColor;
  final VoidCallback? onEdit;

  final List<dynamic> task; // <-- Change from Task to List<dynamic>

  const TodoTile({
    super.key,
    required this.taskName,
    required this.taskCompleted,
    required this.onChanged,
    required this.deleteFunction,
    required this.containerColor,
    this.onEdit,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(taskName),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              if (onEdit != null) onEdit!();
            },
            backgroundColor: const Color.fromARGB(255, 147, 39, 248),
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => deleteFunction(context),
            backgroundColor: const Color.fromARGB(255, 204, 29, 29),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Checkbox(value: taskCompleted, onChanged: onChanged),
            Expanded(
              child: Text(
                taskName,
                style: TextStyle(
                    decoration: taskCompleted ? TextDecoration.lineThrough : null,
                    decorationThickness: taskCompleted ? 2 : null,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: const Color.fromARGB(255, 147, 39, 248)),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: const Color.fromARGB(255, 204, 29, 29)),
              onPressed: () => deleteFunction(context),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedTodoTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onRemove;

  const AnimatedTodoTile({
    super.key,
    required this.child,
    required this.onRemove,
  });

  @override
  State<AnimatedTodoTile> createState() => _AnimatedTodoTileState();
}

class _AnimatedTodoTileState extends State<AnimatedTodoTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0,
    );
  }

  void animateRemove() async {
    await _controller.reverse();
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _controller, child: widget.child);
  }
}
// final List<List<dynamic>> taskList = db.toDoList;