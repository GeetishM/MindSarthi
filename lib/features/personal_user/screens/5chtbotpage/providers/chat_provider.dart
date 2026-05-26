import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindsarthi/core/services/groq_service.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/api/api_service.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/constants.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/boxes.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/chat_history.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/knowledge_article.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/models/message.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/services/sync_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _inChatMessages = [];
  final PageController _pageController = PageController();
  List<XFile>? _imagesFileList = [];
  int _currentIndex = 0;
  String _currentChatId = '';
  String _modelType = 'llama3-8b-8192';
  bool _isLoading = false;

  List<Message> get inChatMessages => _inChatMessages;
  PageController get pageController => _pageController;
  List<XFile>? get imagesFileList => _imagesFileList;
  int get currentIndex => _currentIndex;
  String get currentChatId => _currentChatId;
  String get modelType => _modelType;
  bool get isLoading => _isLoading;

  void setImagesFileList({required List<XFile> listValue}) {
    _imagesFileList = listValue;
    notifyListeners();
  }

  void setCurrentIndex({required int newIndex}) {
    _currentIndex = newIndex;
    notifyListeners();
  }

  void setCurrentChatId({required String newChatId}) {
    _currentChatId = newChatId;
    notifyListeners();
  }

  void setLoading({required bool value}) {
    _isLoading = value;
    notifyListeners();
  }

  String setCurrentModel({required String newModel}) {
    _modelType = newModel;
    notifyListeners();
    return newModel;
  }

  String getApiKey() {
    // 1. Check static API key in ApiService
    if (ApiService.apiKey.isNotEmpty) {
      return ApiService.apiKey;
    }
    // 2. Fallback to settings box
    final box = Hive.box('journalSettings');
    return box.get('GROQ_API_KEY', defaultValue: '') as String;
  }

  String getChatId() =>
      _currentChatId.isEmpty ? const Uuid().v4() : _currentChatId;

  List<String> getImagesUrls({required bool isTextOnly}) {
    return !isTextOnly && _imagesFileList != null
        ? _imagesFileList!.map((img) => img.path).toList()
        : [];
  }

  Future<List<Message>> loadMessagesFromDB({required String chatId}) async {
    await Hive.openBox('${Constants.chatMessagesBox}$chatId');
    final messageBox = Hive.box('${Constants.chatMessagesBox}$chatId');

    final newData =
        messageBox.keys.map((e) {
          final message = messageBox.get(e);
          return Message.fromMap(Map<String, dynamic>.from(message));
        }).toList();

    notifyListeners();
    return newData;
  }

  Future<void> setInChatMessages({required String chatId}) async {
    final messagesFromDB = await loadMessagesFromDB(chatId: chatId);
    for (var message in messagesFromDB) {
      if (!_inChatMessages.contains(message)) _inChatMessages.add(message);
    }
    notifyListeners();
  }

  Future<void> prepareChatRoom({
    required bool isNewChat,
    required String chatID,
  }) async {
    _inChatMessages.clear();
    if (!isNewChat) {
      final chatHistory = await loadMessagesFromDB(chatId: chatID);
      _inChatMessages.addAll(chatHistory);
    }
    setCurrentChatId(newChatId: chatID);
  }

  Future<void> sentMessage({
    required String message,
    required bool isTextOnly,
  }) async {
    setLoading(value: true);

    final chatId = getChatId();
    final imagesUrls = getImagesUrls(isTextOnly: isTextOnly);
    final messagesBox = await Hive.openBox(
      '${Constants.chatMessagesBox}$chatId',
    );

    // Get current chat history copy before adding new user message
    final List<Message> history = List.from(_inChatMessages);

    final userMessage = Message(
      messageId: messagesBox.length.toString(),
      chatId: chatId,
      role: Role.user,
      message: StringBuffer(message),
      imagesUrls: imagesUrls,
      timeSent: DateTime.now(),
    );

    final assistantMessageId = (messagesBox.length + 1).toString();

    _inChatMessages.add(userMessage);
    notifyListeners();

    if (_currentChatId.isEmpty) setCurrentChatId(newChatId: chatId);

    await sendMessageAndWaitForResponse(
      message: message,
      chatId: chatId,
      isTextOnly: isTextOnly,
      historyMessages: history,
      userMessage: userMessage,
      modelMessageId: assistantMessageId,
      messagesBox: messagesBox,
    );
  }

  Future<void> sendMessageAndWaitForResponse({
    required String message,
    required String chatId,
    required bool isTextOnly,
    required List<Message> historyMessages,
    required Message userMessage,
    required String modelMessageId,
    required Box messagesBox,
  }) async {
    final assistantMessage = userMessage.copyWith(
      messageId: modelMessageId,
      role: Role.assistant,
      message: StringBuffer(),
      timeSent: DateTime.now(),
    );

    _inChatMessages.add(assistantMessage);
    notifyListeners();

    try {
      // Format history messages for Groq API
      final List<Map<String, String>> history = [];
      for (var msg in historyMessages) {
        history.add({
          "role": msg.role == Role.user ? "user" : "assistant",
          "content": msg.message.toString(),
        });
      }

      final apiKey = getApiKey();
      final response = await GroqService.getChatResponse(
        history: history,
        userMessage: message,
        apiKey: apiKey,
      );

      // Append response to the assistant message
      assistantMessage.message.write(response);
      notifyListeners();

      await saveMessagesToDB(
        chatID: chatId,
        userMessage: userMessage,
        assistantMessage: assistantMessage,
        messagesBox: messagesBox,
      );
      setLoading(value: false);
    } catch (e) {
      log('Groq error: $e');
      assistantMessage.message.write(
        'Sorry, I encountered an error while communicating with Groq: $e'
      );
      notifyListeners();
      setLoading(value: false);
    }
  }

  Future<void> saveMessagesToDB({
    required String chatID,
    required Message userMessage,
    required Message assistantMessage,
    required Box messagesBox,
  }) async {
    String currentUserId = '';
    try {
      final user = await AppwriteService().account.get();
      currentUserId = user.$id;
    } catch (_) {}

    userMessage.userId = currentUserId;
    userMessage.isSynced = false;
    assistantMessage.userId = currentUserId;
    assistantMessage.isSynced = false;

    await messagesBox.add(userMessage.toMap());
    await messagesBox.add(assistantMessage.toMap());

    final chatHistoryBox = Boxes.getChatHistory();
    final chatHistory = ChatHistory(
      chatId: chatID,
      prompt: userMessage.message.toString(),
      response: assistantMessage.message.toString(),
      imagesUrls: userMessage.imagesUrls,
      timestamp: DateTime.now(),
      isSynced: false,
      userId: currentUserId,
    );

    await chatHistoryBox.put(chatID, chatHistory);
    await messagesBox.close();

    // Trigger sync in background
    SyncService().syncAll();
  }

  Future<void> deletChatMessages({required String chatId}) async {
    final boxName = '${Constants.chatMessagesBox}$chatId';

    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }

    await Hive.box(boxName).clear();
    await Hive.box(boxName).close();

    if (_currentChatId == chatId) {
      setCurrentChatId(newChatId: '');
      _inChatMessages.clear();
      notifyListeners();
    }
  }

  static Future<void> initHive() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserModelAdapter());
    }

    if (!Hive.isBoxOpen(Constants.chatHistoryBox)) {
      await Hive.openBox<ChatHistory>(Constants.chatHistoryBox);
    }

    if (!Hive.isBoxOpen(Constants.userBox)) {
      await Hive.openBox<UserModel>(Constants.userBox);
    }

    if (!Hive.isBoxOpen('knowledgeBase')) {
      await Hive.openBox<KnowledgeArticle>('knowledgeBase');
    }

    await _seedKnowledgeBase();
  }

  static Future<void> _seedKnowledgeBase() async {
    final box = Hive.box<KnowledgeArticle>('knowledgeBase');
    if (box.isEmpty) {
      await box.addAll([
        KnowledgeArticle(
          id: 'panic_grounding',
          category: 'panic',
          keywords: ['panic', 'scared', 'hyperventilating', 'heart racing', 'fear', 'cannot breathe'],
          content: 'Grounding Technique: Guide them through 5-4-3-2-1 breathing. Remind them they are safe, the sensation is temporary, and they can breathe through it.',
          appSuggestion: 'relief_resources',
        ),
        KnowledgeArticle(
          id: 'adhd_overwhelm',
          category: 'adhd',
          keywords: ['focus', 'adhd', 'distracted', 'procrastination', 'overwhelmed', 'cannot concentrate'],
          content: 'Action: Validate the difficulty of starting. Suggest breaking the goal into a single micro-task (e.g., "just write for 1 minute" or write task in Daily Goals).',
          appSuggestion: 'daily_goals',
        ),
        KnowledgeArticle(
          id: 'depression_sadness',
          category: 'depression',
          keywords: ['sad', 'lonely', 'depressed', 'crying', 'hopeless', 'heartbroken', 'empty'],
          content: 'Action: Validate their pain. Encourage small self-care step (drinking warm water, stretch, or journal thoughts).',
          appSuggestion: 'journal',
        ),
        KnowledgeArticle(
          id: 'anxiety_stress',
          category: 'anxiety',
          keywords: ['anxious', 'anxiety', 'worried', 'stress', 'nervous', 'tense'],
          content: 'Action: Remind them to release control of future. Deep breathing circle or box-breathing. Suggest tracking mood to identify triggers.',
          appSuggestion: 'mood',
        ),
        KnowledgeArticle(
          id: 'suicidal_thoughts',
          category: 'suicidal',
          keywords: ['suicide', 'kill myself', 'self-harm', 'die', 'hurt myself', 'give up'],
          content: 'Action: Direct, non-judgmental validation. Prioritize safety. Point directly to helpline page or panic SOS button immediately.',
          appSuggestion: 'helpline',
        ),
      ]);
    }
  }
}
