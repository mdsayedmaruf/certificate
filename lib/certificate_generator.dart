import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'template.dart';

/// Exception thrown when certificate generation fails
class CertificateGenerationException implements Exception {
  final String message;
  final dynamic originalError;

  const CertificateGenerationException(this.message, [this.originalError]);

  @override
  String toString() => 'CertificateGenerationException: $message';
}

/// Exception thrown when input validation fails
class ValidationException implements Exception {
  final String message;
  final Map<String, String> fieldErrors;

  const ValidationException(this.message, [this.fieldErrors = const {}]);

  @override
  String toString() => 'ValidationException: $message';
}

/// Configuration for certificate output settings
class OutputConfig {
  final int dpi;
  final int quality;
  final String format;
  final bool preserveAspectRatio;
  final String outputDirectory;

  const OutputConfig({
    this.dpi = 300,
    this.quality = 95,
    this.format = 'jpg',
    this.preserveAspectRatio = true,
    this.outputDirectory = '',
  });

  /// Validate output configuration
  bool isValid() {
    return dpi >= 72 && dpi <= 600 &&
           quality >= 1 && quality <= 100 &&
           ['jpg', 'jpeg', 'png'].contains(format.toLowerCase());
  }
}

/// Anti-forgery configuration
class SecurityConfig {
  final bool enableWatermark;
  final bool enableDigitalSignature;
  final String secretKey;
  final bool embedMetadata;
  final bool enableQRCode;

  const SecurityConfig({
    this.enableWatermark = true,
    this.enableDigitalSignature = true,
    this.secretKey = '',
    this.embedMetadata = true,
    this.enableQRCode = false,
  });
}

/// Certificate generation result
class CertificateResult {
  final String certificateId;
  final String filePath;
  final int fileSize;
  final DateTime generatedAt;
  final String checksum;
  final Map<String, dynamic> metadata;

  const CertificateResult({
    required this.certificateId,
    required this.filePath,
    required this.fileSize,
    required this.generatedAt,
    required this.checksum,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'certificateId': certificateId,
    'filePath': filePath,
    'fileSize': fileSize,
    'generatedAt': generatedAt.toIso8601String(),
    'checksum': checksum,
    'metadata': metadata,
  };
}

/// Main certificate generator class
class CertificateGenerator {
  final CertificateTemplate template;
  final OutputConfig outputConfig;
  final SecurityConfig securityConfig;
  final Uuid _uuid = const Uuid();

  CertificateGenerator({
    required this.template,
    this.outputConfig = const OutputConfig(),
    this.securityConfig = const SecurityConfig(),
  });

  /// Generate a certificate with the given data
  Future<CertificateResult> generateCertificate({
    required StudentInfo student,
    required CourseInfo course,
    String? customCertificateId,
    String? logoPath,
    String? outputFileName,
  }) async {
    try {
      // Validate input data
      await _validateInputData(student, course);

      // Generate unique certificate ID
      final certificateId = customCertificateId ?? _generateCertificateId(student, course);

      // Validate certificate ID
      _validateCertificateId(certificateId);

      // Generate certificate image
      final imageBytes = await template.generateCertificate(
        student: student,
        course: course,
        certificateId: certificateId,
        logoPath: logoPath,
      );

      // Apply security measures
      final securedImageBytes = await _applySecurityMeasures(
        imageBytes,
        certificateId,
        student,
        course,
      );

      // Convert to high-quality JPG
      final finalImageBytes = await _convertToOutputFormat(securedImageBytes);

      // Save to file
      final filePath = await _saveToFile(
        finalImageBytes,
        certificateId,
        outputFileName,
      );

      // Calculate checksum
      final checksum = _calculateChecksum(finalImageBytes);

      // Create metadata
      final metadata = _createMetadata(student, course, certificateId);

      // Get file size
      final file = File(filePath);
      final fileSize = await file.length();

      return CertificateResult(
        certificateId: certificateId,
        filePath: filePath,
        fileSize: fileSize,
        generatedAt: DateTime.now(),
        checksum: checksum,
        metadata: metadata,
      );
    } catch (e) {
      if (e is ValidationException || e is CertificateGenerationException) {
        rethrow;
      }
      throw CertificateGenerationException(
        'Failed to generate certificate: ${e.toString()}',
        e,
      );
    }
  }

  /// Validate input data
  Future<void> _validateInputData(StudentInfo student, CourseInfo course) async {
    final errors = <String, String>{};

    // Validate student data
    if (student.name.trim().isEmpty) {
      errors['student.name'] = 'Student name is required';
    } else if (student.name.length < 2) {
      errors['student.name'] = 'Student name must be at least 2 characters';
    } else if (student.name.length > 100) {
      errors['student.name'] = 'Student name must not exceed 100 characters';
    }

    if (student.id.trim().isEmpty) {
      errors['student.id'] = 'Student ID is required';
    } else if (!RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(student.id)) {
      errors['student.id'] = 'Student ID contains invalid characters';
    }

    if (student.email.trim().isEmpty) {
      errors['student.email'] = 'Student email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(student.email)) {
      errors['student.email'] = 'Invalid email format';
    }

    if (student.completionDate.isAfter(DateTime.now())) {
      errors['student.completionDate'] = 'Completion date cannot be in the future';
    }

    // Validate course data
    if (course.name.trim().isEmpty) {
      errors['course.name'] = 'Course name is required';
    } else if (course.name.length < 3) {
      errors['course.name'] = 'Course name must be at least 3 characters';
    } else if (course.name.length > 200) {
      errors['course.name'] = 'Course name must not exceed 200 characters';
    }

    if (course.instructor.trim().isEmpty) {
      errors['course.instructor'] = 'Instructor name is required';
    } else if (course.instructor.length < 2) {
      errors['course.instructor'] = 'Instructor name must be at least 2 characters';
    }

    if (course.institution.trim().isEmpty) {
      errors['course.institution'] = 'Institution name is required';
    } else if (course.institution.length < 2) {
      errors['course.institution'] = 'Institution name must be at least 2 characters';
    }

    if (course.duration.trim().isEmpty) {
      errors['course.duration'] = 'Course duration is required';
    }

    if (errors.isNotEmpty) {
      throw ValidationException('Input validation failed', errors);
    }
  }

  /// Generate unique certificate ID
  String _generateCertificateId(StudentInfo student, CourseInfo course) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4();
    
    // Create a hash from student and course data for uniqueness
    final dataString = '${student.name}${student.id}${course.name}${course.instructor}$timestamp';
    final dataHash = sha256.convert(dataString.codeUnits).toString().substring(0, 8);
    
    return 'CERT-${dataHash.toUpperCase()}-${uuid.substring(0, 8).toUpperCase()}';
  }

  /// Validate certificate ID format
  void _validateCertificateId(String certificateId) {
    if (certificateId.isEmpty) {
      throw ValidationException('Certificate ID cannot be empty');
    }

    if (certificateId.length < 10 || certificateId.length > 50) {
      throw ValidationException('Certificate ID must be between 10 and 50 characters');
    }

    if (!RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(certificateId)) {
      throw ValidationException('Certificate ID contains invalid characters');
    }
  }

  /// Apply security measures to the certificate
  Future<Uint8List> _applySecurityMeasures(
    Uint8List imageBytes,
    String certificateId,
    StudentInfo student,
    CourseInfo course,
  ) async {
    try {
      var image = img.decodeImage(imageBytes);
      if (image == null) {
        throw CertificateGenerationException('Failed to decode generated image');
      }

      // Add digital signature if enabled
      if (securityConfig.enableDigitalSignature) {
        image = _addDigitalSignature(image, certificateId, student, course);
      }

      // Embed metadata if enabled
      if (securityConfig.embedMetadata) {
        image = _embedMetadata(image, certificateId, student, course);
      }

      // Add QR code if enabled
      if (securityConfig.enableQRCode) {
        image = await _addQRCode(image, certificateId);
      }

      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      throw CertificateGenerationException(
        'Failed to apply security measures: ${e.toString()}',
        e,
      );
    }
  }

  /// Add digital signature to image
  img.Image _addDigitalSignature(
    img.Image image,
    String certificateId,
    StudentInfo student,
    CourseInfo course,
  ) {
    // Create signature data
    final signatureData = '$certificateId${student.name}${student.id}${course.name}${securityConfig.secretKey}';
    final signature = sha256.convert(signatureData.codeUnits).toString();
    
    // Embed signature in image metadata (simplified implementation)
    // In a real implementation, you would use proper digital signature algorithms
    return image;
  }

  /// Embed metadata in image
  img.Image _embedMetadata(
    img.Image image,
    String certificateId,
    StudentInfo student,
    CourseInfo course,
  ) {
    // Add metadata to image (simplified implementation)
    // In a real implementation, you would embed metadata in EXIF data
    return image;
  }

  /// Add QR code to certificate
  Future<img.Image> _addQRCode(img.Image image, String certificateId) async {
    // QR code generation would be implemented here
    // For now, return the original image
    return image;
  }

  /// Convert image to output format with high quality
  Future<Uint8List> _convertToOutputFormat(Uint8List imageBytes) async {
    try {
      var image = img.decodeImage(imageBytes);
      if (image == null) {
        throw CertificateGenerationException('Failed to decode image for format conversion');
      }

      // Ensure proper dimensions based on DPI
      final targetWidth = (template.layout.width * outputConfig.dpi / 300).round();
      final targetHeight = (template.layout.height * outputConfig.dpi / 300).round();

      // Resize if necessary
      if (image.width != targetWidth || image.height != targetHeight) {
        image = img.copyResize(
          image,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.cubic,
        );
      }

      // Convert to output format
      switch (outputConfig.format.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
          return Uint8List.fromList(img.encodeJpg(image, quality: outputConfig.quality));
        case 'png':
          return Uint8List.fromList(img.encodePng(image));
        default:
          throw CertificateGenerationException('Unsupported output format: ${outputConfig.format}');
      }
    } catch (e) {
      throw CertificateGenerationException(
        'Failed to convert image format: ${e.toString()}',
        e,
      );
    }
  }

  /// Save certificate to file
  Future<String> _saveToFile(
    Uint8List imageBytes,
    String certificateId,
    String? customFileName,
  ) async {
    try {
      // Get output directory
      final outputDir = await _getOutputDirectory();
      
      // Create filename
      final fileName = customFileName ?? 
          'certificate_${certificateId}_${DateTime.now().millisecondsSinceEpoch}.${outputConfig.format}';
      
      final filePath = path.join(outputDir.path, fileName);
      
      // Write file
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      
      return filePath;
    } catch (e) {
      throw CertificateGenerationException(
        'Failed to save certificate file: ${e.toString()}',
        e,
      );
    }
  }

  /// Get output directory
  Future<Directory> _getOutputDirectory() async {
    if (outputConfig.outputDirectory.isNotEmpty) {
      final dir = Directory(outputConfig.outputDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    // Use documents directory as default
    final documentsDir = await getApplicationDocumentsDirectory();
    final certificatesDir = Directory(path.join(documentsDir.path, 'certificates'));
    
    if (!await certificatesDir.exists()) {
      await certificatesDir.create(recursive: true);
    }
    
    return certificatesDir;
  }

  /// Calculate checksum for file integrity
  String _calculateChecksum(Uint8List data) {
    return sha256.convert(data).toString();
  }

  /// Create metadata for the certificate
  Map<String, dynamic> _createMetadata(
    StudentInfo student,
    CourseInfo course,
    String certificateId,
  ) {
    return {
      'certificateId': certificateId,
      'template': template.templateName,
      'student': student.toJson(),
      'course': course.toJson(),
      'outputConfig': {
        'dpi': outputConfig.dpi,
        'quality': outputConfig.quality,
        'format': outputConfig.format,
      },
      'securityFeatures': {
        'watermark': securityConfig.enableWatermark,
        'digitalSignature': securityConfig.enableDigitalSignature,
        'metadata': securityConfig.embedMetadata,
        'qrCode': securityConfig.enableQRCode,
      },
      'generatedBy': 'Certificate Maker v1.0',
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Verify certificate integrity
  Future<bool> verifyCertificate(String filePath, String expectedChecksum) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final bytes = await file.readAsBytes();
      final actualChecksum = _calculateChecksum(bytes);
      
      return actualChecksum == expectedChecksum;
    } catch (e) {
      return false;
    }
  }

  /// Get certificate information from file
  Future<Map<String, dynamic>?> getCertificateInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return null;
      }

      // Extract metadata from image (simplified implementation)
      // In a real implementation, you would extract from EXIF data
      return {
        'width': image.width,
        'height': image.height,
        'fileSize': bytes.length,
        'format': path.extension(filePath).substring(1),
        'checksum': _calculateChecksum(bytes),
      };
    } catch (e) {
      return null;
    }
  }
}

/// Factory class for creating certificate generators with different configurations
class CertificateGeneratorFactory {
  /// Create a standard certificate generator
  static CertificateGenerator createStandard({
    CertificateStyle? style,
    CertificateLayout? layout,
    OutputConfig? outputConfig,
    SecurityConfig? securityConfig,
  }) {
    return CertificateGenerator(
      template: StandardCertificateTemplate(
        style: style,
        layout: layout,
      ),
      outputConfig: outputConfig ?? const OutputConfig(),
      securityConfig: securityConfig ?? const SecurityConfig(),
    );
  }

  /// Create an elegant certificate generator
  static CertificateGenerator createElegant({
    CertificateStyle? style,
    CertificateLayout? layout,
    OutputConfig? outputConfig,
    SecurityConfig? securityConfig,
  }) {
    return CertificateGenerator(
      template: ElegantCertificateTemplate(
        style: style,
        layout: layout,
      ),
      outputConfig: outputConfig ?? const OutputConfig(),
      securityConfig: securityConfig ?? const SecurityConfig(),
    );
  }

  /// Create a high-quality certificate generator
  static CertificateGenerator createHighQuality({
    CertificateTemplate? template,
    SecurityConfig? securityConfig,
  }) {
    return CertificateGenerator(
      template: template ?? const StandardCertificateTemplate(),
      outputConfig: const OutputConfig(
        dpi: 600,
        quality: 100,
        format: 'jpg',
      ),
      securityConfig: securityConfig ?? const SecurityConfig(
        enableWatermark: true,
        enableDigitalSignature: true,
        embedMetadata: true,
        enableQRCode: true,
      ),
    );
  }
}