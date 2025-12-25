const String kApiBaseUrl = 'https://api.vps-sep490.io.vn';

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
  static String recruitmentPostsByGroup(String groupId) =>
      '/api/recruitment-posts/group/$groupId';

  /// Group endpoints.
  static const groupMembership = '/api/groups/membership';
  static const groupsMyGroups = '/api/groups/my';
  static String groupTracking(String groupId) =>
      '/api/groups/$groupId/tracking/reports/project';
  static String groupTrackingScores(String groupId) =>
      '/api/groups/$groupId/tracking/scores';
  static String groupBoard(String groupId) => '/api/groups/$groupId/board';
  static String boardTaskComments(String groupId, String taskId) =>
      '/api/groups/$groupId/board/tasks/$taskId/comments';
  static String boardComment(String groupId, String commentId) =>
      '/api/groups/$groupId/board/comments/$commentId';
  static String boardTaskFiles(String groupId, String taskId) =>
      '/api/groups/$groupId/board/tasks/$taskId/files';
  static String boardFiles(String groupId) => '/api/groups/$groupId/board/files';
  static String boardFile(String groupId, String fileId) =>
      '/api/groups/$groupId/board/files/$fileId';
  static String boardUploadFile(String groupId) =>
      '/api/groups/$groupId/board/files/upload';
  static String groupBacklog(String groupId) =>
      '/api/groups/$groupId/tracking/backlog';
  static String groupBacklogItem(String groupId, String backlogItemId) =>
      '/api/groups/$groupId/tracking/backlog/$backlogItemId';
  static String groupBacklogPromote(String groupId, String backlogItemId) =>
      '/api/groups/$groupId/tracking/backlog/$backlogItemId/promote';
  static String groupMilestones(String groupId) =>
      '/api/groups/$groupId/tracking/milestones';
  static String groupMilestone(String groupId, String milestoneId) =>
      '/api/groups/$groupId/tracking/milestones/$milestoneId';
  static String groupMilestoneItems(String groupId, String milestoneId) =>
      '/api/groups/$groupId/tracking/milestones/$milestoneId/items';
  static String groupMilestoneItem(
    String groupId,
    String milestoneId,
    String backlogItemId,
  ) => '/api/groups/$groupId/tracking/milestones/$milestoneId/items/$backlogItemId';
  static const groupsCreate = '/api/groups';
  static String groupLeaveMember(String groupId) =>
      '/api/groups/$groupId/members/me';
  static String groupMembers(String groupId) => '/api/groups/$groupId/members';
  static String groupInvite(String groupId) => '/api/groups/$groupId/invites';
  static String groupUpdate(String groupId) => '/api/groups/$groupId';
  static String groupActivate(String groupId) => '/api/groups/$groupId/activate';
  static String groupFeedback(String groupId) => '/api/groups/$groupId/feedback';
  static String groupFeedbackStatus(String groupId, String feedbackId) =>
      '/api/groups/$groupId/feedback/$feedbackId/status';

  /// Major endpoints.
  static const majors = '/api/majors';
  static String skillsByMajor(String majorName) =>
      '/api/skills?major=$majorName&pageSize=100';

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
