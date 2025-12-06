const String kApiBaseUrl = 'https://teammy-api.onrender.com';

/// Centralized list of API endpoints mirroring the shared API spec.
class ApiPath {
  ApiPath._();

  /// Public endpoints.
  static const commonPublic = '/api/client';

  /// Authentication endpoints.
  static const authLogin = '/api/auth/login';
  static const authMe = '/api/auth/me';

  /// Admin endpoints.
  static const adminListUsers = '/api/users/admin';
  static String adminDetailUser(String id) => '/api/users/admin/$id';
  static String adminBanUser(String id) => '/api/users/admin/$id';
  static const adminImportUsers = '/api/users/import';
  static const adminValidateImport = '/api/users/import/validate';
  static const adminExportUsers = '/api/users/import/template';
  static String adminUpdateUser(String id) => '/api/users/admin/$id';

  /// Post endpoints.
  static const postGetPersonal = '/api/profile-posts';
  static const postGetGroup = '/api/recruitment-posts';
  static const postPersonal = '/api/profile-posts';
  static const postGroup = '/api/recruitment-posts';

  /// Group endpoints.
  static const groupMembership = '/api/groups/membership';

  /// User endpoints.
  static const usersList = '/api/users';
  static String usersDetail(String id) => '/api/users/$id';
  static const usersMyProfile = '/api/users/me/profile';
  static const usersUpdateProfile = '/api/users/me/profile';
  static String usersGetById(String id) => '/api/users/$id/profile';
  static String usersProfileByUserId(String userId) =>
      '/api/users/$userId/profile';

  /// Chat endpoints.
  static const chatConversations = '/api/chat/conversations';
  static String chatSessionMessages(String sessionId) =>
      '/api/chat/sessions/$sessionId/messages';
  static String groupChatMessages(String groupId) =>
      '/api/groups/$groupId/chat/messages';
  static String chatSessionSend(String sessionId) =>
      '/api/chat/sessions/$sessionId/messages';
  static const chatHub = '/groupChatHub';

  /// Invitation endpoints.
  static const invitationsList = '/api/invitations';
  static String invitationsDetail(String id) => '/api/invitations/$id';
}
