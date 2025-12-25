import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../group/data/datasources/group_remote_data_source.dart';
import '../../../group/data/repositories/group_repository_impl.dart';
import '../../../group/presentation/pages/contribute_score_page.dart';
import '../../../group/presentation/pages/group_detail_page.dart';
import '../../../timeline/presentation/widgets/navigation_drawer_widget.dart';
import '../../domain/entities/group_invitation.dart';
import '../controllers/group_page_controller.dart';
import '../widgets/create_group_dialog.dart';
import '../widgets/group_card.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key, required this.session, required this.language});

  final AuthSession session;
  final AppLanguage language;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late final GroupPageController _controller;
  int _invitationTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedDrawerIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = GroupPageController(session: widget.session);
    _controller.loadGroups();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  Future<void> _handleDrawerNavigation(int index) async {
    switch (index) {
      case 0: // Overview
        try {
          final repository = GroupRepositoryImpl(
            remoteDataSource: GroupRemoteDataSource(baseUrl: kApiBaseUrl),
          );
          final groups = await repository.fetchMyGroups(widget.session.accessToken);
          if (groups.isNotEmpty && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupDetailPage(
                  groupId: groups.first.id,
                  session: widget.session,
                  language: widget.language,
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
        break;
      case 1: // Contribute Score
        try {
          final repository = GroupRepositoryImpl(
            remoteDataSource: GroupRemoteDataSource(baseUrl: kApiBaseUrl),
          );
          final groups = await repository.fetchMyGroups(widget.session.accessToken);
          if (groups.isNotEmpty && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContributeScorePage(
                  groupId: groups.first.id,
                  session: widget.session,
                  language: widget.language,
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
        break;
      case 2: // Feedback
        break;
      case 3: // Posts
        // Navigate to Forum - handled by MainPage
        break;
      case 4: // Files
        break;
    }
  }

  void _showCreateGroupDialog() {
    if (_controller.groups.isNotEmpty) {
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
        userMajor: 'Software Engineering',
        onGroupCreated: _controller.loadGroups,
      ),
    );
  }

  void _navigateToGroupDetail(String groupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailPage(
          groupId: groupId,
          session: widget.session,
          language: widget.language,
        ),
      ),
    );
  }

  Future<void> _handleLeaveGroup(String groupId, String groupName) async {
    // Kiểm tra xem user có phải là leader không
    final currentGroup = _controller.groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Group not found'),
    );

    final isLeader = currentGroup.role == 'leader';
    final hasOtherMembers = currentGroup.currentMembers > 1;

    // Nếu là leader và còn member khác, phải transfer leader trước
    if (isLeader && hasOtherMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate(
              'Bạn cần chuyển quyền leader cho thành viên khác trước khi rời nhóm',
              'You need to transfer leadership to another member before leaving the group',
            ),
          ),
          backgroundColor: const Color(0xFFF59E0B),
          duration: const Duration(seconds: 3),
        ),
      );

      // Mở trang group detail để transfer leader
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupDetailPage(
            groupId: groupId,
            session: widget.session,
            language: widget.language,
          ),
        ),
      );
      return;
    }

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

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _controller.leaveGroup(groupId);
      if (!mounted) return;
      Navigator.pop(context);

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
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate('Lỗi: $errorMessage', 'Error: $errorMessage'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.loading) {
          return const Center(
            child: SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (_controller.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${_controller.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _controller.loadGroups,
                  child: Text(_translate('Thử lại', 'Retry')),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: NavigationDrawerWidget(
            selectedIndex: _selectedDrawerIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedDrawerIndex = index;
              });
              Navigator.of(context).pop();
              _handleDrawerNavigation(index);
            },
            language: widget.language,
          ),
          body: RefreshIndicator(
            onRefresh: _controller.loadGroups,
            child: _buildGroupPageContent(),
          ),
        );
      },
    );
  }

  Widget _buildGroupPageContent() {
    return CustomScrollView(
      slivers: [
        _buildHeaderSliverAppBar(),
        _buildTabsSliverToBoxAdapter(),
        if (_controller.selectedTabIndex == 0)
          _buildGroupsSliver()
        else
          _buildInvitationsSliver(),
      ],
    );
  }

  Widget _buildHeaderSliverAppBar() {
    return SliverAppBar(
      floating: false,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate('Nhóm & Dự Án Của Tôi', 'My Groups & Projects'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF212631),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _translate(
                  'Quản lý dự án, theo dõi tiến độ và cộng tác với các đồng đội. Tạo nhóm mới hoặc tham gia nhóm có sẵn để xây dựng...',
                  'Manage projects, track progress and collaborate with your team. Create new groups or join existing ones to build...',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF747A8A),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              _buildHeaderActionButtons(),
              const SizedBox(height: 20),
              _buildHeaderStats(),
            ],
          ),
        ),
      ),
      collapsedHeight: 80,
      expandedHeight: 290,
    );
  }

  Widget _buildHeaderActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(FeatherIcons.plus, size: 18),
        label: Text(
          _translate('Tạo Nhóm Mới', 'Create New Group'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B5FE5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    final applicationCount = _controller.pendingInvitations
        .where((inv) => inv.type == 'application')
        .length;

    return Row(
      children: [
        // Active Groups Stat
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B5FE5).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  FeatherIcons.users,
                  size: 18,
                  color: Color(0xFF3B5FE5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _translate(
                    '${_controller.groups.length} nhóm đang hoạt động',
                    '${_controller.groups.length} active group${_controller.groups.length != 1 ? 's' : ''}',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212631),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Pending Applications Stat
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF57C1F).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  FeatherIcons.mail,
                  size: 18,
                  color: Color(0xFFF57C1F),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _translate(
                    '$applicationCount đơn xin vào đang chờ',
                    '$applicationCount pending application${applicationCount != 1 ? 's' : ''}',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212631),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabsSliverToBoxAdapter() {
    final invitationCount =
        _controller.invitations.length + _controller.pendingInvitations.length;

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                index: 0,
                label: _translate('Nhóm', 'Groups'),
                badge: null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTabButton(
                index: 1,
                label: _translate('Lời Mời', 'Invitations'),
                badge: invitationCount > 0 ? invitationCount : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    int? badge,
  }) {
    final isSelected = _controller.selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _controller.setSelectedTabIndex(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF3B5FE5) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF212631)
                    : const Color(0xFF747A8A),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsSliver() {
    if (_controller.groups.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FeatherIcons.users, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _translate('Chưa có nhóm nào', 'No groups yet'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final group = _controller.groups[index];
          final progress = _controller.groupProgress[group.id] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GroupCard(
              group: group,
              progress: progress,
              language: widget.language,
              onViewTap: () => _navigateToGroupDetail(group.id),
              onLeaveGroupTap: () => _handleLeaveGroup(group.id, group.name),
            ),
          );
        }, childCount: _controller.groups.length),
      ),
    );
  }

  Widget _buildInvitationsSliver() {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Sub-tabs for invitations
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E4E9), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildInvitationTabButton(
                    index: 0,
                    label: _translate('Đơn xin vào', 'Applications'),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildInvitationTabButton(
                    index: 1,
                    label: _translate('Đang chờ', 'Pending'),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content based on selected sub-tab
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: _invitationTabIndex == 0
              ? _buildApplicationsList()
              : _buildInvitationsList(),
        ),
      ]),
    );
  }

  Widget _buildInvitationTabButton({
    required int index,
    required String label,
  }) {
    final isSelected = _invitationTabIndex == index;
    final applicationCount = _controller.pendingInvitations
        .where((inv) => inv.type == 'application')
        .length;
    final invitationCount = _controller.pendingInvitations
        .where((inv) => inv.type == 'invitation')
        .length;
    final badgeCount = index == 0 ? applicationCount : invitationCount;

    return GestureDetector(
      onTap: () => setState(() => _invitationTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF212631)
                    : const Color(0xFF747A8A),
              ),
              textAlign: TextAlign.center,
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList() {
    final applications = _controller.pendingInvitations
        .where((inv) => inv.type == 'application')
        .toList();

    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _translate('Chưa có đơn xin vào nào', 'No applications yet'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final app = applications[index];
        return _buildInvitationCard(app, showActions: true);
      },
    );
  }

  Widget _buildInvitationsList() {
    final pending = _controller.pendingInvitations
        .where((inv) => inv.type == 'invitation')
        .toList();

    if (pending.isEmpty) {
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
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final invite = pending[index];
        return _buildInvitationCard(invite, showActions: false);
      },
    );
  }

  Widget _buildInvitationCard(
    GroupInvitation invitation, {
    bool showActions = true,
  }) {
    final initials = invitation.displayName.isNotEmpty
        ? invitation.displayName[0].toUpperCase()
        : 'U';
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6366F1),
                backgroundImage: invitation.avatarUrl.isNotEmpty
                    ? NetworkImage(invitation.avatarUrl)
                    : null,
                child: invitation.avatarUrl.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212631),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invitation.email,
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
          if (invitation.message != null && invitation.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B5FE5).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                invitation.message!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (showActions)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Decline
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_translate('Từ chối', 'Declined')),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEF4444)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _translate('Hủy', 'Decline'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Accept
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_translate('Chấp nhận', 'Accepted')),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B5FE5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _translate('Chấp nhận', 'Accept'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                timeText,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ),
        ],
      ),
    );
  }
}
