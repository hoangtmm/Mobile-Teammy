import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/services/group_invitation_service.dart';
import '../../data/datasources/invitation_remote_data_source.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../data/models/invitation_model.dart';
import '../../../../core/constants/api_constants.dart';

class GroupInvitationsPage extends StatefulWidget {
  const GroupInvitationsPage({
    super.key,
    required this.invitationService,
    required this.accessToken,
  });

  final GroupInvitationService invitationService;
  final String accessToken;

  @override
  State<GroupInvitationsPage> createState() => _GroupInvitationsPageState();
}

class _GroupInvitationsPageState extends State<GroupInvitationsPage> {
  late InvitationRepository _repository;
  late Stream<GroupInvitation> _invitations;
  List<InvitationModel> _pendingInvitations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = InvitationRepository(
      remoteDataSource: InvitationRemoteDataSource(
        baseUrl: kApiBaseUrl,
        accessToken: widget.accessToken,
      ),
    );
    _invitations = widget.invitationService.invitations;
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invitations = await _repository.getPendingInvitations();
      if (!mounted) return;
      setState(() {
        _pendingInvitations = invitations;
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

  Future<void> _acceptInvitation(InvitationModel invitation) async {
    try {
      await _repository.acceptInvitation(invitation.invitationId);
      if (!mounted) return;
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[GroupInvitationsPage] Error accepting invitation: $e');
    }
  }

  Future<void> _declineInvitation(InvitationModel invitation) async {
    try {
      await _repository.declineInvitation(invitation.invitationId);
      if (!mounted) return;
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[GroupInvitationsPage] Error declining invitation: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Padding(
          padding: const EdgeInsets.only(top: 35),
          child: AppBar(
            title: const Text('Lời Mời Vào Nhóm'),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
              onPressed: () => Navigator.pop(context),
            ),
            titleTextStyle: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text('Lỗi: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvitations,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_pendingInvitations.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox,
              size: 80,
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có lời mời nào',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn sẽ nhận thông báo khi có lời mời',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ],
        ),
      );
    }

    // Filter to show only pending invitations
    final pendingOnly = _pendingInvitations
        .where((inv) => inv.status == 'pending')
        .toList();

    if (pendingOnly.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox,
              size: 80,
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có lời mời nào',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn sẽ nhận thông báo khi có lời mời',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ],
        ),
      );
    }

   return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: pendingOnly.length,
      itemBuilder: (context, index) {
        final invitation = pendingOnly[index];
        return _buildInvitationCard(invitation);
      },
    );
  } 

  Widget _buildInvitationCard(InvitationModel invitation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invitation.groupName ?? 'Nhóm',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getInvitationTypeText(invitation.type),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF06B6D4),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (invitation.topicTitle != null) ...[
            const SizedBox(height: 8),
            Text(
              'Chủ đề: ${invitation.topicTitle}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _declineInvitation(invitation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Từ chối',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _acceptInvitation(invitation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Chấp nhận',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInvitationTypeText(String type) {
    switch (type) {
      case 'mentor':
        return 'Mời làm Cố vấn';
      case 'mentor_request':
        return 'Yêu cầu làm Cố vấn';
      case 'member':
      default:
        return 'Mời vào nhóm';
    }
  }
}

