import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/image_validator.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/models/message_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firestore conversion helpers
// ─────────────────────────────────────────────────────────────────────────────
ChatModel _chatFromFirestore(DocumentSnapshot doc) {
  final data = Map<String, dynamic>.from(doc.data() as Map);
  if (data['lastMessageTime'] is Timestamp) {
    data['lastMessageTime'] =
        (data['lastMessageTime'] as Timestamp).toDate().toIso8601String();
  }
  return ChatModel.fromJson({...data, 'chatId': doc.id});
}

MessageModel _messageFromFirestore(DocumentSnapshot doc) {
  final data = Map<String, dynamic>.from(doc.data() as Map);
  if (data['timestamp'] is Timestamp) {
    data['timestamp'] =
        (data['timestamp'] as Timestamp).toDate().toIso8601String();
  }
  return MessageModel.fromJson({...data, 'messageId': doc.id});
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────
class ChatRepository {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  ChatRepository({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference get _chats => _db.collection(AppConstants.chatsCol);

  // ── Build deterministic chatId ────────────────────────────────────────────
  static String buildChatId(String taskId, String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${taskId}_${sorted.join('_')}';
  }

  // ── Stream all chats for a user ───────────────────────────────────────────
  Stream<List<ChatModel>> getChatsStream(String userId) {
    return _chats
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_chatFromFirestore).toList());
  }

  // ── Stream a single chat document ─────────────────────────────────────────
  Stream<ChatModel?> getChatStream(String chatId) {
    return _chats.doc(chatId).snapshots().map(
          (s) => s.exists ? _chatFromFirestore(s) : null,
        );
  }

  // ── Stream messages for a chat ────────────────────────────────────────────
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection(AppConstants.messagesCol)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(_messageFromFirestore).toList());
  }

  // ── Send a message ────────────────────────────────────────────────────────
  Future<void> sendMessage(String chatId, MessageModel message) async {
    final msgId = _uuid.v4();
    final now = DateTime.now();
    final msgData = {
      ...message.copyWith(messageId: msgId, timestamp: now).toJson(),
      'timestamp': Timestamp.fromDate(now),
    };

    await _chats
        .doc(chatId)
        .collection(AppConstants.messagesCol)
        .doc(msgId)
        .set(msgData);

    await _chats.doc(chatId).update({
      'lastMessage': message.text ?? '📷 Image',
      'lastMessageTime': Timestamp.fromDate(now),
    });
  }

  // ── Upload chat image ─────────────────────────────────────────────────────
  Future<String> uploadChatImage(String chatId, File file) async {
    final validationError = ImageValidator.validate(file);
    if (validationError != null) throw Exception(validationError);

    final id = _uuid.v4();
    final ext = file.path.split('.').last;
    final ref =
        _storage.ref('${AppConstants.chatMediaPath}/$chatId/$id.$ext');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}'),
    );
    return task.ref.getDownloadURL();
  }

  // ── Mark all messages in a chat as read ────────────────────────────────────
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final batch = _db.batch();

    // Get unread messages NOT sent by the current user
    final unread = await _chats
        .doc(chatId)
        .collection(AppConstants.messagesCol)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Reset unread count on the chat document
    batch.update(_chats.doc(chatId), {'unreadCount': 0});

    if (unread.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  // ── Create or get a direct (non-task) chat ─────────────────────────────────
  Future<String> createDirectChat(
      String uid1, String uid2, String otherUserName) async {
    final sorted = [uid1, uid2]..sort();
    final chatId = 'direct_${sorted.join('_')}';
    final chatRef = _chats.doc(chatId);

    try {
      final existing = await chatRef.get();
      if (existing.exists) return chatId;
    } catch (_) {}

    await chatRef.set({
      'chatId': chatId,
      'taskId': null,
      'taskTitle': null,
      'otherUserName': otherUserName,
      'participantIds': sorted,
      'lastMessage': null,
      'lastMessageTime': null,
      'unreadCount': 0,
      'createdAt': Timestamp.now(),
    });

    return chatId;
  }

  // ── Create chat and send initial message ────────────────────────────────
  Future<String> createChatWithMessage({
    required String taskId,
    required String posterId,
    required String providerId,
    required String senderId,
    required String messageText,
  }) async {
    final chatId = await createOrGetChat(taskId, posterId, providerId);
    final message = MessageModel(
      messageId: '',
      chatId: chatId,
      senderId: senderId,
      text: messageText,
      timestamp: DateTime.now(),
    );
    await sendMessage(chatId, message);
    return chatId;
  }

  // ── Create or get existing chat ───────────────────────────────────────────
  Future<String> createOrGetChat(
      String taskId, String posterId, String providerId) async {
    final chatId = buildChatId(taskId, posterId, providerId);
    final chatRef = _chats.doc(chatId);

    // Try reading first — if it exists and user is a participant, just return.
    // If get fails (permission-denied for non-existent doc), create it.
    try {
      final existing = await chatRef.get();
      if (existing.exists) return chatId;
    } catch (_) {
      // Permission denied — doc likely doesn't exist yet.
    }

    String taskTitle = 'Task';
    try {
      final taskSnap =
          await _db.collection(AppConstants.tasksCol).doc(taskId).get();
      if (taskSnap.exists) {
        taskTitle = (taskSnap.data() as Map<String, dynamic>)['title']
                as String? ??
            'Task';
      }
    } catch (_) {}

    final sorted = [posterId, providerId]..sort();
    await chatRef.set({
      'chatId': chatId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'participantIds': sorted,
      'lastMessage': null,
      'lastMessageTime': null,
      'unreadCount': 0,
      'createdAt': Timestamp.now(),
    });

    return chatId;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>(
  (_) => ChatRepository(),
);

final chatsStreamProvider =
    StreamProvider.family<List<ChatModel>, String>((ref, userId) {
  return ref.watch(chatRepositoryProvider).getChatsStream(userId);
});

final messagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).getMessagesStream(chatId);
});

final chatStreamProvider =
    StreamProvider.family<ChatModel?, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).getChatStream(chatId);
});

final unreadChatsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  return ref.watch(chatRepositoryProvider).getChatsStream(user.uid).map(
    (chats) => chats.fold<int>(0, (total, c) => total + c.unreadCount),
  );
});
