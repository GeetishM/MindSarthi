import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'journal_entry.dart';

class JournalNew extends StatefulWidget {
  const JournalNew({super.key});

  @override
  State<JournalNew> createState() => _JournalNewState();
}

class _JournalNewState extends State<JournalNew> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];

  bool get _hasChanges =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty ||
      _tags.isNotEmpty;

void _saveEntry() {
  final title = _titleController.text.trim();
  final content = _contentController.text.trim();

  if (title.isEmpty && content.isEmpty && _tags.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Entry is empty. Please add title, tag or content."),
        duration: Duration(seconds: 4),
      ),
    );
    return; // Don't save
  }

  final newEntry = JournalEntry(
    title: title,
    content: content,
    tag: _tags,
    createdAt: DateTime.now(),
    lastEdited: DateTime.now(),
  );
  Hive.box<JournalEntry>('journalBox').add(newEntry);
  Navigator.pop(context);
}

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
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
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Add',
                onPressed: () {
                  _addTag(_tagController.text.trim());
                },
              ),
            ),
          );
          return false;
        }
        if (_hasChanges) {
          final scaffold = ScaffoldMessenger.of(context);
          scaffold.hideCurrentSnackBar();
          scaffold.showSnackBar(
            SnackBar(
              content: const Text("Wanna save this entry?"),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Yes',
                onPressed: _saveEntry,
              ),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("New Entry"),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveEntry,
            ),
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
                    hintText: 'What’s on your mind?',
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
