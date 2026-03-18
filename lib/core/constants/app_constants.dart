// ─────────────────────────────────────────────────────────────────────────────
// App-wide constants
// ─────────────────────────────────────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  static const appName        = 'NeighbourGo';
  static const appVersion     = '1.0.0';
  static const supportEmail   = 'support@neighbourgo.sg';
  static const privacyPolicyUrl = 'https://neighbourgo.sg/privacy';
  static const termsUrl         = 'https://neighbourgo.sg/terms';

  // Firestore collection names
  static const usersCol      = 'users';
  static const tasksCol      = 'tasks';
  static const bidsCol       = 'bids';
  static const chatsCol      = 'chats';
  static const messagesCol   = 'messages';
  static const reviewsCol    = 'reviews';
  static const paymentsCol   = 'payments';
  static const notificationsCol = 'notifications';

  // Storage paths
  static const profilePhotosPath  = 'profile_photos';
  static const taskPhotosPath      = 'task_photos';
  static const chatMediaPath       = 'chat_media';
  static const verificationDocsPath = 'verification_docs';

  // Pagination
  static const pageSize = 20;

  // Search radius options (km)
  static const radiusOptions = [1, 2, 3, 5, 10];
  static const defaultRadius = 3;

  // Media limits
  static const maxProfilePhotos    = 12;
  static const maxProfilePhotosMB  = 10;
  static const maxTaskPhotos       = 6;
  static const maxVideoSeconds     = 60;
  static const maxVideoMB          = 50;

  // Platform fee percentage
  static const platformFeePercent  = 13.0;   // 13% blended

  // Currencies
  static const currency = 'SGD';
  static const currencySymbol = 'S\$';

  // Singapore phone prefix
  static const phonePrefix = '+65';

  // Session timeout (minutes)
  static const sessionTimeoutMinutes = 30;
}

// ─────────────────────────────────────────────────────────────────────────────
// Route names (used with GoRouter)
// ─────────────────────────────────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const splash          = '/';
  static const welcome         = '/welcome';
  static const phoneAuth       = '/auth/phone';
  static const otpVerify       = '/auth/otp';
  static const roleSelect      = '/auth/role';
  static const profileSetup    = '/auth/profile-setup';

  // Main
  static const home            = '/home';
  static const taskList        = '/tasks';
  static const taskDetail      = '/tasks/:taskId';
  static const postTask        = '/tasks/post';
  static const myTasks         = '/tasks/mine';
  static const bidsReceived    = '/tasks/:taskId/bids';

  // Profile
  static const myProfile       = '/profile';
  static const publicProfile   = '/profile/:userId';
  static const editProfile     = '/profile/edit';
  static const photoGallery    = '/profile/gallery';
  static const verificationCentre = '/profile/verify';

  // Chat
  static const chatList        = '/chats';
  static const chatThread      = '/chats/:chatId';

  // Payments
  static const wallet          = '/wallet';
  static const checkout        = '/checkout/:taskId';

  // Settings
  static const settings        = '/settings';
  static const notifications   = '/settings/notifications';
  static const helpSupport     = '/settings/help';
}
