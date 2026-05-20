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

class JournalNew extends StatefulWidget {
  final bool autoStartRecord;
  const JournalNew({super.key, this.autoStartRecord = false});

  @override
  State<JournalNew> createState() => _JournalNewState();
}

class _JournalNewState extends State<JournalNew> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];

  FlutterSoundRecorder? _audioRecorder;
  bool _isRecorderInit = false;
  String? _recordingPath;

  bool get _hasChanges =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty ||
      _tags.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initAudioRecorder();
  }

  Future<void> _initAudioRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    try {
      await _audioRecorder!.openRecorder();
      setState(() {
        _isRecorderInit = true;
      });

      if (widget.autoStartRecord) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showRecordingSheet();
        });
      }
    } catch (e) {
      debugPrint("Could not initialize recorder: $e");
    }
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
                    if (mounted) Navigator.pop(context); // Close sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("AI Journal Entry created successfully!")),
                    );
                  }
                } catch (e) {
                  if (e.toString().contains("API_KEY_MISSING")) {
                    // Prompt API key
                    setModalState(() {
                      isTranscribing = false;
                    });
                    _showApiKeyRequestDialog(() {
                      // retry transcription
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
                      "Transcribing with Gemini AI...",
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
      return;
    }

    final newEntry = JournalEntry(
      title: title.isEmpty ? "Untitled Entry" : title,
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
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(CupertinoIcons.back, color: primaryColor),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            "New Entry",
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
              tooltip: 'Start Voice-based AI Journaling',
            ),
            IconButton(
              icon: Icon(CupertinoIcons.check_mark, color: primaryColor, size: 20),
              onPressed: _saveEntry,
              tooltip: 'Save Entry',
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
                color: primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.15), width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.info, size: 16, color: primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tip: Tap the keyboard's microphone button 🎙️ for offline typing, or tap the top microphone icon to transcribe via Gemini AI.",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textPrimary.withOpacity(0.8),
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
                  hintText: "Pour your heart out, express freely...",
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
