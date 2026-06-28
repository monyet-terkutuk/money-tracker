import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/utils/constants.dart';

class AiParseResult {
  final String? storeName;
  final String? date;
  final int? totalAmount;
  final List<Map<String, dynamic>> items;
  final String? paymentMethod;
  final bool isReceipt;

  AiParseResult({
    this.storeName,
    this.date,
    this.totalAmount,
    this.items = const [],
    this.paymentMethod,
    this.isReceipt = true,
  });
}

class AiParserService {
  static const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
  final _storage = const FlutterSecureStorage();

  Future<String?> _getApiKey() async {
    return await _storage.read(key: apiKeyPrefKey);
  }

  Future<AiParseResult> parseReceipt(String ocrText) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key belum diatur. Silakan isi di Settings.');
    }

    final prompt = '''
Kamu adalah parser struk belanja Indonesia.
Dari teks OCR hasil scan struk berikut, ekstrak data dalam format JSON.
Aturan:
- amount dalam Rupiah (integer, tanpa titik/koma)
- date dalam format YYYY-MM-DD
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
  "is_receipt": true
}

Teks OCR:
$ocrText
''';

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
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
    final content = body['choices']?[0]?['message']?['content'] ?? '';

    try {
      final parsed = jsonDecode(content.trim()) as Map<String, dynamic>;
      return AiParseResult(
        storeName: parsed['store_name'] as String?,
        date: parsed['date'] as String?,
        totalAmount: parsed['total_amount'] as int?,
        items: (parsed['items'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        paymentMethod: parsed['payment_method'] as String?,
        isReceipt: parsed['is_receipt'] as bool? ?? true,
      );
    } catch (_) {
      throw FormatException('AI mengembalikan format tidak valid. $content');
    }
  }
}
