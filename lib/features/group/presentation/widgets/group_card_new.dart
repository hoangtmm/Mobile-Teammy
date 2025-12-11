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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and role badge
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212631),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.major.majorName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF747A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (group.role == 'leader')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B5FE5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF3B5FE5).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Color(0xFF3B5FE5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _translate('Trưởng nhóm', 'Team Lead'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B5FE5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Info Grid: Semester | Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translate('Kỳ học', 'Semester'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF747A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.semester.season} ${group.semester.year}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212631),
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
                          fontSize: 10,
                          color: Color(0xFF747A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(group.status)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
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

          const SizedBox(height: 12),

          // Progress Bar
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
                        color: Color(0xFF747A8A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$progress%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B5FE5),
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
                    backgroundColor: const Color(0xFFE2E4E9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Members and Skills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      FeatherIcons.users,
                      size: 14,
                      color: Color(0xFF747A8A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      group.currentMembers == 0
                          ? _translate('Chưa có thành viên', 'No members')
                          : _translate(
                              '${group.currentMembers}/${group.maxMembers} thành viên',
                              '${group.currentMembers}/${group.maxMembers} members',
                            ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF747A8A),
                      ),
                    ),
                  ],
                ),
                if (group.skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: group.skills.take(3).map((skill) {
                      return SkillTag(skill: skill);
                    }).toList(),
                  ),
                  if (group.skills.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '+${group.skills.length - 3} ${_translate('khác', 'more')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF747A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFFE2E4E9),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onViewTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5FE5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onLeaveGroupTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _translate('Rời khỏi', 'Leave'),
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

  String _formatStatus(String status) {
    if (status == 'recruiting') return _translate('Tuyển dụng', 'Recruiting');
    if (status == 'active') return _translate('Hoạt động', 'Active');
    if (status == 'completed') return _translate('Hoàn thành', 'Completed');
    return status;
  }

  Color _getProgressColor(int percent) {
    if (percent < 33) return const Color(0xFF9CA3AF);
    if (percent < 66) return const Color(0xFFF57C1F);
    return const Color(0xFF10B981);
  }

  Color _getStatusColor(String status) {
    if (status == 'recruiting') return const Color(0xFF3B5FE5);
    if (status == 'active') return const Color(0xFF10B981);
    if (status == 'completed') return const Color(0xFF8B5CF6);
    return const Color(0xFF747A8A);
  }
}
