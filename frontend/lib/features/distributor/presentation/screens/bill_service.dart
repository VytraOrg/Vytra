import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'distributor_models.dart';
import 'distributor_ui.dart' show formatInr, formatDateTime;

/// Builds a GST tax invoice and opens the system print / share dialog
/// (works with Bluetooth/Wi-Fi printers, "Save as PDF", WhatsApp share, etc.).
///
/// Needs:  flutter pub add pdf printing
class BillService {
  static Future<void> printBill(DistributorOrder order, DistributorProfile agency) {
    return Printing.layoutPdf(
      name: 'Bill_${order.id}',
      onLayout: (format) => buildBill(order, agency, format),
    );
  }

  /// "Rs." is used instead of ₹ because the built-in PDF font has no ₹ glyph.
  static String _rs(double v) => 'Rs. ${formatInr(v, symbol: false, decimals: 2)}';

  static Future<Uint8List> buildBill(DistributorOrder order, DistributorProfile agency, PdfPageFormat format) async {
    final doc = pw.Document();
    const brown = PdfColor.fromInt(0xFF4A2F1B);
    const light = PdfColor.fromInt(0xFFF6EDE4);

    pw.Widget kv(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(text: '$k: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.TextSpan(text: v, style: const pw.TextStyle(fontSize: 9)),
            ]),
          ),
        );

    pw.Widget totalRow(String k, String v, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(k, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null, fontSize: bold ? 12 : 10)),
            pw.Text(v, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null, fontSize: bold ? 12 : 10)),
          ]),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          // Agency header
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: const pw.BoxDecoration(color: brown, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(agency.agencyName,
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(agency.address, style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                  pw.Text('Ph: ${agency.phone}  |  ${agency.email}',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                ]),
              ),
              pw.Text('TAX INVOICE', style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: light,
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              kv('GSTIN', agency.gstNo),
              kv('FSSAI Lic.', agency.fssaiNo),
              kv('Trade Lic.', agency.tradeLicenseNo),
            ]),
          ),
          pw.SizedBox(height: 14),

          // Bill to + invoice meta
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(order.shopName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text('Owner: ${order.ownerName}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(order.address, style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Ph: ${order.phone}', style: const pw.TextStyle(fontSize: 9)),
              ]),
            ),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              kv('Invoice No', order.id),
              kv('Date', formatDateTime(order.placedAt)),
              kv('Status', order.status.label),
            ]),
          ]),
          pw.SizedBox(height: 14),

          // Items table
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Item', 'Unit', 'Qty', 'Rate', 'GST %', 'Amount'],
            data: [
              for (var i = 0; i < order.items.length; i++)
                [
                  '${i + 1}',
                  order.items[i].name,
                  order.items[i].unit,
                  '${order.items[i].qty}',
                  _rs(order.items[i].rate),
                  '${order.items[i].gstPercent.toStringAsFixed(0)}%',
                  _rs(order.items[i].amount),
                ],
            ],
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: brown),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
              6: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FixedColumnWidth(22),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1.1),
              3: const pw.FixedColumnWidth(32),
              4: const pw.FlexColumnWidth(1.4),
              5: const pw.FixedColumnWidth(38),
              6: const pw.FlexColumnWidth(1.6),
            },
            oddRowDecoration: const pw.BoxDecoration(color: light),
            border: null,
          ),
          pw.SizedBox(height: 12),

          // Totals
          pw.Row(children: [
            pw.Expanded(
              child: pw.Text('Total items: ${order.items.length}   |   Total qty: ${order.totalQty}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ),
            pw.SizedBox(
              width: 220,
              child: pw.Column(children: [
                totalRow('Taxable value', _rs(order.subtotal)),
                totalRow('CGST', _rs(order.gstTotal / 2)),
                totalRow('SGST', _rs(order.gstTotal / 2)),
                pw.Divider(color: brown),
                totalRow('Grand Total', _rs(order.grandTotal), bold: true),
              ]),
            ),
          ]),
          pw.SizedBox(height: 40),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Thank you for your business!', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Column(children: [
              pw.Container(width: 140, height: 0.8, color: PdfColors.grey600),
              pw.SizedBox(height: 4),
              pw.Text('For ${agency.agencyName}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Authorised Signatory', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ]),
          ]),
        ],
      ),
    );
    return doc.save();
  }
}
