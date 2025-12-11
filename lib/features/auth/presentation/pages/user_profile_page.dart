import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../domain/entities/auth_session.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../../chat/data/datasources/chat_remote_data_source.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/domain/entities/chat_conversation.dart';
import '../../../chat/presentation/pages/chat_detail_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final AuthSession session;
  final AppLanguage language;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.session,
    required this.language,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late UserRepository _repository;
  UserProfile? _profile;
  bool _loading = true;
  String? _error;
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();
    _repository = UserRepository(
      remoteDataSource: UserRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final profile = await _repository.fetchProfileByUserId(
        widget.session.accessToken,
        widget.userId,
      );

      if (!mounted) return;
      setState(() {
        _profile = profile;
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

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  Future<void> _sendMessage() async {
    if (_profile == null || _openingChat) return;

    if (_profile!.userId == widget.session.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate(
              'Ban khong the nhan tin cho chinh minh',
              'You cannot message yourself',
            ),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _openingChat = true);
    final chatRepository = ChatRepository(
      remoteDataSource: ChatRemoteDataSource(baseUrl: kApiBaseUrl),
    );

    try {
      ChatConversation? conversation;

      try {
        final items = await chatRepository.fetchConversations(
          accessToken: widget.session.accessToken,
        );
        for (final item in items) {
          if (item.isDirect && item.otherUserId == _profile!.userId) {
            conversation = item;
            break;
          }
        }
      } catch (_) {}

      conversation ??= await chatRepository.createDirectConversation(
        accessToken: widget.session.accessToken,
        otherUserId: _profile!.userId,
      );

      if (!mounted || conversation == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            session: widget.session,
            language: widget.language,
            conversation: conversation!,
            repository: chatRepository,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate(
              'Khong the mo chat: $e',
              'Unable to open chat: $e',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _translate('Thông tin cá nhân', 'Profile'),
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B5FE5)),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FeatherIcons.alertCircle,
                        size: 48,
                        color: const Color(0xFFD1D5DB),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _translate(
                          'Không thể tải thông tin người dùng',
                          'Unable to load user profile',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? Center(
                      child: Text(
                        _translate(
                          'Không tìm thấy người dùng',
                          'User not found',
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 56,
                              backgroundColor: const Color(0xFFE4E7EC),
                              backgroundImage: _profile!.avatarUrl != null
                                  ? NetworkImage(_profile!.avatarUrl!)
                                  : null,
                              child: _profile!.avatarUrl == null
                                  ? Text(
                                      _profile!.displayName.isNotEmpty
                                          ? _profile!.displayName[0]
                                          : 'U',
                                      style: const TextStyle(
                                        color: Color(0xFF39476A),
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // Display Name
                            Text(
                              _profile!.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF212631),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Email
                            Text(
                              _profile!.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF747A8A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Action Buttons
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B5FE5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _openingChat ? null : _sendMessage,
                                icon: const Icon(
                                  Icons.message,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _translate('Gửi tin nhắn', 'Send Message'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Profile Details Card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
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
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Student Code
                                    if (_profile!.studentCode != null &&
                                        _profile!.studentCode!.isNotEmpty)
                                      _buildInfoRow(
                                        _translate('Mã sinh viên', 'Student Code'),
                                        _profile!.studentCode!,
                                      ),

                                    // Major
                                    if (_profile!.majorName != null &&
                                        _profile!.majorName!.isNotEmpty) ...[
                                      if (_profile!.studentCode != null &&
                                          _profile!.studentCode!.isNotEmpty)
                                        const Divider(height: 24),
                                      _buildInfoRow(
                                        _translate('Chuyên ngành', 'Major'),
                                        _profile!.majorName!,
                                      ),
                                    ],

                                    // Phone
                                    if (_profile!.phone != null &&
                                        _profile!.phone!.isNotEmpty) ...[
                                      const Divider(height: 24),
                                      _buildInfoRow(
                                        _translate('Điện thoại', 'Phone'),
                                        _profile!.phone!,
                                      ),
                                    ],

                                    // Gender
                                    if (_profile!.gender != null &&
                                        _profile!.gender!.isNotEmpty) ...[
                                      const Divider(height: 24),
                                      _buildInfoRow(
                                        _translate('Giới tính', 'Gender'),
                                        _translateGender(_profile!.gender!),
                                      ),
                                    ],

                                    // Skills
                                    if (_profile!.skills != null &&
                                        _profile!.skills!.isNotEmpty) ...[
                                      const Divider(height: 24),
                                      Text(
                                        _translate('Kỹ năng', 'Skills'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF747A8A),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _profile!.skills!
                                            .split(',')
                                            .map((skill) {
                                          return Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  const Color(0xFFF3F4F6),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(
                                                    0xFFE5E7EB),
                                              ),
                                            ),
                                            child: Text(
                                              skill.trim(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF747A8A),
                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],

                                    // Portfolio URL
                                    if (_profile!.portfolioUrl != null &&
                                        _profile!.portfolioUrl!.isNotEmpty) ...[
                                      const Divider(height: 24),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _translate(
                                                'Portfolio', 'Portfolio'),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF747A8A),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () {
                                              // Could open URL if needed
                                            },
                                            child: Text(
                                              _profile!.portfolioUrl!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF3B5FE5),
                                                fontWeight: FontWeight.w500,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF747A8A),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF212631),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _translateGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return widget.language == AppLanguage.vi ? 'Nam' : 'Male';
      case 'female':
        return widget.language == AppLanguage.vi ? 'Nữ' : 'Female';
      case 'other':
        return widget.language == AppLanguage.vi ? 'Khác' : 'Other';
      default:
        return gender;
    }
  }
}
