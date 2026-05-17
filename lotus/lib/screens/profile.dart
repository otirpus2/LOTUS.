import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';

void main() {
  runApp(const LotusApp());
}

class LotusApp extends StatelessWidget {
  const LotusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Profile Page',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Roboto',
      ),
      home: const ProfilePage(),
    );
  }
}

/// =======================================================
/// MODEL
/// =======================================================
class StudentProfile {
  final String fullName;
  final String motherName;
  final String fatherName;
  final int? studentClass;
  final String section;
  final String mobileNumber;
  final String email;
  final String category;
  final List<String> subjects;

  const StudentProfile({
    required this.fullName,
    required this.motherName,
    required this.fatherName,
    required this.studentClass,
    required this.section,
    required this.mobileNumber,
    required this.email,
    required this.category,
    required this.subjects,
  });

  factory StudentProfile.empty({String email = ''}) {
    return StudentProfile(
      fullName: '',
      motherName: '',
      fatherName: '',
      studentClass: null,
      section: '',
      mobileNumber: '',
      email: email,
      category: '',
      subjects: const [],
    );
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      fullName: map['full_name'] ?? map['username'] ?? '',
      motherName: map['mother_name'] ?? '',
      fatherName: map['father_name'] ?? '',
      studentClass: _readClassNumber(map['class_rooms']?['name']),
      section: map['class_rooms']?['section'] ?? '',
      mobileNumber: map['mobile_number'] ?? '',
      email: map['email'] ?? '',
      category: map['category'] ?? '',
      subjects: _readSubjects(map['subjects']),
    );
  }

  static List<String> _readSubjects(dynamic value) {
    if (value is List) {
      return value.map((subject) => subject.toString()).toList();
    }

    return const [];
  }

  static int? _readClassNumber(dynamic value) {
    if (value is int && value >= 1 && value <= 12) return value;

    final parsed = int.tryParse((value ?? '').toString().trim());
    if (parsed == null || parsed < 1 || parsed > 12) return null;
    return parsed;
  }

  String get classLabel => studentClass?.toString() ?? '';

  Map<String, dynamic> toMap({
    required String userId,
    required String authEmail,
  }) {
    return {
      'id': userId,
      'username': fullName.trim().isEmpty ? authEmail : fullName.trim(),
      'full_name': fullName.trim(),
      'mother_name': motherName.trim(),
      'father_name': fatherName.trim(),
      'mobile_number': mobileNumber.trim(),
      'email': authEmail,
      'category': category.trim(),
      'subjects': subjects.map((subject) => subject.trim()).where((subject) {
        return subject.isNotEmpty;
      }).toList(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _studentClassController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final List<TextEditingController> _subjectControllers = [];

  StudentProfile student = StudentProfile.empty();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _loadError;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _fullNameController.dispose();
    _motherNameController.dispose();
    _fatherNameController.dispose();
    _studentClassController.dispose();
    _sectionController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _categoryController.dispose();
    _disposeSubjectControllers();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final User? user = _supabase.auth.currentUser;
      if (user == null) {
        throw StateError('Please log in again to view your profile.');
      }

      final Map<String, dynamic>? row = await _supabase
          .from('profiles')
          .select(
            'id, username, full_name, mother_name, father_name, class_id, mobile_number, email, category, subjects, class_rooms(name, section)',
          )
          .eq('id', user.id)
          .maybeSingle();

      final StudentProfile loadedProfile = row == null
          ? StudentProfile.empty(email: user.email ?? '')
          : StudentProfile.fromMap(
              row,
            ).copyWith(email: user.email ?? row['email'] ?? '');

      if (!mounted) return;

      setState(() {
        student = loadedProfile;
        _setControllersFromProfile(loadedProfile);
        _isLoading = false;
      });

      _watchProfile(user.id);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  void _watchProfile(String userId) {
    _profileSubscription?.cancel();
    _profileSubscription = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((rows) {
          if (!mounted || rows.isEmpty) return;

          final updatedProfile = StudentProfile.fromMap(rows.first).copyWith(
            email:
                _supabase.auth.currentUser?.email ?? rows.first['email'] ?? '',
          );

          setState(() {
            student = updatedProfile;
            if (!_isEditing) {
              _setControllersFromProfile(updatedProfile);
            }
          });
        });
  }

  Future<void> _saveProfile() async {
    final User? user = _supabase.auth.currentUser;
    if (user == null) {
      _showMessage('Please log in again to save your profile.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final StudentProfile profile = _profileFromControllers(
        authEmail: user.email ?? '',
      );

      await _supabase
          .from('profiles')
          .upsert(
            profile.toMap(
              userId: user.id,
              authEmail: user.email ?? profile.email,
            ),
            onConflict: 'id',
          );

      if (!mounted) return;

      setState(() {
        student = profile;
        _isEditing = false;
        _isSaving = false;
      });

      _showMessage('Profile saved successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
      _showMessage('Failed to save profile: $e');
    }
  }

  void _setControllersFromProfile(StudentProfile profile) {
    _fullNameController.text = profile.fullName;
    _motherNameController.text = profile.motherName;
    _fatherNameController.text = profile.fatherName;
    _studentClassController.text = profile.classLabel;
    _sectionController.text = profile.section;
    _mobileNumberController.text = profile.mobileNumber;
    _emailController.text = profile.email;
    _categoryController.text = profile.category;

    _disposeSubjectControllers();

    final List<String> subjects = profile.subjects.isEmpty
        ? ['']
        : profile.subjects;

    for (final String subject in subjects) {
      _subjectControllers.add(TextEditingController(text: subject));
    }
  }

  StudentProfile _profileFromControllers({required String authEmail}) {
    return StudentProfile(
      fullName: _fullNameController.text,
      motherName: _motherNameController.text,
      fatherName: _fatherNameController.text,
      studentClass: student.studentClass,
      section: student.section,
      mobileNumber: _mobileNumberController.text,
      email: authEmail.isEmpty ? _emailController.text : authEmail,
      category: _categoryController.text,
      subjects: _subjectControllers
          .map((controller) => controller.text)
          .where((subject) => subject.trim().isNotEmpty)
          .toList(),
    );
  }

  void _disposeSubjectControllers() {
    for (final TextEditingController controller in _subjectControllers) {
      controller.dispose();
    }
    _subjectControllers.clear();
  }

  void _addSubjectField() {
    setState(() {
      _subjectControllers.add(TextEditingController());
    });
  }

  void _removeSubjectField(int index) {
    setState(() {
      final TextEditingController controller = _subjectControllers.removeAt(
        index,
      );
      controller.dispose();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 18,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          _isLoading
              ? const SizedBox.shrink()
              : IconButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          if (_isEditing) {
                            _saveProfile();
                          } else {
                            setState(() {
                              _isEditing = true;
                            });
                          }
                        },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                          color: const Color(0xFF5B5BD6),
                          size: 20,
                        ),
                ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),

          /// PROFILE IMAGE
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C72A8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.person, size: 55, color: Colors.white),
              ),

              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF5B5BD6),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            _isEditing ? _fullNameController.text : student.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 18),

          /// PERSONAL DETAILS
          _sectionTitle("Personal Details"),

          _profileTile(
            icon: Icons.person_outline_rounded,
            title: "Full Name",
            value: student.fullName,
            controller: _fullNameController,
          ),

          _profileTile(
            icon: Icons.woman_2_outlined,
            title: "Mother Name",
            value: student.motherName,
            controller: _motherNameController,
          ),

          _profileTile(
            icon: Icons.man_2_outlined,
            title: "Father Name",
            value: student.fatherName,
            controller: _fatherNameController,
          ),

          _profileTile(
            icon: Icons.phone_outlined,
            title: "Mobile Number",
            value: student.mobileNumber,
            controller: _mobileNumberController,
            keyboardType: TextInputType.phone,
          ),

          _profileTile(
            icon: Icons.email_outlined,
            title: "Email",
            value: student.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: false,
          ),

          const SizedBox(height: 14),

          /// ACADEMIC DETAILS
          _sectionTitle("Academic Details"),

          _profileTile(
            icon: Icons.school_outlined,
            title: "Class",
            value: student.classLabel,
            controller: _studentClassController,
            enabled: false,
          ),

          _profileTile(
            icon: Icons.groups_outlined,
            title: "Section",
            value: student.section,
            controller: _sectionController,
            enabled: false,
          ),

          _profileTile(
            icon: Icons.badge_outlined,
            title: "Category",
            value: student.category,
            controller: _categoryController,
          ),

          const SizedBox(height: 14),

          /// SUBJECTS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Subjects",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    onPressed: _addSubjectField,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Color(0xFF5B5BD6),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(children: _subjectWidgets()),
          ),

          const SizedBox(height: 14),

          /// LOGOUT BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _logout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _subjectWidgets() {
    if (_isEditing) {
      return _subjectControllers.asMap().entries.map((entry) {
        return _subjectTile(
          controller: entry.value,
          onRemove: _subjectControllers.length == 1
              ? null
              : () {
                  _removeSubjectField(entry.key);
                },
        );
      }).toList();
    }

    if (student.subjects.isEmpty) {
      return [_subjectTile(value: '')];
    }

    return student.subjects.map((subject) {
      return _subjectTile(value: subject);
    }).toList();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String title,
    required String value,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                if (_isEditing && controller != null && enabled)
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  )
                else
                  Text(
                    enabled ? value : controller?.text ?? value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectTile({
    String? value,
    TextEditingController? controller,
    VoidCallback? onRemove,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: Color(0xFF5B5BD6),
            size: 18,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _isEditing && controller != null
                ? TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    value ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),

          if (_isEditing && onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: Colors.redAccent,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

extension on StudentProfile {
  StudentProfile copyWith({
    String? fullName,
    String? motherName,
    String? fatherName,
    int? studentClass,
    String? section,
    String? mobileNumber,
    String? email,
    String? category,
    List<String>? subjects,
  }) {
    return StudentProfile(
      fullName: fullName ?? this.fullName,
      motherName: motherName ?? this.motherName,
      fatherName: fatherName ?? this.fatherName,
      studentClass: studentClass ?? this.studentClass,
      section: section ?? this.section,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      category: category ?? this.category,
      subjects: subjects ?? this.subjects,
    );
  }
}
