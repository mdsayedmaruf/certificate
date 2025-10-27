import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'template.dart';
import 'certificate_generator.dart';

void main() {
  runApp(const CertificateMakerApp());
}

class CertificateMakerApp extends StatelessWidget {
  const CertificateMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certificate Maker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37), // Gold color
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
           elevation: 4,
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
           ),
         ),    
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      home: const CertificateBuilderPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CertificateBuilderPage extends StatefulWidget {
  const CertificateBuilderPage({super.key});

  @override
  State<CertificateBuilderPage> createState() => _CertificateBuilderPageState();
}

class _CertificateBuilderPageState extends State<CertificateBuilderPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _studentNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _courseDurationController = TextEditingController();
  final _instructorController = TextEditingController();
  final _institutionController = TextEditingController();
  final _courseDescriptionController = TextEditingController();
  
  DateTime _completionDate = DateTime.now();
  String _selectedTemplate = 'standard';
  bool _isGenerating = false;
  CertificateResult? _lastGeneratedCertificate;
  Uint8List? _previewImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentNameController.dispose();
    _studentIdController.dispose();
    _studentEmailController.dispose();
    _courseNameController.dispose();
    _courseDurationController.dispose();
    _instructorController.dispose();
    _institutionController.dispose();
    _courseDescriptionController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    _studentNameController.text = 'John Doe';
    _studentIdController.text = 'STU2024001';
    _studentEmailController.text = 'john.doe@example.com';
    _courseNameController.text = 'Advanced Flutter Development';
    _courseDurationController.text = '40 hours';
    _instructorController.text = 'Dr. Jane Smith';
    _institutionController.text = 'Tech University';
    _courseDescriptionController.text = 'Comprehensive course covering advanced Flutter concepts and best practices.';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _completionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _completionDate) {
      setState(() {
        _completionDate = picked;
      });
    }
  }

  Future<void> _generateCertificate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
      _previewImage = null;
    });

    try {
      final student = StudentInfo(
        name: _studentNameController.text.trim(),
        id: _studentIdController.text.trim(),
        completionDate: _completionDate,
        email: _studentEmailController.text.trim(),
      );

      final course = CourseInfo(
        name: _courseNameController.text.trim(),
        duration: _courseDurationController.text.trim(),
        instructor: _instructorController.text.trim(),
        institution: _institutionController.text.trim(),
        description: _courseDescriptionController.text.trim(),
      );

      final generator = _selectedTemplate == 'elegant'
          ? CertificateGeneratorFactory.createElegant()
          : CertificateGeneratorFactory.createStandard();

      final result = await generator.generateCertificate(
        student: student,
        course: course,
      );

      // Load preview image
      final file = File(result.filePath);
      final imageBytes = await file.readAsBytes();

      setState(() {
        _lastGeneratedCertificate = result;
        _previewImage = imageBytes;
        _isGenerating = false;
      });

      // Switch to preview tab
      _tabController.animateTo(2);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate generated successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _tabController.animateTo(2),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        String errorMessage = 'Failed to generate certificate';
        if (e is ValidationException) {
          errorMessage = e.message;
        } else if (e is CertificateGenerationException) {
          errorMessage = e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Certificate Maker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Student Info'),
            Tab(icon: Icon(Icons.school), text: 'Course Info'),
            Tab(icon: Icon(Icons.preview), text: 'Preview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentInfoTab(),
          _buildCourseInfoTab(),
          _buildPreviewTab(),
        ],
      ),
      floatingActionButton: _isGenerating
          ? const CircularProgressIndicator()
          : FloatingActionButton.extended(
              onPressed: _generateCertificate,
              icon: const Icon(Icons.create),
              label: const Text('Generate Certificate'),
            ),
    );
  }

  Widget _buildStudentInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter student full name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Student name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        if (value.trim().length > 100) {
                          return 'Name must not exceed 100 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentIdController,
                      decoration: const InputDecoration(
                        labelText: 'Student ID *',
                        hintText: 'Enter student ID',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Student ID is required';
                        }
                        if (!RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(value)) {
                          return 'ID can only contain letters, numbers, hyphens, and underscores';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        hintText: 'Enter email address',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Completion Date *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_completionDate.day}/${_completionDate.month}/${_completionDate.year}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Selection',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<String>(
                      title: const Text('Modern Standard Template'),
                      subtitle: const Text('Clean modern design with blue accents'),
                      value: 'standard',
                      groupValue: _selectedTemplate,
                      onChanged: (value) {
                        setState(() {
                          _selectedTemplate = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Modern Elegant Template'),
                        subtitle: const Text('Contemporary blue design with decorative elements'),
                      value: 'elegant',
                      groupValue: _selectedTemplate,
                      onChanged: (value) {
                        setState(() {
                          _selectedTemplate = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course Information',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name *',
                  hintText: 'Enter course name',
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Course name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Course name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseDurationController,
                decoration: const InputDecoration(
                  labelText: 'Duration *',
                  hintText: 'e.g., 40 hours, 6 weeks',
                  prefixIcon: Icon(Icons.schedule),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Course duration is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructorController,
                decoration: const InputDecoration(
                  labelText: 'Instructor Name *',
                  hintText: 'Enter instructor name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Instructor name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _institutionController,
                decoration: const InputDecoration(
                  labelText: 'Institution Name *',
                  hintText: 'Enter institution name',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Institution name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Course Description (Optional)',
                  hintText: 'Brief description of the course',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    if (_previewImage == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.preview,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No certificate generated yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fill in the student and course information, then tap "Generate Certificate"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certificate Preview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _previewImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_lastGeneratedCertificate != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Certificate Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Certificate ID', _lastGeneratedCertificate!.certificateId),
                    _buildDetailRow('File Path', _lastGeneratedCertificate!.filePath),
                    _buildDetailRow('File Size', '${(_lastGeneratedCertificate!.fileSize / 1024).toStringAsFixed(1)} KB'),
                    _buildDetailRow('Generated At', _lastGeneratedCertificate!.generatedAt.toString()),
                    _buildDetailRow('Checksum', _lastGeneratedCertificate!.checksum.substring(0, 16) + '...'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openFile(_lastGeneratedCertificate!.filePath),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open File'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareFile(_lastGeneratedCertificate!.filePath),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _openFile(String filePath) {
    // Platform-specific file opening would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File saved to: $filePath'),
        action: SnackBarAction(
          label: 'Copy Path',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: filePath));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File path copied to clipboard')),
            );
          },
        ),
      ),
    );
  }

  void _shareFile(String filePath) {
    // Platform-specific sharing would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality would be implemented here')),
    );
  }
}
