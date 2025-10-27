import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:certificate_maker/template.dart';
import 'package:certificate_maker/certificate_generator.dart';

void main() {
  group('Certificate Template Tests', () {
    late StandardCertificateTemplate standardTemplate;
    late ElegantCertificateTemplate elegantTemplate;
    late StudentInfo testStudent;
    late CourseInfo testCourse;

    setUpAll(() {
      standardTemplate = const StandardCertificateTemplate();
      elegantTemplate = const ElegantCertificateTemplate();
      
      testStudent = StudentInfo(
        name: 'John Doe',
        id: 'STU001',
        completionDate: DateTime(2024, 1, 15),
        email: 'john.doe@example.com',
      );
      
      testCourse = const CourseInfo(
        name: 'Advanced Flutter Development',
        duration: '40 hours',
        instructor: 'Dr. Jane Smith',
        institution: 'Tech University',
        description: 'Comprehensive Flutter development course',
      );
    });

    test('Standard template should have correct default configuration', () {
      expect(standardTemplate.templateName, equals('Standard Certificate'));
      expect(standardTemplate.style.backgroundColor, equals(const Color(0xFFFFFFF8)));
      expect(standardTemplate.layout.width, equals(2480));
      expect(standardTemplate.layout.height, equals(3508));
    });

    test('Elegant template should have correct styling', () {
      expect(elegantTemplate.style.backgroundColor, equals(const Color(0xFFF8F8FF)));
      expect(elegantTemplate.style.borderColor, equals(const Color(0xFF4A4A4A)));
      expect(elegantTemplate.style.accentColor, equals(const Color(0xFF8B4513)));
    });

    test('Template should validate data correctly', () {
      expect(standardTemplate.validateData(testStudent, testCourse), isTrue);
      
      // Test invalid student data
      final invalidStudent = StudentInfo(
        name: '',
        id: 'STU001',
        completionDate: DateTime.now(),
        email: 'john.doe@example.com',
      );
      expect(standardTemplate.validateData(invalidStudent, testCourse), isFalse);
      
      // Test invalid course data
      const invalidCourse = CourseInfo(
        name: '',
        duration: '40 hours',
        instructor: 'Dr. Jane Smith',
        institution: 'Tech University',
      );
      expect(standardTemplate.validateData(testStudent, invalidCourse), isFalse);
    });

    test('Template should create text painter correctly', () {
      const testStyle = TextStyle(fontSize: 24, color: Colors.black);
      final textPainter = standardTemplate.createTextPainter(
        text: 'Test Text',
        style: testStyle,
      );
      
      expect(textPainter.text!.toPlainText(), equals('Test Text'));
      expect(textPainter.textDirection, equals(TextDirection.ltr));
      expect(textPainter.textAlign, equals(TextAlign.center));
    });

    test('Certificate layout should support different sizes', () {
      const defaultLayout = CertificateLayout();
      expect(defaultLayout.width, equals(2480));
      expect(defaultLayout.height, equals(3508));
      
      expect(CertificateLayout.letter.width, equals(2550));
      expect(CertificateLayout.letter.height, equals(3300));
    });
  });

  group('Student and Course Info Tests', () {
    test('StudentInfo should serialize and deserialize correctly', () {
      final student = StudentInfo(
        name: 'Alice Johnson',
        id: 'STU002',
        completionDate: DateTime(2024, 2, 20),
        email: 'alice@example.com',
      );
      
      final json = student.toJson();
      final deserializedStudent = StudentInfo.fromJson(json);
      
      expect(deserializedStudent.name, equals(student.name));
      expect(deserializedStudent.id, equals(student.id));
      expect(deserializedStudent.completionDate, equals(student.completionDate));
      expect(deserializedStudent.email, equals(student.email));
    });

    test('CourseInfo should serialize and deserialize correctly', () {
      const course = CourseInfo(
        name: 'Machine Learning Basics',
        duration: '60 hours',
        instructor: 'Prof. Bob Wilson',
        institution: 'AI Institute',
        description: 'Introduction to machine learning concepts',
      );
      
      final json = course.toJson();
      final deserializedCourse = CourseInfo.fromJson(json);
      
      expect(deserializedCourse.name, equals(course.name));
      expect(deserializedCourse.duration, equals(course.duration));
      expect(deserializedCourse.instructor, equals(course.instructor));
      expect(deserializedCourse.institution, equals(course.institution));
      expect(deserializedCourse.description, equals(course.description));
    });
  });

  group('Certificate Generator Tests', () {
    late CertificateGenerator generator;
    late StudentInfo validStudent;
    late CourseInfo validCourse;

    setUpAll(() {
      generator = CertificateGeneratorFactory.createStandard();
      
      validStudent = StudentInfo(
        name: 'Test Student',
        id: 'TEST001',
        completionDate: DateTime(2024, 1, 1),
        email: 'test@example.com',
      );
      
      validCourse = const CourseInfo(
        name: 'Test Course',
        duration: '10 hours',
        instructor: 'Test Instructor',
        institution: 'Test Institution',
      );
    });

    test('Generator should validate input data correctly', () async {
      // Valid data should not throw
      expect(
        () async => await generator.generateCertificate(
          student: validStudent,
          course: validCourse,
        ),
        returnsNormally,
      );
    });

    test('Generator should reject invalid student data', () async {
      final invalidStudent = StudentInfo(
        name: '', // Empty name
        id: 'TEST001',
        completionDate: DateTime.now(),
        email: 'invalid-email', // Invalid email
      );
      
      expect(
        () async => await generator.generateCertificate(
          student: invalidStudent,
          course: validCourse,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Generator should reject invalid course data', () async {
      const invalidCourse = CourseInfo(
        name: 'A', // Too short
        duration: '',
        instructor: '',
        institution: '',
      );
      
      expect(
        () async => await generator.generateCertificate(
          student: validStudent,
          course: invalidCourse,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Generator should create unique certificate IDs', () {
      final generator = CertificateGeneratorFactory.createStandard();
      
      // Generate multiple IDs and ensure they're unique
      final ids = <String>{};
      for (int i = 0; i < 10; i++) {
        final id = generator._generateCertificateId(validStudent, validCourse);
        expect(ids.contains(id), isFalse, reason: 'Certificate ID should be unique');
        ids.add(id);
      }
    });

    test('Generator should validate certificate ID format', () {
      final generator = CertificateGeneratorFactory.createStandard();
      
      // Valid IDs should not throw
      expect(() => generator._validateCertificateId('CERT-12345678-ABCD1234'), returnsNormally);
      
      // Invalid IDs should throw
      expect(() => generator._validateCertificateId(''), throwsA(isA<ValidationException>()));
      expect(() => generator._validateCertificateId('a'), throwsA(isA<ValidationException>()));
      expect(() => generator._validateCertificateId('invalid@id'), throwsA(isA<ValidationException>()));
    });

    test('Output configuration should validate correctly', () {
      const validConfig = OutputConfig(dpi: 300, quality: 95, format: 'jpg');
      expect(validConfig.isValid(), isTrue);
      
      const invalidDpiConfig = OutputConfig(dpi: 50, quality: 95, format: 'jpg');
      expect(invalidDpiConfig.isValid(), isFalse);
      
      const invalidQualityConfig = OutputConfig(dpi: 300, quality: 150, format: 'jpg');
      expect(invalidQualityConfig.isValid(), isFalse);
      
      const invalidFormatConfig = OutputConfig(dpi: 300, quality: 95, format: 'bmp');
      expect(invalidFormatConfig.isValid(), isFalse);
    });
  });

  group('Certificate Generator Factory Tests', () {
    test('Factory should create standard generator correctly', () {
      final generator = CertificateGeneratorFactory.createStandard();
      expect(generator.template, isA<StandardCertificateTemplate>());
      expect(generator.outputConfig.dpi, equals(300));
      expect(generator.outputConfig.quality, equals(95));
    });

    test('Factory should create elegant generator correctly', () {
      final generator = CertificateGeneratorFactory.createElegant();
      expect(generator.template, isA<ElegantCertificateTemplate>());
    });

    test('Factory should create high-quality generator correctly', () {
      final generator = CertificateGeneratorFactory.createHighQuality();
      expect(generator.outputConfig.dpi, equals(600));
      expect(generator.outputConfig.quality, equals(100));
      expect(generator.securityConfig.enableWatermark, isTrue);
      expect(generator.securityConfig.enableDigitalSignature, isTrue);
    });
  });

  group('Integration Tests', () {
    test('End-to-end certificate generation with various inputs', () async {
      final generator = CertificateGeneratorFactory.createStandard(
        outputConfig: const OutputConfig(
          dpi: 150, // Lower DPI for faster testing
          quality: 80,
          format: 'jpg',
        ),
      );

      final testCases = [
        {
          'student': StudentInfo(
            name: 'María García',
            id: 'INT001',
            completionDate: DateTime(2024, 3, 15),
            email: 'maria.garcia@example.com',
          ),
          'course': const CourseInfo(
            name: 'International Business Management',
            duration: '120 hours',
            instructor: 'Prof. International',
            institution: 'Global University',
          ),
        },
        {
          'student': StudentInfo(
            name: 'Ahmed Al-Rashid',
            id: 'AR2024',
            completionDate: DateTime(2024, 1, 30),
            email: 'ahmed.rashid@example.com',
          ),
          'course': const CourseInfo(
            name: 'Advanced Data Science',
            duration: '80 hours',
            instructor: 'Dr. Data Scientist',
            institution: 'Tech Institute',
          ),
        },
        {
          'student': StudentInfo(
            name: '李小明',
            id: 'CN001',
            completionDate: DateTime(2024, 2, 14),
            email: 'xiaoming.li@example.com',
          ),
          'course': const CourseInfo(
            name: 'Artificial Intelligence Fundamentals',
            duration: '100 hours',
            instructor: 'Prof. AI Expert',
            institution: 'Future Tech University',
          ),
        },
      ];

      for (final testCase in testCases) {
        final result = await generator.generateCertificate(
          student: testCase['student'] as StudentInfo,
          course: testCase['course'] as CourseInfo,
        );

        expect(result.certificateId, isNotEmpty);
        expect(result.filePath, isNotEmpty);
        expect(result.fileSize, greaterThan(0));
        expect(result.checksum, isNotEmpty);
        expect(result.metadata, isNotEmpty);

        // Verify file exists
        final file = File(result.filePath);
        expect(await file.exists(), isTrue);

        // Verify file size matches
        final actualSize = await file.length();
        expect(actualSize, equals(result.fileSize));

        // Clean up test file
        await file.delete();
      }
    });

    test('Certificate verification should work correctly', () async {
      final generator = CertificateGeneratorFactory.createStandard();
      
      final student = StudentInfo(
        name: 'Verification Test',
        id: 'VER001',
        completionDate: DateTime.now(),
        email: 'verify@example.com',
      );
      
      const course = CourseInfo(
        name: 'Verification Course',
        duration: '5 hours',
        instructor: 'Test Instructor',
        institution: 'Test Institution',
      );

      final result = await generator.generateCertificate(
        student: student,
        course: course,
      );

      // Verify with correct checksum
      final isValid = await generator.verifyCertificate(
        result.filePath,
        result.checksum,
      );
      expect(isValid, isTrue);

      // Verify with incorrect checksum
      final isInvalid = await generator.verifyCertificate(
        result.filePath,
        'invalid_checksum',
      );
      expect(isInvalid, isFalse);

      // Clean up
      await File(result.filePath).delete();
    });

    test('Certificate info extraction should work', () async {
      final generator = CertificateGeneratorFactory.createStandard();
      
      final student = StudentInfo(
        name: 'Info Test',
        id: 'INFO001',
        completionDate: DateTime.now(),
        email: 'info@example.com',
      );
      
      const course = CourseInfo(
        name: 'Info Course',
        duration: '3 hours',
        instructor: 'Info Instructor',
        institution: 'Info Institution',
      );

      final result = await generator.generateCertificate(
        student: student,
        course: course,
      );

      final info = await generator.getCertificateInfo(result.filePath);
      expect(info, isNotNull);
      expect(info!['width'], greaterThan(0));
      expect(info['height'], greaterThan(0));
      expect(info['fileSize'], equals(result.fileSize));
      expect(info['checksum'], equals(result.checksum));

      // Clean up
      await File(result.filePath).delete();
    });
  });

  group('Error Handling Tests', () {
    test('Should handle file system permission errors gracefully', () async {
      final generator = CertificateGeneratorFactory.createStandard(
        outputConfig: const OutputConfig(
          outputDirectory: '/invalid/path/that/does/not/exist',
        ),
      );

      final student = StudentInfo(
        name: 'Permission Test',
        id: 'PERM001',
        completionDate: DateTime.now(),
        email: 'perm@example.com',
      );
      
      const course = CourseInfo(
        name: 'Permission Course',
        duration: '1 hour',
        instructor: 'Permission Instructor',
        institution: 'Permission Institution',
      );

      expect(
        () async => await generator.generateCertificate(
          student: student,
          course: course,
        ),
        throwsA(isA<CertificateGenerationException>()),
      );
    });

    test('Should handle invalid image data gracefully', () {
      // This would test image processing error handling
      // Implementation would depend on specific error scenarios
    });

    test('Should validate edge cases in input data', () async {
      final generator = CertificateGeneratorFactory.createStandard();

      // Test very long names
      final longNameStudent = StudentInfo(
        name: 'A' * 200, // Very long name
        id: 'LONG001',
        completionDate: DateTime.now(),
        email: 'long@example.com',
      );
      
      const course = CourseInfo(
        name: 'Test Course',
        duration: '1 hour',
        instructor: 'Test Instructor',
        institution: 'Test Institution',
      );

      expect(
        () async => await generator.generateCertificate(
          student: longNameStudent,
          course: course,
        ),
        throwsA(isA<ValidationException>()),
      );

      // Test future completion date
      final futureStudent = StudentInfo(
        name: 'Future Test',
        id: 'FUT001',
        completionDate: DateTime.now().add(const Duration(days: 1)),
        email: 'future@example.com',
      );

      expect(
        () async => await generator.generateCertificate(
          student: futureStudent,
          course: course,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}