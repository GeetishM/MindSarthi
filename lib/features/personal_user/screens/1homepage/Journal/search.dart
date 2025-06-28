import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'journal_entry.dart';
import 'journal_edit.dart';
import 'package:intl/intl.dart';

class SearchJournal extends StatefulWidget {
  const SearchJournal({super.key});

  @override
  State<SearchJournal> createState() => _SearchJournalState();
}

class _SearchJournalState extends State<SearchJournal> {
  final TextEditingController _searchController = TextEditingController();
  List<JournalEntry> _results = [];
  late Box<JournalEntry> journalBox;

  @override
  void initState() {
    super.initState();
    journalBox = Hive.box<JournalEntry>('journalBox');
    _results = journalBox.values.toList().cast<JournalEntry>()
      ..sort(
        (a, b) => b.lastEdited.compareTo(a.lastEdited),
      ); // ✅ latest edited first
  }

  void _search(String query) {
    final lowerQuery = query.toLowerCase();
    final entries = journalBox.values.toList().cast<JournalEntry>();

    final filtered =
        entries.where((entry) {
          return entry.title.toLowerCase().contains(lowerQuery) ||
              entry.content.toLowerCase().contains(lowerQuery) ||
              entry.tag.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
              entry.createdAt.toString().toLowerCase().contains(lowerQuery);
        }).toList()..sort(
          (a, b) => b.lastEdited.compareTo(a.lastEdited),
        ); // ✅ keep sorted

    setState(() {
      _results = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Entries")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Search by title, tag, word or date...",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text("No matching entries."))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final entry = _results[index];
                      final key = journalBox.keys.firstWhere(
                        (k) => journalBox.get(k) == entry,
                        orElse: () => 0, // fallback if not found
                      );

                      return ListTile(
                        title: Text(entry.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.tag.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                children: entry.tag
                                    .map(
                                      (tag) => Chip(
                                        label: Text('#$tag'),
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          175,
                                          215,
                                          244,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              entry.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "🗓 ${DateFormat('dd MMM yyyy').format(entry.createdAt)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (entry.lastEdited != entry.createdAt)
                                  Text(
                                    "✏️ ${DateFormat('dd MMM').format(entry.lastEdited)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ], // Children
                        ),
                        isThreeLine: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                JournalEdit(entry: entry, index: key),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
