import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/models/group_recruitment_post_model.dart';

class GroupPostsPage extends StatefulWidget {
  final String groupId;
  final AuthSession session;
  final AppLanguage language;

  const GroupPostsPage({
    super.key,
    required this.groupId,
    required this.session,
    required this.language,
  });

  @override
  State<GroupPostsPage> createState() => _GroupPostsPageState();
}

class _GroupPostsPageState extends State<GroupPostsPage> {
  late final GroupRemoteDataSource _dataSource;
  bool _loading = false;
  String? _error;
  List<GroupRecruitmentPostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _dataSource = GroupRemoteDataSource(baseUrl: kApiBaseUrl);
    _loadPosts();
  }

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _dataSource.fetchGroupRecruitmentPosts(
        widget.session.accessToken,
        widget.groupId,
      );
      if (!mounted) return;
      setState(() {
        _posts = posts;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('Bai viet', 'Recruitment Posts')),
        elevation: 0,
      ),
      body: _loading && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: Text(_translate('Thu lai', 'Retry')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        _translate('Bai tuyen dung', 'Recruitment Posts'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _translate(
                          '${_posts.length} vi tri dang tuyen',
                          '${_posts.length} position(s) available',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_posts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              _translate(
                                'Chua co bai viet nao',
                                'No recruitment posts yet',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        )
                      else
                        ..._posts.map(_buildPostCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPostCard(GroupRecruitmentPostModel post) {
    final dateText = post.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(post.createdAt!.toLocal())
        : '-';
    final deadlineText = post.applicationDeadline != null
        ? DateFormat('dd/MM/yyyy')
            .format(post.applicationDeadline!.toLocal())
        : '-';
    final statusText = post.status.isNotEmpty ? post.status : 'open';
    final statusColor =
        statusText == 'open' ? const Color(0xFF22C55E) : const Color(0xFF94A3B8);
    final membersText =
        (post.currentMembers != null && post.maxMembers != null)
            ? '${post.currentMembers}/${post.maxMembers} Members'
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF111827),
                backgroundImage: post.mentorAvatarUrl != null
                    ? NetworkImage(post.mentorAvatarUrl!)
                    : null,
                child: post.mentorAvatarUrl == null
                    ? Text(
                        post.mentorName != null && post.mentorName!.isNotEmpty
                            ? post.mentorName![0].toUpperCase()
                            : 'H',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    if (post.mentorName != null && post.mentorName!.isNotEmpty)
                      post.mentorName,
                    if (post.groupName != null && post.groupName!.isNotEmpty)
                      post.groupName,
                  ].whereType<String>().join('  '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                dateText,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                'Due: $deadlineText',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (post.positionNeeded != null && post.positionNeeded!.isNotEmpty) ...[
            const Text(
              'Positions Needed:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.positionNeeded!
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .map(
                    (position) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        position,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (post.majorName != null && post.majorName!.isNotEmpty) ...[
            const Text(
              'Major:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              post.majorName!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
          ],
          if (post.skills.isNotEmpty) ...[
            const Text(
              'Skills:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.skills
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (membersText != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  membersText,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
