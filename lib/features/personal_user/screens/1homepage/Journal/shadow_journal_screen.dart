import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'journal_entry.dart';
import 'ai_service.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

class ShadowJournalScreen extends StatefulWidget {
  const ShadowJournalScreen({super.key});

  @override
  State<ShadowJournalScreen> createState() => _ShadowJournalScreenState();
}

class _ShadowJournalScreenState extends State<ShadowJournalScreen> {
  final List<Map<String, String>> _chatHistory = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isSaving = false;
  String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  void _checkApiKey() {
    setState(() {
      _apiKey = JournalAIService.getApiKey();
    });
    if (_apiKey.isNotEmpty) {
      // Add initial greeting from the reflection partner
      _chatHistory.add({
        'role': 'reflection',
        'message': "Hello! I am your Digital Reflection. I'm here to help you unpack your thoughts today. How are you feeling right now, or what is on your mind?"
      });
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

        return AlertDialog(
          title: Text(
            "Configure Gemini API Key",
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Provide a Gemini API Key to enable AI-driven Shadow Journaling. Get one for free from Google AI Studio.",
                style: TextStyle(
                  color: textPrimary.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
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
                JournalAIService.saveApiKey(controller.text);
                Navigator.pop(context);
                setState(() {
                  _apiKey = controller.text.trim();
                });
                _checkApiKey();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gemini API Key saved successfully")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() {
      _chatHistory.add({'role': 'user', 'message': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final followUp = await JournalAIService.getShadowJournalFollowUp(
        userMessage: text,
        chatHistory: _chatHistory.sublist(0, _chatHistory.length - 1),
      );

      setState(() {
        _isLoading = false;
        _chatHistory.add({
          'role': 'reflection',
          'message': followUp ?? "I'm listening. Tell me more about that."
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _chatHistory.add({
          'role': 'reflection',
          'message': "I'm sorry, I encountered an issue reflecting on that. Can you repeat or try again?"
        });
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveSession() async {
    // We need at least one user message to summarize.
    final hasUserMessage = _chatHistory.any((m) => m['role'] == 'user');
    if (!hasUserMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please type something before completing the session.")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final synthesis = await JournalAIService.generateShadowJournalSummary(_chatHistory);
      
      String entryTitle = "Digital Reflection";
      String entrySummary = "A reflection session with your Digital Reflection companion.";
      List<String> entryTags = ["reflection"];
      double sentimentScore = 5.0;
      List<String> sentimentEmotions = ["Reflective"];
      String sentimentRec = "Continue taking time for mindful self-reflection.";
      bool crisisFlag = false;

      if (synthesis != null) {
        entryTitle = synthesis['title'] ?? entryTitle;
        entrySummary = synthesis['summary'] ?? entrySummary;
        final tagsVal = synthesis['tags'];
        if (tagsVal is List) {
          entryTags = List<String>.from(tagsVal);
        }
        sentimentScore = (synthesis['score'] as num?)?.toDouble() ?? sentimentScore;
        final emotionsVal = synthesis['emotions'];
        if (emotionsVal is List) {
          sentimentEmotions = List<String>.from(emotionsVal);
        }
        sentimentRec = synthesis['recommendation'] ?? sentimentRec;
        crisisFlag = synthesis['crisis_flag'] ?? crisisFlag;
      }

      // Format complete transcript
      final transcriptBuffer = StringBuffer();
      transcriptBuffer.writeln("### Reflection Synthesis\n$entrySummary\n");
      transcriptBuffer.writeln("---");
      transcriptBuffer.writeln("### Conversation Transcript\n");
      for (var msg in _chatHistory) {
        final role = msg['role'] == 'user' ? 'You' : 'Digital Reflection';
        transcriptBuffer.writeln("**$role**: ${msg['message']}\n");
      }

      final newEntry = JournalEntry(
        title: entryTitle,
        content: transcriptBuffer.toString(),
        tag: entryTags,
        createdAt: DateTime.now(),
        lastEdited: DateTime.now(),
        sentimentScore: sentimentScore,
        sentimentEmotions: sentimentEmotions,
        sentimentRecommendation: sentimentRec,
        crisisFlag: crisisFlag,
      );

      final box = Hive.box<JournalEntry>('journalBox');
      await box.add(newEntry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reflection saved successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving reflection: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    final hasUserMessage = _chatHistory.any((m) => m['role'] == 'user');
    if (!hasUserMessage) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit reflection?"),
        content: const Text("Your current Shadow Journaling session will be discarded. Do you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Stay"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text("Discard"),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    if (_apiKey.isEmpty) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(CupertinoIcons.back, color: primaryColor),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text("Shadow Journaling"),
          centerTitle: true,
          backgroundColor: surfaceColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.sparkles,
                    size: 48,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Gemini API Key Required",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Shadow Journaling uses conversational AI to guide your reflection. Please configure a Gemini API key to start.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showApiKeyDialog,
                  icon: const Icon(CupertinoIcons.settings),
                  label: const Text("Set API Key"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(CupertinoIcons.back, color: primaryColor),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (await _onWillPop()) {
                navigator.maybePop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Digital Reflection",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.amber : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isLoading ? "Reflecting..." : "Listening",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: surfaceColor,
          elevation: 0,
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _saveSession,
                child: Text(
                  "Finish",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Chat Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _chatHistory.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _chatHistory.length && _isLoading) {
                    return _buildTypingIndicator();
                  }

                  final message = _chatHistory[index];
                  final isUser = message['role'] == 'user';

                  return _buildChatBubble(
                    message: message['message'] ?? '',
                    isUser: isUser,
                    isDark: isDark,
                    primaryColor: primaryColor,
                    surfaceColor: surfaceColor,
                    textPrimary: textPrimary,
                  );
                },
              ),
            ),

            // Message Input bar
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 10,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(top: BorderSide(color: borderCol, width: 0.8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderCol, width: 0.8),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        style: TextStyle(color: textPrimary, fontSize: 15),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "Reflect on your thoughts...",
                          hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_up,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble({
    required String message,
    required bool isUser,
    required bool isDark,
    required Color primaryColor,
    required Color surfaceColor,
    required Color textPrimary,
  }) {
    final bubbleBg = isUser
        ? primaryColor
        : (isDark ? AppColors.darkPrimaryLight : primaryColor.withOpacity(0.08));
    final textColor = isUser
        ? Colors.white
        : textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.sparkles,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 32), // spacer on right if user message
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.sparkles,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkPrimaryLight
                  : primaryColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBlinkingDot(0),
                const SizedBox(width: 4),
                _buildBlinkingDot(1),
                const SizedBox(width: 4),
                _buildBlinkingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlinkingDot(int delay) {
    return _BlinkingDot(delay: delay);
  }
}

class _BlinkingDot extends StatefulWidget {
  final int delay;
  const _BlinkingDot({required this.delay});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay * 200), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: textSecondary.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
