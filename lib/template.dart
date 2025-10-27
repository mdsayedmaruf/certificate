import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

/// Configuration class for certificate template styling
class CertificateStyle {
  final Color backgroundColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final Color accentColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final String primaryFont;
  final String secondaryFont;
  final double borderWidth;
  final double cornerRadius;
  final bool showWatermark;
  final String watermarkText;
  final Color watermarkColor;
  final bool useGradientBackground;
  final bool showShadow;
  final Color shadowColor;

  const CertificateStyle({
    this.backgroundColor = const Color(0xFFFFFFFF), // Pure white
    this.primaryTextColor = const Color(0xFF1E3A8A), // Modern deep blue
    this.secondaryTextColor = const Color(0xFF64748B), // Modern slate gray
    this.borderColor = const Color(0xFF3B82F6), // Modern blue
    this.accentColor = const Color(0xFF06B6D4), // Modern cyan accent
    this.gradientStartColor = const Color(0xFFF8FAFC), // Very light blue-gray
    this.gradientEndColor = const Color(0xFFFFFFFF), // Pure white
    this.primaryFont = 'sans-serif',
    this.secondaryFont = 'sans-serif',
    this.borderWidth = 4.0,
    this.cornerRadius = 16.0,
    this.showWatermark = true,
    this.watermarkText = 'CERTIFIED',
    this.watermarkColor = const Color(0x08000000), // Very subtle dark
    this.useGradientBackground = true,
    this.showShadow = true,
    this.shadowColor = const Color(0x10000000), // Subtle shadow
  });

  /// Modern elegant style with deeper blues
  static const CertificateStyle modernElegant = CertificateStyle(
    backgroundColor: Color(0xFFFFFFFF),
    primaryTextColor: Color(0xFF0F172A), // Very dark blue
    secondaryTextColor: Color(0xFF475569), // Medium slate
    borderColor: Color(0xFF1E40AF), // Deep blue
    accentColor: Color(0xFF0EA5E9), // Bright blue
    gradientStartColor: Color(0xFFEFF6FF), // Light blue tint
    gradientEndColor: Color(0xFFFFFFFF),
    borderWidth: 6.0,
    cornerRadius: 20.0,
    watermarkText: 'EXCELLENCE',
    watermarkColor: Color(0x06000000),
  );

  /// Minimalist modern style
  static const CertificateStyle modernMinimal = CertificateStyle(
    backgroundColor: Color(0xFFFFFFFF),
    primaryTextColor: Color(0xFF1F2937), // Dark gray
    secondaryTextColor: Color(0xFF6B7280), // Medium gray
    borderColor: Color(0xFF2563EB), // Clean blue
    accentColor: Color(0xFF3B82F6), // Standard blue
    gradientStartColor: Color(0xFFFBFCFE), // Almost white with blue hint
    gradientEndColor: Color(0xFFFFFFFF),
    borderWidth: 2.0,
    cornerRadius: 12.0,
    watermarkText: 'VERIFIED',
    watermarkColor: Color(0x04000000),
    useGradientBackground: false,
  );
}

/// Layout configuration for certificate elements positioning
class CertificateLayout {
  final double width;
  final double height;
  final EdgeInsets padding;
  final double headerHeight;
  final double footerHeight;
  final double logoSize;
  final double titleFontSize;
  final double nameFontSize;
  final double bodyFontSize;
  final double signatureFontSize;

  const CertificateLayout({
    this.width = 2480, // A4 width at 300 DPI
    this.height = 3508, // A4 height at 300 DPI
    this.padding = const EdgeInsets.all(120),
    this.headerHeight = 300,
    this.footerHeight = 400,
    this.logoSize = 150,
    this.titleFontSize = 96, // Increased from 72
    this.nameFontSize = 128, // Increased from 96
    this.bodyFontSize = 48, // Increased from 36
    this.signatureFontSize = 32, // Increased from 24
  });

  /// Get layout for US Letter size
  static const CertificateLayout letter = CertificateLayout(
    width: 2550, // Letter width at 300 DPI
    height: 3300, // Letter height at 300 DPI
    titleFontSize: 96, // Increased from 72
    nameFontSize: 128, // Increased from 96
    bodyFontSize: 48, // Increased from 36
    signatureFontSize: 32, // Increased from 24
  );
}

/// Data model for student information
class StudentInfo {
  final String name;
  final String id;
  final DateTime completionDate;
  final String email;

  const StudentInfo({
    required this.name,
    required this.id,
    required this.completionDate,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
    'completionDate': completionDate.toIso8601String(),
    'email': email,
  };

  factory StudentInfo.fromJson(Map<String, dynamic> json) => StudentInfo(
    name: json['name'],
    id: json['id'],
    completionDate: DateTime.parse(json['completionDate']),
    email: json['email'],
  );
}

/// Data model for course information
class CourseInfo {
  final String name;
  final String duration;
  final String instructor;
  final String institution;
  final String description;

  const CourseInfo({
    required this.name,
    required this.duration,
    required this.instructor,
    required this.institution,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'duration': duration,
    'instructor': instructor,
    'institution': institution,
    'description': description,
  };

  factory CourseInfo.fromJson(Map<String, dynamic> json) => CourseInfo(
    name: json['name'],
    duration: json['duration'],
    instructor: json['instructor'],
    institution: json['institution'],
    description: json['description'] ?? '',
  );
}

/// Base certificate template class
abstract class CertificateTemplate {
  final CertificateStyle style;
  final CertificateLayout layout;
  final String templateName;

  const CertificateTemplate({
    required this.style,
    required this.layout,
    required this.templateName,
  });

  /// Generate certificate image as bytes
  Future<Uint8List> generateCertificate({
    required StudentInfo student,
    required CourseInfo course,
    required String certificateId,
    String? logoPath,
  });

  /// Validate input data
  bool validateData(StudentInfo student, CourseInfo course) {
    if (student.name.trim().isEmpty) return false;
    if (student.id.trim().isEmpty) return false;
    if (course.name.trim().isEmpty) return false;
    if (course.instructor.trim().isEmpty) return false;
    if (course.institution.trim().isEmpty) return false;
    return true;
  }

  /// Create text painter for rendering text
  TextPainter createTextPainter({
    required String text,
    required TextStyle style,
    TextAlign textAlign = TextAlign.center,
    int? maxLines,
  }) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: maxLines,
    )..layout();
  }

  /// Draw watermark on canvas
  void drawWatermark(Canvas canvas, Size size) {
    if (!style.showWatermark) return;

    final paint = Paint()
      ..color = style.watermarkColor
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: style.watermarkColor,
      fontSize: layout.width * 0.08,
      fontWeight: FontWeight.bold,
      letterSpacing: 8,
    );

    final textPainter = createTextPainter(
      text: style.watermarkText,
      style: textStyle,
    );

    // Rotate and position watermark diagonally
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.3); // Rotate -17 degrees
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  /// Draw modern background with gradient
  void _drawModernBackground(Canvas canvas, Size size) {
    if (style.useGradientBackground) {
      // Create gradient background
      final gradient = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [style.gradientStartColor, style.gradientEndColor],
        [0.0, 1.0],
      );

      final backgroundPaint = Paint()
        ..shader = gradient;

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    } else {
      // Solid background
      final backgroundPaint = Paint()..color = style.backgroundColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    }

    // Add subtle shadow effect if enabled
    if (style.showShadow) {
      final shadowPaint = Paint()
        ..color = style.shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final shadowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          style.borderWidth + 4,
          style.borderWidth + 4,
          size.width - (style.borderWidth + 4) * 2,
          size.height - (style.borderWidth + 4) * 2,
        ),
        Radius.circular(style.cornerRadius),
      );

      canvas.drawRRect(shadowRect, shadowPaint);
    }
  }

  /// Draw modern decorative border
  void drawBorder(Canvas canvas, Size size) {
    // Main border with modern styling
    final borderPaint = Paint()
      ..color = style.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.borderWidth;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        style.borderWidth / 2,
        style.borderWidth / 2,
        size.width - style.borderWidth,
        size.height - style.borderWidth,
      ),
      Radius.circular(style.cornerRadius),
    );

    canvas.drawRRect(rect, borderPaint);

    // Modern accent line
    final accentPaint = Paint()
      ..color = style.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final accentRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        style.borderWidth + 12,
        style.borderWidth + 12,
        size.width - (style.borderWidth + 12) * 2,
        size.height - (style.borderWidth + 12) * 2,
      ),
      Radius.circular(style.cornerRadius - 8),
    );

    canvas.drawRRect(accentRect, accentPaint);
  }
}

/// Standard certificate template implementation with modern blue/white styling
class StandardCertificateTemplate extends CertificateTemplate {
  const StandardCertificateTemplate({
    CertificateStyle? style,
    CertificateLayout? layout,
  }) : super(
    style: style ?? const CertificateStyle(),
    layout: layout ?? const CertificateLayout(),
    templateName: 'Modern Standard Certificate',
  );

  @override
  Future<Uint8List> generateCertificate({
    required StudentInfo student,
    required CourseInfo course,
    required String certificateId,
    String? logoPath,
  }) async {
    if (!validateData(student, course)) {
      throw ArgumentError('Invalid student or course data');
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(layout.width, layout.height);

    // Draw modern background with gradient
    _drawModernBackground(canvas, size);

    // Draw border
    drawBorder(canvas, size);

    // Draw watermark
    drawWatermark(canvas, size);

    await _drawContent(canvas, size, student, course, certificateId, logoPath);

    final picture = recorder.endRecording();
    final image = await picture.toImage(layout.width.toInt(), layout.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  Future<void> _drawContent(
    Canvas canvas,
    Size size,
    StudentInfo student,
    CourseInfo course,
    String certificateId,
    String? logoPath,
  ) async {
    final contentArea = Rect.fromLTWH(
      layout.padding.left,
      layout.padding.top,
      size.width - layout.padding.horizontal,
      size.height - layout.padding.vertical,
    );

    double currentY = contentArea.top;

    // Draw header with logo and institution
    currentY = await _drawHeader(canvas, contentArea, course.institution, logoPath, currentY);

    // Draw certificate title
    currentY = _drawTitle(canvas, contentArea, currentY);

    // Draw student name
    currentY = _drawStudentName(canvas, contentArea, student.name, currentY);

    // Draw course completion text
    currentY = _drawCompletionText(canvas, contentArea, course, currentY);

    // Draw completion date
    currentY = _drawCompletionDate(canvas, contentArea, student.completionDate, currentY);

    // Draw footer with signatures and certificate ID
    _drawFooter(canvas, contentArea, course.instructor, certificateId, contentArea.bottom - layout.footerHeight);
  }

  Future<double> _drawHeader(
    Canvas canvas,
    Rect contentArea,
    String institution,
    String? logoPath,
    double startY,
  ) async {
    double currentY = startY;

    // Draw logo if provided
    if (logoPath != null) {
      // Logo drawing would be implemented here
      currentY += layout.logoSize + 40;
    }

    // Draw institution name
    final institutionStyle = TextStyle(
      color: style.primaryTextColor,
      fontSize: layout.bodyFontSize * 1.2,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );

    final institutionPainter = createTextPainter(
      text: institution.toUpperCase(),
      style: institutionStyle,
    );

    institutionPainter.paint(
      canvas,
      Offset(
        contentArea.center.dx - institutionPainter.width / 2,
        currentY,
      ),
    );

    return currentY + institutionPainter.height + 60;
  }

  double _drawTitle(Canvas canvas, Rect contentArea, double startY) {
    final titleStyle = TextStyle(
      color: style.primaryTextColor,
      fontSize: layout.titleFontSize,
      fontWeight: FontWeight.bold,
      letterSpacing: 4,
    );

    final titlePainter = createTextPainter(
      text: 'CERTIFICATE OF COMPLETION',
      style: titleStyle,
    );

    titlePainter.paint(
      canvas,
      Offset(
        contentArea.center.dx - titlePainter.width / 2,
        startY,
      ),
    );

    return startY + titlePainter.height + 80;
  }

  double _drawStudentName(Canvas canvas, Rect contentArea, String name, double startY) {
    final nameStyle = TextStyle(
      color: style.accentColor,
      fontSize: layout.nameFontSize,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );

    final namePainter = createTextPainter(
      text: name,
      style: nameStyle,
    );

    // Draw underline
    final underlinePaint = Paint()
      ..color = style.accentColor
      ..strokeWidth = 3;

    final underlineY = startY + namePainter.height + 10;
    canvas.drawLine(
      Offset(contentArea.center.dx - namePainter.width / 2 - 50, underlineY),
      Offset(contentArea.center.dx + namePainter.width / 2 + 50, underlineY),
      underlinePaint,
    );

    namePainter.paint(
      canvas,
      Offset(
        contentArea.center.dx - namePainter.width / 2,
        startY,
      ),
    );

    return underlineY + 60;
  }

  double _drawCompletionText(Canvas canvas, Rect contentArea, CourseInfo course, double startY) {
    final completionText = 'has successfully completed the course\n\n"${course.name}"\n\nDuration: ${course.duration}';
    
    final completionStyle = TextStyle(
      color: style.primaryTextColor,
      fontSize: layout.bodyFontSize,
      height: 1.5,
    );

    final completionPainter = createTextPainter(
      text: completionText,
      style: completionStyle,
      maxLines: 5,
    );

    completionPainter.paint(
      canvas,
      Offset(
        contentArea.center.dx - completionPainter.width / 2,
        startY,
      ),
    );

    return startY + completionPainter.height + 60;
  }

  double _drawCompletionDate(Canvas canvas, Rect contentArea, DateTime date, double startY) {
    final dateText = 'Completed on ${_formatDate(date)}';
    
    final dateStyle = TextStyle(
      color: style.secondaryTextColor,
      fontSize: layout.bodyFontSize * 0.9,
      fontStyle: FontStyle.italic,
    );

    final datePainter = createTextPainter(
      text: dateText,
      style: dateStyle,
    );

    datePainter.paint(
      canvas,
      Offset(
        contentArea.center.dx - datePainter.width / 2,
        startY,
      ),
    );

    return startY + datePainter.height + 40;
  }

  void _drawFooter(
    Canvas canvas,
    Rect contentArea,
    String instructor,
    String certificateId,
    double startY,
  ) {
    // Draw instructor signature
    final instructorStyle = TextStyle(
      color: style.primaryTextColor,
      fontSize: layout.signatureFontSize,
      fontWeight: FontWeight.w500,
    );

    final instructorPainter = createTextPainter(
      text: instructor,
      style: instructorStyle,
    );

    // Signature line
    final signatureLinePaint = Paint()
      ..color = style.primaryTextColor
      ..strokeWidth = 1;

    final signatureLineY = startY + 60;
    canvas.drawLine(
      Offset(contentArea.left + 100, signatureLineY),
      Offset(contentArea.left + 400, signatureLineY),
      signatureLinePaint,
    );

    instructorPainter.paint(
      canvas,
      Offset(contentArea.left + 100, signatureLineY + 10),
    );

    final instructorLabelPainter = createTextPainter(
      text: 'Instructor',
      style: instructorStyle.copyWith(
        fontSize: layout.signatureFontSize * 0.8,
        color: style.secondaryTextColor,
      ),
    );

    instructorLabelPainter.paint(
      canvas,
      Offset(contentArea.left + 100, signatureLineY + 40),
    );

    // Draw certificate ID
    final idStyle = TextStyle(
      color: style.secondaryTextColor,
      fontSize: layout.signatureFontSize * 0.7,
      fontFamily: 'monospace',
    );

    final idPainter = createTextPainter(
      text: 'Certificate ID: $certificateId',
      style: idStyle,
    );

    idPainter.paint(
      canvas,
      Offset(
        contentArea.right - idPainter.width,
        contentArea.bottom - idPainter.height,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Elegant certificate template with modern blue styling and decorative elements
class ElegantCertificateTemplate extends StandardCertificateTemplate {
  const ElegantCertificateTemplate({
    CertificateStyle? style,
    CertificateLayout? layout,
  }) : super(
    style: style ?? CertificateStyle.modernElegant,
    layout: layout ?? const CertificateLayout(),
  );

  @override
  void drawBorder(Canvas canvas, Size size) {
    super.drawBorder(canvas, size);
    
    // Add decorative corner elements
    _drawCornerDecorations(canvas, size);
  }

  void _drawCornerDecorations(Canvas canvas, Size size) {
    final decorationPaint = Paint()
      ..color = style.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final accentFillPaint = Paint()
      ..color = style.accentColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final cornerSize = 60.0;
    final margin = style.borderWidth + 30;

    // Top-left corner
    _drawCornerDecoration(canvas, Offset(margin, margin), cornerSize, decorationPaint, accentFillPaint);
    
    // Top-right corner
    canvas.save();
    canvas.translate(size.width - margin, margin);
    canvas.rotate(1.5708); // 90 degrees
    _drawCornerDecoration(canvas, Offset.zero, cornerSize, decorationPaint, accentFillPaint);
    canvas.restore();
    
    // Bottom-right corner
    canvas.save();
    canvas.translate(size.width - margin, size.height - margin);
    canvas.rotate(3.14159); // 180 degrees
    _drawCornerDecoration(canvas, Offset.zero, cornerSize, decorationPaint, accentFillPaint);
    canvas.restore();
    
    // Bottom-left corner
    canvas.save();
    canvas.translate(margin, size.height - margin);
    canvas.rotate(-1.5708); // -90 degrees
    _drawCornerDecoration(canvas, Offset.zero, cornerSize, decorationPaint, accentFillPaint);
    canvas.restore();
  }

  void _drawCornerDecoration(Canvas canvas, Offset center, double size, Paint strokePaint, Paint fillPaint) {
    // Create modern corner decoration with subtle fill
    final fillPath = Path();
    fillPath.moveTo(center.dx, center.dy);
    fillPath.lineTo(center.dx + size * 0.6, center.dy);
    fillPath.quadraticBezierTo(center.dx + size * 0.7, center.dy + size * 0.1, center.dx + size * 0.6, center.dy + size * 0.2);
    fillPath.lineTo(center.dx + size * 0.2, center.dy + size * 0.6);
    fillPath.quadraticBezierTo(center.dx + size * 0.1, center.dy + size * 0.7, center.dx, center.dy + size * 0.6);
    fillPath.close();
    
    // Draw fill first
    canvas.drawPath(fillPath, fillPaint);
    
    // Create stroke path for modern lines
    final strokePath = Path();
    strokePath.moveTo(center.dx, center.dy);
    strokePath.lineTo(center.dx + size, center.dy);
    strokePath.moveTo(center.dx, center.dy);
    strokePath.lineTo(center.dx, center.dy + size);
    
    // Add modern decorative elements
    strokePath.moveTo(center.dx + size * 0.3, center.dy);
    strokePath.quadraticBezierTo(center.dx + size * 0.4, center.dy + size * 0.1, center.dx + size * 0.3, center.dy + size * 0.3);
    strokePath.moveTo(center.dx, center.dy + size * 0.3);
    strokePath.quadraticBezierTo(center.dx + size * 0.1, center.dy + size * 0.4, center.dx + size * 0.3, center.dy + size * 0.3);
    
    canvas.drawPath(strokePath, strokePaint);
  }
}