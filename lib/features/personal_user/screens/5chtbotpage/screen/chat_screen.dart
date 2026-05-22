import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/providers/chat_provider.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/screen/chat_history_screen.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/widgets/bottom_chat_field.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/widgets/chat_messages.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().addListener(_onChatProviderChanged);
      }
    });
  }

  void _onChatProviderChanged() {
    if (mounted) {
      final provider = context.read<ChatProvider>();
      if (provider.inChatMessages.isNotEmpty) {
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    try {
      context.read<ChatProvider>().removeListener(_onChatProviderChanged);
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0.0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.inChatMessages.isNotEmpty) {
          _scrollToBottom();
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: MediaQuery.of(context).size.width >= 1024
                ? null
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatHistoryScreen()),
                      );
                    },
                    child: Icon(
                      CupertinoIcons.clock,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
            title: Text(
              'Sarthi AI',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Start New Chat'),
                      content: const Text('Are you sure you want to start a new chat?'),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () async {
                            final chatProvider = context.read<ChatProvider>();
                            await chatProvider.prepareChatRoom(
                              isNewChat: true,
                              chatID: '',
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Start'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  CupertinoIcons.plus,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Expanded(
                    child: chatProvider.inChatMessages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface2
                                          : AppColors.primaryLight.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: SizedBox(
                                      height: 360,
                                      width: 360,
                                      child: Lottie.asset(
                                        'assets/lottie/chatbot.json',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                  Text(
                                    'Hey there, how are you feeling today?',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "I'm here to listen, whenever you're ready.",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      letterSpacing: -0.1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 48),
                                ],
                              ),
                            ),
                          )
                        : ChatMessages(
                            scrollController: _scrollController,
                            chatProvider: chatProvider,
                          ),
                  ),
                  const SizedBox(height: 8),
                  // input field
                  BottomChatField(chatProvider: chatProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

