import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../controllers/group_page_controller.dart';
import '../widgets/create_group_dialog.dart';
import '../widgets/group_card.dart';
import 'group_detail_page.dart';

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
  late final GroupPageController _controller;

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
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
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

        return RefreshIndicator(
          onRefresh: _controller.loadGroups,
          child: _buildGroupPageContent(),
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
              _buildHeaderActionButtons(),
              const SizedBox(height: 16),
              _buildHeaderStats(),
            ],
          ),
        ),
      ),
      collapsedHeight: 180,
      expandedHeight: 180,
    );
  }

  Widget _buildHeaderActionButtons() {
    return Row(
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
    );
  }

  Widget _buildHeaderStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          FeatherIcons.users,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 6),
        Text(
          '${_controller.groups.length} ${_translate('nhóm đang hoạt động', 'active groups')}',
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
    );
  }

  Widget _buildTabsSliverToBoxAdapter() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                index: 0,
                label: _translate('Nhóm', 'Groups'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTabButton(
                index: 1,
                label: _translate('Lời Mời', 'Invitations'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label}) {
    final isSelected = _controller.selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _controller.setSelectedTabIndex(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? const Color(0xFF3A6FD8)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFF3A6FD8)
                : const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
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
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final group = _controller.groups[index];
            final progress = _controller.groupProgress[group.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GroupCard(
                group: group,
                progress: progress,
                language: widget.language,
                onViewTap: () => _navigateToGroupDetail(group.id),
                onLeaveGroupTap: () =>
                    _handleLeaveGroup(group.id, group.name),
              ),
            );
          },
          childCount: _controller.groups.length,
        ),
      ),
    );
  }

  Widget _buildInvitationsSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Text(
          _translate('Chưa có lời mời nào', 'No invitations yet'),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

