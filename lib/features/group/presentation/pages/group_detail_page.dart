import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/pages/user_profile_page.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/datasources/topic_remote_data_source.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../controllers/group_detail_controller.dart';
import 'topic_selection_page.dart';
import 'contribute_score_page.dart';
import 'feedback_page.dart';
import 'group_posts_page.dart';
import 'group_files_page.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedDrawerIndex = 0;
  bool _activatingGroup = false;

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
    final canActivate = isLeader && group.status == 'recruiting';

    return Scaffold(
      key: _scaffoldKey,
      drawer: _NavigationDrawer(
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.menu,
                      color: Color(0xFF666666),
                      size: 20,
                    ),
                  ),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _translate('Chi tiết nhóm', 'Group Details'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B2B57),
                      ),
                    ),
                  ),
                ),
                if (isLeader)
                  IconButton(
                    icon: const Icon(FeatherIcons.edit),
                    onPressed: () => _showEditGroup(),
                  ),
                if (!isLeader) const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupHeader(group: group, language: widget.language),
            const SizedBox(height: 20),
            _GroupInfoGrid(group: group, progress: _controller.groupProgress, language: widget.language),
            if (canActivate) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _activatingGroup ? null : _confirmActivateGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5FE5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _activatingGroup
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_translate('Kích hoạt nhóm', 'Confirm Group')),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _MentorSection(group: group, language: widget.language, session: widget.session),
            const SizedBox(height: 20),
            _TopicSection(group: group, isLeader: isLeader, language: widget.language, session: widget.session, onSelectTopic: () => _loadAndShowTopics(context)),
            const SizedBox(height: 20),
            _TechnologiesSection(group: group, language: widget.language),
            const SizedBox(height: 20),
            _TeamMembersSection(
              parentContext: context,
              group: group,
              members: _controller.members,
              isLeader: isLeader,
              language: widget.language,
              session: widget.session,
              onInvite: _showInviteMembersDialog,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAndShowTopics(BuildContext context) async {
    try {
      final topicDataSource = TopicRemoteDataSource(baseUrl: kApiBaseUrl);
      final topicModels = await topicDataSource.fetchTopics(widget.session.accessToken);
      
      if (!context.mounted) return;

      final topics = topicModels.map((model) => model.toEntity()).toList();

      // Get mentor user ID from group mentor or session
      final group = _controller.group;
      final mentorUserId = group?.mentor?.userId ?? widget.session.userId;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TopicSelectionPage(
            topics: topics,
            selectedTopic: group?.topic,
            language: widget.language,
            groupId: group?.id,
            accessToken: widget.session.accessToken,
            mentorUserId: mentorUserId,
            group: group,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
    }
  }

  void _showEditGroup() {
    showDialog(
      context: context,
      builder: (_) => _EditGroupDialog(
        group: _controller.group!,
        session: widget.session,
        language: widget.language,
        onGroupUpdated: () => _controller.loadGroupDetail(),
      ),
    );
  }

  Future<void> _confirmActivateGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          _translate('Xác nhận kích hoạt nhóm?', 'Confirm activate group?'),
        ),
        content: Text(
          _translate(
            'Khi kích hoạt, nhóm sẽ được khóa trong học kỳ này. Bạn có muốn tiếp tục?',
            'Once activated, your group will be locked for this semester. Do you want to continue?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_translate('Hủy', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_translate('Xác nhận', 'Confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || _activatingGroup) return;

    setState(() {
      _activatingGroup = true;
    });

    try {
      final dataSource = GroupRemoteDataSource(baseUrl: kApiBaseUrl);
      final message = await dataSource.activateGroup(
        widget.session.accessToken,
        widget.groupId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              message.contains('Need') ? Colors.orange : Colors.green,
        ),
      );
      _controller.loadGroupDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _activatingGroup = false;
        });
      }
    }
  }

  Future<void> _handleDrawerNavigation(int index) async {
    // Handle navigation based on drawer item selection
    switch (index) {
      case 0: // Overview
        // Already on Group Details page, just close drawer
        break;
      case 1: // Contribute Score
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ContributeScorePage(
              groupId: widget.groupId,
              session: widget.session,
              language: widget.language,
            ),
          ),
        );
        if (!mounted) return;
        setState(() {
          _selectedDrawerIndex = 0;
        });
        break;
      case 2: // Feedback
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FeedbackPage(
              groupId: widget.groupId,
              session: widget.session,
              language: widget.language,
            ),
          ),
        );
        if (!mounted) return;
        setState(() {
          _selectedDrawerIndex = 0;
        });
        break;
      case 3: // Posts
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupPostsPage(
              groupId: widget.groupId,
              session: widget.session,
              language: widget.language,
            ),
          ),
        );
        if (!mounted) return;
        setState(() {
          _selectedDrawerIndex = 0;
        });
        break;
      case 4: // Files
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupFilesPage(
              groupId: widget.groupId,
              session: widget.session,
              language: widget.language,
            ),
          ),
        );
        if (!mounted) return;
        setState(() {
          _selectedDrawerIndex = 0;
        });
        break;
    }
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
                    Text(group.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF212631))),
                    const SizedBox(height: 6),
                    Text(group.major.majorName, style: const TextStyle(fontSize: 14, color: Color(0xFF747A8A), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              _buildRoleBadge(),
            ],
          ),
          if (group.description != null && group.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(group.description!, style: const TextStyle(fontSize: 14, color: Color(0xFF747A8A))),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3B5FE5).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B5FE5).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getRoleIcon(), size: 14, color: const Color(0xFF3B5FE5)),
          const SizedBox(width: 4),
          Text(_formatRole(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B5FE5))),
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
        _buildInfoSection(),
        const SizedBox(height: 16),
        _buildProgressSection(),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_translate('Thông tin nhóm', 'Group Info'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoCard(FeatherIcons.calendar, _translate('Kỳ học', 'Semester'), '${group.semester.season} ${group.semester.year}')),
              const SizedBox(width: 12),
              Expanded(child: _buildInfoCard(FeatherIcons.activity, _translate('Trạng thái', 'Status'), _formatStatus())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF3B5FE5)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF747A8A), fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212631)), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.trendingUp, size: 18, color: const Color(0xFF3B5FE5)),
              const SizedBox(width: 8),
              Text(_translate('Tiến độ dự án', 'Project Progress'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$progress%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF3B5FE5))),
            ],
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
  final AuthSession session;

  const _MentorSection({required this.group, required this.language, required this.session});

  String _translate(String vi, String en) => language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.briefcase, size: 18, color: const Color(0xFF212631)),
              const SizedBox(width: 8),
              Text(_translate('Cố vấn', 'Mentor'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
            ],
          ),
          const SizedBox(height: 12),
          group.mentor != null ? _buildMentorContent(context) : _buildEmptyContent(),
        ],
      ),
    );
  }

  Widget _buildMentorContent(BuildContext context) {
    final mentor = group.mentor!;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserProfilePage(
              userId: mentor.userId,
              session: session,
              language: language,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildAvatar(mentor.displayName, mentor.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mentor.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
                  const SizedBox(height: 4),
                  Text(mentor.email, style: const TextStyle(fontSize: 12, color: Color(0xFF747A8A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(FeatherIcons.star, size: 18, color: const Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Text(_translate('Chưa có cố vấn', 'No mentor assigned'), style: const TextStyle(fontSize: 14, color: Color(0xFF747A8A)));
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
  final AuthSession session;
  final VoidCallback? onSelectTopic;

  const _TopicSection({required this.group, required this.isLeader, required this.language, required this.session, this.onSelectTopic});

  String _translate(String vi, String en) => language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.book, size: 18, color: const Color(0xFF3B5FE5)),
              const SizedBox(width: 8),
              Text(_translate('Chủ đề dự án', 'Project Topic'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
            ],
          ),
          const SizedBox(height: 12),
          if (isLeader && group.topic == null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSelectTopic,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B5FE5).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3B5FE5).withOpacity(0.3), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: _buildTopicContent()),
                      const SizedBox(width: 12),
                      Icon(FeatherIcons.chevronRight, color: const Color(0xFF3B5FE5), size: 24),
                    ],
                  ),
                ),
              ),
            )
          else
            _buildTopicContent(),
        ],
      ),
    );
  }

  Widget _buildTopicContent() {
    return group.topic != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.topic!.topicName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
              const SizedBox(height: 8),
              Text(group.topic!.description, style: const TextStyle(fontSize: 13, color: Color(0xFF747A8A)), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _translate('Chưa chọn chủ đề', 'No topic selected'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF747A8A),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.zap, size: 18, color: const Color(0xFF3B5FE5)),
              const SizedBox(width: 8),
              Text(_translate('Công nghệ sử dụng', 'Technologies'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
            ],
          ),
          const SizedBox(height: 12),
          group.skills.isNotEmpty
              ? Wrap(spacing: 8, runSpacing: 8, children: group.skills.map((skill) => SkillTag(skill: skill)).toList())
              : Text(_translate('Chưa có công nghệ nào', 'No technologies selected'), style: const TextStyle(fontSize: 14, color: Color(0xFF747A8A))),
        ],
      ),
    );
  }
}

// ============ TEAM MEMBERS SECTION ============
class _TeamMembersSection extends StatelessWidget {
  final BuildContext parentContext;
  final Group group;
  final List<GroupMember> members;
  final bool isLeader;
  final AppLanguage language;
  final AuthSession session;
  final VoidCallback onInvite;

  const _TeamMembersSection({
    required this.parentContext,
    required this.group,
    required this.members,
    required this.isLeader,
    required this.language,
    required this.session,
    required this.onInvite,
  });

  String _translate(String vi, String en) => language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.users, size: 18, color: const Color(0xFF3B5FE5)),
              const SizedBox(width: 8),
              Text(_translate('Thành viên nhóm', 'Team Members'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
              const Spacer(),
              Text('${members.length} ${_translate('người', 'members')}', style: const TextStyle(fontSize: 14, color: Color(0xFF747A8A), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              ...members.map((member) => _buildMemberCard(member, parentContext)),
              if (isLeader) ...[const SizedBox(height: 12), _buildInviteButton()],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onInvite,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B5FE5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    );
  }

  Widget _buildMemberCard(GroupMember member, BuildContext context) {
    final displayName = member.displayName;
    final role = member.role;
    final hasRole = role.trim().isNotEmpty;
    final avatarUrl = member.avatarUrl;
    final isCurrentUserLeader = isLeader;
    final isMemberLeader = role == 'leader';
    // Chỉ cho kick khi: là leader, member không phải leader, và group chưa active
    final canKick = isCurrentUserLeader && !isMemberLeader && group.status != 'active';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _openUserProfile(context, member.userId),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E4E9)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
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
                    Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
                    const SizedBox(height: 4),
                    Text(
                      _formatRole(hasRole ? role : null),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF747A8A)),
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
              if (canKick) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(FeatherIcons.userMinus, size: 18, color: Color(0xFFEF4444)),
                  onPressed: () => _showKickConfirmation(context, member),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
              if (isCurrentUserLeader && !isMemberLeader) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(FeatherIcons.star, size: 18, color: Color(0xFFF59E0B)),
                  onPressed: () => _showTransferLeaderConfirmation(context, member),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _translate('Chuyển quyền leader', 'Transfer leadership'),
                ),
              ],
            ],
          ),
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
        color: const Color(0xFF3B5FE5),
        image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
      ),
      child: url == null ? Center(child: Text(name.isEmpty ? '?' : name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))) : null,
    );
  }

  void _showKickConfirmation(BuildContext context, GroupMember member) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_translate('Xác nhận', 'Confirm')),
        content: Text(
          _translate(
            'Bạn có chắc chắn muốn xóa ${member.displayName} khỏi nhóm?',
            'Are you sure you want to remove ${member.displayName} from the group?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_translate('Hủy', 'Cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _kickMember(context, member);
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: Text(_translate('Xóa', 'Remove')),
          ),
        ],
      ),
    );
  }

  void _showTransferLeaderConfirmation(BuildContext context, GroupMember member) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_translate('Chuyển quyền leader', 'Transfer Leadership')),
        content: Text(
          _translate(
            'Bạn có chắc chắn muốn chuyển quyền leader cho ${member.displayName}?\n\nBạn sẽ trở thành thành viên thường sau khi chuyển.',
            'Are you sure you want to transfer leadership to ${member.displayName}?\n\nYou will become a regular member after the transfer.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_translate('Hủy', 'Cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _transferLeader(context, member);
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF59E0B)),
            child: Text(_translate('Chuyển', 'Transfer')),
          ),
        ],
      ),
    );
  }

  Future<void> _kickMember(BuildContext context, GroupMember member) async {
    print('[GROUP] Attempting to kick member: ${member.displayName} (${member.userId})');
    print('[GROUP] Current group status: ${group.status}');
    print('[GROUP] Current user role: ${group.role}');
    print('[GROUP] Is leader: $isLeader');
    
    try {
      final dataSource = GroupRemoteDataSource(baseUrl: kApiBaseUrl);
      await dataSource.kickMember(
        accessToken: session.accessToken,
        groupId: group.id,
        userId: member.userId,
      );

      print('[GROUP] Successfully kicked member');
      if (!context.mounted) return;

      // Reload page
      if (parentContext.mounted) {
        Navigator.of(parentContext).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GroupDetailPage(
              groupId: group.id,
              session: session,
              language: language,
            ),
          ),
        );
      }
    } catch (e) {
      print('[GROUP] ERROR kicking member: $e');
      print('[GROUP] Error type: ${e.runtimeType}');
      if (!context.mounted) return;
    }
  }

  Future<void> _transferLeader(BuildContext context, GroupMember member) async {
    print('[GROUP] Attempting to transfer leader to: ${member.displayName} (${member.userId})');
    
    try {
      final dataSource = GroupRemoteDataSource(baseUrl: kApiBaseUrl);
      await dataSource.transferLeader(
        accessToken: session.accessToken,
        groupId: group.id,
        newLeaderUserId: member.userId,
      );

      print('[GROUP] Successfully transferred leadership');
      if (!context.mounted) return;

      // Reload page
      if (parentContext.mounted) {
        Navigator.of(parentContext).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GroupDetailPage(
              groupId: group.id,
              session: session,
              language: language,
            ),
          ),
        );
      }
    } catch (e) {
      print('[GROUP] ERROR transferring leader: $e');
      print('[GROUP] Error type: ${e.runtimeType}');
      if (!context.mounted) return;
    }
  }

  void _openUserProfile(BuildContext context, String userId) {
    try {
      print('[GROUP DETAIL] Opening user profile for userId: $userId');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UserProfilePage(
            userId: userId,
            session: session,
            language: language,
          ),
        ),
      );
    } catch (e) {
      print('[GROUP DETAIL] Error opening user profile: $e');
    }
  }

  String _formatRole(String? role) {
    if (role == 'leader') return _translate('Trưởng nhóm', 'Team Leader');
    if (role == 'member') return _translate('Thành viên', 'Member');
    if (role == 'mentor') return _translate('Cố vấn', 'Mentor');
    return role ?? '';
  }

  Color _getRoleColor(String role) {
    if (role == 'leader') return const Color(0xFFEF4444);
    if (role == 'member') return const Color(0xFF3B5FE5);
    if (role == 'mentor') return const Color(0xFF8B5CF6);
    return const Color(0xFF747A8A);
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
    }
  }

  Future<void> _inviteUser(String userId) async {
    try {
      setState(() => _inviting = true);
      await _dataSource.inviteUserToGroup(widget.session.accessToken, widget.groupId, userId);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onMemberAdded();
    } catch (e) {
      if (!mounted) return;
      setState(() => _inviting = false);
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

// ============ EDIT GROUP DIALOG ============
class _EditGroupDialog extends StatefulWidget {
  final Group group;
  final AuthSession session;
  final AppLanguage language;
  final VoidCallback onGroupUpdated;

  const _EditGroupDialog({
    required this.group,
    required this.session,
    required this.language,
    required this.onGroupUpdated,
  });

  @override
  State<_EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<_EditGroupDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxMembersController;
  late GroupRemoteDataSource _dataSource;

  List<Map<String, dynamic>> _allSkills = [];
  List<Map<String, dynamic>> _selectedSkills = [];
  List<Map<String, dynamic>> _availableSkills = [];
  bool _loading = true;
  bool _saving = false;
  String? _warningMessage;
  String _selectedCategory = 'all'; // Track selected category for filtering

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(text: widget.group.description);
    _maxMembersController = TextEditingController(text: widget.group.maxMembers.toString());
    _dataSource = GroupRemoteDataSource(baseUrl: kApiBaseUrl);

    // Initialize selected skills from strings
    _selectedSkills = widget.group.skills.map((skillToken) {
      return {'token': skillToken, 'role': 'unknown', 'major': 'unknown'};
    }).toList();

    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final response = await _dataSource.fetchAllSkills();
      if (!mounted) return;

      setState(() {
        _allSkills = response;
        _updateAvailableSkills();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _updateAvailableSkills() {
    final selectedTokens = _selectedSkills
        .map((s) => s['token'] as String?)
        .whereType<String>()
        .toSet();
    
    List<Map<String, dynamic>> filtered = _allSkills
        .where((skill) => !selectedTokens.contains(skill['token'] as String?))
        .toList();
    
    // Filter by selected category
    if (_selectedCategory != 'all') {
      filtered = filtered
          .where((skill) => 
              (skill['role']?.toString() ?? '').toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }
    
    _availableSkills = filtered;
  }

  void _addSkill(Map<String, dynamic> skill) {
    try {
      setState(() {
        final skillMap = {
          'token': skill['token'].toString(),
          'role': skill['role']?.toString() ?? 'unknown',
          'major': skill['major']?.toString() ?? 'unknown',
        };
        _selectedSkills.add(skillMap);
        _updateAvailableSkills();
      });
    } catch (e) {
      debugPrint('Error adding skill: $e');
    }
  }

  void _removeSkill(String token) {
    setState(() {
      _selectedSkills.removeWhere((s) {
        final t = s['token'];
        return t.toString() == token;
      });
      _updateAvailableSkills();
    });
  }

  String _translate(String vi, String en) => widget.language == AppLanguage.vi ? vi : en;

  Color _getSkillColor(String? role) {
    switch ((role ?? 'backend').toLowerCase()) {
      case 'frontend':
        return const Color(0xFF06B6D4); // Cyan
      case 'backend':
        return const Color(0xFF8B5CF6); // Purple
      case 'mobile':
        return const Color(0xFFEC4899); // Pink
      case 'devops':
        return const Color(0xFFEF4444); // Red
      case 'qa':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Widget _buildCategoryButton(String label, String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _updateAvailableSkills();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F2937) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF374151) : const Color(0xFFE0E7FF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6366F1),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _translate('CHỈNH SỬA NHÓM', 'EDIT GROUP'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3B5FE5), letterSpacing: 0.5),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 24, color: Color(0xFF747A8A)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _translate('Cập nhật chi tiết nhóm', 'Update group details'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF212631)),
              ),
              const SizedBox(height: 24),

              // Group Name Field
              Text(_translate('Tên nhóm', 'Group Name'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: _translate('Nhập tên nhóm', 'Enter group name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Description Field
              Text(_translate('Mô tả', 'Description'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _translate('Nhập mô tả', 'Enter description'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Max Members Field
              Text(_translate('Số thành viên tối đa', 'Max Members'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
              const SizedBox(height: 8),
              TextField(
                controller: _maxMembersController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _translate('Nhập số thành viên', 'Enter max members'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              if (_warningMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _warningMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Tech Stack Section
              Text(_translate('Công nghệ sử dụng', 'Tech Stack'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212631))),
              const SizedBox(height: 12),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Selected Skills Container - Fixed Width
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_translate('Công nghệ đã chọn', 'Your Selected Skills')} (${_selectedSkills.length})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF212631)),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedSkills.isEmpty)
                        Text(
                          _translate('Chưa chọn công nghệ', 'No skills selected'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedSkills.map((skill) {
                            final token = skill['token']?.toString() ?? '';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E4E9)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(token, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _removeSkill(token),
                                    child: const Icon(Icons.close, size: 14, color: Color(0xFF747A8A)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Category Filter Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCategoryButton('All (${_allSkills.length})', 'all'),
                    _buildCategoryButton('Frontend (${_allSkills.where((s) => (s['role'] ?? '').toString().toLowerCase() == 'frontend').length})', 'frontend'),
                    _buildCategoryButton('Backend (${_allSkills.where((s) => (s['role'] ?? '').toString().toLowerCase() == 'backend').length})', 'backend'),
                    _buildCategoryButton('Mobile (${_allSkills.where((s) => (s['role'] ?? '').toString().toLowerCase() == 'mobile').length})', 'mobile'),
                    _buildCategoryButton('Devops (${_allSkills.where((s) => (s['role'] ?? '').toString().toLowerCase() == 'devops').length})', 'devops'),
                    _buildCategoryButton('Qa (${_allSkills.where((s) => (s['role'] ?? '').toString().toLowerCase() == 'qa').length})', 'qa'),
                  ],
                ),
                const SizedBox(height: 16),

                // Available Skills Title
                Text(
                  _translate('Công nghệ có sẵn', 'Available Skills (Click to add)'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF747A8A)),
                ),
                const SizedBox(height: 12),

                // Available Skills Grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSkills.map((skill) {
                    final token = skill['token']?.toString() ?? '';
                    final role = skill['role']?.toString() ?? 'backend';
                    final color = _getSkillColor(role);
                    return GestureDetector(
                      onTap: () => _addSkill(skill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: token,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: color,
                                ),
                              ),
                              TextSpan(
                                text: ' +',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F6F8),
                        foregroundColor: const Color(0xFF212631),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(_translate('Hủy', 'Cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _saveChanges(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B5FE5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : Text(_translate('Lưu thay đổi', 'Save changes')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _saving = true;
      _warningMessage = null;
    });
    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final maxMembers = int.tryParse(_maxMembersController.text) ?? widget.group.maxMembers;
      final skills = _selectedSkills
          .map((s) => s['token']?.toString() ?? '')
          .where((token) => token.isNotEmpty)
          .toList();

      // Validate inputs
      if (name.isEmpty) {
        throw Exception(_translate('Group name cannot be empty', 'Group name cannot be empty'));
      }

      // Call API to update group
      await _dataSource.updateGroup(
        widget.session.accessToken,
        widget.group.id,
        {
          'name': name,
          'description': description,
          'maxMembers': maxMembers,
          'skills': skills,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate('Group updated successfully', 'Group updated successfully')),
          backgroundColor: Colors.green,
        ),
      );
      widget.onGroupUpdated();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Save error: $e');
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _saving = false;
        _warningMessage = message;
      });
    }
  }
}

// ============ NAVIGATION DRAWER ============
class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.language,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final AppLanguage language;

  String _translate(String vi, String en) =>
      language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _DrawerItem(
        icon: Icons.dashboard_outlined,
        labelVi: 'Tổng quan',
        labelEn: 'Overview',
      ),
      _DrawerItem(
        icon: Icons.people_outline,
        labelVi: 'Điểm đóng góp',
        labelEn: 'Contribute Score',
      ),
      _DrawerItem(
        icon: Icons.feedback_outlined,
        labelVi: 'Phản hồi',
        labelEn: 'Feedback',
      ),
      _DrawerItem(
        icon: Icons.article_outlined,
        labelVi: 'Bài viết',
        labelEn: 'Posts',
      ),
      _DrawerItem(
        icon: Icons.folder_outlined,
        labelVi: 'Tệp',
        labelEn: 'Files',
      ),
    ];

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
      ),
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top,
            color: const Color(0xFFF5F5F5),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = index == selectedIndex;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      if (isSelected)
                        Positioned(
                          left: 0,
                          top: 8,
                          bottom: 8,
                          child: Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          item.icon,
                          color: isSelected
                              ? const Color(0xFF2196F3)
                              : const Color(0xFF666666),
                          size: 24,
                        ),
                        title: Text(
                          _translate(item.labelVi, item.labelEn),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF2196F3)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        onTap: () => onItemSelected(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.icon,
    required this.labelVi,
    required this.labelEn,
  });

  final IconData icon;
  final String labelVi;
  final String labelEn;
}











