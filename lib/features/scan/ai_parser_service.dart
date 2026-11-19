import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/constants.dart';
import '../settings/domain/ai_provider_config.dart';
import 'quick_parser.dart';

class AiParseResult {
  final String? storeName;
  final String? date;
  final int? totalAmount;
  final List<Map<String, dynamic>> items;
  final String? paymentMethod;
  final String? suggestedCategory;
  final bool isReceipt;
  final String? raw;

  AiParseResult({
    this.storeName,
    this.date,
    this.totalAmount,
    this.items = const [],
    this.paymentMethod,
    this.suggestedCategory,
    this.isReceipt = true,
    this.raw,
  });
}

class AiParserService {
  Future<AiParseResult> parseReceipt(
    String ocrText, {
    List<String> categories = const [],
  }) async {
    final config = await AiConfigStorage.load();
    final apiKey = config.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key belum diatur. Silakan isi di Setelan.');
    }
    if (config.apiUrl.isEmpty || config.model.isEmpty) {
      throw Exception('Endpoint atau model AI belum diisi di Setelan.');
    }

    final categoryHint = categories.isNotEmpty
        ? '- category harus salah satu dari: ${categories.join(', ')} (atau null jika tidak cocok)'
        : '- category: nama kategori pengeluaran yang paling sesuai (atau null)';

    final prompt = '''
Kamu adalah parser struk belanja Indonesia.
Dari teks OCR hasil scan struk berikut, ekstrak data dalam format JSON.
Aturan:
- amount dalam Rupiah (integer, tanpa titik/koma)
- date dalam format YYYY-MM-DD
$categoryHint
- Jika tidak yakin, isi null
- Hanya kembalikan JSON, tanpa teks lain.
- Jangan mengarang data. Jika tidak ada, null.

{
  "store_name": "string | null",
  "date": "YYYY-MM-DD | null",
  "total_amount": "integer | null",
  "items": [
    {"name": "string", "price": "integer", "qty": "integer"}
  ],
  "payment_method": "cash | debit | credit | qris | ewallet | null",
  "category": "string | null",
  "is_receipt": true
}

Teks OCR:
$ocrText
''';

    final response = await http.post(
      Uri.parse(config.apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': config.model,
        'messages': [
          {'role': 'system', 'content': 'You are a receipt parser. Always respond with valid JSON only.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.1,
      }),
    );

    if (response.statusCode == 401) {
      throw Exception('API Key tidak valid. Periksa kembali di Settings.');
    }
    if (response.statusCode == 429) {
      throw Exception('Terlalu banyak permintaan. Coba lagi nanti.');
    }
    if (response.statusCode >= 500) {
      throw Exception('Server AI mengalami gangguan. Coba lagi nanti.');
    }
    if (response.statusCode != 200) {
      throw Exception('Gagal memproses: ${response.statusCode}');
    }

    final body = jsonDecode(response.body);
    final content = (body['choices']?[0]?['message']?['content'] ?? '') as String;
    final cleaned = content
        .trim()
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();

    try {
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      return AiParseResult(
        storeName: parsed['store_name'] as String?,
        date: parsed['date'] as String?,
        totalAmount: (parsed['total_amount'] as num?)?.toInt(),
        items: (parsed['items'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        paymentMethod: parsed['payment_method'] as String?,
        suggestedCategory: parsed['category'] as String?,
        isReceipt: parsed['is_receipt'] as bool? ?? true,
        raw: cleaned,
      );
    } catch (_) {
      throw FormatException('AI mengembalikan format tidak valid. $content');
    }
  }

  Future<List<QuickParsedTransaction>> parseQuickText(
    String input, {
    List<String> expenseCategories = const [],
    List<String> incomeCategories = const [],
  }) async {
    final config = await AiConfigStorage.load();
    final apiKey = config.apiKey;
    if (apiKey == null ||
        apiKey.isEmpty ||
        config.apiUrl.isEmpty ||
        config.model.isEmpty) {
      return parseQuickTextOffline(input);
    }

    final prompt = '''
Ubah kalimat catatan keuangan Indonesia berikut menjadi array JSON transaksi.
Aturan:
- Kembalikan HANYA JSON array, tanpa teks lain.
- "type": "expense" atau "income"
- "amount": integer dalam Rupiah (tanpa titik/koma)
- "note": deskripsi singkat transaksi
- "category": pilih dari kategori pengeluaran [${expenseCategories.join(', ')}] atau kategori pemasukan [${incomeCategories.join(', ')}], atau null
- "payment_method": "cash | debit | credit | qris | ewallet" (default "cash")

Kalimat:
$input
''';

    try {
      final response = await http.post(
        Uri.parse(config.apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': config.model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a personal finance parser. Respond with a valid JSON array only.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode != 200) {
        return parseQuickTextOffline(input);
      }

      final body = jsonDecode(response.body);
      final content = (body['choices']?[0]?['message']?['content'] ?? '') as String;
      final cleaned = content
          .trim()
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) return parseQuickTextOffline(input);

      final parsed = <QuickParsedTransaction>[];
      for (final item in decoded.whereType<Map>()) {
        final amount = (item['amount'] as num?)?.toInt() ?? 0;
        if (amount <= 0) continue;
        final method = item['payment_method']?.toString();
        parsed.add(
          QuickParsedTransaction(
            type: item['type'] == 'income' ? 'income' : 'expense',
            amount: amount,
            note: (item['note']?.toString().trim().isNotEmpty ?? false)
                ? item['note'].toString().trim()
                : 'Transaksi',
            categoryName: item['category']?.toString(),
            paymentMethod: (method != null && paymentMethods.contains(method))
                ? method
                : 'cash',
          ),
        );
      }
      return parsed.isNotEmpty ? parsed : parseQuickTextOffline(input);
    } catch (_) {
      return parseQuickTextOffline(input);
    }
  }
}
