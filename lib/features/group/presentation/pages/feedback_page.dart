import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/models/group_feedback_model.dart';

class FeedbackPage extends StatefulWidget {
  final String groupId;
  final AuthSession session;
  final AppLanguage language;

  const FeedbackPage({
    super.key,
    required this.groupId,
    required this.session,
    required this.language,
  });

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  late final GroupRemoteDataSource _dataSource;
  final TextEditingController _searchController = TextEditingController();
  bool _loading = false;
  String? _error;
  int _page = 1;
  final int _pageSize = 10;
  int _total = 0;
  String? _statusFilter;
  List<GroupFeedbackModel> _items = [];

  @override
  void initState() {
    super.initState();
    _dataSource = GroupRemoteDataSource(baseUrl: kApiBaseUrl);
    _loadFeedback();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  Future<void> _loadFeedback() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dataSource.fetchGroupFeedback(
        widget.session.accessToken,
        widget.groupId,
        page: _page,
        pageSize: _pageSize,
        status: _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _items = response.items;
        _total = response.total;
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

  List<GroupFeedbackModel> _filteredItems() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _items;
    }
    return _items.where((item) {
      return item.summary.toLowerCase().contains(query) ||
          item.details.toLowerCase().contains(query) ||
          item.mentorName.toLowerCase().contains(query);
    }).toList();
  }

  int get _totalPages {
    if (_total == 0) return 1;
    return (_total / _pageSize).ceil();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'follow_up_requested':
        return 'Follow Up Requested';
      case 'acknowledged':
        return 'Acknowledged';
      case 'resolved':
        return 'Resolved';
      case 'submitted':
        return 'Submitted';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'follow_up_requested':
        return const Color(0xFFF59E0B);
      case 'acknowledged':
        return const Color(0xFF10B981);
      case 'resolved':
        return const Color(0xFF2563EB);
      case 'submitted':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'codeQuality':
        return 'Code Quality';
      case 'progress':
        return 'Progress';
      case 'communication':
        return 'Communication';
      case 'collaboration':
        return 'Collaboration';
      default:
        return category;
    }
  }

  Future<void> _showUpdateStatusDialog(GroupFeedbackModel item) async {
    final noteController = TextEditingController();
    String selectedStatus = item.status;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Update Feedback Status',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: saving ? null : () => Navigator.pop(context),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'follow_up_requested',
                          child: Text('Follow Up Requested'),
                        ),
                        DropdownMenuItem(
                          value: 'acknowledged',
                          child: Text('Acknowledged'),
                        ),
                        DropdownMenuItem(
                          value: 'resolved',
                          child: Text('Resolved'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() {
                                selectedStatus = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter note (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              saving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  setDialogState(() {
                                    saving = true;
                                  });
                                  try {
                                    await _dataSource.updateGroupFeedbackStatus(
                                      widget.session.accessToken,
                                      widget.groupId,
                                      item.feedbackId,
                                      status: selectedStatus,
                                      note: noteController.text.trim(),
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    await _loadFeedback();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Status updated successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    setDialogState(() {
                                      saving = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Update'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems();
    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('Feedback', 'Feedback')),
        elevation: 0,
      ),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadFeedback,
                        child: Text(_translate('Retry', 'Retry')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText:
                                  _translate('Search feedback...', 'Search feedback...'),
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _statusFilter ?? '',
                                      items: const [
                                        DropdownMenuItem(
                                          value: '',
                                          child: Text('All statuses'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'follow_up_requested',
                                          child: Text('Follow Up Requested'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'acknowledged',
                                          child: Text('Acknowledged'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'resolved',
                                          child: Text('Resolved'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'submitted',
                                          child: Text('Submitted'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _statusFilter =
                                              value != null && value.isNotEmpty
                                                  ? value
                                                  : null;
                                          _page = 1;
                                        });
                                        _loadFeedback();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.filter_alt_outlined),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Text(
                                _translate(
                                  'No feedback available',
                                  'No feedback available',
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return _buildFeedbackCard(item);
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('page $_page / $_totalPages'),
                          Row(
                            children: [
                              TextButton(
                                onPressed: _page <= 1
                                    ? null
                                    : () {
                                        setState(() {
                                          _page -= 1;
                                        });
                                        _loadFeedback();
                                      },
                                child: const Text('Previous'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _page >= _totalPages
                                    ? null
                                    : () {
                                        setState(() {
                                          _page += 1;
                                        });
                                        _loadFeedback();
                                      },
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFeedbackCard(GroupFeedbackModel item) {
    final dateText = DateFormat('dd/MM/yyyy').format(item.createdAt.toLocal());
    final initials =
        item.mentorName.isNotEmpty ? item.mentorName[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF22C55E),
                backgroundImage:
                    item.mentorAvatar.isNotEmpty ? NetworkImage(item.mentorAvatar) : null,
                child: item.mentorAvatar.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.mentorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(item.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(item.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(item.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.summary,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _categoryLabel(item.category),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Color(0xFFFBBF24), size: 16),
              const SizedBox(width: 4),
              Text(
                '${item.rating}/5',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.details.isNotEmpty) ...[
            const Text(
              'Details',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              item.details,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 10),
          ],
          if (item.blockers != null && item.blockers!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.report_problem_outlined,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.blockers!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (item.nextSteps != null && item.nextSteps!.isNotEmpty) ...[
            const Text(
              'Next Steps',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              item.nextSteps!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 10),
          ],
          if (item.acknowledgedNote != null &&
              item.acknowledgedNote!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Team Response',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.acknowledgedNote!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _showUpdateStatusDialog(item),
              child: const Text('Update Status'),
            ),
          ),
        ],
      ),
    );
  }
}
