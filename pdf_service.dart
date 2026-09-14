import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class PdfService {
  final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final date = DateFormat('dd/MM/yyyy');

  Future<void> printCashReport(List<CashTransaction> txs) async {
    final doc = pw.Document();
    int income = 0;
    int expense = 0;
    for (final x in txs) {
      if (x.type == TransactionType.income) income += x.amount;
      else expense += x.amount;
    }

    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text('BUKU KAS WARGA', style: pw.TextStyle(fontSize: 20)),
          pw.SizedBox(height: 8),
          pw.Text('Dicetak: ${date.format(DateTime.now())}'),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            headers: ['Tanggal', 'Jenis', 'Kategori', 'Jumlah', 'Keterangan'],
            data: txs.map((x) => [
              date.format(x.date),
              x.type == TransactionType.income ? 'Masuk' : 'Keluar',
              x.category,
              money.format(x.amount),
              x.description,
            ]).toList(),
          ),
          pw.SizedBox(height: 15),
          pw.Text('Total masuk : ${money.format(income)}'),
          pw.Text('Total keluar: ${money.format(expense)}'),
          pw.Text('Saldo       : ${money.format(income - expense)}'),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}