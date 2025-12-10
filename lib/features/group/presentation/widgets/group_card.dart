import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../domain/entities/group.dart';
import 'skill_tag.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final int progress;
  final AppLanguage language;
  final VoidCallback onViewTap;
  final VoidCallback onLeaveGroupTap;

  const GroupCard({
    super.key,
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
          // Header with role badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 6),
                      Text(
                        group.major.majorName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (group.description != null &&
                          group.description!.isNotEmpty)
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
                    .map((skill) => SkillTag(skill: skill))
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
