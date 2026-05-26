import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'journal_entry.dart';
import 'ai_service.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/services/notification_service.dart';
import 'package:uuid/uuid.dart';
import 'package:mindsarthi/core/services/sync_service.dart';
import 'package:mindsarthi/core/widgets/markdown_text_editing_controller.dart';

class JournalNew extends StatefulWidget {
  final bool autoStartRecord;
  const JournalNew({super.key, this.autoStartRecord = false});

  @override
  State<JournalNew> createState() => _JournalNewState();
}

class _JournalNewState extends State<JournalNew> {
  final TextEditingController _titleController = TextEditingController();
  late final MarkdownTextEditingController _contentController;
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];
  final FocusNode _contentFocusNode = FocusNode();

  FlutterSoundRecorder? _audioRecorder;
  bool _isRecorderInit = false;
  String? _recordingPath;

  // Auto-save logic fields
  int? _entryKey;
  Timer? _autoSaveTimer;
  String _saveStatus = "";
  bool _isExplicitSaving = false;

  bool get _hasChanges =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty ||
      _tags.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _contentController = MarkdownTextEditingController(
      syntaxColor: const Color(0x66009688), // Subtle teal transparency
      boldStyle: const TextStyle(fontWeight: FontWeight.bold),
      italicStyle: const TextStyle(fontStyle: FontStyle.italic),
      underlineStyle: const TextStyle(decoration: TextDecoration.underline),
      strikethroughStyle: const TextStyle(decoration: TextDecoration.lineThrough),
      codeStyle: const TextStyle(fontFamily: 'monospace'),
      headingStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );
    _titleController.addListener(_onFieldChanged);
    _contentController.addListener(_onFieldChanged);
    _contentFocusNode.addListener(_onFocusChanged);
    _initAudioRecorder();
  }

  void _onFieldChanged() {
    _triggerAutoSave();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  Future<void> _initAudioRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    try {
      var status = await Permission.microphone.status;
      if (status.isDenied) {
        status = await Permission.microphone.request();
      }

      if (status.isGranted) {
        await _audioRecorder!.openRecorder();
        setState(() {
          _isRecorderInit = true;
        });

        if (widget.autoStartRecord) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showRecordingSheet();
          });
        }
      } else {
        debugPrint("Microphone permission was denied.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Microphone permission is required for voice journaling."),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Could not initialize recorder: $e");
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFieldChanged);
    _contentController.removeListener(_onFieldChanged);
    _contentFocusNode.removeListener(_onFocusChanged);
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _contentFocusNode.dispose();
    _autoSaveTimer?.cancel();
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

  // Voice recording & AI transcription modal bottom sheet
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
              try {
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
              } catch (e) {
                debugPrint("Error starting recorder: $e");
                setModalState(() {
                  isRecording = false;
                });
                if (context.mounted) {
                  Navigator.pop(context); // Close the sheet if it failed
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to start voice recording: $e")),
                  );
                }
              }
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
                    setState(() {
                      _titleController.text = result['title'] ?? '';
                      _contentController.text = result['content'] ?? '';
                      if (result['tags'] != null) {
                        _tags.clear();
                        for (var t in result['tags']) {
                          _tags.add(t.toString());
                        }
                      }
                    });
                    if (context.mounted) {
                      Navigator.pop(context); // Close sheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("AI Journal Entry created successfully!")),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint("AI Transcription failed: $e");
                  if (context.mounted) {
                    if (e.toString().contains("API_KEY_MISSING")) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("AI features are unavailable. Please configure the Groq API key in the app environment.")),
                      );
                    } else {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("AI Transcription failed: $e")),
                      );
                    }
                  }
                }
              } else {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            }

            // Discard recording
            void discard() async {
              durationTimer?.cancel();
              waveTimer?.cancel();
              await _stopRecording();
              if (context.mounted) {
                Navigator.pop(context);
              }
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

            // Auto-trigger start on open
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
                      "Transcribing with Groq Whisper...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      "This might take a few seconds",
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
                            color: isPaused ? textSecondary.withValues(alpha:  0.4) : primaryColor,
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
                              color: primaryColor.withValues(alpha:  0.1),
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



  void _triggerAutoSave() {
    _autoSaveTimer?.cancel();
    if (_saveStatus != "Saving...") {
      setState(() {
        _saveStatus = "Saving...";
      });
    }
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      _performAutoSave();
    });
  }

  void _performAutoSave() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _tags.isEmpty) {
      if (mounted) {
        setState(() {
          _saveStatus = "";
        });
      }
      return;
    }

    final box = Hive.box<JournalEntry>('journalBox');

    if (_entryKey == null) {
      final newEntry = JournalEntry(
        id: const Uuid().v4(),
        title: title.isEmpty ? "Untitled Entry" : title,
        content: content,
        tag: _tags,
        createdAt: DateTime.now(),
        lastEdited: DateTime.now(),
      );
      box.add(newEntry).then((key) {
        _entryKey = key;
        if (mounted) {
          setState(() {
            _saveStatus = "Saved";
          });
        }
      });
    } else {
      final entry = box.get(_entryKey);
      if (entry != null) {
        entry.title = title.isEmpty ? "Untitled Entry" : title;
        entry.content = content;
        entry.tag = _tags;
        entry.lastEdited = DateTime.now();
        entry.save().then((_) {
          if (mounted) {
            setState(() {
              _saveStatus = "Saved";
            });
          }
        });
      }
    }
  }

  Future<String?> _showSaveOrDiscardDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Save entry?",
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Would you like to save your progress or discard the changes?",
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text(
                "Keep Editing",
                style: TextStyle(color: textSecondary),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'discard'),
                  child: const Text(
                    "Don't Save",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Save"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _saveEntry() {
    _autoSaveTimer?.cancel();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Entry is empty. Please add title, tag or content."),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isExplicitSaving = true;
    });

    final box = Hive.box<JournalEntry>('journalBox');

    if (_entryKey == null) {
      final newEntry = JournalEntry(
        id: const Uuid().v4(),
        title: title.isEmpty ? "Untitled Entry" : title,
        content: content,
        tag: _tags,
        createdAt: DateTime.now(),
        lastEdited: DateTime.now(),
      );
      box.add(newEntry).then((index) {
        _runSentimentAnalysis(index, content);
        SyncService().syncAll();
      });
    } else {
      final entry = box.get(_entryKey);
      if (entry != null) {
        entry.title = title.isEmpty ? "Untitled Entry" : title;
        entry.content = content;
        entry.tag = _tags;
        entry.lastEdited = DateTime.now();
        entry.save().then((_) {
          _runSentimentAnalysis(_entryKey!, content);
          SyncService().syncAll();
        });
      }
    }

    Navigator.pop(context);
  }

  void _runSentimentAnalysis(dynamic key, String content) {
    if (content.isNotEmpty) {
      final box = Hive.box<JournalEntry>('journalBox');
      JournalAIService.analyzeSentiment(content).then((sentimentData) {
        if (sentimentData != null) {
          final entryToUpdate = box.get(key);
          if (entryToUpdate != null) {
            entryToUpdate.sentimentScore = (sentimentData['score'] as num?)?.toDouble();
            final emotionsList = sentimentData['emotions'];
            entryToUpdate.sentimentEmotions = emotionsList is List ? List<String>.from(emotionsList) : null;
            entryToUpdate.sentimentRecommendation = sentimentData['recommendation'] as String?;
            entryToUpdate.crisisFlag = sentimentData['crisis_flag'] as bool?;
            entryToUpdate.save().then((_) {
              NotificationService.scheduleDailyReminders();
              SyncService().syncAll();
            });
          }
        }
      });
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
      });
      _tagController.clear();
      _triggerAutoSave();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _triggerAutoSave();
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
        if (_isExplicitSaving) return true;
        _autoSaveTimer?.cancel();
        if (_tagController.text.trim().isNotEmpty) {
          _addTag(_tagController.text.trim());
        }

        final title = _titleController.text.trim();
        final content = _contentController.text.trim();

        // If there are no changes, just discard draft if exists and exit directly
        if (title.isEmpty && content.isEmpty && _tags.isEmpty) {
          if (_entryKey != null) {
            final box = Hive.box<JournalEntry>('journalBox');
            await box.delete(_entryKey);
          }
          return true;
        }

        // Show dialog asking whether to save, discard, or cancel
        final result = await _showSaveOrDiscardDialog();

        if (result == 'save') {
          final box = Hive.box<JournalEntry>('journalBox');
          setState(() {
            _isExplicitSaving = true;
          });
          if (_entryKey == null) {
            final newEntry = JournalEntry(
              id: const Uuid().v4(),
              title: title.isEmpty ? "Untitled Entry" : title,
              content: content,
              tag: _tags,
              createdAt: DateTime.now(),
              lastEdited: DateTime.now(),
            );
            await box.add(newEntry).then((index) {
              _runSentimentAnalysis(index, content);
              SyncService().syncAll();
            });
          } else {
            final entry = box.get(_entryKey);
            if (entry != null) {
              entry.title = title.isEmpty ? "Untitled Entry" : title;
              entry.content = content;
              entry.tag = _tags;
              entry.lastEdited = DateTime.now();
              await entry.save();
              _runSentimentAnalysis(_entryKey!, content);
              SyncService().syncAll();
            }
          }
          return true;
        } else if (result == 'discard') {
          if (_entryKey != null) {
            final box = Hive.box<JournalEntry>('journalBox');
            await box.delete(_entryKey);
          }
          return true;
        } else {
          _triggerAutoSave(); // resume auto-save
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(CupertinoIcons.back, color: primaryColor),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Row(
            children: [
              const Text(
                "New Entry",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              if (_saveStatus.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  _saveStatus == "Saving..." ? "• Saving..." : "• Saved",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _saveStatus == "Saving..." 
                        ? primaryColor 
                        : textSecondary.withValues(alpha:  0.6),
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: surfaceColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(CupertinoIcons.mic_fill, color: primaryColor, size: 20),
              onPressed: _showRecordingSheet,
              tooltip: 'Start Voice-based AI Journaling',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Tips banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha:  0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha:  0.15), width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.info, size: 16, color: primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tip: Tap the keyboard's microphone button 🎙️ for offline typing, or tap the top microphone icon to transcribe via Groq Whisper.",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textPrimary.withValues(alpha:  0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
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
                hintStyle: TextStyle(color: textSecondary.withValues(alpha:  0.4)),
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
                      hintStyle: TextStyle(color: textSecondary.withValues(alpha:  0.4)),
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
                      color: primaryColor.withValues(alpha:  0.1),
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
                        backgroundColor: primaryColor.withValues(alpha:  0.08),
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
            _buildFormatToolbar(isDark, primaryColor, surfaceColor, borderCol, textSecondary),
            const SizedBox(height: 6),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 11.5,
                    color: textSecondary.withValues(alpha:  0.7),
                  ),
                  children: const [
                    TextSpan(text: "Visual guide: "),
                    TextSpan(text: "**bold**", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " | "),
                    TextSpan(text: "*italic*", style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: " | "),
                    TextSpan(text: "__underline__", style: TextStyle(decoration: TextDecoration.underline)),
                    TextSpan(text: " | "),
                    TextSpan(text: "~~strikethrough~~", style: TextStyle(decoration: TextDecoration.lineThrough)),
                    TextSpan(text: " | "),
                    TextSpan(text: "### Heading", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _contentFocusNode.hasFocus ? primaryColor : borderCol,
                  width: _contentFocusNode.hasFocus ? 1.2 : 0.8,
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  maxLines: null,
                  style: TextStyle(color: textPrimary, fontSize: 15, height: 1.4),
                  decoration: InputDecoration(
                    hintText: "Pour your heart out, express freely...",
                    hintStyle: TextStyle(color: textSecondary.withValues(alpha:  0.4)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(color: borderCol),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Save Entry"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyFormat(String prefix, String suffix) {
    _contentFocusNode.requestFocus();
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start;
      final end = selection.end;
      
      final selectedText = text.substring(start, end);
      final newText = text.replaceRange(start, end, '$prefix$selectedText$suffix');
      
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: end + prefix.length,
        ),
      );
    } else {
      final start = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(start, start, '$prefix$suffix');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length),
      );
    }
  }

  void _applyLinePrefix(String prefix) {
    _contentFocusNode.requestFocus();
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    
    int lineStart = start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    
    final beforeText = text.substring(0, lineStart);
    final selectionText = text.substring(lineStart, end);
    final afterText = text.substring(end);
    
    final lines = selectionText.split('\n');
    final formattedLines = lines.map((line) {
      if (line.startsWith(prefix)) {
        return line.substring(prefix.length);
      }
      return '$prefix$line';
    }).join('\n');
    
    final newText = '$beforeText$formattedLines$afterText';
    
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: lineStart,
        extentOffset: lineStart + formattedLines.length,
      ),
    );
  }

  Widget _buildFormatToolbar(
    bool isDark,
    Color primaryColor,
    Color surfaceColor,
    Color borderCol,
    Color textSecondary,
  ) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        children: [
          _buildFormatButton(
            icon: CupertinoIcons.bold,
            tooltip: "Bold",
            onTap: () => _applyFormat("**", "**"),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.italic,
            tooltip: "Italic",
            onTap: () => _applyFormat("*", "*"),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.underline,
            tooltip: "Underline",
            onTap: () => _applyFormat("__", "__"),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.strikethrough,
            tooltip: "Strikethrough",
            onTap: () => _applyFormat("~~", "~~"),
            color: primaryColor,
          ),
          _buildDivider(borderCol),
          _buildFormatButton(
            icon: Icons.title,
            tooltip: "Heading",
            onTap: () => _applyLinePrefix("### "),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.list_bullet,
            tooltip: "Bullet List",
            onTap: () => _applyLinePrefix("- "),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.list_number,
            tooltip: "Numbered List",
            onTap: () => _applyLinePrefix("1. "),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.square_list,
            tooltip: "Checklist",
            onTap: () => _applyLinePrefix("- [ ] "),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.quote_bubble,
            tooltip: "Quote",
            onTap: () => _applyLinePrefix("> "),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: Icons.code,
            tooltip: "Code Block",
            onTap: () => _applyFormat("```\n", "\n```"),
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(Color borderCol) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      width: 1,
      color: borderCol,
    );
  }
}
