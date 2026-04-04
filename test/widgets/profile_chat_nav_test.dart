import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide PhoneAuthProvider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/core/constants/category_constants.dart';
import 'package:neighbourgo/features/auth/data/models/user_model.dart';
import 'package:neighbourgo/features/auth/data/repositories/auth_repository.dart';
import 'package:neighbourgo/features/auth/domain/providers/auth_provider.dart';
import 'package:neighbourgo/features/chat/data/repositories/chat_repository.dart';
import 'package:neighbourgo/features/chat/domain/models/chat_model.dart';
import 'package:neighbourgo/features/chat/domain/models/message_model.dart';
import 'package:neighbourgo/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:neighbourgo/features/chat/presentation/screens/chat_thread_screen.dart';
import 'package:neighbourgo/features/home/presentation/screens/main_shell_screen.dart';
import 'package:neighbourgo/features/profile/data/repositories/profile_repository.dart';
import 'package:neighbourgo/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:neighbourgo/features/profile/presentation/screens/photo_gallery_screen.dart';
import 'package:neighbourgo/features/profile/presentation/screens/profile_screen.dart';
import 'package:neighbourgo/features/tasks/data/models/task_model.dart';
import 'package:neighbourgo/features/tasks/data/repositories/task_repository.dart';

// =============================================================================
// Fakes
// =============================================================================

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => Stream.value(null);
  @override
  User? get currentUser => null;
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

class FakeFirebaseStorage extends Fake implements FirebaseStorage {}

class FakeAuthRepository extends AuthRepository {
  UserModel? userToReturn;
  bool shouldThrow = false;

  FakeAuthRepository()
      : super(
          auth: FakeFirebaseAuth(),
          db: FakeFirebaseFirestore(),
        );

  @override
  Stream<User?> get authStateChanges => Stream.value(null);
  @override
  User? get currentUser => null;

  @override
  Future<UserModel?> fetchCurrentUser() async {
    if (shouldThrow) throw Exception('fetch failed');
    return userToReturn;
  }

  @override
  Future<void> createOrUpdateUser(UserModel user) async {
    if (shouldThrow) throw Exception('update failed');
    userToReturn = user;
  }

  @override
  Stream<UserModel?> watchCurrentUser() => Stream.value(userToReturn);

  @override
  Future<void> signOut() async {}
}

class FakeProfileRepository extends ProfileRepository {
  bool updateCalled = false;

  FakeProfileRepository()
      : super(
          db: FakeFirebaseFirestore(),
          storage: FakeFirebaseStorage(),
        );

  @override
  Future<void> updateProfile(UserModel user) async {
    updateCalled = true;
  }

  @override
  Future<String> uploadAvatar(String uid, dynamic file) async {
    return 'https://example.com/avatar.jpg';
  }
}

class FakeChatRepository extends ChatRepository {
  List<ChatModel> chatsToReturn;
  List<MessageModel> messagesToReturn;
  ChatModel? chatToReturn;
  bool shouldThrowOnSend;
  bool shouldThrowOnGetChats;

  FakeChatRepository({
    this.chatsToReturn = const [],
    this.messagesToReturn = const [],
    this.chatToReturn,
    this.shouldThrowOnSend = false,
    this.shouldThrowOnGetChats = false,
  }) : super(db: FakeFirebaseFirestore(), storage: FakeFirebaseStorage());

  @override
  Stream<List<ChatModel>> getChatsStream(String userId) {
    if (shouldThrowOnGetChats) {
      return Stream.error(Exception('boom'));
    }
    return Stream.value(chatsToReturn);
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return Stream.value(messagesToReturn);
  }

  @override
  Stream<ChatModel?> getChatStream(String chatId) {
    return Stream.value(chatToReturn);
  }

  @override
  Future<void> sendMessage(String chatId, MessageModel message) async {
    if (shouldThrowOnSend) {
      throw Exception('send failed');
    }
  }

  @override
  Future<String> createOrGetChat(
      String taskId, String posterId, String providerId) async {
    return 'fake-chat-id';
  }
}

class FakeTaskRepository extends TaskRepository {
  List<TaskModel> tasksToReturn;
  final StreamController<List<TaskModel>> _controller =
      StreamController<List<TaskModel>>.broadcast();

  FakeTaskRepository({this.tasksToReturn = const []})
      : super(db: FakeFirebaseFirestore(), storage: FakeFirebaseStorage());

  @override
  Stream<List<TaskModel>> watchOpenTasks(
      {String? categoryId, int limit = 20, DocumentSnapshot? startAfter}) {
    Future.microtask(() => _controller.add(tasksToReturn));
    return _controller.stream;
  }

  @override
  Stream<List<TaskModel>> watchMyPostedTasks(String uid) {
    return Stream.value(tasksToReturn);
  }

  @override
  Future<String> createTask(TaskModel task,
      {List<dynamic> photos = const []}) async {
    return 'fake-task-id';
  }

  void dispose() => _controller.close();
}

// =============================================================================
// Test data
// =============================================================================

UserModel _testUser({
  String uid = 'test-uid',
  String displayName = 'Test User',
  UserRole role = UserRole.both,
  String phone = '+6591234567',
  String? headline,
  String? bio,
  List<String> serviceCategories = const [],
  List<String> skillTags = const [],
}) =>
    UserModel(
      uid: uid,
      phone: phone,
      displayName: displayName,
      role: role,
      headline: headline,
      bio: bio,
      serviceCategories: serviceCategories,
      skillTags: skillTags,
    );

ChatModel _testChat({
  String chatId = 'chat-1',
  String taskId = 'task-1',
  String taskTitle = 'Clean my HDB',
  String? lastMessage,
  DateTime? lastMessageTime,
  int unreadCount = 0,
}) =>
    ChatModel(
      chatId: chatId,
      taskId: taskId,
      taskTitle: taskTitle,
      participants: ['user-1', 'user-2'],
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
    );

// =============================================================================
// Helpers
// =============================================================================

Widget buildTestWidget(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

/// testWidgets with a large surface and overflow error suppression.
void testScreen(
  String description,
  Future<void> Function(WidgetTester tester) callback,
) {
  testWidgets(description, (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final origOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exception.toString();
      if (msg.contains('overflowed by')) return;
      origOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = origOnError);

    await callback(tester);
  });
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // ProfileScreen
  // ─────────────────────────────────────────────────────────────────────────
  group('ProfileScreen', () {
    final user = _testUser(
      displayName: 'Jane Doe',
      headline: 'Trusted cleaner',
      role: UserRole.provider,
    );

    late FakeAuthRepository fakeAuthRepo;

    setUp(() {
      fakeAuthRepo = FakeAuthRepository()..userToReturn = user;
    });

    List<Override> overrides() => [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          signOutProvider.overrideWithValue(() async {}),
        ];

    testScreen('renders Profile title', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
    });

    testScreen('renders avatar section with display name', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testScreen('renders menu items', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();
      expect(
          find.text('Edit Profile'), findsWidgets); // AppBar action + menu item
      expect(find.text('Verification Centre'), findsOneWidget);
      expect(find.text('Photo Gallery'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testScreen('renders current role section with Change Role button',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('My Role'), findsOneWidget);
      expect(find.text('Service Provider'), findsOneWidget);
      expect(find.text('Change Role'), findsOneWidget);
    });

    testScreen('shows friendly error when profile fails to load',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          currentUserProvider.overrideWith((_) => Stream.error(Exception('boom'))),
          signOutProvider.overrideWithValue(() async {}),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Could not load your profile right now.'),
          findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // EditProfileScreen
  // ─────────────────────────────────────────────────────────────────────────
  group('EditProfileScreen', () {
    final user = _testUser(
      displayName: 'Jane Doe',
      headline: 'Trusted cleaner',
      bio: 'I love cleaning!',
    );

    late FakeProfileRepository fakeProfileRepo;

    setUp(() {
      fakeProfileRepo = FakeProfileRepository();
    });

    List<Override> overrides() => [
          profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
          currentUserProvider.overrideWith((_) => Stream.value(user)),
        ];

    testScreen('renders Display Name, Headline, Bio fields pre-filled',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const EditProfileScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Headline'), findsOneWidget);
      expect(find.text('About Me'), findsOneWidget);
      // Pre-filled values
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Trusted cleaner'), findsOneWidget);
      expect(find.text('I love cleaning!'), findsOneWidget);
    });

    testScreen('renders Service Categories as FilterChips', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const EditProfileScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Service Categories'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(AppCategories.all.length));
    });

    testScreen('Save button exists in AppBar', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const EditProfileScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PhotoGalleryScreen
  // ─────────────────────────────────────────────────────────────────────────
  group('PhotoGalleryScreen', () {
    testScreen('shows add photos CTA when gallery is empty', (tester) async {
      final user = _testUser(role: UserRole.provider);
      await tester.pumpWidget(buildTestWidget(
        const PhotoGalleryScreen(),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No photos yet'), findsOneWidget);
      expect(find.text('Add Photos'), findsAtLeastNWidgets(1));
    });

    testScreen(
        'shows filter-specific empty state when selected category has no photos',
        (tester) async {
      final user = _testUser(
        role: UserRole.provider,
      ).copyWith(
        photos: [
          ProfilePhoto(
            id: 'photo-1',
            url: 'https://example.com/photo.jpg',
            categoryId: 'cleaning',
            uploadedAt: DateTime(2026, 4, 1),
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(
        const PhotoGalleryScreen(),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('📚 Tutoring'));
      await tester.pumpAndSettle();

      expect(find.text('No photos in this category'), findsOneWidget);
      expect(find.text('Show All Photos'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatListScreen
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatListScreen', () {
    final user = _testUser();

    testScreen('renders Messages title in AppBar', (tester) async {
      final fakeChatRepo = FakeChatRepository();
      await tester.pumpWidget(buildTestWidget(
        const ChatListScreen(),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          chatRepositoryProvider.overrideWithValue(fakeChatRepo),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Messages'), findsOneWidget);
    });

    testScreen('shows empty state when no chats', (tester) async {
      final fakeChatRepo = FakeChatRepository(chatsToReturn: []);
      await tester.pumpWidget(buildTestWidget(
        const ChatListScreen(),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          chatRepositoryProvider.overrideWithValue(fakeChatRepo),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('No conversations yet'), findsOneWidget);
      expect(
          find.text(
              'Accept a bid or open one of your tasks to message a provider'),
          findsOneWidget);
      expect(find.text('💬'), findsOneWidget);
      expect(find.text('View My Tasks'), findsOneWidget);
    });

    testScreen('shows provider-specific empty state CTA', (tester) async {
      final fakeChatRepo = FakeChatRepository(chatsToReturn: []);
      final providerUser = _testUser(role: UserRole.provider);
      await tester.pumpWidget(buildTestWidget(
        const ChatListScreen(),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(providerUser)),
          chatRepositoryProvider.overrideWithValue(fakeChatRepo),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Bid on an open task to start chatting with posters'),
          findsOneWidget);
      expect(find.text('Browse Tasks'), findsOneWidget);
    });

    testScreen('shows friendly error when chats fail to load', (tester) async {
      final fakeChatRepo = FakeChatRepository(shouldThrowOnGetChats: true);
      await tester.pumpWidget(buildTestWidget(
        const ChatListScreen(),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          chatRepositoryProvider.overrideWithValue(fakeChatRepo),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Could not load your conversations right now.'),
          findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatThreadScreen
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatThreadScreen', () {
    final user = _testUser();
    final chat = _testChat(taskTitle: 'Clean my HDB');

    testScreen('renders message input field and send button', (tester) async {
      final fakeChatRepo = FakeChatRepository(
        chatToReturn: chat,
        messagesToReturn: [],
      );
      await tester.pumpWidget(buildTestWidget(
        const ChatThreadScreen(chatId: 'chat-1'),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          chatRepositoryProvider.overrideWithValue(fakeChatRepo),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type a message…'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testScreen('shows empty state when no messages', (tester) async {
      final fakeChatRepo = FakeChatRepository(
        chatToReturn: chat,
        messagesToReturn: [],
      );
      await tester.pumpWidget(buildTestWidget(
        const ChatThreadScreen(chatId: 'chat-1'),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          chatRepositoryProvider.overrideWithValue(fakeChatRepo),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Say hello!'), findsOneWidget);
    });

    testScreen('restores typed message when send fails',
        (tester) async {
      final fakeChatRepo = FakeChatRepository(
        chatToReturn: chat,
        messagesToReturn: [],
        shouldThrowOnSend: true,
      );
      await tester.pumpWidget(buildTestWidget(
        const ChatThreadScreen(chatId: 'chat-1'),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          chatRepositoryProvider.overrideWithValue(fakeChatRepo),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello there');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Hello there'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // MainShellScreen
  // ─────────────────────────────────────────────────────────────────────────
  group('MainShellScreen', () {
    testScreen('renders bottom navigation bar with 5 items', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const MainShellScreen(child: Scaffold(body: Text('Home Content'))),
      ));
      await tester.pump();
      // 5 tab labels: Home, Discover, (Post has no label), Messages, Profile
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testScreen('bottom nav includes correct icons', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const MainShellScreen(child: Scaffold(body: Text('Home Content'))),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.home), findsOneWidget); // active home icon
      expect(find.byIcon(Icons.search_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testScreen('FAB (Post Task) button renders with gradient', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const MainShellScreen(child: Scaffold(body: Text('Home Content'))),
      ));
      await tester.pump();
      // The Post FAB uses Icons.add inside a gradient Container
      expect(find.byIcon(Icons.add), findsOneWidget);
      // Verify the gradient container exists
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.gradient != null;
        }
        return false;
      });
      expect(hasGradient, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HomeScreen (role-aware dispatcher)
  // ─────────────────────────────────────────────────────────────────────────
  group('HomeScreen', () {
    late FakeTaskRepository fakeTaskRepo;

    setUp(() {
      fakeTaskRepo = FakeTaskRepository();
    });

    testScreen('renders PosterHomeScreen for poster role user', (tester) async {
      final user = _testUser(role: UserRole.poster);
      await tester.pumpWidget(buildTestWidget(
        const HomeScreen(),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
        ],
      ));
      await tester.pumpAndSettle();
      // PosterHomeScreen shows 'My Tasks' and 'Post a Task' (appears in both top CTA and empty state)
      expect(find.text('My Tasks'), findsOneWidget);
      expect(find.text('Post a Task'), findsAtLeastNWidgets(1));
    });

    testScreen('renders ProviderHomeScreen for provider role user',
        (tester) async {
      final user = _testUser(role: UserRole.provider);
      await tester.pumpWidget(buildTestWidget(
        const HomeScreen(),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
        ],
      ));
      await tester.pumpAndSettle();
      // ProviderHomeScreen shows 'Find Work' and 'All Open Tasks'
      expect(find.text('Find Work'), findsOneWidget);
      expect(find.text('All Open Tasks'), findsOneWidget);
    });

    testScreen('renders TabBar with Find Help and Find Work tabs for both role',
        (tester) async {
      final user = _testUser(role: UserRole.both);
      await tester.pumpWidget(buildTestWidget(
        const HomeScreen(),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Find Help'), findsOneWidget);
      expect(find.text('Find Work'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });
  });
}
