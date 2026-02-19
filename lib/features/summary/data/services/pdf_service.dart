import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:medinote_ai/features/summary/domain/models/clinical_summary.dart';

class PDFService {
  Future<void> generateAndPrintSummary(ClinicalSummary summary) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'MediNoteAI - Clinical Summary',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Date: ${summary.visitDate.toString().split(' ')[0]}',
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Patient Info
              pw.Text(
                'Patient Name: ${summary.patientName}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Patient ID: ${summary.patientId}'),
              pw.SizedBox(height: 24),

              // SOAP Sections
              _buildPDFSection('Subjective', summary.soapSubjective),
              _buildPDFSection('Objective', summary.soapObjective),
              _buildPDFSection('Assessment', summary.soapAssessment),
              _buildPDFSection('Plan', summary.soapPlan),

              pw.SizedBox(height: 24),

              // Medical Entities
              pw.Text(
                'Extracted Entities:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: summary.entities
                    .map((e) => pw.Bullet(text: '${e.name} (${e.type})'))
                    .toList(),
              ),

              pw.SizedBox(height: 24),

              // Clinical Codes
              pw.Text(
                'Suggested Clinical Codes:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: summary.codes
                    .map(
                      (c) => pw.Bullet(
                        text: '${c.code}: ${c.description} (${c.system})',
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildPDFSection(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(content, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
