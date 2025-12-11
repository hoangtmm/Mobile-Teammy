import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../controllers/group_detail_controller.dart';
import '../widgets/skill_tag.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;
  final AuthSession session;
  final AppLanguage language;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.session,
    required this.language,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late GroupDetailController _controller;
  bool _controllerInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllerInitialized) {
      _controller = GroupDetailController(
        groupId: widget.groupId,
        session: widget.session,
      );
      _controller.loadGroupDetail();
      _controllerInitialized = true;
    }
  }

  @override
  void dispose() {
    if (_controllerInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  void _showInviteMembersDialog() {
    showDialog(
      context: context,
      builder: (_) => _InviteMembersDialog(
        groupId: widget.groupId,
        session: widget.session,
        language: widget.language,
        onMemberAdded: () => _controller.loadGroupDetail(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_controllerInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(_translate('Chi tiết nhóm', 'Group Details'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    if (_controller.loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_translate('Chi tiết nhóm', 'Group Details'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller.error != null || _controller.group == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_translate('Chi tiết nhóm', 'Group Details'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${_controller.error ?? 'Group not found'}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _controller.loadGroupDetail,
                child: Text(_translate('Thử lại', 'Retry')),
              ),
            ],
          ),
        ),
      );
    }

    final group = _controller.group!;
    final isLeader = group.role == 'leader';

    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('Chi tiết nhóm', 'Group Details')),
        elevation: 0,
        actions: isLeader
            ? [
                IconButton(
                  icon: const Icon(FeatherIcons.edit),
                  onPressed: () => _showEditSnackbar(),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupHeader(group: group, language: widget.language),
            const SizedBox(height: 20),
            _GroupInfoGrid(group: group, progress: _controller.groupProgress, language: widget.language),
            const SizedBox(height: 20),
            _MentorSection(group: group, language: widget.language),
            const SizedBox(height: 20),
            _TopicSection(group: group, isLeader: isLeader, language: widget.language),
            const SizedBox(height: 20),
            _TechnologiesSection(group: group, language: widget.language),
            const SizedBox(height: 20),
            _TeamMembersSection(
              group: group,
              members: _controller.members,
              isLeader: isLeader,
              language: widget.language,
              onInvite: _showInviteMembersDialog,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_translate('Chế độ chỉnh sửa đang phát triển', 'Edit mode coming soon'))),
    );
  }
}

// ============ GROUP HEADER ============
class _GroupHeader extends StatelessWidget {
  final Group group;
  final AppLanguage language;

  const _GroupHeader({required this.group, required this.language});

  String _translate(String vi, String en) => language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1C293F))),
                    const SizedBox(height: 6),
                    Text(group.major.majorName, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              _buildRoleBadge(),
            ],
          ),
          if (group.description != null && group.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(group.description!, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3A6FD8).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3A6FD8).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getRoleIcon(), size: 14, color: const Color(0xFF3A6FD8)),
          const SizedBox(width: 6),
          Text(_formatRole(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3A6FD8))),
        ],
      ),
    );
  }

  IconData _getRoleIcon() {
    if (group.role == 'leader') return FeatherIcons.award;
    if (group.role == 'mentor') return FeatherIcons.star;
    return FeatherIcons.user;
  }

  String _formatRole() {
    if (group.role == 'leader') return _translate('Trưởng nhóm', 'Team Leader');
    if (group.role == 'mentor') return _translate('Cố vấn', 'Mentor');
    return _translate('Thành viên', 'Member');
  }
}

// ============ INFO GRID ============
class _GroupInfoGrid extends StatelessWidget {
  final Group group;
  final int progress;
  final AppLanguage language;

  const _GroupInfoGrid({required this.group, required this.progress, required this.language});

  String _translate(String vi, String en) => language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildInfoCard(FeatherIcons.calendar, _translate('Kỳ học', 'Semester'), '${group.semester.season} ${group.semester.year}')),
            const SizedBox(width: 12),
            Expanded(child: _buildInfoCard(FeatherIcons.activity, _translate('Trạng thái', 'Status'), _formatStatus())),
          ],
        ),
        const SizedBox(height: 12),
        _buildProgressCard(),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF3A6FD8)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C293F)), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_translate('Tiến độ dự án', 'Project Progress'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C293F))),
              Text('$progress%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF3A6FD8))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus() {
    if (group.status == 'recruiting') return _translate('Tuyển dụng', 'Recruiting');
    if (group.status == 'active') return _translate('Hoạt động', 'Active');
    if (group.status == 'completed') return _translate('Hoàn thành', 'Completed');
    return group.status;
  }

  Color _getProgressColor() {
    if (progress < 33) return const Color(0xFF9CA3AF);
    if (progress < 66) return const Color(0xFFF97316);
    return const Color(0xFF16A34A);
  }
}

// ============ MENTOR SECTION ============
class _MentorSection extends StatelessWidget {
  final Group group;
  final AppLanguage language;

  const _MentorSection({required this.group, required this.language});

  String _translate(String vi, String en) => language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_translate('Cố vấn', 'Mentor'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C293F))),
        const SizedBox(height: 12),
        group.mentor != null ? _buildMentorCard() : _buildEmptyState(),
      ],
    );
  }

  Widget _buildMentorCard() {
    final mentor = group.mentor!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildAvatar(mentor.displayName, mentor.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mentor.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C293F))),
                const SizedBox(height: 4),
                Text(mentor.email, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(FeatherIcons.star, size: 18, color: const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Text(_translate('Chưa có cố vấn', 'No mentor assigned'), style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
    );
  }

  Widget _buildAvatar(String name, String? url) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8B5CF6),
        image: (url?.isNotEmpty ?? false) ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover) : null,
      ),
      child: (url?.isEmpty ?? true)
          ? Center(
              child: Text(name.isEmpty ? '?' : name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

// ============ TOPIC SECTION ============
class _TopicSection extends StatelessWidget {
  final Group group;
  final bool isLeader;
  final AppLanguage language;

  const _TopicSection({required this.group, required this.isLeader, required this.language});

  String _translate(String vi, String en) => language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_translate('Chủ đề dự án', 'Project Topic'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C293F))),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: isLeader ? () => _showTopicSnackbar(context) : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
              border: isLeader ? Border.all(color: const Color(0xFF3A6FD8), width: 1) : null,
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: group.topic != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group.topic!.topicName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C293F))),
                            const SizedBox(height: 8),
                            Text(group.topic!.description, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        )
                      : Text(_translate('Chưa chọn chủ đề', 'No topic selected'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
                ),
                const SizedBox(width: 12),
                isLeader
                    ? Icon(FeatherIcons.chevronRight, color: const Color(0xFF3A6FD8), size: 24)
                    : Icon(FeatherIcons.lock, color: const Color(0xFF9CA3AF), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTopicSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_translate('Chuyển sang danh sách chủ đề', 'Navigate to topic list'))),
    );
  }
}

// ============ TECHNOLOGIES SECTION ============
class _TechnologiesSection extends StatelessWidget {
  final Group group;
  final AppLanguage language;

  const _TechnologiesSection({required this.group, required this.language});

  String _translate(String vi, String en) => language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_translate('Công nghệ sử dụng', 'Technologies'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C293F))),
        const SizedBox(height: 12),
        group.skills.isNotEmpty
            ? Wrap(spacing: 8, runSpacing: 8, children: group.skills.map((skill) => SkillTag(skill: skill)).toList())
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Text(_translate('Chưa có công nghệ nào', 'No technologies selected'), style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              ),
      ],
    );
  }
}

// ============ TEAM MEMBERS SECTION ============
class _TeamMembersSection extends StatelessWidget {
  final Group group;
  final List<GroupMember> members;
  final bool isLeader;
  final AppLanguage language;
  final VoidCallback onInvite;

  const _TeamMembersSection({
    required this.group,
    required this.members,
    required this.isLeader,
    required this.language,
    required this.onInvite,
  });

  String _translate(String vi, String en) => language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_translate('Thành viên nhóm', 'Team Members'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C293F))),
            Text('${members.length} ${_translate('người', 'members')}', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 12),
        ...members.map((member) => _buildMemberCard(member)),
        if (isLeader) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A6FD8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FeatherIcons.userPlus, size: 18),
                  const SizedBox(width: 8),
                  Text(_translate('Mời thành viên', 'Invite Members'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberCard(GroupMember member) {
    final displayName = member.displayName;
    final role = member.role;
    final hasRole = role.trim().isNotEmpty;
    final avatarUrl = member.avatarUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildAvatar(displayName, avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C293F))),
                  const SizedBox(height: 4),
                  Text(
                    _formatRole(hasRole ? role : null),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (hasRole)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_formatRole(role), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getRoleColor(role))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? url) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3A6FD8),
        image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
      ),
      child: url == null ? Center(child: Text(name.isEmpty ? '?' : name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))) : null,
    );
  }

  String _formatRole(String? role) {
    if (role == 'leader') return _translate('Trưởng nhóm', 'Team Leader');
    if (role == 'member') return _translate('Thành viên', 'Member');
    if (role == 'mentor') return _translate('Cố vấn', 'Mentor');
    return role ?? '';
  }

  Color _getRoleColor(String role) {
    if (role == 'leader') return const Color(0xFFEF4444);
    if (role == 'member') return const Color(0xFF3A6FD8);
    if (role == 'mentor') return const Color(0xFF8B5CF6);
    return const Color(0xFF6B7280);
  }
}

// ============ INVITE DIALOG ============
class _InviteMembersDialog extends StatefulWidget {
  final String groupId;
  final AuthSession session;
  final AppLanguage language;
  final VoidCallback onMemberAdded;

  const _InviteMembersDialog({
    required this.groupId,
    required this.session,
    required this.language,
    required this.onMemberAdded,
  });

  @override
  State<_InviteMembersDialog> createState() => _InviteMembersDialogState();
}

class _InviteMembersDialogState extends State<_InviteMembersDialog> {
  final _searchController = TextEditingController();
  late final GroupRemoteDataSource _dataSource;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  bool _inviting = false;

  @override
  void initState() {
    super.initState();
    _dataSource = GroupRemoteDataSource(baseUrl: kApiBaseUrl);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _translate(String vi, String en) => widget.language == AppLanguage.vi ? vi : en;

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _searchUsers(_searchController.text);
  }

  Future<void> _searchUsers(String email) async {
    try {
      setState(() => _searching = true);
      final results = await _dataSource.searchUsers(widget.session.accessToken, email);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _inviteUser(String userId) async {
    try {
      setState(() => _inviting = true);
      await _dataSource.inviteUserToGroup(widget.session.accessToken, widget.groupId, userId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate('Mời thành công', 'Invited successfully')),
          backgroundColor: Colors.green,
        ),
      );
      widget.onMemberAdded();
    } catch (e) {
      if (!mounted) return;
      setState(() => _inviting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_translate('Mời thành viên', 'Invite Members')),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _translate('Nhập email...', 'Enter email...'),
                prefixIcon: const Icon(FeatherIcons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            if (_searching)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
              Text(_translate('Không tìm thấy', 'No results found'))
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.where((u) => !(u['hasGroupInSemester'] as bool? ?? false)).length,
                  itemBuilder: (context, index) {
                    final filtered = _searchResults.where((u) => !(u['hasGroupInSemester'] as bool? ?? false)).toList();
                    final user = filtered[index];
                    final displayName = user['displayName'] as String?;
                    final email = user['email'] as String?;
                    final avatarUrl = user['avatarUrl'] as String?;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3A6FD8),
                          image: avatarUrl != null ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                        ),
                        child: avatarUrl == null
                            ? Center(
                                child: Text((displayName?.isEmpty ?? true) ? '?' : displayName![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              )
                            : null,
                      ),
                      title: Text(displayName ?? 'Unknown'),
                      subtitle: Text(email ?? ''),
                      trailing: ElevatedButton(
                        onPressed: _inviting ? null : () => _inviteUser(user['userId']),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3A6FD8)),
                        child: Text(_translate('Mời', 'Invite'), style: const TextStyle(fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_translate('Đóng', 'Close'))),
      ],
    );
  }
}
