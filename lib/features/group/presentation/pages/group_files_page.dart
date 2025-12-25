import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/models/group_file_model.dart';

class GroupFilesPage extends StatefulWidget {
  final String groupId;
  final AuthSession session;
  final AppLanguage language;

  const GroupFilesPage({
    super.key,
    required this.groupId,
    required this.session,
    required this.language,
  });

  @override
  State<GroupFilesPage> createState() => _GroupFilesPageState();
}

class _GroupFilesPageState extends State<GroupFilesPage> {
  late final GroupRemoteDataSource _dataSource;
  bool _loading = false;
  String? _error;
  List<GroupFileModel> _files = [];

  @override
  void initState() {
    super.initState();
    _dataSource = GroupRemoteDataSource(baseUrl: kApiBaseUrl);
    _loadFiles();
  }

  String _translate(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final files = await _dataSource.fetchGroupFiles(
        widget.session.accessToken,
        widget.groupId,
      );
      if (!mounted) return;
      setState(() {
        _files = files;
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

  Future<void> _openDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open file')),
      );
    }
  }

  Future<void> _confirmDelete(GroupFileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file'),
        content: Text(
          'Are you sure you want to delete this file?\n\n${file.description ?? file.fileName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _dataSource.deleteGroupFile(
        widget.session.accessToken,
        widget.groupId,
        file.fileId,
      );
      if (!mounted) return;
      await _loadFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showUploadDialog() async {
    PlatformFile? selected;
    final descriptionController = TextEditingController();
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
                        const Text(
                          'Upload File',
                          style: TextStyle(
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
                      'Select file *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    withData: true,
                                  );
                                  if (result == null ||
                                      result.files.isEmpty) {
                                    return;
                                  }
                                  setDialogState(() {
                                    selected = result.files.first;
                                  });
                                },
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Choose file'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1F2937),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            elevation: 0,
                          ),
                        ),
                        if (selected != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description_outlined,
                                      size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      selected!.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: saving
                                        ? null
                                        : () {
                                            setDialogState(() {
                                              selected = null;
                                            });
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Description (Optional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter description',
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
                          onPressed: saving || selected == null
                              ? null
                              : () async {
                                  setDialogState(() {
                                    saving = true;
                                  });
                                  try {
                                    final filePath = selected!.path;
                                    final bytes = selected!.bytes ??
                                        (filePath != null
                                            ? await File(filePath).readAsBytes()
                                            : null);
                                    if (bytes == null) {
                                      throw Exception('No file data');
                                    }
                                    await _dataSource.uploadGroupFile(
                                      widget.session.accessToken,
                                      widget.groupId,
                                      bytes: bytes,
                                      fileName: selected!.name,
                                      description:
                                          descriptionController.text.trim(),
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    await _loadFiles();
                                  } catch (e) {
                                    if (!mounted) return;
                                    setDialogState(() {
                                      saving = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
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
                              : const Text('Upload'),
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

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(2)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('Tep du an', 'Project Files')),
        elevation: 0,
      ),
      body: _loading && _files.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadFiles,
                        child: Text(_translate('Thu lai', 'Retry')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFiles,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _translate('Tep du an', 'Project Files'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showUploadDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Upload Files'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_files.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            _translate(
                              'Chua co file. Hay tai len file dau tien.',
                              'No files yet. Upload your first document.',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        )
                      else
                        ..._files.map(_buildFileCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFileCard(GroupFileModel file) {
    final title = (file.description != null && file.description!.isNotEmpty)
        ? file.description!
        : file.fileName;
    final dateText = DateFormat('dd/MM/yyyy').format(file.createdAt.toLocal());

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined,
                color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded by ${file.uploadedByName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      file.fileType.split('/').last.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•',
                        style: TextStyle(color: Color(0xFFCBD5E1))),
                    const SizedBox(width: 8),
                    Text(
                      _formatFileSize(file.fileSize),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•',
                        style: TextStyle(color: Color(0xFFCBD5E1))),
                    const SizedBox(width: 8),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'download') {
                _openDownload(file.fileUrl);
              } else if (value == 'delete') {
                _confirmDelete(file);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 18),
                    SizedBox(width: 8),
                    Text('Download'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
