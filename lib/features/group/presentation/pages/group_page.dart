import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/group.dart';
import '../widgets/create_group_dialog.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({
    super.key,
    required this.session,
    required this.language,
  });

  final AuthSession session;
  final AppLanguage language;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late final GroupRepositoryImpl _repository;
  List<Group> _groups = [];
  bool _loading = true;
  String? _error;
  Map<String, int?> _groupProgress = {};
  int _selectedTabIndex = 0; // 0: Groups, 1: Invitations

  @override
  void initState() {
    super.initState();
    _repository = GroupRepositoryImpl(
      remoteDataSource: GroupRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final groups = await _repository.fetchMyGroups(widget.session.accessToken);
      if (!mounted) return;

      // Load progress for each group
      for (final group in groups) {
        _loadGroupProgress(group.id);
      }

      setState(() {
        _groups = groups;
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

  Future<void> _loadGroupProgress(String groupId) async {
    try {
      final tracking = await _repository.fetchGroupTracking(
        widget.session.accessToken,
        groupId,
      );
      final completionPercent =
          tracking['project']?['completionPercent'] as int? ?? 0;
      if (!mounted) return;
      setState(() {
        _groupProgress[groupId] = completionPercent;
      });
    } catch (_) {
      // Ignore tracking load errors
    }
  }

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  void _showCreateGroupDialog() {
    // Check if user already has a group
    if (_groups.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate(
              'Bạn chỉ có thể tạo 1 nhóm. Vui lòng rời khỏi nhóm hiện tại trước khi tạo nhóm mới.',
              'You can only create 1 group. Please leave your current group before creating a new one.',
            ),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => CreateGroupDialog(
        language: widget.language,
        accessToken: widget.session.accessToken,
        userMajor: 'Software Engineering', // TODO: Get from user profile
        onGroupCreated: _loadGroups,
      ),
    );
  }

  Future<void> _handleLeaveGroup(String groupId, String groupName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_translate('Rời khỏi nhóm', 'Leave Group')),
        content: Text(
          _translate(
            'Bạn có chắc chắn muốn rời khỏi nhóm "$groupName" không?',
            'Are you sure you want to leave the group "$groupName"?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_translate('Hủy', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _translate('Rời khỏi', 'Leave'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _repository.leaveGroup(widget.session.accessToken, groupId);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate(
              'Bạn đã rời khỏi nhóm thành công',
              'You have successfully left the group',
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      await _loadGroups();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Extract error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate(
              'Lỗi: $errorMessage',
              'Error: $errorMessage',
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGroups,
              child: Text(_translate('Thử lại', 'Retry')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translate('Nhóm & Dự Án Của Tôi', 'My Groups & Projects'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C293F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _translate(
                        'Quản lý dự án tập thể, theo dõi tiến độ, và cộng tác với các đồng đội. Tạo nhóm mới hoặc tham gia nhóm có sẵn để xây dựng những dự án tuyệt vời cùng nhau.',
                        'Manage your capstone project teams, track progress, and collaborate with teammates. Create new groups or join existing ones to build amazing projects together.',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showCreateGroupDialog,
                            icon: const Icon(FeatherIcons.plus),
                            label: Text(
                              _translate('Tạo Nhóm Mới', 'Create New Group'),
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A6FD8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _translate(
                                      'Tham gia nhóm đang phát triển',
                                      'Join group feature coming soon',
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(FeatherIcons.userPlus),
                            label: Text(
                              _translate('Tham Gia Nhóm', 'Join Group'),
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8C00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FeatherIcons.users,
                          size: 18,
                          color: const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_groups.length} ${_translate('nhóm đang hoạt động', 'active groups')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 60),
                        Icon(
                          FeatherIcons.inbox,
                          size: 18,
                          color: const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '0 ${_translate('đơn xin vào đang chờ', 'pending applications')}',
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
            ),
            collapsedHeight: 180,
            expandedHeight: 180,
          ),

          // Tabs Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTabIndex == 0
                                  ? const Color(0xFF3A6FD8)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          _translate('Nhóm', 'Groups'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedTabIndex == 0
                                ? const Color(0xFF3A6FD8)
                                : const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTabIndex == 1
                                  ? const Color(0xFF3A6FD8)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          _translate('Lời Mời', 'Invitations'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedTabIndex == 1
                                ? const Color(0xFF3A6FD8)
                                : const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content based on selected tab
          if (_selectedTabIndex == 0)
            // Groups tab
            if (_groups.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FeatherIcons.users,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _translate('Chưa có nhóm nào', 'No groups yet'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final group = _groups[index];
                      final progress = _groupProgress[group.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GroupCard(
                          group: group,
                          progress: progress,
                          language: widget.language,
                          onViewTap: () {
                            // TODO: Navigate to group detail
                          },
                          onLeaveGroupTap: () {
                            _handleLeaveGroup(group.id, group.name);
                          },
                        ),
                      );
                    },
                    childCount: _groups.length,
                  ),
                ),
              )
          else
            // Invitations tab - empty for now
            SliverFillRemaining(
              child: Center(
                child: Text(
                  _translate('Chưa có lời mời nào', 'No invitations yet'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final int progress;
  final AppLanguage language;
  final VoidCallback onViewTap;
  final VoidCallback onLeaveGroupTap;

  const _GroupCard({
    required this.group,
    required this.progress,
    required this.language,
    required this.onViewTap,
    required this.onLeaveGroupTap,
  });

  String _translate(String vi, String en) =>
      language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with role badge and emoji
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C293F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        group.major.majorName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (group.description != null && group.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            group.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B909F),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A6FD8).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF3A6FD8).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoleIcon(group.role),
                        size: 12,
                        color: const Color(0xFF3A6FD8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatRole(group.role),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3A6FD8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Status and semester row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translate('Kỳ học', 'Semester'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA0AEC0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.semester.season} ${group.semester.year}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2A37),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translate('Trạng thái', 'Status'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA0AEC0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(group.status)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatStatus(group.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(group.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _translate('Tiến độ', 'Progress'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$progress%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3A6FD8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Members section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  FeatherIcons.users,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  group.currentMembers == 0
                      ? _translate('Chưa có thành viên', 'No members yet')
                      : _translate(
                          '${group.currentMembers}/${group.maxMembers} thành viên',
                          '${group.currentMembers}/${group.maxMembers} members',
                        ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Skills
          if (group.skills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: group.skills
                    .map((skill) => _SkillTag(skill: skill))
                    .toList(),
              ),
            ),
          const SizedBox(height: 16),
          // Divider before footer
          Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
          // Footer with action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onViewTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A6FD8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _translate('Xem', 'View'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Leave group button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onLeaveGroupTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _translate('Rời khỏi nhóm', 'Leave Group'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    if (role == 'leader') return _translate('Trưởng nhóm', 'Team Leader');
    if (role == 'member') return _translate('Thành viên', 'Member');
    if (role == 'mentor') return _translate('Cố vấn', 'Mentor');
    return role;
  }

  IconData _getRoleIcon(String role) {
    if (role == 'leader') return FeatherIcons.award;
    if (role == 'member') return FeatherIcons.user;
    if (role == 'mentor') return FeatherIcons.star;
    return FeatherIcons.user;
  }

  String _formatStatus(String status) {
    if (status == 'recruiting') return _translate('Tuyển dụng', 'Recruiting');
    if (status == 'active') return _translate('Hoạt động', 'Active');
    if (status == 'completed') return _translate('Hoàn thành', 'Completed');
    return status;
  }

  Color _getProgressColor(int percent) {
    if (percent < 33) return const Color(0xFF9CA3AF);
    if (percent < 66) return const Color(0xFFF97316);
    return const Color(0xFF16A34A);
  }

  Color _getStatusColor(String status) {
    if (status == 'recruiting') return const Color(0xFF3B82F6);
    if (status == 'active') return const Color(0xFF10B981);
    if (status == 'completed') return const Color(0xFF8B5CF6);
    return const Color(0xFF6B7280);
  }
}

class _SkillTag extends StatelessWidget {
  final String skill;

  const _SkillTag({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF3A6FD8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

