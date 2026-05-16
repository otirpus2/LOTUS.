import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/class_management_repository.dart';
import 'data/homework_repository.dart';
import 'models/class_scope.dart';
import 'models/homework_model.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  final HomeworkRepository _repo = HomeworkRepository();
  final ClassManagementRepository _classRepo = ClassManagementRepository();

  final List<String> subjects = const ['All', 'Math', 'Science', 'SST'];
  final List<String> fileTypes = const ['All', 'PDF', 'DOC', 'Excel'];

  String selectedSubject = 'All';
  String selectedFileType = 'All';

  bool isLoading = true;
  String? error;

  ClassScope currentClass = const ClassScope(
    classNumber: null,
    className: '',
    section: '',
  );
  List<HomeworkModel> homeworks = [];
  StreamSubscription<ClassScope>? _classSubscription;
  StreamSubscription<List<HomeworkModel>>? _homeworkSubscription;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _classSubscription?.cancel();
    _homeworkSubscription?.cancel();
    super.dispose();
  }

  String? normalizeSelectedFileType(String type) {
    // UI: PDF/DOC/Excel
    if (type == 'All') return null;
    final lower = type.toLowerCase();
    if (lower == 'pdf') return 'pdf';
    if (lower == 'doc') return 'doc';
    if (lower == 'excel') return 'excel';
    return null;
  }

  Future<void> _bootstrap() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      _watchClassScope();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  void _watchClassScope() {
    _classSubscription?.cancel();
    _classSubscription = _classRepo.watchCurrentClassScope().listen(
      (scope) {
        if (!mounted) return;

        setState(() {
          currentClass = scope;
          isLoading = true;
          error = null;
        });

        _watchHomeworks(scope);
      },
      onError: (Object e) {
        if (!mounted) return;

        setState(() {
          error = e.toString();
          isLoading = false;
        });
      },
    );
  }

  void _watchHomeworks(ClassScope scope) {
    _homeworkSubscription?.cancel();

    if (!scope.isAssigned) {
      setState(() {
        homeworks = const <HomeworkModel>[];
        isLoading = false;
      });
      return;
    }

    _homeworkSubscription = _classRepo
        .watchClassHomeworks(
          scope: scope,
          subject: selectedSubject,
          fileType: normalizeSelectedFileType(selectedFileType),
        )
        .listen(
          (list) {
            if (!mounted) return;

            setState(() {
              homeworks = list;
              isLoading = false;
              error = null;
            });
          },
          onError: (Object e) {
            if (!mounted) return;

            setState(() {
              error = e.toString();
              isLoading = false;
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4F46E5);
    const Color backgroundColor = Color(0xFFF7F5FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Homework',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilters(primaryColor),
              const SizedBox(height: 16),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : homeworks.isEmpty
                    ? Center(
                        child: Text(
                          currentClass.isAssigned
                              ? 'No homework found'
                              : 'Your profile is not assigned to a class yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: homeworks.length,
                        itemBuilder: (context, index) {
                          final h = homeworks[index];
                          return _HomeworkCard(
                            subject: h.subject,
                            fileType: h.fileType,
                            fileName: h.fileName,
                            createdAt: h.createdAt,
                            onOpen: () async {
                              final url = await _repo.getDownloadUrl(
                                storagePath: h.storagePath,
                              );
                              if (!context.mounted) return;

                              final opened = await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );

                              if (!opened && context.mounted) {
                                await Clipboard.setData(
                                  ClipboardData(text: url),
                                );
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Download link copied. Open it in your browser to download.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildFilters(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filters',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedSubject,
                items: subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) {
                  setState(() {
                    selectedSubject = v ?? 'All';
                  });
                  _watchHomeworks(currentClass);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedFileType,
                items: fileTypes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) {
                  setState(() {
                    selectedFileType = v ?? 'All';
                  });
                  _watchHomeworks(currentClass);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Class ${currentClass.label} - ${selectedSubject == 'All' ? 'All subjects' : selectedSubject} - ${selectedFileType == 'All' ? 'All file types' : selectedFileType}',
          style: TextStyle(color: primaryColor.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final String subject;
  final String fileType;
  final String fileName;
  final DateTime createdAt;
  final VoidCallback onOpen;

  const _HomeworkCard({
    required this.subject,
    required this.fileType,
    required this.fileName,
    required this.createdAt,
    required this.onOpen,
  });

  String _prettyType() {
    final t = fileType.toLowerCase();
    if (t == 'pdf') return 'PDF';
    if (t == 'doc') return 'DOC';
    if (t == 'excel') return 'Excel';
    return fileType;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4F46E5);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.menu_book_rounded, color: primaryColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$subject • ${_prettyType()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOpen,
            icon: Icon(Icons.download_rounded, color: primaryColor),
          ),
        ],
      ),
    );
  }
}
