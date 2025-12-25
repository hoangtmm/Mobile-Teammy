import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../group/data/datasources/group_remote_data_source.dart';
import '../../../group/data/repositories/group_repository_impl.dart';
import '../../../group/domain/repositories/group_repository.dart';
import '../../data/datasources/forum_remote_data_source.dart';
import '../../data/repositories/forum_repository_impl.dart';
import '../../domain/entities/forum_membership.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/entities/forum_post_suggestion.dart';
import '../../domain/repositories/forum_repository.dart';
import '../../../auth/data/datasources/user_remote_data_source.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import 'forum_post_detail_page.dart';
import 'forum_create_recruitment_post_page.dart';
import 'forum_create_personal_post_modal.dart';

enum _ForumTab { groups, individuals }

class ForumPage extends StatefulWidget {
  const ForumPage({super.key, required this.session, required this.language});

  final AuthSession session;
  final AppLanguage language;

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  late final ForumRepository _repository;
  late final GroupRepository _groupRepository;
  late final UserRemoteDataSource _userDataSource;
  UserProfile? _userProfile;

  _ForumTab _tab = _ForumTab.groups;
  ForumMembership? _membership;

  bool _loading = true;
  String? _error;

  final List<ForumPost> _groupPosts = [];
  final List<ForumPost> _individualPosts = [];
  final List<ForumPostSuggestion> _suggestedGroupPosts = [];
  final List<ForumPostSuggestion> _suggestedProfilePosts = [];

  final _searchController = TextEditingController();

  // Modal Apply state
  ForumPost? _applyingPost;
  String? _selectedPosition;
  final _messageController = TextEditingController();
  bool _isApplying = false;

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  @override
  void initState() {
    super.initState();
    _repository = ForumRepositoryImpl(
      remoteDataSource: ForumRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _groupRepository = GroupRepositoryImpl(
      remoteDataSource: GroupRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _userDataSource = UserRemoteDataSource(baseUrl: kApiBaseUrl);
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = widget.session.accessToken;
      final membershipFuture = _repository.fetchMembership(token);
      final groupsFuture = _repository.fetchRecruitmentPosts(token);
      final individualsFuture = _repository.fetchPersonalPosts(token);
      final profileFuture = _userDataSource.getProfile(token);

      final membership = await membershipFuture;
      final groups = await groupsFuture;
      final individuals = await individualsFuture;
      final profile = await profileFuture;

      List<ForumPostSuggestion> suggestedGroups = const [];
      List<ForumPostSuggestion> suggestedProfiles = const [];

      if (profile?.majorId != null) {
        try {
          suggestedGroups = await _repository.fetchRecruitmentSuggestions(
            token,
            majorId: profile!.majorId!,
            limit: 5,
          );
        } catch (_) {}
      }

      if (membership?.groupId != null) {
        try {
          suggestedProfiles = await _repository.fetchProfileSuggestions(
            token,
            groupId: membership!.groupId!,
            limit: 5,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _membership = membership;
        _userProfile = profile;
        _groupPosts
          ..clear()
          ..addAll(groups);
        _individualPosts
          ..clear()
          ..addAll(individuals);
        _suggestedGroupPosts
          ..clear()
          ..addAll(suggestedGroups);
        _suggestedProfilePosts
          ..clear()
          ..addAll(suggestedProfiles);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ForumPost> get _visiblePosts {
    final src = _tab == _ForumTab.groups ? _groupPosts : _individualPosts;
    final openPosts = src.where((p) => !_isClosed(p)).toList(growable: false);
    final suggestionIds = _currentSuggestions
        .map((s) => s.post.id)
        .where((id) => id.isNotEmpty)
        .toSet();
    final filteredPosts = openPosts
        .where((p) => !suggestionIds.contains(p.id))
        .toList(growable: false);
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return List.unmodifiable(filteredPosts);

    return filteredPosts
        .where(
          (p) =>
              p.title.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query) ||
              p.skills.any((s) => s.toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }

  List<ForumPostSuggestion> get _currentSuggestions {
    return _tab == _ForumTab.groups
        ? _suggestedGroupPosts
        : _suggestedProfilePosts;
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return '-';
    final d = date.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  String _timeAgoFrom(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date.toLocal());

    if (diff.inMinutes < 1) {
      return _t('vừa xong', 'just now');
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return widget.language == AppLanguage.vi
          ? '$m phút trước'
          : '$m minutes ago';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return widget.language == AppLanguage.vi
          ? '$h giờ trước'
          : '$h hours ago';
    } else if (diff.inDays < 7) {
      final d = diff.inDays;
      return widget.language == AppLanguage.vi
          ? '$d ngày trước'
          : '$d days ago';
    }

    // lâu quá thì hiện dạng dd/MM/yyyy
    return _formatDateShort(date);
  }

  bool _isClosed(ForumPost post) {
    if ((post.status ?? '').toLowerCase() == 'closed') return true;
    if (post.expiresAt == null) return false;
    return post.expiresAt!.isBefore(DateTime.now());
  }

  // Helper methods để kiểm tra quyền tạo bài
  bool _shouldShowGroupPostButton() {
    // Chỉ hiện nút tạo bài tuyển nếu user có group VÀ là leader
    return _membership?.hasGroup == true && _membership?.status == 'leader';
  }

  bool _shouldShowPersonalPostButton() {
    // Chỉ hiện nút tạo bài cá nhân nếu chưa có group
    // Ẩn nếu: đã có group (bất kể leader hay member)
    return _membership?.hasGroup != true;
  }

  Future<void> _openCreateRecruitmentPost() async {
    final result = await showCreateRecruitmentPostModal(
      context: context,
      session: widget.session,
      language: widget.language,
      repository: _repository,
      membership: _membership,
    );

    if (!mounted) return;

    if (result == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Tạo bài tuyển thành công', 'Recruitment post created'),
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadAll();
    } else if (result != null && result.startsWith('error:')) {
      final fullError = result.substring(6);
      // Parse để lấy message từ format: AuthApiException(409): "Group is full"
      String errorMsg = fullError;
      final pattern = RegExp(r'"([^"]+)"');
      final match = pattern.firstMatch(fullError);
      if (match != null) {
        errorMsg = match.group(1) ?? fullError;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Không thể tạo bài tuyển: $errorMsg',
              'Failed to create post: $errorMsg',
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openCreatePersonalPost() async {
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Đang tải thông tin người dùng...', 'Loading user profile...'),
          ),
        ),
      );
      return;
    }

    final result = await showCreatePersonalPostModal(
      context: context,
      session: widget.session,
      language: widget.language,
      repository: _repository,
      userProfile: _userProfile!,
    );

    if (!mounted) return;

    if (result == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Tạo profile post thành công', 'Profile post created'),
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadAll();
    } else if (result != null && result.startsWith('error:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Không thể tạo bài: ${result.substring(6)}',
              'Failed to create post: ${result.substring(6)}',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showApplyModal(ForumPost post) async {
    if (post.hasApplied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Bạn đã nộp đơn cho bài này rồi',
              'You have already applied to this post',
            ),
          ),
        ),
      );
      return;
    }

    final pageContext = context;

    final positions = (post.positionNeeded ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // trạng thái LOCAL cho dialog
    String? selectedPosition;
    _messageController.clear();

    await showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) => AlertDialog(
            title: Text(_t('Ứng tuyển vào bài viết', 'Apply to Post')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (positions.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Chọn vị trí', 'Select Position'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: selectedPosition,
                          isExpanded: true,
                          hint: Text(_t('Chọn vị trí', 'Choose a position')),
                          items: positions
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedPosition = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  Text(
                    _t(
                      'Tại sao bạn muốn tham gia dự án này?',
                      'Why you want to join this project?',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: _t(
                        'Nhập mô tả...',
                        'Tell us about yourself...',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_t('Huỷ', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: _isApplying
                    ? null
                    : () async {
                        final message = _messageController.text.trim();

                        if ((positions.isNotEmpty &&
                                selectedPosition == null) ||
                            message.isEmpty) {
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                _t(
                                  'Vui lòng điền đầy đủ thông tin',
                                  'Please fill all fields',
                                ),
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() => _isApplying = true);

                        Navigator.of(dialogContext).pop();

                        await Future.delayed(const Duration(milliseconds: 100));

                        try {
                          final fullMessage =
                              positions.isNotEmpty && selectedPosition != null
                              ? '$selectedPosition - $message'
                              : message;

                          await _repository.applyToRecruitmentPost(
                            widget.session.accessToken,
                            postId: post.id,
                            message: fullMessage,
                          );

                          if (!mounted) return;

                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                _t(
                                  'Đã gửi yêu cầu tham gia nhóm',
                                  'Application sent',
                                ),
                              ),
                              backgroundColor: const Color(0xFF16A34A),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          _loadAll();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                _t(
                                  'Không thể gửi yêu cầu: $e',
                                  'Failed to apply: $e',
                                ),
                              ),
                              backgroundColor: const Color(0xFFEF4444),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _applyingPost = null;
                              _isApplying = false;
                            });
                          }
                        }
                      },
                child: _isApplying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(_t('Gửi', 'Submit')),
              ),
            ],
          ),
        );
      },
    );

    setState(() => _applyingPost = null);
  }

  Future<void> _openDetail(ForumPost post) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForumPostDetailPage(
          session: widget.session,
          language: widget.language,
          post: post,
          repository: _repository,
          canApply: !(_membership?.hasGroup ?? false),
        ),
      ),
    );

    if (result != null && mounted) {
      if (result == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('Đã gửi yêu cầu tham gia nhóm', 'Application sent'),
            ),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // RẤT QUAN TRỌNG: reload lại list
        _loadAll();
      } else if (result is String && result.startsWith('error:')) {
        final error = result.substring(6);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('Không thể gửi yêu cầu: $error', 'Failed to apply: $error'),
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _inviteProfilePost(ForumPost post) async {
    final token = widget.session.accessToken;

    try {
      await _repository.inviteToProfilePost(token, postId: post.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Đã gửi lời mời tham gia nhóm', 'Invitation sent')),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _loadAll(); // reload để cập nhật hasApplied / status
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Không thể gửi lời mời: $e', 'Failed to send invite: $e'),
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTabButton(_ForumTab tab, String label) {
    final bool selected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF020617) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(ForumPost post) {
    final bool isGroup = post.type == 'group_hiring';
    final bool isPersonal = !isGroup;

    final closed = _isClosed(post);
    final statusLabel = closed ? _t('closed', 'closed') : _t('open', 'open');
    final statusColor = closed
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF16A34A);

    // user đã có group thì không được apply nữa
    final bool canApply =
        isGroup && !post.hasApplied && !(_membership?.hasGroup ?? false);

    // chỉ leader trong group mới được mời (giống FE: userRole === 'leader')
    final bool isLeader = _membership?.status == 'leader';
    final bool canInvite =
        isPersonal &&
        isLeader &&
        (_membership?.hasGroup ?? false) &&
        !post.hasApplied;

    final List<String> positions = (post.positionNeeded ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final String authorName = (post.authorName?.isNotEmpty ?? false)
        ? post.authorName!
        : 'Leader';
    final String avatarInitial = authorName.trim().isNotEmpty
        ? authorName.trim().characters.first.toUpperCase()
        : 'L';

    final String? avatarUrl = post.authorAvatarUrl;
    final String timeAgo = _timeAgoFrom(post.createdAt);
    final String majorName =
        post.majorName ?? post.majorName ?? post.mentorName ?? '';

    // ====== CARD PROFILE (PERSONAL POST) ======
    if (isPersonal) {
      final String? primaryPosition = positions.isNotEmpty
          ? positions.first
          : null;
      final List<String> skills = post.skills.isNotEmpty
          ? post.skills
          : positions; // fallback nếu backend để skills trong position

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // avatar + name + time
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (post.authorId != null && post.authorId!.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(
                              userId: post.authorId!,
                              session: widget.session,
                              language: widget.language,
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE5E7EB),
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? null
                          : Text(
                              avatarInitial,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (timeAgo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // description
            Text(
              post.description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 8),

            // Skills + Major
            // Skills + Major (major nằm dưới skills)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skills
                Text(
                  _t('Kỹ năng:', 'Skills:'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills
                      .map(
                        (s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFE5EDFF),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 12),

                // Major
                Text(
                  _t('Ngành:', 'Major:'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  majorName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 8),

            // Status / Invite button giống FE
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (post.hasApplied && post.myApplicationStatus != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: post.myApplicationStatus == 'accepted'
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : post.myApplicationStatus == 'rejected'
                          ? const Color(0xFFEF4444).withOpacity(0.1)
                          : const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      post.myApplicationStatus == 'accepted'
                          ? _t('Đã chấp nhận', 'Accepted')
                          : post.myApplicationStatus == 'rejected'
                          ? _t('Đã từ chối', 'Rejected')
                          : _t('Đang chờ', 'Pending'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: post.myApplicationStatus == 'accepted'
                            ? const Color(0xFF10B981)
                            : post.myApplicationStatus == 'rejected'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ] else if (canInvite) ...[
                  ElevatedButton(
                    onPressed: () => _inviteProfilePost(post),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_alt_1_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _t('Invite to Group', 'Invite to Group'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title + status + stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!closed) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (isGroup) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.remove_red_eye_outlined, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${post.applicationsCount} ${_t('Applications', 'Applications')}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (post.expiresAt != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${_t('Due', 'Due')}: ${_formatDateShort(post.expiresAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // avatar + meta
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (post.authorId != null && post.authorId!.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            userId: post.authorId!,
                            session: widget.session,
                            language: widget.language,
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE5E7EB),
                    backgroundImage: (post.authorAvatarUrl?.isNotEmpty ?? false)
                        ? NetworkImage(post.authorAvatarUrl!)
                        : null,
                    child: (post.authorAvatarUrl?.isNotEmpty ?? false)
                        ? null
                        : Text(
                            avatarInitial,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '• ${_t('leader', 'leader')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if ((post.groupName ?? '').isNotEmpty)
                      Text(
                        '• ${post.groupName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    if (post.createdAt != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 4,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDateShort(post.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // description
          Text(
            post.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // positions
          if (positions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Positions Needed:', 'Positions Needed:'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: positions
                      .map(
                        (p) => Chip(
                          label: Text(p, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFE0ECFF),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          if (positions.isNotEmpty) const SizedBox(height: 8),

          // skills
          if (post.skills.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Skills:', 'Skills:'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: post.skills
                      .map(
                        (s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFE5EDFF),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.people_alt_outlined,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              if (post.currentMembers != null && post.maxMembers != null)
                Text(
                  widget.language == AppLanguage.vi
                      ? '${post.currentMembers}/${post.maxMembers} thành viên'
                      : '${post.currentMembers}/${post.maxMembers} members',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              const Spacer(),
              // Hiển thị trạng thái application nếu đã apply
              // Status chip – giữ nguyên cho cả group & personal nếu đã gửi (apply/invite)
              if (post.hasApplied && post.myApplicationStatus != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: post.myApplicationStatus == 'accepted'
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : post.myApplicationStatus == 'rejected'
                        ? const Color(0xFFEF4444).withOpacity(0.1)
                        : const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    post.myApplicationStatus == 'accepted'
                        ? _t('Đã chấp nhận', 'Accepted')
                        : post.myApplicationStatus == 'rejected'
                        ? _t('Đã từ chối', 'Rejected')
                        : _t('Đang chờ', 'Pending'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: post.myApplicationStatus == 'accepted'
                          ? const Color(0xFF10B981)
                          : post.myApplicationStatus == 'rejected'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // APPLY button – chỉ group, chưa apply, chưa có group
              if (canApply) ...[
                ElevatedButton(
                  onPressed: () => _showApplyModal(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    elevation: 0,
                  ),
                  child: Text(
                    _t('Apply', 'Apply'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // INVITE button – chỉ personal, leader mới thấy
              if (canInvite) ...[
                ElevatedButton(
                  onPressed: () => _inviteProfilePost(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_alt_1_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _t('Invite to Group', 'Invite to Group'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // View Details chỉ còn cho group-post
              if (isGroup)
                TextButton(
                  onPressed: () => _openDetail(post),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    _t('View Details', 'View Details'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostList() {
    final posts = _visiblePosts;
    final suggestions = _currentSuggestions
        .where((s) => !_isClosed(s.post))
        .toList(growable: false);

    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              'Error: ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _loadAll,
              child: Text(_t('Thử lại', 'Retry')),
            ),
          ),
        ],
      );
    }

    if (posts.isEmpty) {
      if (suggestions.isNotEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildSuggestionsSection(suggestions),
          ],
        );
      }

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              _tab == _ForumTab.groups
                  ? _t(
                      'Chưa có bài tuyển nào.\nHãy là người đầu tiên tạo bài tuyển nhóm.',
                      'No recruitment posts yet.\nBe the first to create a group post.',
                    )
                  : _t(
                      'Chưa có sinh viên nào đăng bài tìm nhóm.',
                      'No students have posted personal profiles yet.',
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      );
    }

    if (suggestions.isNotEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildSuggestionsSection(suggestions),
          const SizedBox(height: 8),
          ...posts.map(_buildPostCard),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: posts.map(_buildPostCard).toList(),
    );
  }

  Widget _buildSuggestionsSection(List<ForumPostSuggestion> suggestions) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final title = _tab == _ForumTab.groups
        ? _t('AI Suggested Groups', 'AI Suggested Groups')
        : _t('AI Suggested Profiles', 'AI Suggested Profiles');
    final subtitle = _tab == _ForumTab.groups
        ? _t(
            'Gợi ý phù hợp theo chuyên ngành của bạn',
            'Suggestions tailored to your major',
          )
        : _t(
            'Gợi ý hồ sơ phù hợp cho nhóm của bạn',
            'Suggestions tailored to your group',
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...suggestions.map(_buildSuggestionCard),
      ],
    );
  }

  Widget _buildSuggestionCard(ForumPostSuggestion suggestion) {
    final post = suggestion.post;
    final isGroup = post.type == 'group_hiring';
    final canApply = isGroup && !post.hasApplied && !(_membership?.hasGroup ?? false);
    final canInvite = !isGroup && (_membership?.status == 'leader');
    final closed = _isClosed(post);

    final score = suggestion.scorePercent;
    final majorName = (post.majorName ?? _t('Không rõ', 'Unknown'));
    final desiredPosition = (suggestion.desiredPosition ??
            post.positionNeeded ??
            post.title)
        .toString()
        .trim();
    final positions = (post.positionNeeded ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final dueText = post.expiresAt != null
        ? _formatDateShort(post.expiresAt)
        : '-';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (score != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$score% Match',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if ((post.authorName ?? '').isNotEmpty)
                Text(
                  post.authorName ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              if ((post.authorName ?? '').isNotEmpty &&
                  post.groupName != null &&
                  post.groupName!.isNotEmpty)
                const Icon(
                  Icons.circle,
                  size: 4,
                  color: Color(0xFF9CA3AF),
                ),
              if (post.groupName != null && post.groupName!.isNotEmpty)
                Text(
                  post.groupName!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (post.createdAt != null) ...[
                const Icon(
                  Icons.circle,
                  size: 4,
                  color: Color(0xFF9CA3AF),
                ),
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                Text(
                  _formatDateShort(post.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
              if (!closed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F8ED),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _t('open', 'open'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              if (isGroup)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.applicationsCount} ${_t('Applications', 'Applications')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              if (!closed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_t('Due', 'Due')}: $dueText',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if ((suggestion.aiReason ?? '').isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _t('Vì sao gợi ý?', 'Why suggested?'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    suggestion.aiReason ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (isGroup)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Vị trí cần tuyển:', 'Positions Needed:'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (positions.isEmpty)
                        Text(
                          _t('Chưa có', 'N/A'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: positions
                              .map(
                                (p) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    p,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1D4ED8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Ngành:', 'Major:'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      majorName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Role Needed:', 'Role Needed:'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (desiredPosition.isEmpty)
                        Text(
                          _t('Chưa có', 'N/A'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            desiredPosition,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Ngành:', 'Major:'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      majorName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (!isGroup) ...[
            const SizedBox(height: 12),
            Text(
              _t('Kỹ năng trùng:', 'Matching Skills:'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            if (suggestion.matchingSkills.isEmpty)
              Text(
                _t('Chưa có', 'N/A'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestion.matchingSkills
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isGroup) ...[
                const Icon(
                  Icons.people_alt_outlined,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                if (post.currentMembers != null && post.maxMembers != null)
                  Text(
                    '${post.currentMembers}/${post.maxMembers} ${_t('members', 'members')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
              ],
              const Spacer(),
              if (post.hasApplied && post.myApplicationStatus != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: post.myApplicationStatus == 'accepted'
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : post.myApplicationStatus == 'rejected'
                        ? const Color(0xFFEF4444).withOpacity(0.1)
                        : const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    post.myApplicationStatus == 'accepted'
                        ? _t('Đã chấp nhận', 'Accepted')
                        : post.myApplicationStatus == 'rejected'
                        ? _t('Đã từ chối', 'Rejected')
                        : _t('Đang chờ', 'Pending'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: post.myApplicationStatus == 'accepted'
                          ? const Color(0xFF10B981)
                          : post.myApplicationStatus == 'rejected'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (isGroup)
                TextButton(
                  onPressed: () => _openDetail(post),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    _t('View Details', 'View Details'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (canApply)
                ElevatedButton(
                  onPressed: () => _showApplyModal(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    elevation: 0,
                  ),
                  child: Text(
                    _t('Apply Now', 'Apply Now'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (canInvite && !(post.hasApplied && post.myApplicationStatus != null))
                ElevatedButton(
                  onPressed: () => _inviteProfilePost(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_alt_1_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _t('Invite to Group', 'Invite to Group'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final totalRecruitment = _groupPosts.length;
    final totalPersonal = _individualPosts.length;

    return Padding(
      // top = 0 để dính sát AppBar giống màn Nhóm
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Text(
            _t('Recruitment Forum', 'Recruitment Forum'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t(
              'Post recruitment opportunities or showcase your profile to find the perfect team match. Connect with students and groups across all departments.',
              'Post recruitment opportunities or showcase your profile to find the perfect team match. Connect with students and groups across all departments.',
            ),
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // nút Create + stats
          Row(
            children: [
              // Logic hiển thị nút:
              // - Leader: chỉ hiện nút tạo bài tuyển (group post)
              // - Member: hiện cả 2 nút
              // - Chưa có group: chỉ hiện nút tạo bài cá nhân
              if (_shouldShowGroupPostButton())
                ElevatedButton.icon(
                  onPressed: _openCreateRecruitmentPost,
                  icon: const Icon(Icons.add),
                  label: Text(_t('Create group post', 'Create group post')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (_shouldShowGroupPostButton() &&
                  _shouldShowPersonalPostButton())
                const SizedBox(width: 8),
              if (_shouldShowPersonalPostButton())
                ElevatedButton.icon(
                  onPressed: _openCreatePersonalPost,
                  icon: const Icon(Icons.add),
                  label: Text(
                    _t('Create personal post', 'Create personal post'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalRecruitment ${_t('recruitment post', 'recruitment post')}${totalRecruitment == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalPersonal ${_t('student profile', 'student profile')}${totalPersonal == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: _t(
                'Search posts by project, skills',
                'Search posts by project, skills',
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                _buildTabButton(
                  _ForumTab.groups,
                  _t('Post Group', 'Post Group'),
                ),
                const SizedBox(width: 6),
                _buildTabButton(
                  _ForumTab.individuals,
                  _t('Post Personal', 'Post Personal'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          _buildHeaderSection(),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF4CB065),
              onRefresh: _loadAll,
              child: _buildPostList(),
            ),
          ),
        ],
      ),
    );
  }
}
