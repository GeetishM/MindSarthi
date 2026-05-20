import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'journal_entry.dart';
import 'ai_service.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

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

  FlutterSoundRecorder? _audioRecorder;
  bool _isRecorderInit = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
    _tagController = TextEditingController();
    _tags = List<String>.from(widget.entry.tag);

    _titleController.addListener(_markUnsaved);
    _contentController.addListener(_markUnsaved);

    _initAudioRecorder();
  }

  Future<void> _initAudioRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    try {
      await _audioRecorder!.openRecorder();
      setState(() {
        _isRecorderInit = true;
      });
    } catch (e) {
      debugPrint("Could not initialize recorder: $e");
    }
  }

  void _markUnsaved() {
    setState(() => _hasUnsavedChanges = true);
  }

  void _save() {
    final newContent = _contentController.text.trim();
    widget.entry.title = _titleController.text.trim();
    widget.entry.content = newContent;
    widget.entry.tag = _tags;
    widget.entry.lastEdited = DateTime.now();
    widget.entry.save();

    if (newContent.isNotEmpty) {
      JournalAIService.analyzeSentiment(newContent).then((sentimentData) {
        if (sentimentData != null) {
          widget.entry.sentimentScore = (sentimentData['score'] as num?)?.toDouble();
          final emotionsList = sentimentData['emotions'];
          widget.entry.sentimentEmotions = emotionsList is List ? List<String>.from(emotionsList) : null;
          widget.entry.sentimentRecommendation = sentimentData['recommendation'] as String?;
          widget.entry.crisisFlag = sentimentData['crisis_flag'] as bool?;
          widget.entry.save();
        }
      });
    }

    _hasUnsavedChanges = false;
    Navigator.pop(context);
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
    if (mounted) Navigator.of(context).pop();

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
    if (_audioRecorder != null) {
      _audioRecorder!.closeRecorder();
      _audioRecorder = null;
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInit) return;
    final tempDir = await getTemporaryDirectory();
    _recordingPath = '${tempDir.path}/journal_voice_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _audioRecorder!.startRecorder(
      toFile: _recordingPath,
      codec: Codec.aacADTS,
    );
  }

  Future<String?> _stopRecording() async {
    if (!_isRecorderInit) return null;
    return await _audioRecorder!.stopRecorder();
  }

  Future<void> _pauseRecording() async {
    if (!_isRecorderInit) return;
    await _audioRecorder!.pauseRecorder();
  }

  Future<void> _resumeRecording() async {
    if (!_isRecorderInit) return;
    await _audioRecorder!.resumeRecorder();
  }

  // Voice recording & AI transcription append sheet
  void _showRecordingSheet() {
    bool isRecording = false;
    bool isPaused = false;
    bool isTranscribing = false;
    int duration = 0;
    Timer? durationTimer;
    Timer? waveTimer;
    List<double> waveHeights = List.filled(7, 10.0);
    final random = Random();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceColor = isDark ? AppColors.darkSurface2 : AppColors.white;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
        final borderCol = isDark ? AppColors.darkBorder : AppColors.border;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return StatefulBuilder(
          builder: (context, setModalState) {
            // Start recording utility
            void start() async {
              setModalState(() {
                isRecording = true;
                isPaused = false;
                duration = 0;
              });
              await _startRecording();

              durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                setModalState(() {
                  duration++;
                });
              });

              waveTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
                setModalState(() {
                  waveHeights = List.generate(7, (index) {
                    if (isPaused) return 10.0;
                    return random.nextInt(40).toDouble() + 8.0;
                  });
                });
              });
            }

            // Stop recording & transcribe
            void stopAndTranscribe() async {
              durationTimer?.cancel();
              waveTimer?.cancel();
              setModalState(() {
                isTranscribing = true;
              });

              final path = await _stopRecording();
              if (path != null && _recordingPath != null) {
                try {
                  final result = await JournalAIService.transcribeAudio(_recordingPath!);
                  if (result != null) {
                    final transcribedText = result['content'] ?? '';
                    setState(() {
                      if (_contentController.text.trim().isEmpty) {
                        _contentController.text = transcribedText;
                      } else {
                        _contentController.text = "${_contentController.text}\n\n$transcribedText";
                      }
                      if (result['tags'] != null) {
                        for (var t in result['tags']) {
                          final cleaned = t.toString().trim();
                          if (!_tags.contains(cleaned)) {
                            _tags.add(cleaned);
                          }
                        }
                      }
                      _hasUnsavedChanges = true;
                    });
                    if (mounted) Navigator.pop(context); // Close sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Transcribed text appended successfully!")),
                    );
                  }
                } catch (e) {
                  if (e.toString().contains("API_KEY_MISSING")) {
                    setModalState(() {
                      isTranscribing = false;
                    });
                    _showApiKeyRequestDialog(() {
                      setModalState(() {
                        isTranscribing = true;
                      });
                      stopAndTranscribe();
                    });
                  } else {
                    if (mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("AI Transcription failed: $e")),
                    );
                  }
                }
              } else {
                if (mounted) Navigator.pop(context);
              }
            }

            // Discard recording
            void discard() async {
              durationTimer?.cancel();
              waveTimer?.cancel();
              await _stopRecording();
              if (mounted) Navigator.pop(context);
            }

            // Pause
            void pause() async {
              await _pauseRecording();
              durationTimer?.cancel();
              setModalState(() {
                isPaused = true;
              });
            }

            // Resume
            void resume() async {
              await _resumeRecording();
              durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                setModalState(() {
                  duration++;
                });
              });
              setModalState(() {
                isPaused = false;
              });
            }

            if (!isRecording && !isTranscribing && duration == 0) {
              start();
            }

            String formatDuration(int sec) {
              final m = (sec ~/ 60).toString().padLeft(2, '0');
              final s = (sec % 60).toString().padLeft(2, '0');
              return "$m:$s";
            }

            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isTranscribing) ...[
                    const SizedBox(height: 20),
                    const CupertinoActivityIndicator(radius: 18),
                    const SizedBox(height: 16),
                    Text(
                      "Transcribing with Gemini AI...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      "Appending transcription to content",
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text(
                      isPaused ? "Recording Paused" : "Listening...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatDuration(duration),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Waveform visualizer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: waveHeights.map((h) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 4,
                          height: h,
                          decoration: BoxDecoration(
                            color: isPaused ? textSecondary.withOpacity(0.4) : primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Controls Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Discard
                        IconButton(
                          onPressed: discard,
                          icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 24),
                          tooltip: 'Discard',
                        ),
                        // Pulsating Pause/Play
                        GestureDetector(
                          onTap: isPaused ? resume : pause,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPaused ? CupertinoIcons.play_arrow_solid : CupertinoIcons.pause_fill,
                              color: primaryColor,
                              size: 28,
                            ),
                          ),
                        ),
                        // Finish & Transcribe
                        IconButton(
                          onPressed: stopAndTranscribe,
                          icon: const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.green, size: 28),
                          tooltip: 'Finish & AI Transcribe',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showApiKeyRequestDialog(VoidCallback onSaved) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Gemini API Key Required"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("To use voice transcription, please enter your Gemini API Key. Free keys are available on Google AI Studio."),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  JournalAIService.saveApiKey(controller.text);
                  Navigator.pop(context);
                  onSaved();
                }
              },
              child: const Text("Save & Resume"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme colors
    final primaryColor = Theme.of(context).colorScheme.primary;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return WillPopScope(
      onWillPop: () async {
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
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(CupertinoIcons.back, color: primaryColor),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'Edit Entry',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: surfaceColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(CupertinoIcons.mic_fill, color: primaryColor, size: 20),
              onPressed: _showRecordingSheet,
              tooltip: 'Append Voice-to-Text',
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
              onPressed: _confirmDelete,
              tooltip: 'Delete Entry',
            ),
            IconButton(
              icon: Icon(CupertinoIcons.check_mark, color: primaryColor, size: 20),
              onPressed: _save,
              tooltip: 'Save Entry',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title Input
            Text(
              "Title",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textSecondary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: TextStyle(color: textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Give your entry a title...",
                hintStyle: TextStyle(color: textSecondary.withOpacity(0.4)),
                filled: true,
                fillColor: surfaceColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderCol, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderCol, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tags section
            Text(
              "Tags",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textSecondary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Add topic tag...",
                      hintStyle: TextStyle(color: textSecondary.withOpacity(0.4)),
                      filled: true,
                      fillColor: surfaceColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderCol, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderCol, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primaryColor, width: 1.2),
                      ),
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _addTag(_tagController.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(CupertinoIcons.plus, color: primaryColor, size: 20),
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text(
                          '#$tag',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        deleteIcon: Icon(CupertinoIcons.clear, size: 12, color: primaryColor),
                        backgroundColor: primaryColor.withOpacity(0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onDeleted: () => _removeTag(tag),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Content input
            Text(
              "Journal Content",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textSecondary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                style: TextStyle(color: textPrimary, fontSize: 15, height: 1.4),
                decoration: InputDecoration(
                  hintText: "Update your thoughts here...",
                  hintStyle: TextStyle(color: textSecondary.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
