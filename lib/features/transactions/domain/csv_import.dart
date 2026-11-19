import 'package:csv/csv.dart';

class CsvImportRow {
  const CsvImportRow({
    required this.date,
    required this.type,
    required this.amount,
    required this.categoryName,
    required this.paymentMethod,
    this.note,
  });

  final DateTime date;
  final String type;
  final int amount;
  final String categoryName;
  final String paymentMethod;
  final String? note;
}

class ParsedCsvImport {
  const ParsedCsvImport({required this.rows, required this.rejected});

  final List<CsvImportRow> rows;
  final List<String> rejected;
}

class CsvImportException implements Exception {
  const CsvImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

const csvImportHeaders = [
  'Tanggal',
  'Tipe',
  'Jumlah',
  'Kategori',
  'Catatan',
  'Metode Bayar',
];

const _monthNumbers = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'mei': 5,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'agu': 8,
  'aug': 8,
  'sep': 9,
  'okt': 10,
  'oct': 10,
  'nov': 11,
  'des': 12,
  'dec': 12,
};

const _typeByLabel = {
  'pemasukan': 'income',
  'pengeluaran': 'expense',
  'income': 'income',
  'expense': 'expense',
};

const _methodByLabel = {
  'tunai': 'cash',
  'debit': 'debit',
  'kredit': 'credit',
  'qris': 'qris',
  'e-wallet': 'ewallet',
  'lainnya': 'unknown',
  'cash': 'cash',
  'credit': 'credit',
  'ewallet': 'ewallet',
  'unknown': 'unknown',
};

ParsedCsvImport parseCatatUangCsv(String raw) {
  final normalized = raw.trim().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final table = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(normalized);
  if (table.isEmpty) {
    throw const CsvImportException('File CSV kosong.');
  }
  final header = table.first.map((cell) => cell.toString().trim()).toList();
  if (header.length < csvImportHeaders.length ||
      !_sameHeader(header)) {
    throw const CsvImportException(
      'Header CSV harus: Tanggal, Tipe, Jumlah, Kategori, Catatan, Metode Bayar.',
    );
  }

  final rows = <CsvImportRow>[];
  final rejected = <String>[];
  for (var i = 1; i < table.length; i++) {
    final line = table[i];
    if (line.every((cell) => cell.toString().trim().isEmpty)) continue;
    final parsed = _parseRow(line, i + 1);
    if (parsed is CsvImportRow) {
      rows.add(parsed);
    } else {
      rejected.add(parsed as String);
    }
  }
  return ParsedCsvImport(rows: rows, rejected: rejected);
}

bool _sameHeader(List<String> header) {
  for (var i = 0; i < csvImportHeaders.length; i++) {
    if (header[i].toLowerCase() != csvImportHeaders[i].toLowerCase()) {
      return false;
    }
  }
  return true;
}

Object _parseRow(List<dynamic> line, int lineNumber) {
  String cell(int index) =>
      index < line.length ? line[index].toString().trim() : '';

  final date = _parseDate(cell(0));
  final type = _typeByLabel[cell(1).toLowerCase()];
  final amount = int.tryParse(cell(2).replaceAll(RegExp(r'[^0-9]'), ''));
  final category = cell(3);
  final note = cell(4);
  final method = _methodByLabel[cell(5).toLowerCase()];

  if (date == null || type == null || amount == null || amount <= 0) {
    return 'Baris $lineNumber dilewati: tanggal, tipe, atau jumlah tidak valid.';
  }
  if (category.isEmpty) {
    return 'Baris $lineNumber dilewati: kategori kosong.';
  }
  if (method == null) {
    return 'Baris $lineNumber dilewati: metode bayar tidak dikenal.';
  }
  return CsvImportRow(
    date: date,
    type: type,
    amount: amount,
    categoryName: category,
    paymentMethod: method,
    note: note.isEmpty ? null : note,
  );
}

DateTime? _parseDate(String raw) {
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (iso != null) {
    return _validDate(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
    );
  }
  final local = RegExp(r'^(\d{1,2}) ([A-Za-z]{3}) (\d{4})$').firstMatch(raw);
  if (local == null) return null;
  final month = _monthNumbers[local.group(2)!.toLowerCase()];
  if (month == null) return null;
  return _validDate(int.parse(local.group(3)!), month, int.parse(local.group(1)!));
}

DateTime? _validDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}
