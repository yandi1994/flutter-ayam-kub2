
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(const KalkulatorAyamApp());
}

class KalkulatorAyamApp extends StatelessWidget {
  const KalkulatorAyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalkulator Ayam KUB',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController ayamController = TextEditingController(text: '30');
  final TextEditingController umurController = TextEditingController(text: '21');
  final TextEditingController produksiController = TextEditingController(text: '0');
  final TextEditingController hargaTelurController = TextEditingController(text: '2000');
  final TextEditingController bobotController = TextEditingController(text: '1.2');
  final TextEditingController hargaDagingController = TextEditingController(text: '40000');
  final TextEditingController hargaPakanController = TextEditingController(text: '4000');

  final Map<String,int> pakanPerUmur = {
    '0-4': 20, '5-8': 40, '9-12': 60, '13-16': 80, '17-20': 95, '21+': 110
  };

  int konsumsiEkor = 0;
  double totalPakan = 0;
  double pakanPagi = 0;
  double pakanSore = 0;
  double biayaBulanan = 0;
  double pendapatanTelur = 0;
  double pendapatanPedaging = 0;

  String kategoriUmur(int umur){
    if (umur <= 4) return '0-4';
    if (umur <= 8) return '5-8';
    if (umur <= 12) return '9-12';
    if (umur <= 16) return '13-16';
    if (umur <= 20) return '17-20';
    return '21+';
  }

  void hitung(){
    final int ayam = int.tryParse(ayamController.text) ?? 0;
    final int umur = int.tryParse(umurController.text) ?? 0;
    final double produksi = double.tryParse(produksiController.text) ?? 0;
    final double hargaTelur = double.tryParse(hargaTelurController.text) ?? 0;
    final double bobot = double.tryParse(bobotController.text) ?? 0;
    final double hargaDaging = double.tryParse(hargaDagingController.text) ?? 0;
    final double hargaPakan = double.tryParse(hargaPakanController.text) ?? 0;

    konsumsiEkor = pakanPerUmur[kategoriUmur(umur)] ?? 0;
    totalPakan = ayam * konsumsiEkor / 1000; // kg/day
    pakanPagi = totalPakan / 2;
    pakanSore = totalPakan / 2;
    biayaBulanan = totalPakan * 30 * hargaPakan;
    pendapatanTelur = ayam * produksi * hargaTelur * 30;
    pendapatanPedaging = ayam * bobot * hargaDaging;

    setState(() {});
  }

  Future<void> exportExcel() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.getRangeByName('A1').setText('Laporan Kalkulator Ayam KUB');
    sheet.getRangeByName('A2').setText('Jumlah Ayam');
    sheet.getRangeByName('B2').setNumber(double.tryParse(ayamController.text) ?? 0);
    sheet.getRangeByName('A3').setText('Umur (minggu)');
    sheet.getRangeByName('B3').setNumber(double.tryParse(umurController.text) ?? 0);
    sheet.getRangeByName('A4').setText('Konsumsi per ekor (gr/hari)');
    sheet.getRangeByName('B4').setNumber(konsumsiEkor.toDouble());
    sheet.getRangeByName('A5').setText('Total Pakan (kg/hari)');
    sheet.getRangeByName('B5').setNumber(totalPakan);
    sheet.getRangeByName('A6').setText('Pakan Pagi (kg)');
    sheet.getRangeByName('B6').setNumber(pakanPagi);
    sheet.getRangeByName('A7').setText('Pakan Sore (kg)');
    sheet.getRangeByName('B7').setNumber(pakanSore);
    sheet.getRangeByName('A8').setText('Biaya Bulanan (Rp)');
    sheet.getRangeByName('B8').setNumber(biayaBulanan);
    sheet.getRangeByName('A9').setText('Pendapatan Telur (Rp/bln)');
    sheet.getRangeByName('B9').setNumber(pendapatanTelur);
    sheet.getRangeByName('A10').setText('Pendapatan Pedaging (Rp)');
    sheet.getRangeByName('B10').setNumber(pendapatanPedaging);

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/Laporan_Ayam_KUB.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(path);
  }

  Future<void> exportPDF() async {
    final PdfDocument pdf = PdfDocument();
    final page = pdf.pages.add();
    page.graphics.drawString('Laporan Kalkulator Ayam KUB', PdfStandardFont(PdfFontFamily.helvetica, 18));
    final lines = [
      'Jumlah Ayam: ${ayamController.text}',
      'Umur (minggu): ${umurController.text}',
      'Konsumsi per ekor: $konsumsiEkor gr/hari',
      'Total Pakan (kg/hari): ${totalPakan.toStringAsFixed(2)}',
      'Pakan Pagi (kg): ${pakanPagi.toStringAsFixed(2)}',
      'Pakan Sore (kg): ${pakanSore.toStringAsFixed(2)}',
      'Biaya Bulanan (Rp): ${biayaBulanan.toStringAsFixed(0)}',
      'Pendapatan Telur (Rp/bln): ${pendapatanTelur.toStringAsFixed(0)}',
      'Pendapatan Pedaging (Rp): ${pendapatanPedaging.toStringAsFixed(0)}',
    ];
    double y = 40;
    for (var l in lines){
      page.graphics.drawString(l, PdfStandardFont(PdfFontFamily.helvetica,12), bounds: Rect.fromLTWH(0, y, 500, 20));
      y += 20;
    }
    final bytes = pdf.save();
    pdf.dispose();
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/Laporan_Ayam_KUB.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator Ayam KUB')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Input Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: ayamController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Ayam')),
            TextField(controller: umurController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Umur Ayam (minggu)')),
            TextField(controller: produksiController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Produksi Telur per Ekor per Hari (butir)', hintText: 'isi 0 jika tidak petelur')),
            TextField(controller: hargaTelurController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Telur (Rp/butir)')),
            TextField(controller: bobotController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bobot Rata-rata (kg/ekor)')),
            TextField(controller: hargaDagingController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Daging (Rp/kg)')),
            TextField(controller: hargaPakanController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Pakan (Rp/kg)')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: hitung, child: const Text('Hitung'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: exportExcel, child: const Text('Export Excel'))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: exportPDF, child: const Text('Export PDF'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: () async {
                hitung();
                final snack = ScaffoldMessenger.of(context);
                snack.showSnackBar(const SnackBar(content: Text('Hasil dihitung, cek layar')));
              }, child: const Text('Refresh'))),
            ]),
            const SizedBox(height: 16),
            if (totalPakan > 0) ...[
              Text('Konsumsi per ekor: \$konsumsiEkor gr/hari'),
            ],
            const SizedBox(height: 10),
            Text('Total pakan/hari: \${totalPakan.toStringAsFixed(2)} kg'),
            Text('Pakan pagi: \${pakanPagi.toStringAsFixed(2)} kg'),
            Text('Pakan sore: \${pakanSore.toStringAsFixed(2)} kg'),
            Text('Biaya bulanan: Rp \${biayaBulanan.toStringAsFixed(0)}'),
            Text('Pendapatan telur/bln: Rp \${pendapatanTelur.toStringAsFixed(0)}'),
            Text('Pendapatan pedaging: Rp \${pendapatanPedaging.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            SizedBox(height: 180, child: PieChart(PieChartData(sections: [
              PieChartSectionData(value: biayaBulanan, color: Colors.red, title: 'Pakan'),
              PieChartSectionData(value: pendapatanTelur, color: Colors.blue, title: 'Telur'),
              PieChartSectionData(value: pendapatanPedaging, color: Colors.green, title: 'Pedaging'),
            ])))
          ],
        ),
      ),
    );
  }
}
