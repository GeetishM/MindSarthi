import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/api/api_service.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/constants.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/boxes.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/chat_history.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/models/message.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/user_model.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _inChatMessages = [];
  final PageController _pageController = PageController();
  List<XFile>? _imagesFileList = [];
  int _currentIndex = 0;
  String _currentChatId = '';
  GenerativeModel? _model;
  GenerativeModel? _textModel;
  GenerativeModel? _visionModel;
  String _modelType = 'gemini-pro';
  bool _isLoading = false;

  List<Message> get inChatMessages => _inChatMessages;
  PageController get pageController => _pageController;
  List<XFile>? get imagesFileList => _imagesFileList;
  int get currentIndex => _currentIndex;
  String get currentChatId => _currentChatId;
  GenerativeModel? get model => _model;
  GenerativeModel? get textModel => _textModel;
  GenerativeModel? get visionModel => _visionModel;
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

  String getApiKey() => ApiService.apiKey;

  String getChatId() =>
      _currentChatId.isEmpty ? const Uuid().v4() : _currentChatId;

  List<String> getImagesUrls({required bool isTextOnly}) {
    return !isTextOnly && _imagesFileList != null
        ? _imagesFileList!.map((img) => img.path).toList()
        : [];
  }

  Future<Content> getContent({
    required String message,
    required bool isTextOnly,
  }) async {
    if (isTextOnly) return Content.text(message);

    final imageFutures =
        _imagesFileList?.map((image) => image.readAsBytes()).toList();
    final imageBytes = await Future.wait(imageFutures!);
    final prompt = TextPart(message);
    final imageParts =
        imageBytes
            .map((bytes) => DataPart('image/jpeg', Uint8List.fromList(bytes)))
            .toList();
    return Content.multi([prompt, ...imageParts]);
  }

  Future<void> setModel({required bool isTextOnly}) async {
    log('Using API key: ${getApiKey()}');
    _model =
        isTextOnly
            ? (_textModel ??= GenerativeModel(
              model: setCurrentModel(newModel: 'gemini-2.0-flash'),
              apiKey: getApiKey(),
              generationConfig: GenerationConfig(
                temperature: 0.4,
                topK: 32,
                topP: 1,
                maxOutputTokens: 4096,
              ),
              safetySettings: [
                SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
                SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
              ],
            ))
            : (_visionModel ??= GenerativeModel(
              model: setCurrentModel(newModel: 'gemini-1.5-flash'),
              apiKey: getApiKey(),
              generationConfig: GenerationConfig(
                temperature: 0.4,
                topK: 32,
                topP: 1,
                maxOutputTokens: 4096,
              ),
              safetySettings: [
                SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
                SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
              ],
            ));
    notifyListeners();
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

  Future<List<Content>> getHistory({required String chatId}) async {
    final List<Content> history = [];
    if (_currentChatId.isNotEmpty) {
      await setInChatMessages(chatId: chatId);
      for (var msg in _inChatMessages) {
        history.add(
          msg.role == Role.user
              ? Content.text(msg.message.toString())
              : Content.model([TextPart(msg.message.toString())]),
        );
      }
    }
    return history;
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
    await setModel(isTextOnly: isTextOnly);
    setLoading(value: true);

    final chatId = getChatId();
    final history = await getHistory(chatId: chatId);
    final imagesUrls = getImagesUrls(isTextOnly: isTextOnly);
    final messagesBox = await Hive.openBox(
      '${Constants.chatMessagesBox}$chatId',
    );

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
      history: history,
      userMessage: userMessage,
      modelMessageId: assistantMessageId,
      messagesBox: messagesBox,
    );
  }

  Future<void> sendMessageAndWaitForResponse({
    required String message,
    required String chatId,
    required bool isTextOnly,
    required List<Content> history,
    required Message userMessage,
    required String modelMessageId,
    required Box messagesBox,
  }) async {
    final chatSession = _model!.startChat(
      history: history.isEmpty || !isTextOnly ? null : history,
    );
    final content = await getContent(message: message, isTextOnly: isTextOnly);

    final assistantMessage = userMessage.copyWith(
      messageId: modelMessageId,
      role: Role.assistant,
      message: StringBuffer(),
      timeSent: DateTime.now(),
    );

    _inChatMessages.add(assistantMessage);
    notifyListeners();

    chatSession
        .sendMessageStream(content)
        .listen(
          (event) {
            _inChatMessages
                .firstWhere(
                  (m) =>
                      m.messageId == assistantMessage.messageId &&
                      m.role.name == Role.assistant.name,
                )
                .message
                .write(event.text);
            notifyListeners();
          },
          onDone: () async {
            await saveMessagesToDB(
              chatID: chatId,
              userMessage: userMessage,
              assistantMessage: assistantMessage,
              messagesBox: messagesBox,
            );
            setLoading(value: false);
          },
          onError: (e) {
            log('Gemini error: $e');
            setLoading(value: false);
          },
        );
  }

  Future<void> saveMessagesToDB({
    required String chatID,
    required Message userMessage,
    required Message assistantMessage,
    required Box messagesBox,
  }) async {
    await messagesBox.add(userMessage.toMap());
    await messagesBox.add(assistantMessage.toMap());

    final chatHistoryBox = Boxes.getChatHistory();
    final chatHistory = ChatHistory(
      chatId: chatID,
      prompt: userMessage.message.toString(),
      response: assistantMessage.message.toString(),
      imagesUrls: userMessage.imagesUrls,
      timestamp: DateTime.now(),
    );

    await chatHistoryBox.put(chatID, chatHistory);
    await messagesBox.close();
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
    if (!Hive.isBoxOpen(Constants.chatHistoryBox)) {
      await Hive.openBox<ChatHistory>(Constants.chatHistoryBox);
    }

    if (!Hive.isBoxOpen(Constants.userBox)) {
      await Hive.openBox<UserModel>(Constants.userBox);
    }
  }
}
