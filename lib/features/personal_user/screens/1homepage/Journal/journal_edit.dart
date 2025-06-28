import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'journal_entry.dart';

class JournalEdit extends StatefulWidget {
  final JournalEntry entry;
  final int index;
  const JournalEdit({super.key, required this.entry, required this.index});

  @override
  State<JournalEdit> createState() => _JournalEditState();
}

class _JournalEditState extends State<JournalEdit> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late List<String> _tags;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
    _tagController = TextEditingController();
    _tags = List<String>.from(widget.entry.tag);

    _titleController.addListener(_markUnsaved);
    _contentController.addListener(_markUnsaved);
  }

  void _markUnsaved() {
    setState(() => _hasUnsavedChanges = true);
  }

  void _save() {
    widget.entry.title = _titleController.text.trim();
    widget.entry.content = _contentController.text.trim();
    widget.entry.tag = _tags;
    widget.entry.lastEdited = DateTime.now();
    widget.entry.save();
    _hasUnsavedChanges = false;
    Navigator.pop(context);
  }

  // ignore: unused_element
  Future<bool> _onWillPop() async {
    if (_tagController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("You've typed a tag. Add it before leaving?"),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Add',
            onPressed: () => _addTag(_tagController.text.trim()),
          ),
        ),
      );
      return false;
    } else if (_hasUnsavedChanges) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('Do you want to save before exiting?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                _save();
                Navigator.pop(context, true);
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
          'Are you sure you want to delete this journal entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteEntryWithUndo();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteEntryWithUndo() async {
    final box = Hive.box<JournalEntry>('journalBox');
    final deletedEntry = widget.entry;
    final deletedIndex = widget.index;

    await deletedEntry.delete();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Entry deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await box.putAt(deletedIndex, deletedEntry);
            setState(() {});
          },
        ),
      ),
    );
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
        _hasUnsavedChanges = true;
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasUnsavedChanges = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_tagController.text.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("You've typed a tag. Add it before leaving?"),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Add',
                onPressed: () {
                  _addTag(_tagController.text.trim());
                },
              ),
            ),
          );
          return false; // Prevent exit for now
        }
        return true; // Allow exit
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Entry'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(labelText: 'Add tag'),
                      onSubmitted: _addTag,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(_tagController.text),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => _removeTag(tag),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    hintText: 'Update your thoughts here...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
