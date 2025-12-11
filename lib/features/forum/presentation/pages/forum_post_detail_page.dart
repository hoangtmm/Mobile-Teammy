import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/repositories/forum_repository.dart';

class ForumPostDetailPage extends StatefulWidget {
  const ForumPostDetailPage({
    super.key,
    required this.session,
    required this.language,
    required this.post,
    required this.repository,
    required this.canApply,
  });

  final AuthSession session;
  final AppLanguage language;
  final ForumPost post;
  final ForumRepository repository;
  final bool canApply;

  @override
  State<ForumPostDetailPage> createState() => _ForumPostDetailPageState();
}

class _ForumPostDetailPageState extends State<ForumPostDetailPage> {
  bool _isApplying = false;
  String? _selectedPosition;
  final _messageController = TextEditingController();

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return '-';
    final d = date.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _showApplyModal() async {
    final post = widget.post;

    // LƯU context của màn detail, dùng cho SnackBar + pop('success')
    final pageContext = context;

    if (post.hasApplied) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
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

    setState(() {
      _selectedPosition = null;
      _messageController.clear();
    });

    final positions = (post.positionNeeded ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t('Ứng tuyển vào nhóm', 'Apply to group'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${_t('Ứng tuyển vào:', 'Applying to:')} ${post.groupName ?? post.title}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (positions.isNotEmpty) ...[
                Text(
                  _t(
                    'Vị trí bạn muốn ứng tuyển',
                    'Position you\'re applying for',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPosition,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  hint: Text(_t('Chọn vị trí', 'Select a role')),
                  items: positions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedPosition = value);
                  },
                ),
                const SizedBox(height: 16),
              ],
              Text(
                _t(
                  'Tại sao bạn muốn tham gia dự án này?',
                  'Why you want to join this project?',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _t('Nhập mô tả...', 'Enter description'),
                  border: const OutlineInputBorder(),
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
                    final position = _selectedPosition;
                    final message = _messageController.text.trim();

                    if ((positions.isNotEmpty && position == null) ||
                        message.isEmpty) {
                      // dùng pageContext cho SnackBar
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

                    try {
                      final fullMessage =
                          positions.isNotEmpty && position != null
                          ? '$position - $message'
                          : message;

                      await widget.repository.applyToRecruitmentPost(
                        widget.session.accessToken,
                        postId: post.id,
                        message: fullMessage,
                      );

                      if (!mounted) return;

                      // 1) đóng dialog
                      Navigator.of(dialogContext).pop();
                      // 2) đóng luôn màn detail, trả về 'success'
                      Navigator.of(pageContext).pop('success');
                    } catch (e) {
                      if (!mounted) return;

                      // đóng dialog
                      Navigator.of(dialogContext).pop();
                      // trả lỗi về màn trước
                      Navigator.of(pageContext).pop('error:$e');
                    } finally {
                      if (mounted) {
                        setState(() => _isApplying = false);
                      }
                    }
                  },
            child: _isApplying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(_t('Gửi', 'Submit')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final positions = (post.positionNeeded ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Chi tiết nhóm', 'Group Details')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name
                  if (post.groupName != null && post.groupName!.isNotEmpty)
                    Text(
                      post.groupName!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (post.currentMembers != null &&
                          post.maxMembers != null)
                        _buildStatChip(
                          Icons.people_outline,
                          '${post.currentMembers}/${post.maxMembers} ${_t('thành viên', 'members')}',
                        ),
                      if (post.applicationsCount > 0 &&
                          post.type != 'individual')
                        _buildStatChip(
                          Icons.file_copy_outlined,
                          '${post.applicationsCount} ${_t('đơn ứng tuyển', 'applications')}',
                        ),
                      if (post.expiresAt != null)
                        _buildStatChip(
                          Icons.calendar_today_outlined,
                          '${_t('Hạn:', 'Due:')} ${_formatDateShort(post.expiresAt)}',
                        ),
                      if (post.semesterSeason != null &&
                          post.semesterYear != null)
                        _buildStatChip(
                          Icons.school_outlined,
                          '${post.semesterSeason} ${post.semesterYear}',
                        ),
                      if (post.majorName != null)
                        _buildStatChip(Icons.book_outlined, post.majorName!),
                      if (post.topicName != null)
                        _buildStatChip(Icons.topic_outlined, post.topicName!),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leader info
                  if (post.authorName != null && post.authorName!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF4F46E5),
                            backgroundImage:
                                (post.authorAvatarUrl?.isNotEmpty ?? false)
                                ? NetworkImage(post.authorAvatarUrl!)
                                : null,
                            child: (post.authorAvatarUrl?.isNotEmpty ?? false)
                                ? null
                                : Text(
                                    post.authorName!.characters.first
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  post.type == 'individual'
                                      ? _t('Người đăng', 'Posted by')
                                      : _t('Trưởng nhóm', 'Group Leader'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Mentor info
                  if (post.mentorName != null &&
                      post.mentorName!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFF97316),
                            backgroundImage:
                                (post.mentorAvatarUrl?.isNotEmpty ?? false)
                                ? NetworkImage(post.mentorAvatarUrl!)
                                : null,
                            child: (post.mentorAvatarUrl?.isNotEmpty ?? false)
                                ? null
                                : Text(
                                    post.mentorName!.characters.first
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.mentorName!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _t('Giảng viên hướng dẫn', 'Mentor'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                if (post.mentorEmail != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    post.mentorEmail!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Topic info
                  if (post.topicName != null && post.topicName!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.topic_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t('Chủ đề dự án', 'Project Topic'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E40AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  post.topicName!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Group description
                  if (post.groupDescription != null &&
                      post.groupDescription!.isNotEmpty) ...[
                    _buildSection(
                      _t('Mô tả nhóm', 'Group Description'),
                      Text(
                        post.groupDescription!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF374151),
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  _buildSection(
                    _t('Chi tiết bài ứng tuyển', 'About Project'),
                    Text(
                      post.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF374151),
                        height: 1.6,
                      ),
                    ),
                  ),

                  // Positions needed
                  if (positions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      _t('Vị trí cần tuyển', 'Positions Needed'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: positions
                            .map(
                              (p) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF86EFAC),
                                  ),
                                ),
                                child: Text(
                                  p,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],

                  // Skills
                  if (post.skills.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      _t('Kỹ năng yêu cầu', 'Required Skills'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: post.skills
                            .map(
                              (s) => Chip(
                                label: Text(s),
                                labelStyle: const TextStyle(fontSize: 13),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: const Color(0xFFE5EDFF),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],

                  // Members
                  if (post.members.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      _t('Thành viên nhóm', 'Group Members'),
                      Column(
                        children: post.members.map<Widget>((member) {
                          final initial = member.displayName.trim().isNotEmpty
                              ? member.displayName
                                    .trim()
                                    .characters
                                    .first
                                    .toUpperCase()
                              : 'M';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF6366F1),
                                  backgroundImage:
                                      (member.avatarUrl?.isNotEmpty ?? false)
                                      ? NetworkImage(member.avatarUrl!)
                                      : null,
                                  child: (member.avatarUrl?.isNotEmpty ?? false)
                                      ? null
                                      : Text(
                                          initial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.displayName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      if (member.email != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          member.email!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (member.role != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: member.role == 'leader'
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFE0E7FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      member.role == 'leader'
                                          ? _t('Leader', 'Leader')
                                          : _t('Thành viên', 'Member'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: member.role == 'leader'
                                            ? const Color(0xFF166534)
                                            : const Color(0xFF4338CA),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Application status
                  if (post.hasApplied && post.myApplicationStatus != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: post.myApplicationStatus == 'accepted'
                            ? const Color(0xFFDCFCE7)
                            : post.myApplicationStatus == 'rejected'
                            ? const Color(0xFFFFE4E6)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            post.myApplicationStatus == 'accepted'
                                ? Icons.check_circle
                                : post.myApplicationStatus == 'rejected'
                                ? Icons.cancel
                                : Icons.schedule,
                            color: post.myApplicationStatus == 'accepted'
                                ? const Color(0xFF16A34A)
                                : post.myApplicationStatus == 'rejected'
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFCA8A04),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.myApplicationStatus == 'accepted'
                                      ? _t('Đã chấp nhận', 'Accepted')
                                      : post.myApplicationStatus == 'rejected'
                                      ? _t('Đã từ chối', 'Rejected')
                                      : _t('Đang chờ duyệt', 'Pending'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        post.myApplicationStatus == 'accepted'
                                        ? const Color(0xFF16A34A)
                                        : post.myApplicationStatus == 'rejected'
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFCA8A04),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  post.myApplicationStatus == 'accepted'
                                      ? _t(
                                          'Bạn đã được chấp nhận vào nhóm',
                                          'You have been accepted to the group',
                                        )
                                      : post.myApplicationStatus == 'rejected'
                                      ? _t(
                                          'Đơn của bạn đã bị từ chối',
                                          'Your application was rejected',
                                        )
                                      : _t(
                                          'Đơn của bạn đang được xem xét',
                                          'Your application is under review',
                                        ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          post.type == 'group_hiring' && !post.hasApplied && widget.canApply
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _showApplyModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _t('Ứng tuyển vào nhóm', 'Apply to this group'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }
}
