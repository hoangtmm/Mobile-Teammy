import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../domain/entities/profile_post_invitation.dart';
import '../../domain/entities/member_invitation.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.session,
    required this.language,
  });

  final AuthSession session;
  final AppLanguage language;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final GroupRemoteDataSource _dataSource;
  List<ProfilePostInvitation> _profilePostInvitations = [];
  List<MemberInvitation> _memberInvitations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _dataSource = GroupRemoteDataSource(baseUrl: kApiBaseUrl);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      print('[NOTIFICATIONS] Loading notifications...');

      final profileInvitations = await _dataSource.fetchProfilePostInvitations(
        widget.session.accessToken,
      );
      print(
        '[NOTIFICATIONS] Profile post invitations: ${profileInvitations.length}',
      );

      final memberInvitations = await _dataSource.fetchMemberInvitations(
        widget.session.accessToken,
      );
      print('[NOTIFICATIONS] Member invitations: ${memberInvitations.length}');

      if (!mounted) return;
      setState(() {
        _profilePostInvitations = profileInvitations;
        _memberInvitations = memberInvitations;
        _loading = false;
      });

      print(
        '[NOTIFICATIONS] Total: ${profileInvitations.length + memberInvitations.length}',
      );
    } catch (e, stackTrace) {
      print('[NOTIFICATIONS] Error loading: $e');
      print('[NOTIFICATIONS] Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          _translate('Thông báo', 'Notifications'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212631),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(FeatherIcons.arrowLeft, color: Color(0xFF212631)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _buildInvitationsList(),
            ),
    );
  }

  Widget _buildInvitationsList() {
    final totalCount =
        _profilePostInvitations.length + _memberInvitations.length;

    if (totalCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _translate('Chưa có lời mời nào', 'No invitations yet'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < _profilePostInvitations.length) {
          final invitation = _profilePostInvitations[index];
          return _buildProfilePostInvitationCard(invitation);
        } else {
          final invitation =
              _memberInvitations[index - _profilePostInvitations.length];
          return _buildMemberInvitationCard(invitation);
        }
      },
    );
  }

  Widget _buildProfilePostInvitationCard(ProfilePostInvitation invitation) {
    final daysAgo = DateTime.now().difference(invitation.createdAt).inDays;
    final timeText = daysAgo == 0
        ? _translate('Hôm nay', 'Today')
        : daysAgo == 1
        ? _translate('Hôm qua', 'Yesterday')
        : _translate('$daysAgo ngày trước', '$daysAgo days ago');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translate('Lời mời vào nhóm', 'Group invitation'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212631),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invitation.leaderDisplayName} ${_translate('mời bạn từ bài đăng', 'invited you from a post')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF747A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: Color(0xFF6366F1)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        invitation.groupName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212631),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.school,
                      size: 14,
                      color: Color(0xFF747A8A),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        invitation.groupMajorName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF747A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeText,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_translate('Đã từ chối', 'Declined')),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _translate('Từ chối', 'Decline'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_translate('Đã chấp nhận', 'Accepted')),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5FE5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _translate('Chấp nhận', 'Accept'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberInvitationCard(MemberInvitation invitation) {
    final daysAgo = DateTime.now().difference(invitation.createdAt).inDays;
    final timeText = daysAgo == 0
        ? _translate('Hôm nay', 'Today')
        : daysAgo == 1
        ? _translate('Hôm qua', 'Yesterday')
        : _translate('$daysAgo ngày trước', '$daysAgo days ago');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translate('Lời mời thành viên', 'Member invitation'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212631),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invitation.invitedByName} ${_translate('mời bạn vào nhóm', 'invited you to join')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF747A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        invitation.groupName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212631),
                        ),
                      ),
                    ),
                  ],
                ),
                if (invitation.topicTitle != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.topic,
                        size: 14,
                        color: Color(0xFF747A8A),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          invitation.topicTitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF747A8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeText,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_translate('Đã từ chối', 'Declined')),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _translate('Từ chối', 'Decline'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_translate('Đã chấp nhận', 'Accepted')),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5FE5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _translate('Chấp nhận', 'Accept'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
