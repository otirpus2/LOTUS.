import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'certificate_model.dart';

class AddCertificatePage extends StatefulWidget {
  const AddCertificatePage({super.key});

  @override
  State<AddCertificatePage> createState() =>
      _AddCertificatePageState();
}

class _AddCertificatePageState
    extends State<AddCertificatePage> {
  final titleController = TextEditingController();
  final issuerController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  final categoryController = TextEditingController();

  String selectedFile = '';

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dateController.text = "${picked.day} ${_getMonthName(picked.month)} ${picked.year}";
      });
    }
  }

  bool _validate() {
    return titleController.text.trim().isNotEmpty &&
        issuerController.text.trim().isNotEmpty &&
        dateController.text.trim().isNotEmpty &&
        categoryController.text.trim().isNotEmpty &&
        selectedFile.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    // Rebuild whenever any controller changes
    titleController.addListener(() => setState(() {}));
    issuerController.addListener(() => setState(() {}));
    dateController.addListener(() => setState(() {}));
    categoryController.addListener(() => setState(() {}));
  }

  Widget buildField(
      String hint,
      TextEditingController controller, {
        int maxLines = 1,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),

      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,

        decoration: InputDecoration(
          hintText: hint,

          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,

        title: const Text(
          "Add Achievement",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                FilePickerResult? result =
                await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );

                if (result != null) {
                  setState(() {
                    selectedFile =
                        result.files.single.path ?? '';
                  });
                }
              },

                child: Container(
                  width: double.infinity,
                  height: 200,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),

                  child: selectedFile.isEmpty
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.upload_file_rounded,
                        size: 55,
                        color: Color(0xFF4F46E5),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Upload Certificate",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                      : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.file(
                          File(selectedFile),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, color: Colors.red, size: 40),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              buildField("Achievement Title *", titleController),

              buildField("Issuer / Organization *", issuerController),

              buildField(
                "Date *",
                dateController,
                readOnly: true,
                onTap: _selectDate,
              ),

              buildField("Category *", categoryController),

              buildField(
                "Description (Optional)",
                descriptionController,
                maxLines: 4,
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    disabledBackgroundColor: Colors.grey.shade300,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  onPressed: _validate() ? () {
                    final achievement = Achievement(
                      title: titleController.text,
                      issuer: issuerController.text,
                      description: descriptionController.text.isEmpty
                          ? "No description provided"
                          : descriptionController.text,
                      date: dateController.text,
                      category: categoryController.text,
                      filePath: selectedFile,
                    );

                    Navigator.pop(context, achievement);
                  } : null,

                  child: const Text(
                    "Save Achievement",

                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}