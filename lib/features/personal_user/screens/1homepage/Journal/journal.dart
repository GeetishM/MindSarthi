import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'journal_entry.dart';
import 'journal_edit.dart';
import 'journal_new.dart';
import 'entry_dates.dart';

class Journal extends StatefulWidget {
  const Journal({super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  bool isListView = true;
  late Box<JournalEntry> journalBox;
  late Box journalSettingsBox;
  Offset fabPosition = const Offset(20, 500);
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    journalBox = Hive.box<JournalEntry>('journalBox');
    journalSettingsBox = Hive.box('journalSettings');

    final pos = journalSettingsBox.get('FAB_POSITION');
    if (pos != null && pos is List && pos.length == 2) {
      fabPosition = Offset(pos[0], pos[1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Journal"),
        backgroundColor: const Color.fromARGB(255, 161, 137, 240),
        actions: [
          IconButton(
            icon: Icon(isListView ? Icons.grid_view : Icons.list),
            onPressed: () => setState(() => isListView = !isListView),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: ValueListenableBuilder(
            valueListenable: journalBox.listenable(),
            builder: (context, Box<JournalEntry> box, _) {
              if (box.values.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  shadowColor: Colors.black.withOpacity(0.2),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by title, tag or word...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value.toLowerCase());
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double fabSize = 56;
          const double margin = 10;
          final double appBarHeight = kToolbarHeight;
          final double topPadding = MediaQuery.of(context).padding.top;
          final double bottomPadding = MediaQuery.of(context).padding.bottom;

          final double minX = margin;
          final double maxX = constraints.maxWidth - fabSize - margin;
          final double minY = appBarHeight + topPadding + margin + 60;
          final double maxY =
              constraints.maxHeight - fabSize - bottomPadding - margin;

          final Offset clampedFabPosition = Offset(
            fabPosition.dx.clamp(minX, maxX),
            fabPosition.dy.clamp(minY, maxY),
          );

          return Stack(
            children: [
              Positioned.fill(
                child: ValueListenableBuilder(
                  valueListenable: journalBox.listenable(),
                  builder: (context, Box<JournalEntry> box, _) {
                    final entries =
                        box.values
                            .where(
                              (entry) =>
                                  entry.title.toLowerCase().contains(
                                    searchQuery,
                                  ) ||
                                  entry.content.toLowerCase().contains(
                                    searchQuery,
                                  ) ||
                                  entry.tag.any(
                                    (tag) =>
                                        tag.toLowerCase().contains(searchQuery),
                                  ) ||
                                  entry.createdAt
                                      .toString()
                                      .toLowerCase()
                                      .contains(searchQuery),
                            )
                            .toList()
                          ..sort(
                            (a, b) => b.lastEdited.compareTo(a.lastEdited),
                          );

                    if (entries.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "Your journal is a sanctuary for capturing life's essence — every event, idea, feeling, thought, and memory cherished and revisited. \nIt's where you express freely, painting the tapestry of your experiences. \nEmbrace calm, find clarity, and nurture your soul through the art of journaling.\n",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }

                    return isListView
                        ? ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(
                                    entry.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (entry.tag.isNotEmpty)
                                        Wrap(
                                          spacing: 6,
                                          children: entry.tag
                                              .map(
                                                (tag) => Chip(
                                                  label: Text('#$tag'),
                                                  backgroundColor:
                                                      Colors.blue.shade50,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (entry.lastEdited !=
                                              entry.createdAt)
                                            EntryDates(
                                              createdAt: entry.createdAt,
                                              lastEdited: entry.lastEdited,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => JournalEdit(
                                          entry: entry,
                                          index: index,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          )
                        : GridView.builder(
                            itemCount: entries.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.9,
                            ),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return Card(
                                elevation: 3,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => JournalEdit(
                                          entry: entry,
                                          index: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (entry.tag.isNotEmpty)
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 2,
                                            children: entry.tag
                                                .map(
                                                  (tag) => Chip(
                                                    label: Text('#$tag'),
                                                    backgroundColor:
                                                        Colors.grey.shade200,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 4,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        const Spacer(),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            EntryDates(
                                              createdAt: entry.createdAt,
                                              lastEdited: entry.lastEdited,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                  },
                ),
              ),
              Positioned(
                left: clampedFabPosition.dx,
                top: clampedFabPosition.dy,
                child: Draggable(
                  feedback: FloatingActionButton(
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ),
                  childWhenDragging: const SizedBox.shrink(),
                  onDragEnd: (details) {
                    final Offset localOffset =
                        details.offset - Offset(0, topPadding);
                    final double newX = localOffset.dx.clamp(minX, maxX);
                    final double newY = localOffset.dy.clamp(minY, maxY);

                    setState(() {
                      fabPosition = Offset(newX, newY);
                    });

                    journalSettingsBox.put('FAB_POSITION', [
                      fabPosition.dx,
                      fabPosition.dy,
                    ]);
                  },
                  child: FloatingActionButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JournalNew()),
                    ),
                    child: const Icon(Icons.add),
                    backgroundColor: const Color.fromARGB(255, 210, 125, 236),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
