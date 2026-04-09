import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/real_estate/real_estate_sale_model.dart';
import '../models/real_estate/installment_model.dart';
import '../providers/customer_provider.dart';

class RealEstateLedgerExportService {
  static Future<String?> exportLedger({
    required RealEstateSale sale,
    required Customer customer,
    required List<RealEstateInstallment> installments,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      
      final f = NumberFormat("#,##0.00", "en_US");
      String fd(String? d) {
        if (d == null || d.isEmpty) return '';
        try {
          final dt = DateTime.parse(d);
          return DateFormat('d MMM yy').format(dt);
        } catch (_) { return d; }
      }

      // Widths
      sheet.setColWidth(0, 18); // A
      sheet.setColWidth(1, 20); // B
      sheet.setColWidth(2, 20); // C
      sheet.setColWidth(3, 20); // D

      CellStyle hStyle = CellStyle(bold: true, fontSize: 14, horizontalAlign: HorizontalAlign.Center, leftBorder: Border(borderStyle: BorderStyle.Thick), rightBorder: Border(borderStyle: BorderStyle.Thick), topBorder: Border(borderStyle: BorderStyle.Thick), bottomBorder: Border(borderStyle: BorderStyle.Thick));
      CellStyle sStyle = CellStyle(bold: true, fontSize: 11, horizontalAlign: HorizontalAlign.Center);
      CellStyle bld = CellStyle(bold: true, fontSize: 10);
      CellStyle nrm = CellStyle(fontSize: 10);
      CellStyle und = CellStyle(fontSize: 10, bottomBorder: Border(borderStyle: BorderStyle.Thin));
      CellStyle rgt = CellStyle(fontSize: 10, horizontalAlign: HorizontalAlign.Right);
      CellStyle tHead = CellStyle(bold: true, fontSize: 9, leftBorder: Border(borderStyle: BorderStyle.Thin), rightBorder: Border(borderStyle: BorderStyle.Thin), topBorder: Border(borderStyle: BorderStyle.Thin), bottomBorder: Border(borderStyle: BorderStyle.Thin));
      CellStyle tCell = CellStyle(fontSize: 9, leftBorder: Border(borderStyle: BorderStyle.Thin), rightBorder: Border(borderStyle: BorderStyle.Thin), topBorder: Border(borderStyle: BorderStyle.Thin), bottomBorder: Border(borderStyle: BorderStyle.Thin));
      CellStyle tCellR = CellStyle(fontSize: 9, horizontalAlign: HorizontalAlign.Right, leftBorder: Border(borderStyle: BorderStyle.Thin), rightBorder: Border(borderStyle: BorderStyle.Thin), topBorder: Border(borderStyle: BorderStyle.Thin), bottomBorder: Border(borderStyle: BorderStyle.Thin));
      CellStyle boxStyle = CellStyle(bold: true, fontSize: 11, horizontalAlign: HorizontalAlign.Right, leftBorder: Border(borderStyle: BorderStyle.Thick), rightBorder: Border(borderStyle: BorderStyle.Thick), topBorder: Border(borderStyle: BorderStyle.Thick), bottomBorder: Border(borderStyle: BorderStyle.Thick));

      // Row 1: Header
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0));
      var c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      c0.value = 'ELITE HOMES';
      c0.cellStyle = hStyle;

      // Rows 2-13
      void _p(int r, String l, String v, [CellStyle? s]) {
        var cl = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r));
        cl.value = l; cl.cellStyle = bld;
        var cv = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r));
        cv.value = v; cv.cellStyle = s ?? nrm;
      }
      _p(1, 'Reg No#', sale.registrationNumber ?? '');
      _p(2, 'Date', fd(sale.saleDate));
      _p(3, 'Name', customer.name);
      _p(4, 'F/Name', customer.fatherName ?? '');
      _p(5, 'Contact No#', customer.phone, und);
      _p(6, 'CNIC No#', customer.cnic ?? '', und);
      _p(7, 'Address', customer.address ?? '', und);
      _p(8, 'Block Name', sale.projectName ?? '');
      _p(9, 'Plot No#', sale.plotNumber ?? '');
      _p(10, 'Plot Size', sale.plotSize ?? '');
      _p(11, 'Cutting %', '');
      _p(12, 'Commercial', 'NO');

      // Row 14: PLAN
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 13), CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 13));
      var s14 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 13));
      s14.value = 'Installment PLAN';
      s14.cellStyle = sStyle;

      void _pL(int r, String l, double a) {
        var cl = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r));
        cl.value = l; cl.cellStyle = bld;
        var cv = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r));
        cv.value = a > 0 ? f.format(a) : ''; cv.cellStyle = rgt;
      }
      _pL(14, 'Booking', sale.downPayment);
      _pL(15, 'Allocation', 0);
      _pL(16, 'Confirmation', 0);
      _pL(17, 'Installments', sale.totalPrice - sale.downPayment);
      _pL(18, 'Possession', 0);
      _pL(19, 'Last Payment', 0);
      _pL(20, 'Discounts', 0);
      _pL(21, 'Add Extra', 0);

      // Row 23: Total
      var l23 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 22));
      l23.value = 'Total'; l23.cellStyle = bld;
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 22), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 22));
      var v23 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 22));
      v23.value = f.format(sale.totalPrice); v23.cellStyle = boxStyle;

      // Row 25: Receipts
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 24), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 24));
      var s25 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 24));
      s25.value = "Receipt's / Payment Detail";
      s25.cellStyle = sStyle;

      final hs = ['Receipt No#', 'Installment Date', 'Amount', 'Rem/Balance'];
      for (int i = 0; i < 4; i++) {
        var ch = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 25));
        ch.value = hs[i]; ch.cellStyle = tHead;
      }

      double paidTotal = sale.receivedDownPayment;
      double remBal = sale.totalPrice - paidTotal;
      void _setR(int r, String no, String dte, double amt, double bal) {
        var c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r));
        c0.value = no; c0.cellStyle = tCell;
        var c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r));
        c1.value = dte; c1.cellStyle = tCell;
        var c2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r));
        c2.value = amt > 0 ? f.format(amt) : ''; c2.cellStyle = tCellR;
        var c3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r));
        c3.value = f.format(bal); c3.cellStyle = tCellR;
      }

      _setR(26, '0001', fd(sale.saleDate), sale.receivedDownPayment, remBal);
      int curR = 27;
      final pInsts = installments.where((i) => i.paidAmount > 0).toList();
      for (var inst in pInsts) {
        if (curR > 35) break; 
        paidTotal += inst.paidAmount;
        remBal -= inst.paidAmount;
        _setR(curR, (curR - 25).toString().padLeft(4, '0'), fd(inst.paidDate ?? inst.dueDate), inst.paidAmount, remBal);
        curR++;
      }
      while (curR <= 35) {
        for (int i = 0; i < 3; i++) sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: curR)).cellStyle = tCell;
        var bCol = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: curR));
        bCol.value = f.format(remBal); bCol.cellStyle = tCellR;
        curR++;
      }

      // Row 37: Final Total
      var l37 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 36));
      l37.value = 'Total'; l37.cellStyle = bld;
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 36), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 36));
      var v37 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 36));
      v37.value = f.format(paidTotal); v37.cellStyle = boxStyle;

      final dir = await _getExportDirectory();
      if (dir == null) return null;
      final path = '${dir.path}/Executive_Statement_${sale.registrationNumber ?? sale.id}.xlsx';
      await File(path).writeAsBytes(excel.encode()!);
      return path;
    } catch (_) { return null; }
  }


  static Future<Directory?> _getExportDirectory() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return await getDownloadsDirectory();
      } else {
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      return null;
    }
  }

  static Future<void> openFile(String path) async {
    await OpenFile.open(path);
  }
}
