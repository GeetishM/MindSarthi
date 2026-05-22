import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/boxes.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/chat_history.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/providers/chat_provider.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/widgets/chat_history_widget.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/widgets/empty_history_widget.dart';
import 'package:provider/provider.dart';
import 'package:mindsarthi/core/widgets/app_dialog.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chat History',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ValueListenableBuilder<Box<ChatHistory>>(
        valueListenable: Boxes.getChatHistory().listenable(),
        builder: (context, box, _) {
          final chatHistory =
              box.values.toList().cast<ChatHistory>().reversed.toList();
          if (chatHistory.isEmpty) {
            return const EmptyHistoryWidget();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chatHistory.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              endIndent: 16,
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
            itemBuilder: (context, index) {
              final chat = chatHistory[index];
              return Dismissible(
                key: Key(chat.chatId),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await MindSarthiDialog.show(
                    context: context,
                    title: 'Delete Chat?',
                    content: 'Are you sure you want to permanently delete this chat history?',
                    confirmText: 'Yes, Delete',
                    cancelText: 'Cancel',
                    isDestructive: true,
                  );
                },
                onDismissed: (direction) async {
                  final provider = context.read<ChatProvider>();
                  await provider.deletChatMessages(chatId: chat.chatId);
                  await chat.delete();
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24.0),
                  color: AppColors.error,
                  child: const Icon(
                    CupertinoIcons.delete,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                child: ChatHistoryWidget(chat: chat),
              );
            },
          );
        },
      ),
    );
  }
}

