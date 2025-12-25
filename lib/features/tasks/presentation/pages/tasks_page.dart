import 'dart:io';

import 'package:feather_icons/feather_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../timeline/presentation/widgets/navigation_drawer_widget.dart';
import '../../domain/entities/backlog.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/entities/task_file.dart';
import '../../domain/requests/board_requests.dart';
import '../../domain/requests/project_tracking_requests.dart';
import '../controllers/tasks_controller.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.language, required this.session});

  final AppLanguage language;
  final AuthSession session;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage>
    with SingleTickerProviderStateMixin {
  static const List<String> _priorityOptions = [
    'Critical',
    'High',
    'Medium',
    'Low',
  ];
  static const List<String> _categoryOptions = [
    'Feature',
    'Bug',
    'Improvement',
    'Research',
  ];

  late final TasksController _controller;
  late final TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedDrawerIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _controller = TasksController(session: widget.session);
    _controller.initialize();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  void _handleDrawerNavigation(int index) {
    // Navigation handled by MainPage
    // This is just a placeholder to close drawer
  }

  Future<void> _showKanbanActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ActionSheet(
          title: _translate('Thao tác Kanban', 'Kanban actions'),
          actions: [
            _ActionSheetItem(
              icon: FeatherIcons.columns,
              label: _translate('Thêm cột mới', 'Add column'),
              onTap: () {
                Navigator.pop(context);
                _showColumnEditor();
              },
            ),
            _ActionSheetItem(
              icon: FeatherIcons.plusSquare,
              label: _translate('Thêm nhiệm vụ', 'Add task'),
              onTap: () {
                Navigator.pop(context);
                _showTaskEditor();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showColumnEditor({BoardColumn? column}) async {
    final nameController = TextEditingController(
      text: column?.columnName ?? '',
    );
    final positionController = TextEditingController(
      text: column?.position.toString() ?? '0',
    );
    bool isDone = column?.isDone ?? false;
    DateTime? dueDate = column?.dueDate;

    final result = await showDialog<Object?>(
      context: context,
      builder: (context) {
        return _FormDialog(
          title: column == null
              ? _translate('Thêm cột Kanban', 'Create Kanban column')
              : _translate('Cập nhật cột', 'Update column'),
          submitLabel: column == null
              ? _translate('Tạo cột', 'Create')
              : _translate('Lưu', 'Save'),
          cancelLabel: _translate('Huỷ', 'Cancel'),
          onSubmit: () {
            final name = nameController.text.trim();
            final pos = int.tryParse(positionController.text) ?? 0;
            if (name.isEmpty) return null;
            if (column == null) {
              return CreateColumnRequest(columnName: name, position: pos);
            }
            return UpdateColumnRequest(
              columnName: name,
              position: pos,
              isDone: isDone,
              dueDate: dueDate,
            );
          },
          contentBuilder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: _translate('Tên cột', 'Column name'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: positionController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _translate(
                      'Vị trí hiển thị',
                      'Display position',
                    ),
                  ),
                ),
                if (column != null) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isDone,
                    onChanged: (value) => setState(() => isDone = value),
                    title: Text(_translate('Cột hoàn thành', 'Done column')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      dueDate == null
                          ? _translate('Không giới hạn ngày', 'No due date')
                          : _formatDate(dueDate!),
                    ),
                    subtitle: Text(
                      _translate('Hạn hoàn thành cột', 'Column due date'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(FeatherIcons.calendar),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => dueDate = picked);
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    if (column == null && result is CreateColumnRequest) {
      await _controller.createColumn(result);
    } else if (column != null && result is UpdateColumnRequest) {
      await _controller.updateColumn(column.columnId, result);
    }
  }

  Future<void> _confirmDeleteColumn(BoardColumn column) async {
    final confirmed = await _showConfirmDialog(
      title: _translate('Xoá cột?', 'Delete column?'),
      message: _translate(
        'Cột ${column.columnName} và toàn bộ nhiệm vụ bên trong sẽ bị xoá.',
        'Column ${column.columnName} and its tasks will be permanently deleted.',
      ),
      confirmLabel: _translate('Xoá', 'Delete'),
    );
    if (confirmed == true) {
      await _controller.deleteColumn(column.columnId);
    }
  }

  Future<void> _showTaskEditor({
    BoardColumn? initialColumn,
    BoardTask? task,
  }) async {
    final board = _controller.board;
    if (board == null || board.columns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate(
              'Bạn cần ít nhất một cột Kanban để tạo nhiệm vụ.',
              'Add a Kanban column before creating tasks.',
            ),
          ),
        ),
      );
      return;
    }
    final columnId =
        task?.columnId ??
        initialColumn?.columnId ??
        board.columns.first.columnId;
    final column = board.columns.firstWhere((c) => c.columnId == columnId);
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    final dueDate = ValueNotifier<DateTime?>(task?.dueDate);
    final backlogItems = _controller.backlogItems;
    final statusOptions = board.columns
        .map((c) => c.columnName)
        .toSet()
        .toList();
    if (task?.status != null &&
        task!.status.isNotEmpty &&
        !statusOptions.contains(task.status)) {
      statusOptions.add(task.status);
    }
    BoardColumn selectedColumn = column;
    String selectedStatus =
        task?.status != null && statusOptions.contains(task!.status)
        ? task.status
        : selectedColumn.columnName;
    String? selectedPriority = task?.priority ?? 'Medium';
    final List<String> priorityOptions = [..._priorityOptions];
    if (!priorityOptions.contains(selectedPriority)) {
      priorityOptions.add(selectedPriority);
    }
    String? selectedBacklogId =
        task?.backlogItemId != null && task!.backlogItemId!.isNotEmpty
        ? task.backlogItemId
        : null;

    final result = await showDialog<Object?>(
      context: context,
      builder: (context) {
        return _FormDialog(
          title: task == null
              ? _translate('Tạo nhiệm vụ', 'Create task')
              : _translate('Cập nhật nhiệm vụ', 'Update task'),
          submitLabel: task == null
              ? _translate('Tạo', 'Create')
              : _translate('Lưu', 'Save'),
          cancelLabel: _translate('Huỷ', 'Cancel'),
          onSubmit: () {
            final title = titleController.text.trim();
            if (title.isEmpty) return null;
            final description = descriptionController.text.trim();
            final descriptionValue = description.isEmpty ? null : description;
            final priorityValue = selectedPriority;
            final backlogValue = selectedBacklogId;
            final statusValue = (selectedStatus.isEmpty
                ? selectedColumn.columnName
                : selectedStatus);
            if (task == null) {
              return CreateTaskRequest(
                columnId: selectedColumn.columnId,
                title: title,
                description: descriptionValue,
                priority: priorityValue,
                status: statusValue,
                dueDate: dueDate.value,
                backlogItemId: backlogValue,
              );
            }
            return UpdateTaskRequest(
              columnId: selectedColumn.columnId,
              title: title,
              description: descriptionValue,
              priority: priorityValue,
              status: statusValue,
              dueDate: dueDate.value,
              backlogItemId: backlogValue,
            );
          },
          contentBuilder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedColumn.columnId,
                  decoration: InputDecoration(
                    labelText: _translate('Cột', 'Column'),
                  ),
                  items: board.columns
                      .map(
                        (col) => DropdownMenuItem(
                          value: col.columnId,
                          child: Text(col.columnName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedColumn = board.columns.firstWhere(
                        (c) => c.columnId == value,
                      );
                      selectedStatus = selectedColumn.columnName;
                      if (!statusOptions.contains(selectedStatus)) {
                        statusOptions.add(selectedStatus);
                      }
                    });
                  },
                ),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: _translate('Tiêu đề', 'Title'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _translate('Mô tả', 'Description'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: selectedPriority,
                  decoration: InputDecoration(
                    labelText: _translate('Độ ưu tiên', 'Priority'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(_translate('Không thiết lập', 'No priority')),
                    ),
                    ...priorityOptions.map(
                      (option) =>
                          DropdownMenuItem(value: option, child: Text(option)),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedPriority = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    labelText: _translate('Trạng thái', 'Status'),
                  ),
                  items: statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedStatus = value);
                  },
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<DateTime?>(
                  valueListenable: dueDate,
                  builder: (context, value, _) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        value == null
                            ? _translate('Chưa đặt hạn', 'No due date')
                            : _formatDate(value),
                      ),
                      subtitle: Text(_translate('Hạn hoàn thành', 'Due date')),
                      trailing: IconButton(
                        icon: const Icon(FeatherIcons.calendar),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: value ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) dueDate.value = picked;
                        },
                      ),
                    );
                  },
                ),
                DropdownButtonFormField<String?>(
                  initialValue: selectedBacklogId,
                  decoration: InputDecoration(
                    labelText: _translate(
                      'Liên kết backlog',
                      'Linked backlog item',
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        _translate('Không liên kết', 'No backlog link'),
                      ),
                    ),
                    ...backlogItems.map(
                      (item) => DropdownMenuItem(
                        value: item.backlogItemId,
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: backlogItems.isEmpty
                      ? null
                      : (value) => setState(() => selectedBacklogId = value),
                ),
                if (backlogItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _translate(
                        'Backlog trống, hãy tạo hạng mục trước.',
                        'Backlog is empty, create items first.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    if (task == null && result is CreateTaskRequest) {
      await _controller.createTask(result);
    } else if (task != null && result is UpdateTaskRequest) {
      await _controller.updateTask(task.taskId, result);
    }
  }

  Future<void> _confirmDeleteTask(BoardTask task) async {
    final confirmed = await _showConfirmDialog(
      title: _translate('Xoá nhiệm vụ?', 'Delete task?'),
      message: _translate(
        'Bạn sẽ xoá vĩnh viễn nhiệm vụ ${task.title}.',
        'This will permanently delete ${task.title}.',
      ),
      confirmLabel: _translate('Xoá', 'Delete'),
    );
    if (confirmed == true) {
      await _controller.deleteTask(task.taskId);
    }
  }

  Future<void> _showAssigneeEditor(BoardTask task) async {
    final members = _controller.groupMembers;
    if (members.isEmpty) {
      final message = _controller.membersLoading
          ? _translate(
              'Đang tải danh sách thành viên, vui lòng thử lại.',
              'Members are still loading, try again in a moment.',
            )
          : _translate(
              'Nhóm này chưa có thành viên nào để gán.',
              'This group has no members to assign yet.',
            );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final initialSelection = task.assignees
        .map((assignee) => assignee.userId)
        .toSet();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        final selected = Set<String>.from(initialSelection);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                _translate('Gán người thực hiện', 'Manage assignees'),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 320,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isSelected = selected.contains(member.userId);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selected.add(member.userId);
                          } else {
                            selected.remove(member.userId);
                          }
                        });
                      },
                      title: Text(member.displayName),
                      subtitle: Text(member.email),
                      secondary: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFDFE7FF),
                        backgroundImage: member.avatarUrl != null
                            ? NetworkImage(member.avatarUrl!)
                            : null,
                        child: member.avatarUrl == null
                            ? Text(
                                member.displayName.isNotEmpty
                                    ? member.displayName
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_translate('Huỷ', 'Cancel')),
                ),
                TextButton(
                  onPressed: () => setState(selected.clear),
                  child: Text(_translate('Bỏ chọn', 'Clear all')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected.toList()),
                  child: Text(_translate('Lưu', 'Save')),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    await _controller.replaceTaskAssignees(
      task.taskId,
      ReplaceAssigneesRequest(userIds: result),
    );
  }

  Future<void> _showTaskActivitySheet(BoardTask task) async {
    _controller.loadTaskComments(task.taskId);
    _controller.loadTaskFiles(task.taskId);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _TaskActivitySheet(
        task: task,
        controller: _controller,
        translate: _translate,
        parentContext: context,
        resolveMemberName: _resolveMemberName,
        initialsForUser: _initialsForUser,
        formatTimestamp: _formatTimestamp,
        formatFileSize: _formatFileSize,
        fileBadgeLabel: _fileBadgeLabel,
        resolveFileBytes: _resolveFileBytes,
        mimeFromExtension: _mimeFromExtension,
      ),
    );
  }

  Future<void> _showMoveTaskSheet(BoardTask task) async {
    final board = _controller.board;
    if (board == null || board.columns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate(
              'Không có cột để chuyển nhiệm vụ.',
              'No columns available to move the task.',
            ),
          ),
        ),
      );
      return;
    }
    final columns = board.columns;
    BoardColumn selected = columns.firstWhere(
      (c) => c.columnId == task.columnId,
    );
    String? prevTaskId;
    String? nextTaskId;

    String selectionKey = 'top';
    prevTaskId = null;
    nextTaskId = selected.tasks.isEmpty ? null : selected.tasks.first.taskId;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _translate('Chuyển nhiệm vụ', 'Move task'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selected.columnId,
                    decoration: InputDecoration(
                      labelText: _translate('Cột mới', 'Target column'),
                    ),
                    items: columns
                        .map(
                          (col) => DropdownMenuItem(
                            value: col.columnId,
                            child: Text(
                              '${col.columnName} (${col.tasks.length})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() {
                        selected = columns.firstWhere(
                          (c) => c.columnId == value,
                        );
                        selectionKey = 'top';
                        prevTaskId = null;
                        nextTaskId = selected.tasks.isEmpty
                            ? null
                            : selected.tasks.first.taskId;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _translate('Vị trí mới', 'New position'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildPositionChips(
                      column: selected,
                      selectionKey: selectionKey,
                      onSelected: (key, prev, next) {
                        setSheetState(() {
                          selectionKey = key;
                          prevTaskId = prev;
                          nextTaskId = next;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _controller.moveTask(
                          task.taskId,
                          MoveTaskRequest(
                            columnId: selected.columnId,
                            prevTaskId: prevTaskId,
                            nextTaskId: nextTaskId,
                          ),
                        );
                      },
                      child: Text(_translate('Di chuyển', 'Move')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildPositionChips({
    required BoardColumn column,
    required String selectionKey,
    required void Function(String key, String? prev, String? next) onSelected,
  }) {
    final tasks = column.tasks;
    if (tasks.isEmpty) {
      return [
        ChoiceChip(
          label: Text(_translate('Đầu danh sách', 'First task')),
          selected: selectionKey == 'top',
          onSelected: (_) => onSelected('top', null, null),
        ),
      ];
    }

    final chips = <Widget>[
      ChoiceChip(
        label: Text(_translate('Đầu danh sách', 'Top of column')),
        selected: selectionKey == 'top',
        onSelected: (_) => onSelected('top', null, tasks.first.taskId),
      ),
    ];

    for (var i = 0; i < tasks.length; i++) {
      final before = tasks[i];
      final after = i + 1 < tasks.length ? tasks[i + 1] : null;
      final key = 'after-${before.taskId}';
      chips.add(
        ChoiceChip(
          label: Text(
            _translate('Sau ${before.title}', 'After ${before.title}'),
          ),
          selected: selectionKey == key,
          onSelected: (_) => onSelected(key, before.taskId, after?.taskId),
        ),
      );
    }
    return chips;
  }

  Future<void> _showBacklogEditor({BacklogItem? item}) async {
    final titleController = TextEditingController(text: item?.title ?? '');
    final descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    final storyPointsController = TextEditingController(
      text: item?.storyPoints?.toString() ?? '',
    );
    final statusController = TextEditingController(text: item?.status ?? 'NEW');
    final dueDate = ValueNotifier<DateTime?>(item?.dueDate);
    final members = _controller.groupMembers;
    final hasMembers = members.isNotEmpty;
    final ownerFallback = widget.session.userId;
    final List<String> priorityOptions = [..._priorityOptions];
    if (item?.priority != null &&
        item!.priority.isNotEmpty &&
        !priorityOptions.contains(item.priority)) {
      priorityOptions.add(item.priority);
    }
    final List<String> categoryOptions = [..._categoryOptions];
    if (item?.category != null &&
        item!.category.isNotEmpty &&
        !categoryOptions.contains(item.category)) {
      categoryOptions.add(item.category);
    }

    final defaultPriority = priorityOptions.contains('Medium')
        ? 'Medium'
        : priorityOptions.first;
    String selectedPriority =
        item?.priority != null && item!.priority.isNotEmpty
        ? item.priority
        : defaultPriority;
    String selectedCategory =
        item?.category != null && item!.category.isNotEmpty
        ? item.category
        : categoryOptions.first;
    String? selectedOwnerId =
        item?.ownerUserId ??
        (hasMembers ? members.first.userId : ownerFallback);
    String? storyPointsError;
    void Function(VoidCallback)? dialogSetState;

    final result = await showDialog<Object?>(
      context: context,
      builder: (context) {
        return _FormDialog(
          title: item == null
              ? _translate('Thêm hạng mục backlog', 'New backlog item')
              : _translate('Cập nhật backlog', 'Update backlog'),
          submitLabel: item == null
              ? _translate('Tạo', 'Create')
              : _translate('Lưu', 'Save'),
          cancelLabel: _translate('Huỷ', 'Cancel'),
          onSubmit: () {
            final title = titleController.text.trim();
            if (title.isEmpty) return null;
            final description = descriptionController.text.trim();
            final storyPointsRaw = storyPointsController.text.trim();
            int? parsedStoryPoints;
            if (storyPointsRaw.isNotEmpty) {
              final parsed = int.tryParse(storyPointsRaw);
              if (parsed == null || parsed < 0) {
                dialogSetState?.call(() {
                  storyPointsError = _translate(
                    'Story points phải là số không âm.',
                    'Story points must be a non-negative number.',
                  );
                });
                return null;
              }
              parsedStoryPoints = parsed;
              dialogSetState?.call(() => storyPointsError = null);
            } else {
              dialogSetState?.call(() => storyPointsError = null);
            }

            final ownerId = selectedOwnerId ?? ownerFallback;
            if (item == null) {
              return CreateBacklogRequest(
                title: title,
                description: description.isEmpty ? null : description,
                priority: selectedPriority,
                category: selectedCategory,
                storyPoints: parsedStoryPoints,
                dueDate: dueDate.value,
                ownerUserId: ownerId,
              );
            }
            return UpdateBacklogRequest(
              title: title,
              description: description.isEmpty ? null : description,
              priority: selectedPriority,
              category: selectedCategory,
              storyPoints: parsedStoryPoints,
              dueDate: dueDate.value,
              status: statusController.text.trim(),
              ownerUserId: ownerId,
            );
          },
          contentBuilder: (context, setState) {
            dialogSetState = setState;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: _translate('Tiêu đề', 'Title'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: _translate('Mô tả', 'Description'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    decoration: InputDecoration(
                      labelText: _translate('Độ ưu tiên', 'Priority'),
                    ),
                    items: priorityOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedPriority = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: _translate('Danh mục', 'Category'),
                    ),
                    items: categoryOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedCategory = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: storyPointsController,
                    decoration: InputDecoration(
                      labelText: _translate('Story points', 'Story points'),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (storyPointsError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          storyPointsError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedOwnerId,
                    decoration: InputDecoration(
                      labelText: _translate('Người phụ trách', 'Owner'),
                    ),
                    items: hasMembers
                        ? () {
                            final existsInList = members.any(
                              (member) => member.userId == selectedOwnerId,
                            );
                            final dropdownItems = members
                                .map(
                                  (member) => DropdownMenuItem(
                                    value: member.userId,
                                    child: Text(member.displayName),
                                  ),
                                )
                                .toList();
                            if (!existsInList && selectedOwnerId != null) {
                              dropdownItems.insert(
                                0,
                                DropdownMenuItem(
                                  value: selectedOwnerId,
                                  child: Text(
                                    _translate(
                                      'Chủ sở hữu hiện tại (không trong nhóm)',
                                      'Current owner (not in group)',
                                    ),
                                  ),
                                ),
                              );
                            }
                            return dropdownItems;
                          }()
                        : [
                            DropdownMenuItem(
                              value: selectedOwnerId,
                              child: Text(
                                _translate(
                                  'Chưa có thành viên khả dụng',
                                  'No members available',
                                ),
                              ),
                            ),
                          ],
                    onChanged: hasMembers
                        ? (value) => setState(() => selectedOwnerId = value)
                        : null,
                  ),
                  if (!hasMembers)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _translate(
                          'Không tìm thấy thành viên cho nhóm này.',
                          'No group members found to select.',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  if (item != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: statusController,
                      decoration: InputDecoration(
                        labelText: _translate('Trạng thái', 'Status'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ValueListenableBuilder<DateTime?>(
                    valueListenable: dueDate,
                    builder: (context, value, _) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          value == null
                              ? _translate('Chưa đặt hạn', 'No due date')
                              : _formatDate(value),
                        ),
                        subtitle: Text(
                          _translate('Hạn dự kiến', 'Expected deadline'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(FeatherIcons.calendar),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: value ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) dueDate.value = picked;
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    if (item == null && result is CreateBacklogRequest) {
      await _controller.createBacklog(result);
    } else if (item != null && result is UpdateBacklogRequest) {
      await _controller.updateBacklog(item.backlogItemId, result);
    }
  }

  Future<void> _confirmDeleteBacklog(BacklogItem item) async {
    final confirmed = await _showConfirmDialog(
      title: _translate('Xoá backlog?', 'Delete backlog item?'),
      message: _translate(
        'Bạn có chắc muốn xoá ${item.title}?',
        'Are you sure you want to delete ${item.title}?',
      ),
      confirmLabel: _translate('Xoá', 'Delete'),
    );
    if (confirmed == true) {
      await _controller.deleteBacklog(item.backlogItemId);
    }
  }

  Future<void> _showPromoteBacklog(BacklogItem item) async {
    final board = _controller.board;
    if (board == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate(
              'Chưa có bảng Kanban để đưa lên.',
              'No Kanban board available.',
            ),
          ),
        ),
      );
      return;
    }
    final columns = board.columns;
    String columnId = columns.first.columnId;
    final statusController = TextEditingController(text: 'TODO');
    DateTime? dueDate;

    final result = await showDialog<PromoteBacklogRequest>(
      context: context,
      builder: (context) {
        return _FormDialog(
          title: _translate('Đưa lên Kanban', 'Promote to Kanban'),
          submitLabel: _translate('Đưa lên', 'Promote'),
          cancelLabel: _translate('Huỷ', 'Cancel'),
          onSubmit: () {
            return PromoteBacklogRequest(
              columnId: columnId,
              taskStatus: statusController.text.trim().isEmpty
                  ? 'TODO'
                  : statusController.text.trim(),
              taskDueDate: dueDate,
            );
          },
          contentBuilder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: columnId,
                  decoration: InputDecoration(
                    labelText: _translate('Chọn cột', 'Select column'),
                  ),
                  items: columns
                      .map(
                        (col) => DropdownMenuItem(
                          value: col.columnId,
                          child: Text(col.columnName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => columnId = value ?? columnId),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: statusController,
                  decoration: InputDecoration(
                    labelText: _translate('Trạng thái nhiệm vụ', 'Task status'),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    dueDate == null
                        ? _translate('Không đặt hạn', 'No due date')
                        : _formatDate(dueDate!),
                  ),
                  subtitle: Text(
                    _translate(
                      'Hạn nhiệm vụ sau khi đưa lên',
                      'Task due date after promotion',
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(FeatherIcons.calendar),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => dueDate = picked);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    await _controller.promoteBacklog(item.backlogItemId, result);
  }

  Future<void> _showMilestoneEditor({Milestone? milestone}) async {
    final nameController = TextEditingController(text: milestone?.name ?? '');
    final descriptionController = TextEditingController(
      text: milestone?.description ?? '',
    );
    final statusController = TextEditingController(
      text: milestone?.status ?? 'PLANNED',
    );
    final targetDate = ValueNotifier<DateTime?>(milestone?.targetDate);
    final completedAt = ValueNotifier<DateTime?>(milestone?.completedAt);

    final result = await showDialog<Object?>(
      context: context,
      builder: (context) {
        return _FormDialog(
          title: milestone == null
              ? _translate('Thêm milestone', 'Create milestone')
              : _translate('Cập nhật milestone', 'Update milestone'),
          submitLabel: milestone == null
              ? _translate('Tạo', 'Create')
              : _translate('Lưu', 'Save'),
          cancelLabel: _translate('Huỷ', 'Cancel'),
          onSubmit: () {
            final name = nameController.text.trim();
            if (name.isEmpty) return null;
            if (milestone == null) {
              return CreateMilestoneRequest(
                name: name,
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                targetDate: targetDate.value,
              );
            }
            return UpdateMilestoneRequest(
              name: name,
              description: descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
              targetDate: targetDate.value,
              status: statusController.text.trim(),
              completedAt: completedAt.value,
            );
          },
          contentBuilder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: _translate('Tên milestone', 'Milestone name'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: _translate('Mô tả', 'Description'),
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<DateTime?>(
                  valueListenable: targetDate,
                  builder: (context, value, _) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        value == null
                            ? _translate('Không đặt lịch', 'No target date')
                            : _formatDate(value),
                      ),
                      subtitle: Text(
                        _translate('Ngày mục tiêu', 'Target date'),
                      ),
                      trailing: IconButton(
                        icon: const Icon(FeatherIcons.calendar),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: value ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) targetDate.value = picked;
                        },
                      ),
                    );
                  },
                ),
                if (milestone != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: statusController,
                    decoration: InputDecoration(
                      labelText: _translate('Trạng thái', 'Status'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<DateTime?>(
                    valueListenable: completedAt,
                    builder: (context, value, _) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          value == null
                              ? _translate('Chưa hoàn thành', 'Not completed')
                              : _formatDate(value),
                        ),
                        subtitle: Text(
                          _translate('Hoàn thành vào', 'Completed at'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(FeatherIcons.calendar),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: value ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) completedAt.value = picked;
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    if (milestone == null && result is CreateMilestoneRequest) {
      await _controller.createMilestone(result);
    } else if (milestone != null && result is UpdateMilestoneRequest) {
      await _controller.updateMilestone(milestone.milestoneId, result);
    }
  }

  Future<void> _confirmDeleteMilestone(Milestone milestone) async {
    final confirmed = await _showConfirmDialog(
      title: _translate('Xoá milestone?', 'Delete milestone?'),
      message: _translate(
        'Bạn sẽ xoá cột mốc ${milestone.name} và các liên kết của nó.',
        'This will remove milestone ${milestone.name} and its links.',
      ),
      confirmLabel: _translate('Xoá', 'Delete'),
    );
    if (confirmed == true) {
      await _controller.deleteMilestone(milestone.milestoneId);
    }
  }

  Future<void> _showAssignMilestoneItems(Milestone milestone) async {
    final backlog = _controller.backlogItems;
    final selected = <String>{...milestone.items.map((e) => e.backlogItemId)};

    final result = await showDialog<AssignMilestoneItemsRequest>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                _translate('Gán backlog cho milestone', 'Assign backlog items'),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: backlog.isEmpty
                    ? Text(
                        _translate(
                          'Backlog đang trống.',
                          'No backlog items available.',
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: backlog
                            .map(
                              (item) => CheckboxListTile(
                                value: selected.contains(item.backlogItemId),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selected.add(item.backlogItemId);
                                    } else {
                                      selected.remove(item.backlogItemId);
                                    }
                                  });
                                },
                                title: Text(item.title),
                                subtitle: Text(item.priority),
                              ),
                            )
                            .toList(),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_translate('Huỷ', 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      AssignMilestoneItemsRequest(
                        backlogItemIds: selected.toList(),
                      ),
                    );
                  },
                  child: Text(_translate('Lưu', 'Save')),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    await _controller.assignMilestoneItems(milestone.milestoneId, result);
  }

  Future<void> _confirmRemoveMilestoneItem(
    Milestone milestone,
    String backlogItemId,
  ) async {
    final confirmed = await _showConfirmDialog(
      title: _translate('Bỏ liên kết?', 'Remove link?'),
      message: _translate(
        'Backlog sẽ không còn thuộc milestone này.',
        'The backlog item will be detached from this milestone.',
      ),
      confirmLabel: _translate('Bỏ liên kết', 'Detach'),
    );
    if (confirmed == true) {
      await _controller.removeMilestoneItem(
        milestone.milestoneId,
        backlogItemId,
      );
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_translate('Huỷ', 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final showFab =
            !_controller.isBootstrapping &&
            _controller.groups.isNotEmpty &&
            _controller.selectedGroupId != null;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF7F7F7),
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
          floatingActionButton: showFab ? _buildFloatingActionButton() : null,
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.isBootstrapping) {
      return const Center(
        child: SizedBox(
          height: 48,
          width: 48,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_controller.error != null && _controller.board == null) {
      return _wrapSafe(_buildErrorState());
    }

    if (_controller.groups.isEmpty) {
      return _wrapSafe(_buildEmptyState());
    }

    return SafeArea(
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _controller.isMutating
                ? _buildMutationBanner()
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: NestedScrollView(
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(child: _buildHeroSection()),
                SliverToBoxAdapter(child: _buildGroupSelector()),
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  snap: false,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  backgroundColor: const Color(0xFFF7F7F7),
                  toolbarHeight: 0,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: _buildTabBar(),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildKanbanTab(),
                  _buildBacklogTab(),
                  _buildMilestoneTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF0E7C7B),
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorColor: const Color(0xFF0E7C7B),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: _translate('Kanban', 'Kanban')),
          Tab(text: _translate('Backlog', 'Backlog')),
          Tab(text: _translate('Cột mốc', 'Milestones')),
        ],
      ),
    );
  }

  Widget _buildKanbanTab() {
    final board = _controller.board;
    final boardLoading = _controller.boardLoading;
    final widgets = <Widget>[];
    if (boardLoading && board == null) {
      widgets.add(_buildBoardSkeleton());
    } else if (board != null) {
      widgets.addAll([_buildOverviewMetrics(), _buildKanbanSection()]);
    } else {
      widgets.add(
        _EmptyCard(
          message: _translate(
            'Chưa có bảng Kanban nào cho nhóm này.',
            'No Kanban board has been configured for this group.',
          ),
        ),
      );
    }
    widgets.add(const SizedBox(height: 16));
    widgets.add(_buildBacklogSection(compact: true));
    widgets.add(const SizedBox(height: 16));
    widgets.add(_buildMilestonesAndReports(compact: true));

    return RefreshIndicator(
      onRefresh: _controller.refreshBoard,
      color: const Color(0xFF0E7C7B),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: widgets,
      ),
    );
  }

  Widget _buildBacklogTab() {
    final items = _controller.backlogItems;
    final isLoading = _controller.backlogLoading;
    final error = _controller.backlogError;

    Widget content;
    if (isLoading) {
      content = const _SectionLoading();
    } else if (error != null) {
      content = _EmptyCard(
        message: _translate(
          'Không tải được backlog: $error',
          'Unable to load backlog: $error',
        ),
      );
    } else if (items.isEmpty) {
      content = _EmptyCard(
        message: _translate(
          'Chưa có backlog nào. Hãy tạo mới để bắt đầu ưu tiên hạng mục.',
          'Your backlog is empty. Create items to start planning.',
        ),
      );
    } else {
      content = Column(
        children: items
            .map(
              (item) => _BacklogCard(
                item: item,
                translate: _translate,
                onEdit: () => _showBacklogEditor(item: item),
                onDelete: () => _confirmDeleteBacklog(item),
                onPromote: () => _showPromoteBacklog(item),
              ),
            )
            .toList(),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refreshBoard,
      color: const Color(0xFF0E7C7B),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _SectionHeader(
            title: 'Backlog',
            subtitle: _translate(
              'Quản lý ý tưởng và yêu cầu',
              'Manage product ideas',
            ),
            icon: FeatherIcons.layers,
            trailing: IconButton(
              icon: const Icon(FeatherIcons.plus, size: 18),
              onPressed: () => _showBacklogEditor(),
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildMilestoneTab() {
    final milestones = _controller.milestones;
    final isLoading = _controller.milestoneLoading;
    final error = _controller.milestoneError;

    Widget content;
    if (isLoading) {
      content = const _SectionLoading();
    } else if (error != null) {
      content = _EmptyCard(
        message: _translate(
          'Không tải được dữ liệu milestone: $error',
          'Unable to load milestones: $error',
        ),
      );
    } else if (milestones.isEmpty) {
      content = _EmptyCard(
        message: _translate(
          'Chưa có milestone nào. Hãy tạo để neo các hạng mục quan trọng.',
          'No milestones yet. Create one to anchor important backlog items.',
        ),
      );
    } else {
      content = Column(
        children: milestones
            .map(
              (milestone) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MilestoneCard(
                  milestone: milestone,
                  translate: _translate,
                  onEdit: () => _showMilestoneEditor(milestone: milestone),
                  onDelete: () => _confirmDeleteMilestone(milestone),
                  onAssignItems: () => _showAssignMilestoneItems(milestone),
                  onRemoveItem: (backlogId) =>
                      _confirmRemoveMilestoneItem(milestone, backlogId),
                ),
              ),
            )
            .toList(),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refreshBoard,
      color: const Color(0xFF0E7C7B),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _SectionHeader(
            title: _translate('Cột mốc dự án', 'Project milestones'),
            subtitle: _translate(
              'Theo dõi tiến độ mục tiêu',
              'Track commitments',
            ),
            icon: FeatherIcons.flag,
            trailing: IconButton(
              icon: const Icon(FeatherIcons.plus, size: 18),
              onPressed: () => _showMilestoneEditor(),
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildMutationBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _controller.mutationLabel ??
                  _translate('Đang đồng bộ thay đổi...', 'Applying changes...'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapSafe(Widget child) => SafeArea(child: child);

  Widget _buildFloatingActionButton() {
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      return FloatingActionButton.extended(
        onPressed: _showKanbanActions,
        heroTag: 'kanban-fab',
        backgroundColor: const Color(0xFF0E7C7B),
        icon: const Icon(FeatherIcons.plus, color: Colors.white),
        label: Text(_translate('Thao tác bảng', 'Board actions')),
      );
    }
    if (tabIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () => _showBacklogEditor(),
        heroTag: 'backlog-fab',
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(FeatherIcons.filePlus, color: Colors.white),
        label: Text(_translate('Thêm backlog', 'New backlog item')),
      );
    }
    return FloatingActionButton.extended(
      onPressed: () => _showMilestoneEditor(),
      heroTag: 'milestone-fab',
      backgroundColor: const Color(0xFF10B981),
      icon: const Icon(FeatherIcons.flag, color: Colors.white),
      label: Text(_translate('Thêm milestone', 'New milestone')),
    );
  }

  Widget _buildHeroSection() {
    final selected = _controller.selectedGroup;
    final subtitle = selected != null
        ? _translate(
            'Theo dõi sprint hiện tại của ${selected.name}',
            'Tracking ${selected.name} sprint',
          )
        : _translate(
            'Chọn một nhóm để xem bảng Kanban',
            'Select a group to view the Kanban board',
          );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E7C7B), Color(0xFF24A19C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330E7C7B),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translate('Bảng Công Việc', 'Project Command Center'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, height: 1.3),
                ),
                if (_controller.lastUpdated != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _translate('Đồng bộ gần nhất:', 'Last synced:'),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    _formatTimestamp(_controller.lastUpdated!),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FeatherIcons.layout,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector() {
    final items = _controller.groups
        .map(
          (group) => DropdownMenuItem<String>(
            value: group.id,
            child: Text(group.name, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('Nhóm đang theo dõi', 'Active group'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _controller.selectedGroupId,
              items: items,
              borderRadius: BorderRadius.circular(16),
              onChanged: (value) {
                if (value != null) {
                  _controller.selectGroup(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetrics() {
    final board = _controller.board!;
    final total = board.totalTasks;
    final completed = board.completedTasks;
    final progress = total == 0 ? 0.0 : completed / total;
    final overdue = board.allTasks.where((task) => task.isOverdue).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              title: _translate('Tiến độ sprint', 'Sprint progress'),
              highlight: '${(progress * 100).round()}%',
              subtitle:
                  '$completed/${total == 0 ? '-' : total} ${_translate('nhiệm vụ', 'tasks')}',
              accentColor: const Color(0xFF0E7C7B),
              progress: progress,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              title: _translate('Nhiệm vụ trễ', 'Overdue'),
              highlight: overdue.toString(),
              subtitle: _translate('Cần ưu tiên xử lý', 'Require attention'),
              accentColor: const Color(0xFFE8615A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanSection() {
    final columns = [..._controller.board!.columns]
      ..sort((a, b) => a.position.compareTo(b.position));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _translate('Bảng Kanban', 'Kanban board'),
            subtitle: _translate(
              'To Do • In Progress • Done',
              'To Do • In Progress • Done',
            ),
            icon: FeatherIcons.columns,
            trailing: _controller.boardLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(FeatherIcons.refreshCw, size: 18),
                    onPressed: () {
                      _controller.refreshBoard();
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: columns.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final column = columns[index];
                return _KanbanColumn(
                  column: column,
                  translate: _translate,
                  onAddTask: () => _showTaskEditor(initialColumn: column),
                  onEditColumn: () => _showColumnEditor(column: column),
                  onDeleteColumn: () => _confirmDeleteColumn(column),
                  onEditTask: (task) =>
                      _showTaskEditor(initialColumn: column, task: task),
                  onDeleteTask: _confirmDeleteTask,
                  onMoveTask: _showMoveTaskSheet,
                  onManageAssignees: _showAssigneeEditor,
                  onOpenActivity: _showTaskActivitySheet,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBacklogSection({bool compact = false}) {
    final source = _controller.backlogItems;
    final items = compact ? source.take(4).toList() : source;
    final isLoading = _controller.backlogLoading;
    final error = _controller.backlogError;
    final trailing = compact
        ? TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: Text(_translate('Xem tất cả', 'View backlog')),
          )
        : IconButton(
            onPressed: () => _showBacklogEditor(),
            icon: const Icon(FeatherIcons.plus, size: 18),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Backlog',
            subtitle: _translate(
              'Ý tưởng và hạng mục chuẩn bị',
              'Ideas waiting in queue',
            ),
            icon: FeatherIcons.layers,
            trailing: trailing,
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const _SectionLoading()
          else if (error != null)
            _EmptyCard(
              message: _translate(
                'Không tải được backlog: $error',
                'Unable to load backlog: $error',
              ),
            )
          else if (items.isEmpty)
            _EmptyCard(
              message: _translate(
                'Chưa có backlog nào.',
                'Your backlog is empty.',
              ),
            )
          else
            ...items.map(
              (item) => _BacklogCard(
                item: item,
                translate: _translate,
                onEdit: compact ? null : () => _showBacklogEditor(item: item),
                onDelete: compact ? null : () => _confirmDeleteBacklog(item),
                onPromote: compact ? null : () => _showPromoteBacklog(item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMilestonesAndReports({bool compact = false}) {
    final milestones = _controller.milestones;
    final backlogItems = _controller.backlogItems;
    final nextMilestone = _pickNextMilestone(milestones);
    final overdueBacklog = backlogItems.where((item) => item.isOverdue).length;
    final isLoading = _controller.milestoneLoading;
    final error = _controller.milestoneError;
    final Iterable<Milestone> displayed = compact
        ? milestones.take(2)
        : milestones;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          if (compact)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: Text(_translate('Quản lý cột mốc', 'Manage milestones')),
              ),
            ),
          if (isLoading)
            const _SectionLoading()
          else if (error != null)
            _EmptyCard(
              message: _translate(
                'Không tải được dữ liệu milestone: $error',
                'Unable to load milestone insights: $error',
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'Milestones',
                    description: nextMilestone != null
                        ? _translate(
                            'Tiếp theo: ${nextMilestone.name} (${_formatOptionalDate(nextMilestone.targetDate)})',
                            'Next: ${nextMilestone.name} (${_formatOptionalDate(nextMilestone.targetDate)})',
                          )
                        : _translate(
                            'Chưa có cột mốc nào',
                            'No milestone scheduled',
                          ),
                    icon: FeatherIcons.flag,
                    accent: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    title: 'Reports',
                    description: overdueBacklog > 0
                        ? _translate(
                            '$overdueBacklog hạng mục trễ cần xử lý',
                            '$overdueBacklog backlog items overdue',
                          )
                        : _translate(
                            'Tất cả đang đúng tiến độ',
                            'Everything on track',
                          ),
                    icon: FeatherIcons.barChart2,
                    accent: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (displayed.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: displayed
                    .map(
                      (milestone) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MilestoneCard(
                          milestone: milestone,
                          translate: _translate,
                          onEdit: () =>
                              _showMilestoneEditor(milestone: milestone),
                          onDelete: () => _confirmDeleteMilestone(milestone),
                          onAssignItems: () =>
                              _showAssignMilestoneItems(milestone),
                          onRemoveItem: (backlogId) =>
                              _confirmRemoveMilestoneItem(milestone, backlogId),
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              _EmptyCard(
                message: _translate(
                  'Hãy tạo milestone để gom các hạng mục quan trọng.',
                  'Create milestones to group important backlog items.',
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoardSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _translate('Bảng Kanban', 'Kanban board'),
            subtitle: _translate(
              'Đang tải dữ liệu...',
              'Loading board data...',
            ),
            icon: FeatherIcons.columns,
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    String message = _controller.error ?? 'Unknown error';
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
          const SizedBox(height: 12),
          SizedBox(
            width: 260,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              _controller.initialize();
            },
            child: Text(_translate('Thử lại', 'Retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              FeatherIcons.clipboard,
              size: 48,
              color: Color(0xFFCBD5F0),
            ),
            const SizedBox(height: 12),
            Text(
              _translate('Bạn chưa tham gia nhóm nào', 'No projects found'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2A37),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _translate(
                'Tạo hoặc tham gia một nhóm để mở bảng quản lý dự án.',
                'Create or join a group to unlock the project board.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Milestone? _pickNextMilestone(List<Milestone> milestones) {
    if (milestones.isEmpty) return null;
    final upcoming =
        milestones
            .where(
              (milestone) =>
                  milestone.targetDate != null && !milestone.isCompleted,
            )
            .toList()
          ..sort((a, b) => a.targetDate!.compareTo(b.targetDate!));
    if (upcoming.isNotEmpty) {
      return upcoming.first;
    }
    return milestones.first;
  }

  String _formatOptionalDate(DateTime? date) {
    if (date == null) {
      return _translate('Chưa đặt', 'TBD');
    }
    return _formatDate(date);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatTimestamp(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} • $hour:$minute';
  }

  String _resolveMemberName(String userId) {
    for (final member in _controller.groupMembers) {
      if (member.userId == userId) {
        return member.displayName;
      }
    }
    return userId;
  }

  String _initialsForUser(String userId) {
    final displayName = _resolveMemberName(userId).trim();
    if (displayName.isEmpty) {
      return userId.isNotEmpty ? userId.substring(0, 1).toUpperCase() : '?';
    }
    final segments = displayName
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.length == 1) {
      return segments.first.substring(0, 1).toUpperCase();
    }
    final first = segments.first.substring(0, 1);
    final last = segments.last.substring(0, 1);
    return (first + last).toUpperCase();
  }

  Future<List<int>> _resolveFileBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }
    if (!kIsWeb && file.path != null) {
      final ioFile = File(file.path!);
      return ioFile.readAsBytes();
    }
    throw StateError('Selected file data is not available.');
  }

  String _mimeFromExtension(String? extension) {
    if (extension == null || extension.isEmpty) {
      return 'application/octet-stream';
    }
    final ext = extension.toLowerCase();
    const mapping = {
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'heic': 'image/heic',
      'heif': 'image/heif',
      'svg': 'image/svg+xml',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'json': 'application/json',
      'csv': 'text/csv',
      'zip': 'application/zip',
      'rar': 'application/vnd.rar',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    };
    return mapping[ext] ?? 'application/octet-stream';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final precision = unitIndex == 0 ? 0 : 1;
    return '${size.toStringAsFixed(precision)} ${units[unitIndex]}';
  }

  String _fileBadgeLabel(TaskFile file) {
    final name = file.fileName;
    if (name.contains('.')) {
      final ext = name.split('.').last;
      if (ext.isNotEmpty && ext.length <= 4) {
        return ext.toUpperCase();
      }
      if (ext.isNotEmpty) {
        return ext.substring(0, 4).toUpperCase();
      }
    }
    final type = file.fileType.split('/').last;
    if (type.isEmpty) return 'FILE';
    if (type.length <= 4) return type.toUpperCase();
    return type.substring(0, 4).toUpperCase();
  }
}

class _ActivityError extends StatelessWidget {
  const _ActivityError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message!,
        style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
      ),
    );
  }
}

class _TaskActivitySheet extends StatefulWidget {
  const _TaskActivitySheet({
    required this.task,
    required this.controller,
    required this.translate,
    required this.parentContext,
    required this.resolveMemberName,
    required this.initialsForUser,
    required this.formatTimestamp,
    required this.formatFileSize,
    required this.fileBadgeLabel,
    required this.resolveFileBytes,
    required this.mimeFromExtension,
  });

  final BoardTask task;
  final TasksController controller;
  final String Function(String, String) translate;
  final BuildContext parentContext;
  final String Function(String) resolveMemberName;
  final String Function(String) initialsForUser;
  final String Function(DateTime) formatTimestamp;
  final String Function(int) formatFileSize;
  final String Function(TaskFile) fileBadgeLabel;
  final Future<List<int>> Function(PlatformFile) resolveFileBytes;
  final String Function(String?) mimeFromExtension;

  @override
  State<_TaskActivitySheet> createState() => _TaskActivitySheetState();
}

class _TaskActivitySheetState extends State<_TaskActivitySheet> {
  late final TextEditingController _commentController;
  late final TextEditingController _fileDescriptionController;
  bool _submittingComment = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _fileDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _fileDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _submittingComment) return;
    FocusScope.of(context).unfocus();
    setState(() => _submittingComment = true);
    try {
      await widget.controller.addTaskComment(widget.task.taskId, content);
      _commentController.clear();
    } catch (e) {
      _showSnackBar(
        widget.translate(
          'Không gửi được bình luận: $e',
          'Failed to post comment: $e',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submittingComment = false);
      }
    }
  }

  Future<void> _handleFileUpload() async {
    if (widget.controller.isUploadingFile(widget.task.taskId)) return;
    try {
      final result = await FilePicker.platform.pickFiles(withData: kIsWeb);
      if (result == null || result.files.isEmpty) return;
      final selected = result.files.first;
      final bytes = await widget.resolveFileBytes(selected);
      final description = _fileDescriptionController.text.trim();
      await widget.controller.uploadTaskFile(
        widget.task.taskId,
        UploadTaskFileRequest(
          taskId: widget.task.taskId,
          description: description.isEmpty ? null : description,
          fileName: selected.name,
          mimeType: widget.mimeFromExtension(selected.extension),
          bytes: bytes,
        ),
      );
      _fileDescriptionController.clear();
      _showSnackBar(
        widget.translate(
          'Đã tải lên tệp ${selected.name}',
          'Uploaded file ${selected.name}',
        ),
      );
    } catch (e) {
      _showSnackBar(
        widget.translate(
          'Không tải lên được tệp: $e',
          'Unable to upload file: $e',
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      widget.parentContext,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final comments = widget.controller.commentsForTask(widget.task.taskId);
        final files = widget.controller.filesForTask(widget.task.taskId);
        final commentsLoading = widget.controller.commentsLoading(
          widget.task.taskId,
        );
        final filesLoading = widget.controller.filesLoading(widget.task.taskId);
        final commentsError = widget.controller.commentsError(
          widget.task.taskId,
        );
        final filesError = widget.controller.filesError(widget.task.taskId);
        final isUploadingFile = widget.controller.isUploadingFile(
          widget.task.taskId,
        );

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + viewInsets),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.translate(
                              'Bình luận & tệp đính kèm',
                              'Comments & attachments',
                            ),
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.translate('Bình luận', 'Comments'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (commentsLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (commentsError != null)
                          _ActivityError(message: commentsError)
                        else
                          Column(
                            children: comments.isEmpty
                                ? [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        widget.translate(
                                          'Chưa có bình luận nào.',
                                          'No comments yet.',
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ),
                                  ]
                                : comments
                                      .map(
                                        (comment) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            radius: 20,
                                            backgroundColor: const Color(
                                              0xFFEFF4FF,
                                            ),
                                            child: Text(
                                              widget.initialsForUser(
                                                comment.userId,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E3A8A),
                                              ),
                                            ),
                                          ),
                                          title: Text(comment.content),
                                          subtitle: Text(
                                            '${widget.resolveMemberName(comment.userId)} • ${widget.formatTimestamp(comment.createdAt)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed: () async {
                                              await widget.controller
                                                  .deleteTaskComment(
                                                    widget.task.taskId,
                                                    comment.commentId,
                                                  );
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _commentController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: widget.translate(
                              'Thêm bình luận mới',
                              'Add a comment',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: _submittingComment
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(FeatherIcons.send),
                                    onPressed: _submitComment,
                                  ),
                          ),
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          widget.translate('Tệp đính kèm', 'Attachments'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (filesLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (filesError != null)
                          _ActivityError(message: filesError)
                        else
                          Column(
                            children: files.isEmpty
                                ? [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        widget.translate(
                                          'Chưa có tệp nào được tải lên.',
                                          'No files uploaded yet.',
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ),
                                  ]
                                : files
                                      .map(
                                        (file) => Card(
                                          elevation: 0,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFE5E7EB),
                                            ),
                                          ),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: const Color(
                                                0xFFEEF2FF,
                                              ),
                                              child: Text(
                                                widget.fileBadgeLabel(file),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF3730A3),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              file.fileName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${file.uploadedByName} • ${widget.formatTimestamp(file.createdAt)} • ${widget.formatFileSize(file.fileSize)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if (file.description != null &&
                                                    file
                                                        .description!
                                                        .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Text(
                                                      file.description!,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Color(
                                                          0xFF4B5563,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            onTap: () async {
                                              await Clipboard.setData(
                                                ClipboardData(
                                                  text: file.fileUrl,
                                                ),
                                              );
                                              _showSnackBar(
                                                widget.translate(
                                                  'Đã sao chép liên kết tải tệp.',
                                                  'File link copied to clipboard.',
                                                ),
                                              );
                                            },
                                            trailing: IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              onPressed: () async {
                                                await widget.controller
                                                    .deleteTaskFile(
                                                      widget.task.taskId,
                                                      file.fileId,
                                                    );
                                              },
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _fileDescriptionController,
                          decoration: InputDecoration(
                            labelText: widget.translate(
                              'Mô tả tệp (tuỳ chọn)',
                              'File description (optional)',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isUploadingFile
                                ? null
                                : _handleFileUpload,
                            icon: isUploadingFile
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(FeatherIcons.paperclip),
                            label: Text(
                              isUploadingFile
                                  ? widget.translate(
                                      'Đang tải lên...',
                                      'Uploading...',
                                    )
                                  : widget.translate(
                                      'Chọn và tải lên tệp',
                                      'Choose & upload file',
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.accentColor,
    this.progress,
  });

  final String title;
  final String highlight;
  final String subtitle;
  final Color accentColor;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          Text(
            highlight,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 6,
                backgroundColor: accentColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1D4ED8), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.column,
    required this.translate,
    required this.onAddTask,
    required this.onEditColumn,
    required this.onDeleteColumn,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onMoveTask,
    required this.onManageAssignees,
    required this.onOpenActivity,
  });

  final BoardColumn column;
  final String Function(String, String) translate;
  final VoidCallback onAddTask;
  final VoidCallback onEditColumn;
  final VoidCallback onDeleteColumn;
  final ValueChanged<BoardTask> onEditTask;
  final ValueChanged<BoardTask> onDeleteTask;
  final ValueChanged<BoardTask> onMoveTask;
  final ValueChanged<BoardTask> onManageAssignees;
  final ValueChanged<BoardTask> onOpenActivity;

  @override
  Widget build(BuildContext context) {
    final color = _columnAccent(column);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  column.columnName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${column.tasks.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(FeatherIcons.moreVertical, size: 16),
                onSelected: (value) {
                  switch (value) {
                    case 'add':
                      onAddTask();
                      break;
                    case 'edit':
                      onEditColumn();
                      break;
                    case 'delete':
                      onDeleteColumn();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'add',
                    child: Text(translate('Thêm nhiệm vụ', 'Add task')),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(translate('Sửa cột', 'Edit column')),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      translate('Xoá cột', 'Delete column'),
                      style: const TextStyle(color: Color(0xFFE11D48)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: column.tasks.isEmpty
                ? Center(
                    child: Text(
                      translate('Chưa có nhiệm vụ', 'No tasks yet'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemBuilder: (context, index) {
                      final task = column.tasks[index];
                      return _TaskCard(
                        task: task,
                        onEdit: () => onEditTask(task),
                        onDelete: () => onDeleteTask(task),
                        onMove: () => onMoveTask(task),
                        onManageAssignees: () => onManageAssignees(task),
                        onOpenActivity: () => onOpenActivity(task),
                        translate: translate,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: column.tasks.length,
                  ),
          ),
        ],
      ),
    );
  }

  Color _columnAccent(BoardColumn column) {
    if (column.isDone) return const Color(0xFF10B981);
    if (column.columnName.toLowerCase().contains('progress')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF3B82F6);
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
    required this.onManageAssignees,
    required this.onOpenActivity,
    required this.translate,
  });

  final BoardTask task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onManageAssignees;
  final VoidCallback onOpenActivity;
  final String Function(String, String) translate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              if (task.priority != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority!).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.priority!,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w600,
                      color: _priorityColor(task.priority!),
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(
                  FeatherIcons.moreHorizontal,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'move':
                      onMove();
                      break;
                    case 'assignees':
                      onManageAssignees();
                      break;
                    case 'activity':
                      onOpenActivity();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(translate('Chỉnh sửa nhiệm vụ', 'Edit task')),
                  ),
                  PopupMenuItem(
                    value: 'move',
                    child: Text(translate('Chuyển cột', 'Move to column')),
                  ),
                  PopupMenuItem(
                    value: 'assignees',
                    child: Text(
                      translate('Gán người thực hiện', 'Manage assignees'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'activity',
                    child: Text(
                      translate('Hoạt động & tệp', 'Comments & files'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      translate('Xoá nhiệm vụ', 'Delete task'),
                      style: const TextStyle(color: Color(0xFFE11D48)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (task.description != null &&
              task.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
          if (task.dueDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  FeatherIcons.calendar,
                  size: 14,
                  color: task.isOverdue
                      ? const Color(0xFFE8615A)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(task.dueDate!),
                  style: TextStyle(
                    fontSize: 12,
                    color: task.isOverdue
                        ? const Color(0xFFE8615A)
                        : const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ],
          if (task.assignees.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 30,
              child: Stack(
                children: List.generate(task.assignees.length, (index) {
                  final assignee = task.assignees[index];
                  return Positioned(
                    left: index * 22,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: const Color(0xFFE0E7FF),
                      backgroundImage: assignee.avatarUrl != null
                          ? NetworkImage(assignee.avatarUrl!)
                          : null,
                      child: assignee.avatarUrl == null
                          ? Text(
                              assignee.displayName.isNotEmpty
                                  ? assignee.displayName
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF312E81),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  FeatherIcons.users,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
                tooltip: translate(
                  'Quản lý người thực hiện',
                  'Manage assignees',
                ),
                onPressed: onManageAssignees,
              ),
              IconButton(
                icon: const Icon(
                  FeatherIcons.messageCircle,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
                tooltip: translate('Nhật ký hoạt động', 'View activity log'),
                onPressed: onOpenActivity,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('high')) return const Color(0xFFDC2626);
    if (value.contains('low')) return const Color(0xFF10B981);
    return const Color(0xFFF59E0B);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _BacklogCard extends StatelessWidget {
  const _BacklogCard({
    required this.item,
    required this.translate,
    this.onEdit,
    this.onDelete,
    this.onPromote,
  });

  final BacklogItem item;
  final String Function(String, String) translate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPromote;

  @override
  Widget build(BuildContext context) {
    final milestoneName = item.milestoneName;
    final subtitle = item.description?.isNotEmpty == true
        ? item.description!
        : translate('Chờ xác định chi tiết', 'Awaiting refinement');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityColor(item.priority).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _priorityColor(item.priority),
                  ),
                ),
              ),
              if (onEdit != null || onDelete != null || onPromote != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    FeatherIcons.moreVertical,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'promote':
                        onPromote?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(translate('Chỉnh sửa', 'Edit item')),
                      ),
                    if (onPromote != null)
                      PopupMenuItem(
                        value: 'promote',
                        child: Text(
                          translate('Đưa lên Kanban', 'Promote to Kanban'),
                        ),
                      ),
                    if (onDelete != null) const PopupMenuDivider(),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          translate('Xoá backlog', 'Delete backlog item'),
                          style: const TextStyle(color: Color(0xFFE11D48)),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFE0E7FF),
                child: Text(
                  item.ownerDisplayName.isNotEmpty
                      ? item.ownerDisplayName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF312E81),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.ownerDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              if (item.dueDate != null)
                Row(
                  children: [
                    Icon(
                      FeatherIcons.calendar,
                      size: 14,
                      color: item.isOverdue
                          ? const Color(0xFFE8615A)
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(item.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item.isOverdue
                            ? const Color(0xFFE8615A)
                            : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (milestoneName != null && milestoneName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    FeatherIcons.flag,
                    size: 12,
                    color: Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    milestoneName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _priorityColor(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('high')) return const Color(0xFFDC2626);
    if (value.contains('low')) return const Color(0xFF10B981);
    return const Color(0xFFF59E0B);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.translate,
    this.onEdit,
    this.onDelete,
    this.onAssignItems,
    this.onRemoveItem,
  });

  final Milestone milestone;
  final String Function(String, String) translate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAssignItems;
  final void Function(String backlogItemId)? onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final percent = milestone.completionPercent.clamp(0, 1).toDouble();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  milestone.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
              if (onEdit != null || onDelete != null || onAssignItems != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    FeatherIcons.moreVertical,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'assign':
                        onAssignItems?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(translate('Chỉnh sửa', 'Edit milestone')),
                      ),
                    if (onAssignItems != null)
                      PopupMenuItem(
                        value: 'assign',
                        child: Text(
                          translate('Gán backlog', 'Assign backlog items'),
                        ),
                      ),
                    if (onDelete != null) const PopupMenuDivider(),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          translate('Xoá milestone', 'Delete milestone'),
                          style: const TextStyle(color: Color(0xFFE11D48)),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            milestone.description ??
                translate('Chưa có mô tả', 'No description yet'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: const Color(0xFFE0E7FF),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                FeatherIcons.calendar,
                size: 14,
                color: milestone.isCompleted
                    ? const Color(0xFF10B981)
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                milestone.targetDate != null
                    ? _formatStaticDate(milestone.targetDate!)
                    : translate('Chưa đặt lịch', 'No target date'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
              const Spacer(),
              Text(
                '${milestone.completedItems}/${milestone.totalItems} ${translate('hạng mục', 'items')}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
            ],
          ),
          if (milestone.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: milestone.items
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          if (onRemoveItem != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () =>
                                  onRemoveItem?.call(item.backlogItemId),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatStaticDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.title, required this.actions});

  final String title;
  final List<_ActionSheetItem> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionSheetItem extends StatelessWidget {
  const _ActionSheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0E7C7B)),
      title: Text(label),
      onTap: onTap,
    );
  }
}

class _FormDialog extends StatelessWidget {
  const _FormDialog({
    required this.title,
    required this.submitLabel,
    required this.cancelLabel,
    required this.contentBuilder,
    required this.onSubmit,
  });

  final String title;
  final String submitLabel;
  final String cancelLabel;
  final Widget Function(
    BuildContext context,
    void Function(VoidCallback) setState,
  )
  contentBuilder;
  final Object? Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: StatefulBuilder(
        builder: (context, setState) => contentBuilder(context, setState),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () {
            final result = onSubmit();
            if (result != null) {
              Navigator.pop(context, result);
            }
          },
          child: Text(submitLabel),
        ),
      ],
    );
  }
}
