import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

import '../../../../core/localization/app_language.dart';
import '../../data/datasources/group_mentor_data_source.dart';
import '../../data/datasources/group_topic_data_source.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../domain/entities/group.dart';

class TopicSelectionPage extends StatefulWidget {
  final List<Topic> topics;
  final Topic? selectedTopic;
  final AppLanguage language;
  final String? groupId;
  final String? accessToken;
  final String? mentorUserId;
  final Group? group;

  const TopicSelectionPage({
    Key? key,
    required this.topics,
    this.selectedTopic,
    required this.language,
    this.groupId,
    this.accessToken,
    this.mentorUserId,
    this.group,
  }) : super(key: key);

  @override
  State<TopicSelectionPage> createState() => _TopicSelectionPageState();
}

class _TopicSelectionPageState extends State<TopicSelectionPage> {
  late List<Topic> _filteredTopics;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredTopics = widget.topics;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTopics = widget.topics;
      } else {
        _filteredTopics = widget.topics
            .where((topic) =>
                topic.topicName.toLowerCase().contains(query.toLowerCase()) ||
                topic.description.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectTopic(Topic topic) {
    Navigator.of(context).pop(topic);
  }

  void _showMessageDialog(Topic topic) {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            _translate('Mời Mentor', 'Invite Mentor'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212631),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate(
                  'Nhập tin nhắn để gửi lời mời cho mentor:',
                  'Enter message to invite mentor:',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF747A8A),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: _translate('Tin nhắn...', 'Message...'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF3B5FE5)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _translate('Hủy', 'Cancel'),
                style: const TextStyle(
                  color: Color(0xFF747A8A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B5FE5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleSelectTopicWithInvite(topic, messageController.text);
                messageController.dispose();
              },
              child: Text(
                _translate('Xác nhận', 'Confirm'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSelectTopicWithInvite(Topic topic, String message) async {
    if (widget.groupId == null || widget.accessToken == null) {
      _showErrorSnackBar(
        _translate('Lỗi: Thiếu thông tin', 'Error: Missing information'),
      );
      return;
    }

    if (topic.mentors == null || topic.mentors!.isEmpty) {
      _showErrorSnackBar(
        _translate(
          'Chủ đề này chưa có cố vấn được gán. Vui lòng liên hệ quản trị viên.',
          'This topic does not have any mentors assigned. Please contact admin.',
        ),
      );
      return;
    }

    final topicMentor = topic.mentors!.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B5FE5)),
                ),
                const SizedBox(width: 16),
                Text(
                  _translate('Đang xử lý...', 'Processing...'),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      const baseUrl = 'https://api.vps-sep490.io.vn';
      
      final groupDataSource = GroupRemoteDataSource(baseUrl: baseUrl);
      final groups = await groupDataSource.fetchMyGroups(widget.accessToken!);
      
      final latestGroup = groups.firstWhere(
        (g) => g.id == widget.groupId,
        orElse: () => throw Exception('Group not found'),
      );
      
      final allMembers = <dynamic>[];
      if (latestGroup.leader != null) {
        allMembers.add(latestGroup.leader);
      }
      allMembers.addAll(latestGroup.members);
      
      for (var i = 0; i < allMembers.length; i++) {
        dynamic member = allMembers[i];
        String displayName = '';
        String email = '';
        String role = '';
        
        if (member.runtimeType.toString().contains('GroupMember')) {
          displayName = member.displayName;
          email = member.email;
          role = member.role;
        } else {
          displayName = member.displayName ?? 'Unknown';
          email = member.email ?? 'N/A';
          role = member.role ?? 'unknown';
        }
        
        print('    [$i] $displayName ($email) - Role: $role');
      }
      print('  Total including leader: ${allMembers.length}');

      if (latestGroup.currentMembers < latestGroup.maxMembers) {
        if (!mounted) return;
        Navigator.of(context).pop(); 

        _showErrorSnackBar(
          _translate(
            'Nhóm chưa đủ thành viên. Hiện có ${latestGroup.currentMembers}/${latestGroup.maxMembers}. Vui lòng thêm ${latestGroup.maxMembers - latestGroup.currentMembers} thành viên trước khi chọn chủ đề.',
            'Group is not full yet. Current: ${latestGroup.currentMembers}/${latestGroup.maxMembers}. Please add ${latestGroup.maxMembers - latestGroup.currentMembers} more member(s) before selecting topic.',
          ),
        );
        return;
      }
      
      if (latestGroup.topic != null) {
        if (!mounted) return;
        Navigator.of(context).pop(); 

        _showErrorSnackBar(
          _translate(
            'Nhóm của bạn đã có chủ đề rồi. Không thể thay đổi chủ đề.',
            'Your group already has a topic assigned. Cannot change topic.',
          ),
        );
        return;
      }
      
      if (!latestGroup.semester.isActive) {
        if (!mounted) return;
        Navigator.of(context).pop(); 

        _showErrorSnackBar(
          _translate(
            'Học kỳ hiện tại không hoạt động. Không thể chọn chủ đề lúc này.',
            'Current semester is not active. Cannot select topic at this time.',
          ),
        );
        return;
      }

      final mentorDataSource = GroupMentorDataSource(baseUrl: baseUrl);
      final topicDataSource = GroupTopicDataSource(baseUrl: baseUrl);

      try {
        await Future.wait([
          mentorDataSource.inviteMentor(
            accessToken: widget.accessToken!,
            groupId: widget.groupId!,
            mentorUserId: topicMentor.mentorId,
            topicId: topic.topicId,
            message: message,
          ),
          topicDataSource.updateGroupTopic(
            accessToken: widget.accessToken!,
            groupId: widget.groupId!,
            topicId: topic.topicId,
          ),
        ]);
      } on GroupMustBeFullException {
        rethrow;
      } catch (e) {
        rethrow;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      _showSuccessSnackBar(
        _translate(
          'Chọn chủ đề và mời mentor thành công!',
          'Topic selected and mentor invited successfully!',
        ),
      );

      // Pop current page and return the topic
      Navigator.of(context).pop(topic);
    } on MentorNotAssignedToTopicException {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      _showErrorSnackBar(
        _translate(
          'Cố vấn chưa được gán cho chủ đề này. Vui lòng chọn cố vấn được gán cho chủ đề.',
          'This mentor is not assigned to this topic. Please select a mentor assigned to this topic.',
        ),
      );
    } on GroupMustBeFullException {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      _showErrorSnackBar(
        _translate(
          'Nhóm chưa đủ thành viên để mời mentor. Vui lòng thêm đủ thành viên vào nhóm trước.',
          'Group must be full before inviting mentor. Please add enough members first.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      String errorMessage = e.toString();
      if (errorMessage.contains('409')) {
        errorMessage = _translate(
          'Nhóm chưa đủ thành viên để mời mentor (HTTP 409)',
          'Group must be full before inviting mentor (HTTP 409)',
        );
      }

      _showErrorSnackBar(errorMessage);
    }
  }


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _translate('Chọn Chủ Đề', 'Select Topic'),
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: _translate('Tìm chủ đề...', 'Search topics...'),
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: const Icon(FeatherIcons.search, color: Color(0xFF9CA3AF), size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B5FE5)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          // Topic List
          Expanded(
            child: _filteredTopics.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FeatherIcons.inbox,
                          size: 48,
                          color: const Color(0xFFD1D5DB),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _translate(
                            'Không tìm thấy chủ đề',
                            'No topics found',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTopics.length,
                    itemBuilder: (context, index) {
                      final topic = _filteredTopics[index];
                      final isSelected =
                          widget.selectedTopic?.topicId == topic.topicId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildTopicCard(topic, isSelected),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(Topic topic, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected ? const Color(0xFF3B5FE5) : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectTopic(topic),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Topic Name + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        topic.topicName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212631),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (topic.status != null && topic.status!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEF9F4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _translateStatus(topic.status!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Date
                if (topic.createdAt != null)
                  Row(
                    children: [
                      const Icon(FeatherIcons.calendar, size: 16, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(topic.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF747A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  topic.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF747A8A),
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                
                // Major Name with icon
                if (topic.majorName != null && topic.majorName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        const Icon(FeatherIcons.code, size: 16, color: Color(0xFF3B5FE5)),
                        const SizedBox(width: 6),
                        Text(
                          topic.majorName!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF212631),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Skills Section
                if (topic.skills != null && topic.skills!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: topic.skills!.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF747A8A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      _translate('Chưa có kỹ năng', 'No skills'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD1D5DB),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                
                // Mentor Section
                if (topic.mentors != null && topic.mentors!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(FeatherIcons.users, size: 16, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 6),
                            Text(
                              _translate('Mentor', 'Mentor'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF747A8A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...topic.mentors!.take(2).map((mentor) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const SizedBox(width: 22),
                                Expanded(
                                  child: Text(
                                    mentor.mentorName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF212631),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                
                // Select Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5FE5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => widget.groupId != null && widget.accessToken != null && widget.mentorUserId != null
                        ? _showMessageDialog(topic)
                        : _selectTopic(topic),
                    child: Text(
                      _translate('Chọn chủ đề', 'Select topic'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return widget.language == AppLanguage.vi ? 'Đang mở' : 'Open';
      case 'closed':
        return widget.language == AppLanguage.vi ? 'Đã đóng' : 'Closed';
      default:
        return status;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}

