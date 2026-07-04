import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';
import 'inspection_session.dart';

class ReportPdfService {
  ReportPdfService._();

  static Future<void> openCriticalIssuesReport(
    List<InspectionArea> areas,
  ) async {
    final bytes = await buildCriticalIssuesReport(areas);
    await Printing.layoutPdf(
      name: 'kepr-critical-issues-report.pdf',
      onLayout: (_) async => bytes,
    );
  }

  static Future<void> openCompleteReport(List<InspectionArea> areas) async {
    final bytes = await buildCompleteReport(areas);
    await Printing.layoutPdf(
      name: 'kepr-complete-inspection-report.pdf',
      onLayout: (_) async => bytes,
    );
  }

  static Future<Uint8List> buildCriticalIssuesReport(
    List<InspectionArea> areas,
  ) async {
    final criticalRows = _itemsWithArea(areas)
        .where(
          (row) =>
              row.item.completed &&
              (row.item.severity ?? '').toLowerCase() == 'critical',
        )
        .toList();
    return _buildReport(
      title: 'Kepr Critical Issues Report',
      rows: criticalRows,
      includeAllChecks: false,
    );
  }

  static Future<Uint8List> buildCompleteReport(List<InspectionArea> areas) {
    return _buildReport(
      title: 'Home Inspection Report',
      rows: _itemsWithArea(areas).toList(),
      includeAllChecks: true,
    );
  }

  static Future<Uint8List> _buildReport({
    required String title,
    required List<_ReportRow> rows,
    required bool includeAllChecks,
  }) async {
    final document = pw.Document();
    final completed = rows.where((row) => row.item.completed).length;
    final logo = await _loadLogo();
    final photoImages = await _loadPhotoImages(rows);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildHeader(
            logo: logo,
            title: title,
            completed: completed,
            total: rows.length,
          ),
          pw.SizedBox(height: 12),
          _buildPropertySummary(completed: completed, total: rows.length),
          pw.SizedBox(height: 14),
          if (rows.isEmpty)
            pw.Text(
              includeAllChecks
                  ? 'No inspection checks available.'
                  : 'No critical issues found.',
            )
          else
            ..._buildSectionTables(rows, photoImages),
        ],
      ),
    );

    return document.save();
  }

  static Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final bytes =
          await rootBundle.load('assets/brand/kepr_homecare_logo_icon.png');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, List<pw.MemoryImage>>> _loadPhotoImages(
    List<_ReportRow> rows,
  ) async {
    final images = <String, List<pw.MemoryImage>>{};
    for (final row in rows) {
      final loaded = <pw.MemoryImage>[];
      final currentPhotoPaths = _currentPhotoPaths(row.item);
      for (final photoUrl in currentPhotoPaths.take(4)) {
        final uri = Uri.tryParse(photoUrl);
        if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
          continue;
        }
        try {
          final data = await NetworkAssetBundle(uri).load('');
          loaded.add(pw.MemoryImage(data.buffer.asUint8List()));
        } catch (_) {
          // If a photo cannot be fetched, skip it so PDF generation still works.
        }
      }
      if (InspectionSession.inspectionId == null ||
          currentPhotoPaths.isNotEmpty) {
        for (final base64Image
            in row.item.photoEvidenceBase64.take(4 - loaded.length)) {
          try {
            loaded.add(pw.MemoryImage(base64Decode(base64Image)));
          } catch (_) {
            // Ignore malformed local evidence.
          }
        }
      }
      if (loaded.isNotEmpty) {
        images[_rowKey(row)] = loaded;
      }
    }
    return images;
  }

  static pw.Widget _buildHeader({
    required pw.MemoryImage? logo,
    required String title,
    required int completed,
    required int total,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(18, 10, 14, 10),
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EA6157')),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (logo != null) ...[
            pw.SizedBox(width: 12),
            pw.Container(
              width: 54,
              height: 42,
              padding: const pw.EdgeInsets.all(4),
              color: PdfColors.white,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          ] else ...[
            pw.SizedBox(width: 12),
            pw.Container(
              width: 64,
              height: 42,
              alignment: pw.Alignment.center,
              color: PdfColors.white,
              child: pw.Text(
                'KEPR',
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#0F172A'),
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildPropertySummary({
    required int completed,
    required int total,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
      ),
      child: pw.Column(
        children: [
          pw.Row(children: [
            _summaryCell(
                'Inspector Name', InspectionSession.inspectorName ?? '-'),
            _summaryCell('Inspection Date', _dateText(DateTime.now())),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            _summaryCell('Property', InspectionSession.societyName ?? '-'),
            _summaryCell(
              InspectionSession.isIndividualInspection
                  ? 'Owner Mobile'
                  : InspectionSession.isSocietyInspection
                      ? 'Inspection Scope'
                      : 'Flat / Block',
              InspectionSession.isIndividualInspection
                  ? InspectionSession.propertyOwnerMobile ?? '-'
                  : InspectionSession.flatNumber ?? '-',
            ),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            _summaryCell(
              InspectionSession.isIndividualInspection
                  ? 'Property Owner'
                  : 'Inspection Code',
              InspectionSession.isIndividualInspection
                  ? InspectionSession.propertyOwnerName ?? '-'
                  : InspectionSession.inspectionCode ??
                      InspectionSession.keprId ??
                      '-',
            ),
            _summaryCell('Checks Completed', '$completed / $total'),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _summaryCell(String label, String value) {
    return pw.Expanded(
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#111827'),
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
            ),
          ],
        ),
      ),
    );
  }

  static List<pw.Widget> _buildSectionTables(
    List<_ReportRow> rows,
    Map<String, List<pw.MemoryImage>> photoImages,
  ) {
    final grouped = <String, List<_ReportRow>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.item.category, () => []).add(row);
    }

    final widgets = <pw.Widget>[];
    for (final entry in grouped.entries) {
      widgets
        ..add(_sectionTitle(entry.key))
        ..add(_sectionTable(entry.value, photoImages))
        ..add(pw.SizedBox(height: 12));
    }
    return widgets;
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      color: PdfColors.black,
      child: pw.Text(
        title.isEmpty ? 'Inspection Findings' : _clean(title),
        style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
      ),
    );
  }

  static pw.Widget _sectionTable(
    List<_ReportRow> rows,
    Map<String, List<pw.MemoryImage>> photoImages,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.45),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.55),
        1: pw.FlexColumnWidth(2.05),
        2: pw.FlexColumnWidth(0.85),
        3: pw.FlexColumnWidth(0.75),
        4: pw.FlexColumnWidth(1.95),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey600),
          children: [
            _headerCell('Sr. No.'),
            _headerCell('Description of Issue'),
            _headerCell('Area / Room'),
            _headerCell('Impact'),
            _headerCell('Photo'),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.top,
            children: [
              _textCell('${i + 1}', align: pw.TextAlign.center),
              _textCell(_descriptionText(rows[i].item)),
              _textCell(rows[i].area.name),
              _textCell(_impactText(rows[i].item), align: pw.TextAlign.center),
              _photoCell(rows[i], photoImages[_rowKey(rows[i])] ?? const []),
            ],
          ),
      ],
    );
  }

  static pw.Widget _headerCell(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _textCell(
    String value, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        value.isEmpty ? '-' : value,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 7.4),
      ),
    );
  }

  static pw.Widget _photoCell(_ReportRow row, List<pw.MemoryImage> images) {
    final currentPhotoPaths = _currentPhotoPaths(row.item);
    if (images.isEmpty) {
      return _textCell(currentPhotoPaths.isEmpty ? '-' : 'Photo uploaded');
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            height: 126,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.4),
            ),
            child: _photoGrid(images),
          ),
          if (currentPhotoPaths.length > 1)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                '+${currentPhotoPaths.length - 1} more photo(s)',
                textAlign: pw.TextAlign.right,
                style:
                    const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _photoGrid(List<pw.MemoryImage> images) {
    final visible = images.take(4).toList(growable: false);
    if (visible.length == 1) {
      return pw.Image(visible.first, fit: pw.BoxFit.cover);
    }

    if (visible.length == 2) {
      return pw.Row(
        children: [
          pw.Expanded(child: pw.Image(visible[0], fit: pw.BoxFit.cover)),
          pw.SizedBox(width: 1),
          pw.Expanded(child: pw.Image(visible[1], fit: pw.BoxFit.cover)),
        ],
      );
    }

    if (visible.length == 3) {
      return pw.Column(
        children: [
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Image(visible[0], fit: pw.BoxFit.cover)),
                pw.SizedBox(width: 1),
                pw.Expanded(child: pw.Image(visible[1], fit: pw.BoxFit.cover)),
              ],
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Expanded(child: pw.Image(visible[2], fit: pw.BoxFit.cover)),
        ],
      );
    }

    return pw.Column(
      children: [
        pw.Expanded(
          child: pw.Row(
            children: [
              pw.Expanded(child: pw.Image(visible[0], fit: pw.BoxFit.cover)),
              pw.SizedBox(width: 1),
              pw.Expanded(child: pw.Image(visible[1], fit: pw.BoxFit.cover)),
            ],
          ),
        ),
        pw.SizedBox(height: 1),
        pw.Expanded(
          child: pw.Row(
            children: [
              pw.Expanded(child: pw.Image(visible[2], fit: pw.BoxFit.cover)),
              pw.SizedBox(width: 1),
              pw.Expanded(child: pw.Image(visible[3], fit: pw.BoxFit.cover)),
            ],
          ),
        ),
      ],
    );
  }

  static String _dateText(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  static Iterable<_ReportRow> _itemsWithArea(List<InspectionArea> areas) sync* {
    for (final area in areas) {
      for (final item in area.items) {
        yield _ReportRow(area, item);
      }
    }
  }

  static String _clean(String value) {
    return value
        .replaceAll(RegExp(r'[\u2010-\u2015\u2212]'), '-')
        .replaceAll(RegExp(r'[\u2018\u2019]'), "'")
        .replaceAll(RegExp(r'[\u201C\u201D]'), '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _descriptionText(InspectionItem item) {
    final notes = (item.notes ?? '').trim();
    final parts = <String>[
      notes.isNotEmpty ? _clean(notes) : _clean(item.name),
    ];
    final service = _serviceNames(item);
    if (service != '-') {
      parts.add('Service: $service');
    }
    return parts.join('\n');
  }

  static List<String> _currentPhotoPaths(InspectionItem item) {
    final inspectionId = InspectionSession.inspectionId;
    if (inspectionId == null || inspectionId.isEmpty) {
      return item.photoPaths;
    }
    final marker = '/$inspectionId/';
    final encodedMarker = '%2F$inspectionId%2F';
    return item.photoPaths
        .where((path) => path.contains(marker) || path.contains(encodedMarker))
        .toList(growable: false);
  }

  static String _impactText(InspectionItem item) {
    final severity = (item.severity ?? '').trim();
    if (severity.isEmpty) return 'NA';
    if (severity == 'no_issue') return 'No issues';
    return severity[0].toUpperCase() + severity.substring(1).toLowerCase();
  }

  static String _serviceNames(InspectionItem item) {
    if (item.selectedServices.isNotEmpty) {
      return item.selectedServices.map((service) => service.name).join(', ');
    }
    return item.serviceCode ?? '-';
  }

  static String _rowKey(_ReportRow row) {
    return '${row.area.id}:${row.item.id}';
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.indigo900)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Home Inspection Report | KEPR | Confidential',
              style: const pw.TextStyle(fontSize: 7),
            ),
          ),
          pw.Text(
            '${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ],
      ),
    );
  }
}

class _ReportRow {
  final InspectionArea area;
  final InspectionItem item;

  const _ReportRow(this.area, this.item);
}
