import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/tracking_scores.dart';
import '../../domain/repositories/group_repository.dart';
import '../../../timeline/presentation/widgets/navigation_drawer_widget.dart';
import 'group_detail_page.dart';

class ContributeScorePage extends StatefulWidget {
  final String groupId;
  final AuthSession session;
  final AppLanguage language;

  const ContributeScorePage({
    super.key,
    required this.groupId,
    required this.session,
    required this.language,
  });

  @override
  State<ContributeScorePage> createState() => _ContributeScorePageState();
}

class _ContributeScorePageState extends State<ContributeScorePage> {
  late final GroupRepository _repository;
  TrackingScores? _scores;
  bool _loading = false;
  String? _error;
  final Map<String, bool> _expandedMembers = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedDrawerIndex = 1;

  // Filter values
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _highController = TextEditingController(text: '5');
  final TextEditingController _mediumController = TextEditingController(text: '3');
  final TextEditingController _lowController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _repository = GroupRepositoryImpl(
      remoteDataSource: GroupRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    // Set default dates to today
    final now = DateTime.now();
    _fromDate = now;
    _toDate = now;
    _loadScores();
  }

  @override
  void dispose() {
    _highController.dispose();
    _mediumController.dispose();
    _lowController.dispose();
    super.dispose();
  }

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  void _handleDrawerNavigation(int index) {
    switch (index) {
      case 0: // Overview
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupDetailPage(
              groupId: widget.groupId,
              session: widget.session,
              language: widget.language,
            ),
          ),
        );
        break;
      case 1: // Contribute Score
        break;
      case 2: // Feedback
        // Navigate to feedback page
        break;
      case 3: // Posts
        // Navigate to posts/forum page
        break;
      case 4: // Files
        // Navigate to files page
        break;
    }
  }

  Future<void> _loadScores() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fromStr = _fromDate != null
          ? DateFormat('yyyy-MM-dd').format(_fromDate!)
          : null;
      final toStr =
          _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null;
      final high = int.tryParse(_highController.text);
      final medium = int.tryParse(_mediumController.text);
      final low = int.tryParse(_lowController.text);

      final scores = await _repository.fetchTrackingScores(
        widget.session.accessToken,
        widget.groupId,
        from: fromStr,
        to: toStr,
        high: high,
        medium: medium,
        low: low,
      );

      if (mounted) {
        setState(() {
          _scores = scores;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      final now = DateTime.now();
      _fromDate = now;
      _toDate = now;
      _highController.text = '5';
      _mediumController.text = '3';
      _lowController.text = '1';
    });
    _loadScores();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: NavigationDrawerWidget(
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
                Expanded(
                  child: Center(
                    child: Text(
                      _translate('Điểm đóng góp', 'Contribute Score'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B2B57),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
      body: _loading && _scores == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _scores == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadScores,
                        child: Text(_translate('Thử lại', 'Retry')),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFiltersSection(),
                      const SizedBox(height: 20),
                      if (_scores != null) ...[
                        _buildSummaryCards(),
                        const SizedBox(height: 20),
                        _buildContributionSection(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('Bộ lọc', 'Filters'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212631),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: _translate('Từ', 'FROM'),
                  date: _fromDate,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: _translate('Đến', 'TO'),
                  date: _toDate,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: _translate('CAO', 'HIGH'),
                  controller: _highController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  label: _translate('TRUNG BÌNH', 'MEDIUM'),
                  controller: _mediumController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  label: _translate('THẤP', 'LOW'),
                  controller: _lowController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _loadScores,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5FE5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_translate('Thực thi', 'Execute')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Color(0xFFE2E4E9)),
                  ),
                  child: Text(_translate('Xóa', 'Clear')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E4E9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF747A8A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd/MM/yyyy').format(date)
                    : _translate('Chọn ngày', 'Select date'),
                style: TextStyle(
                  fontSize: 14,
                  color: date != null
                      ? const Color(0xFF212631)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF747A8A),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E4E9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E4E9)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    if (_scores == null) return const SizedBox.shrink();

    final totalScore = _scores!.members.fold<int>(
      0,
      (sum, member) => sum + member.scoreTotal,
    );
    final totalMembers = _scores!.members.length;
    final totalTasksDone = _scores!.members.fold<int>(
      0,
      (sum, member) => sum + member.tasks.done,
    );
    final totalAssigned = _scores!.members.fold<int>(
      0,
      (sum, member) => sum + member.tasks.assigned,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _translate('Điểm đóng góp', 'Contribute Score'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212631),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.emoji_events,
                value: '$totalScore',
                label: _translate('Tổng điểm', 'Total Score'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.people,
                value: '$totalMembers',
                label: _translate('Thành viên', 'Team Members'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.check_circle,
                value: '$totalTasksDone',
                label: _translate('Nhiệm vụ hoàn thành', 'Tasks Done'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.list,
                value: '$totalAssigned',
                label: _translate('Tổng được giao', 'Total Assigned'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: const Color(0xFF3B5FE5)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212631),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF747A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionSection() {
    if (_scores == null || _scores!.members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _translate('Không có dữ liệu', 'No data available'),
            style: const TextStyle(color: Color(0xFF747A8A)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _translate('ĐÓNG GÓP', 'CONTRIBUTION'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212631),
          ),
        ),
        const SizedBox(height: 12),
        ..._scores!.members.map((member) => _buildMemberCard(member)),
      ],
    );
  }

  Widget _buildMemberCard(MemberScore member) {
    final isExpanded = _expandedMembers[member.memberId] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF3B5FE5),
                child: Text(
                  member.memberName.isNotEmpty
                      ? member.memberName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.memberName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212631),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _translate('Trưởng nhóm', 'Leader'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF747A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events,
                            size: 16, color: Color(0xFF3B5FE5)),
                        const SizedBox(width: 4),
                        Text(
                          '${member.scoreTotal}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212631),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.tasks.done}/${member.tasks.assigned} ${_translate('Nhiệm vụ', 'Tasks')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF747A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildScoreDot(
                color: Colors.blue,
                label: _translate('Điểm giao hàng', 'Delivery Score'),
                value: member.deliveryScore,
              ),
              const SizedBox(width: 12),
              _buildScoreDot(
                color: Colors.green,
                label: _translate('Điểm chất lượng', 'Quality Score'),
                value: member.qualityScore,
              ),
              const SizedBox(width: 12),
              _buildScoreDot(
                color: const Color(0xFF3B5FE5),
                label: _translate('Điểm hợp tác', 'Collab Score'),
                value: member.collabScore,
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() {
                _expandedMembers[member.memberId] = !isExpanded;
              });
            },
            child: Row(
              children: [
                Text(
                  isExpanded
                      ? _translate('Ẩn chi tiết', 'Hide details')
                      : _translate('Hiển thị chi tiết', 'Show details'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3B5FE5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: const Color(0xFF3B5FE5),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 16),
            _buildByPrioritySection(member),
            const SizedBox(height: 16),
            _buildTasksSection(member),
          ],
        ],
      ),
    );
  }

  Widget _buildByPrioritySection(MemberScore member) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _translate('THEO ĐỘ ƯU TIÊN', 'BY PRIORITY'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212631),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPriorityCard(
                _translate('Cao', 'High'),
                member.byPriority.high.done,
                member.byPriority.high.score,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPriorityCard(
                _translate('Trung bình', 'Medium'),
                member.byPriority.medium.done,
                member.byPriority.medium.score,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPriorityCard(
                _translate('Thấp', 'Low'),
                member.byPriority.low.done,
                member.byPriority.low.score,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityCard(String label, int done, int score, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$done ${_translate('Nhiệm vụ hoàn thành', 'Tasks Done')}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212631),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(MemberScore member) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _translate('NHIỆM VỤ', 'TASKS'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212631),
          ),
        ),
        const SizedBox(height: 12),
        ...member.taskDetails.map((task) => _buildTaskItem(task)),
      ],
    );
  }

  Widget _buildTaskItem(TaskDetail task) {
    final statusColor = task.status == 'DONE'
        ? Colors.green
        : task.status == 'IN_PROGRESS'
            ? Colors.blue
            : Colors.grey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E4E9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212631),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getPriorityColor(task.priority),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (task.scoreContributed > 0)
            Text(
              '+${task.scoreContributed}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B5FE5),
              ),
            ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildScoreDot({
    required Color color,
    required String label,
    required int value,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $value',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF747A8A),
          ),
        ),
      ],
    );
  }
}




