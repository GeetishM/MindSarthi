import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:appwrite/appwrite.dart' hide Role;
import 'package:uuid/uuid.dart';
import 'appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Journal/journal_entry.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/MoodInputs/models/mood_entry.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/task.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/chat_history.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/models/message.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _uuid = const Uuid();
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  /// Main method to sync all collections bidirectionally.
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    debugPrint("SyncService: Starting synchronization...");

    try {
      final user = await AppwriteService().account.get();
      final uid = user.$id;

      // 1. Associate any legacy guest data with the logged-in user ID
      await _associateGuestData(uid);

      // 2. Sync Journals
      await _syncJournals(uid);

      // 3. Sync Moods
      await _syncMoods(uid);

      // 4. Sync Tasks
      await _syncTasks(uid);

      // 5. Sync Chats & Messages
      await _syncChatsAndMessages(uid);

      debugPrint("SyncService: Synchronization completed successfully!");
    } catch (e) {
      debugPrint("SyncService: Synchronization failed or user offline: $e");
    } finally {
      _isSyncing = false;
    }
  }

  /// Associates local data created when not logged in with the current user ID
  Future<void> _associateGuestData(String uid) async {
    // 1. Journals
    final journalBox = Hive.box<JournalEntry>('journalBox');
    for (var key in journalBox.keys) {
      final entry = journalBox.get(key);
      if (entry != null && (entry.userId == null || entry.userId!.isEmpty)) {
        entry.userId = uid;
        entry.isSynced = false;
        await entry.save();
      }
    }

    // 2. Moods
    final moodsBox = Hive.box<MoodEntry>('moodsBox');
    for (var key in moodsBox.keys) {
      final entry = moodsBox.get(key);
      if (entry != null && entry.userId.isEmpty) {
        final updated = MoodEntry(
          id: entry.id,
          mood: entry.mood,
          emotions: entry.emotions,
          activities: entry.activities,
          notes: entry.notes,
          timestamp: entry.timestamp,
          userId: uid,
          isSynced: false,
        );
        await moodsBox.put(key, updated);
      }
    }

    // 3. Tasks
    final tasksBox = Hive.box<Task>('tasksBox');
    for (var key in tasksBox.keys) {
      final entry = tasksBox.get(key);
      if (entry != null && (entry.userId == null || entry.userId!.isEmpty)) {
        entry.userId = uid;
        entry.isSynced = false;
        await entry.save();
      }
    }

    // 4. Chats
    final chatBox = Hive.box<ChatHistory>('chat_history');
    for (var key in chatBox.keys) {
      final entry = chatBox.get(key);
      if (entry != null && (entry.userId == null || entry.userId!.isEmpty)) {
        entry.userId = uid;
        entry.isSynced = false;
        await entry.save();
      }
    }
  }

  /// Pushes unsynced Journals to Appwrite, and pulls remote ones.
  Future<void> _syncJournals(String uid) async {
    final journalBox = Hive.box<JournalEntry>('journalBox');
    final databases = AppwriteService().databases;

    // A. Push local changes
    for (var key in journalBox.keys) {
      final entry = journalBox.get(key);
      if (entry == null) continue;

      if (entry.id == null || entry.id!.isEmpty) {
        entry.id = _uuid.v4();
        entry.isSynced = false;
        await entry.save();
      }

      if (entry.isSynced == false) {
        final journalData = {
          'id': entry.id,
          'title': entry.title,
          'content': entry.content,
          'createdAt': entry.createdAt.toIso8601String(),
          'lastEdited': entry.lastEdited.toIso8601String(),
          'tag': entry.tag,
          'sentimentScore': entry.sentimentScore,
          'sentimentEmotions': entry.sentimentEmotions,
          'sentimentRecommendation': entry.sentimentRecommendation,
          'crisisFlag': entry.crisisFlag,
          'userId': uid,
        };

        try {
          await databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.journalsCollectionId,
            documentId: entry.id!,
            data: journalData,
          );
          entry.isSynced = true;
          await entry.save();
        } on AppwriteException catch (ae) {
          if (ae.code == 409) {
            await databases.updateDocument(
              databaseId: AppwriteConstants.databaseId,
              collectionId: AppwriteConstants.journalsCollectionId,
              documentId: entry.id!,
              data: journalData,
            );
            entry.isSynced = true;
            await entry.save();
          } else {
            debugPrint("Sync journals error: ${ae.message}");
          }
        }
      }
    }

    // B. Pull remote updates
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.journalsCollectionId,
        queries: [
          Query.equal('userId', uid),
          Query.limit(100),
        ],
      );

      for (var doc in response.documents) {
        final docData = doc.data;
        final docId = docData['id'] as String?;
        if (docId == null || docId.isEmpty) continue;

        // Check if we have this locally
        final localMatchKey = journalBox.values.toList().indexWhere((e) => e.id == docId);

        final title = docData['title'] ?? '';
        final content = docData['content'] ?? '';
        final createdAt = DateTime.tryParse(docData['createdAt'] ?? '') ?? DateTime.now();
        final lastEdited = DateTime.tryParse(docData['lastEdited'] ?? '') ?? DateTime.now();
        final tagsList = List<String>.from(docData['tag'] ?? []);
        final sentimentScore = (docData['sentimentScore'] as num?)?.toDouble();
        final sentimentEmotions = List<String>.from(docData['sentimentEmotions'] ?? []);
        final sentimentRecommendation = docData['sentimentRecommendation'] as String?;
        final crisisFlag = docData['crisisFlag'] as bool?;

        if (localMatchKey == -1) {
          // Add to local
          final newEntry = JournalEntry(
            title: title,
            content: content,
            createdAt: createdAt,
            lastEdited: lastEdited,
            tag: tagsList,
            sentimentScore: sentimentScore,
            sentimentEmotions: sentimentEmotions,
            sentimentRecommendation: sentimentRecommendation,
            crisisFlag: crisisFlag,
            id: docId,
            isSynced: true,
            userId: uid,
          );
          await journalBox.add(newEntry);
        } else {
          final localEntry = journalBox.getAt(localMatchKey);
          if (localEntry != null && localEntry.lastEdited.isBefore(lastEdited)) {
            // Update local
            localEntry.title = title;
            localEntry.content = content;
            localEntry.createdAt = createdAt;
            localEntry.lastEdited = lastEdited;
            localEntry.tag = tagsList;
            localEntry.sentimentScore = sentimentScore;
            localEntry.sentimentEmotions = sentimentEmotions;
            localEntry.sentimentRecommendation = sentimentRecommendation;
            localEntry.crisisFlag = crisisFlag;
            localEntry.isSynced = true;
            await localEntry.save();
          }
        }
      }
    } catch (e) {
      debugPrint("Pull journals error: $e");
    }
  }

  /// Pushes unsynced Moods to Appwrite, and pulls remote ones.
  Future<void> _syncMoods(String uid) async {
    final moodsBox = Hive.box<MoodEntry>('moodsBox');
    final databases = AppwriteService().databases;

    // A. Push local changes
    for (var key in moodsBox.keys) {
      final entry = moodsBox.get(key);
      if (entry == null) continue;

      if (!entry.isSynced) {
        final moodData = entry.toAppwrite();

        try {
          await databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.moodsCollectionId,
            documentId: entry.id,
            data: moodData,
          );
          final updated = MoodEntry(
            id: entry.id,
            mood: entry.mood,
            emotions: entry.emotions,
            activities: entry.activities,
            notes: entry.notes,
            timestamp: entry.timestamp,
            userId: uid,
            isSynced: true,
          );
          await moodsBox.put(key, updated);
        } on AppwriteException catch (ae) {
          if (ae.code == 409) {
            await databases.updateDocument(
              databaseId: AppwriteConstants.databaseId,
              collectionId: AppwriteConstants.moodsCollectionId,
              documentId: entry.id,
              data: moodData,
            );
            final updated = MoodEntry(
              id: entry.id,
              mood: entry.mood,
              emotions: entry.emotions,
              activities: entry.activities,
              notes: entry.notes,
              timestamp: entry.timestamp,
              userId: uid,
              isSynced: true,
            );
            await moodsBox.put(key, updated);
          } else {
            debugPrint("Sync moods error: ${ae.message}");
          }
        }
      }
    }

    // B. Pull remote updates
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.moodsCollectionId,
        queries: [
          Query.equal('userId', uid),
          Query.orderDesc('timestamp'),
          Query.limit(100),
        ],
      );

      for (var doc in response.documents) {
        final docId = doc.$id;
        final data = doc.data;

        // Check local
        if (!moodsBox.containsKey(docId)) {
          final remoteEntry = MoodEntry.fromAppwrite(data, docId);
          await moodsBox.put(docId, remoteEntry);
        }
      }
    } catch (e) {
      debugPrint("Pull moods error: $e");
    }
  }

  /// Pushes unsynced Tasks to Appwrite, and pulls remote ones.
  Future<void> _syncTasks(String uid) async {
    final tasksBox = Hive.box<Task>('tasksBox');
    final databases = AppwriteService().databases;

    // A. Push local changes
    for (var key in tasksBox.keys) {
      final entry = tasksBox.get(key);
      if (entry == null) continue;

      if (entry.id == null || entry.id!.isEmpty) {
        entry.id = _uuid.v4();
        entry.isSynced = false;
        await entry.save();
      }

      if (entry.isSynced == false) {
        final taskData = {
          'id': entry.id,
          'title': entry.title,
          'isCompleted': entry.isCompleted,
          'date': entry.date.toIso8601String(),
          'rescheduleCount': entry.rescheduleCount,
          'category': entry.category,
          'userId': uid,
        };

        try {
          await databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.tasksCollectionId,
            documentId: entry.id!,
            data: taskData,
          );
          entry.isSynced = true;
          await entry.save();
        } on AppwriteException catch (ae) {
          if (ae.code == 409) {
            await databases.updateDocument(
              databaseId: AppwriteConstants.databaseId,
              collectionId: AppwriteConstants.tasksCollectionId,
              documentId: entry.id!,
              data: taskData,
            );
            entry.isSynced = true;
            await entry.save();
          } else {
            debugPrint("Sync tasks error: ${ae.message}");
          }
        }
      }
    }

    // B. Pull remote updates
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tasksCollectionId,
        queries: [
          Query.equal('userId', uid),
          Query.limit(100),
        ],
      );

      for (var doc in response.documents) {
        final docData = doc.data;
        final docId = docData['id'] as String?;
        if (docId == null || docId.isEmpty) continue;

        // Check if we have this locally
        final localMatchKey = tasksBox.values.toList().indexWhere((e) => e.id == docId);

        final title = docData['title'] ?? '';
        final isCompleted = docData['isCompleted'] ?? false;
        final date = DateTime.tryParse(docData['date'] ?? '') ?? DateTime.now();
        final rescheduleCount = docData['rescheduleCount'] ?? 0;
        final category = docData['category'] ?? '';

        if (localMatchKey == -1) {
          final newTask = Task(
            title: title,
            isCompleted: isCompleted,
            date: date,
            rescheduleCount: rescheduleCount,
            category: category,
            id: docId,
            isSynced: true,
            userId: uid,
          );
          await tasksBox.add(newTask);
        } else {
          final localTask = tasksBox.getAt(localMatchKey);
          if (localTask != null) {
            // Update local with remote values
            localTask.title = title;
            localTask.isCompleted = isCompleted;
            localTask.date = date;
            localTask.rescheduleCount = rescheduleCount;
            localTask.category = category;
            localTask.isSynced = true;
            await localTask.save();
          }
        }
      }
    } catch (e) {
      debugPrint("Pull tasks error: $e");
    }
  }

  /// Pushes/pulls Chat histories and messages.
  Future<void> _syncChatsAndMessages(String uid) async {
    final chatBox = Hive.box<ChatHistory>('chat_history');
    final databases = AppwriteService().databases;

    // A. Push local chat histories
    for (var key in chatBox.keys) {
      final entry = chatBox.get(key);
      if (entry == null) continue;

      if (entry.isSynced == false) {
        final chatData = {
          'chatId': entry.chatId,
          'prompt': entry.prompt,
          'response': entry.response,
          'imagesUrls': entry.imagesUrls,
          'timestamp': entry.timestamp.toIso8601String(),
          'userId': uid,
        };

        try {
          await databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.chatsCollectionId,
            documentId: entry.chatId,
            data: chatData,
          );
          entry.isSynced = true;
          await entry.save();
        } on AppwriteException catch (ae) {
          if (ae.code == 409) {
            await databases.updateDocument(
              databaseId: AppwriteConstants.databaseId,
              collectionId: AppwriteConstants.chatsCollectionId,
              documentId: entry.chatId,
              data: chatData,
            );
            entry.isSynced = true;
            await entry.save();
          } else {
            debugPrint("Sync chats error: ${ae.message}");
          }
        }
      }

      // Sync individual messages in this chat
      final msgBoxName = 'chat_messages_${entry.chatId}';
      if (await Hive.boxExists(msgBoxName)) {
        final msgBox = await Hive.openBox(msgBoxName);
        for (var mKey in msgBox.keys) {
          final mData = msgBox.get(mKey);
          if (mData == null) continue;

          final msg = Message.fromMap(Map<String, dynamic>.from(mData));
          if (!msg.isSynced) {
            final appwriteMsgData = {
              'messageId': msg.messageId,
              'chatId': msg.chatId,
              'role': msg.role.index,
              'message': msg.message.toString(),
              'imagesUrls': msg.imagesUrls,
              'timeSent': msg.timeSent.toIso8601String(),
              'userId': uid,
            };

            try {
              await databases.createDocument(
                databaseId: AppwriteConstants.databaseId,
                collectionId: AppwriteConstants.messagesCollectionId,
                documentId: msg.messageId,
                data: appwriteMsgData,
              );
              msg.isSynced = true;
              msg.userId = uid;
              await msgBox.put(mKey, msg.toMap());
            } on AppwriteException catch (ae) {
              if (ae.code == 409) {
                await databases.updateDocument(
                  databaseId: AppwriteConstants.databaseId,
                  collectionId: AppwriteConstants.messagesCollectionId,
                  documentId: msg.messageId,
                  data: appwriteMsgData,
                );
                msg.isSynced = true;
                msg.userId = uid;
                await msgBox.put(mKey, msg.toMap());
              } else {
                debugPrint("Sync message error: ${ae.message}");
              }
            }
          }
        }
        await msgBox.close();
      }
    }

    // B. Pull remote Chat histories & Messages
    try {
      final chatResponse = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatsCollectionId,
        queries: [
          Query.equal('userId', uid),
          Query.limit(100),
        ],
      );

      for (var chatDoc in chatResponse.documents) {
        final data = chatDoc.data;
        final cId = data['chatId'] as String?;
        if (cId == null || cId.isEmpty) continue;

        if (!chatBox.containsKey(cId)) {
          final newChat = ChatHistory(
            chatId: cId,
            prompt: data['prompt'] ?? '',
            response: data['response'] ?? '',
            imagesUrls: List<String>.from(data['imagesUrls'] ?? []),
            timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
            isSynced: true,
            userId: uid,
          );
          await chatBox.put(cId, newChat);
        }

        // Pull messages for this chat
        final msgResponse = await databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.messagesCollectionId,
          queries: [
            Query.equal('chatId', cId),
            Query.limit(100),
          ],
        );

        if (msgResponse.documents.isNotEmpty) {
          final msgBoxName = 'chat_messages_$cId';
          final msgBox = await Hive.openBox(msgBoxName);
          
          for (var mDoc in msgResponse.documents) {
            final mData = mDoc.data;
            final mId = mData['messageId'] as String?;
            if (mId == null || mId.isEmpty) continue;

            // Check if local messages contain this messageId
            final hasLocal = msgBox.values.any((m) {
              final localMsg = Message.fromMap(Map<String, dynamic>.from(m));
              return localMsg.messageId == mId;
            });

            if (!hasLocal) {
              final newMsg = Message(
                messageId: mId,
                chatId: cId,
                role: Role.values[mData['role'] ?? 0],
                message: StringBuffer(mData['message'] ?? ''),
                imagesUrls: List<String>.from(mData['imagesUrls'] ?? []),
                timeSent: DateTime.tryParse(mData['timeSent'] ?? '') ?? DateTime.now(),
                isSynced: true,
                userId: uid,
              );
              await msgBox.add(newMsg.toMap());
            }
          }
          await msgBox.close();
        }
      }
    } catch (e) {
      debugPrint("Pull chats and messages error: $e");
    }
  }
}
