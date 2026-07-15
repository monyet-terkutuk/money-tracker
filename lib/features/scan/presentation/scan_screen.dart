import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../transactions/domain/category_providers.dart';
import '../../transactions/domain/transaction_providers.dart';
import '../ai_parser_service.dart';
import '../ocr_service.dart';
import '../scan_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _picker = ImagePicker();
  OcrService? _ocrService;
  AiParserService? _aiParser;

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService();
    _aiParser = AiParserService();
  }

  @override
  void dispose() {
    _ocrService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Struk')),
      body: switch (scanState.state) {
        ScanState.idle => _buildIdle(),
        ScanState.scanning => const LoadingIndicator(message: 'Membaca teks struk...'),
        ScanState.parsing => const LoadingIndicator(message: 'Memproses dengan AI...'),
        ScanState.preview => _buildPreview(scanState),
        ScanState.error => ErrorView(
            message: scanState.errorMessage ?? 'Terjadi kesalahan',
            onRetry: () => ref.read(scanNotifierProvider.notifier).goToIdle(),
          ),
        _ => const SizedBox(),
      },
    );
  }

  Widget _buildIdle() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Ambil foto struk belanja', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Pastikan pencahayaan cukup dan teks terbaca jelas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Ambil Foto'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Pilih dari Galeri'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ScanStateHolder state) {
    return _ScanPreviewForm(state: state);
  }

  Future<void> _pickImage(ImageSource source) async {
    final notifier = ref.read(scanNotifierProvider.notifier);

    notifier.setScanState(ScanState.pickingImage);
    final file = await _picker.pickImage(source: source);

    if (file == null) {
      notifier.goToIdle();
      return;
    }

    notifier.setImagePath(file.path);
    notifier.setScanState(ScanState.scanning);

    try {
      final inputImage = InputImage.fromFile(File(file.path));
      final ocrText = await _ocrService!.recognizeText(inputImage);

      if (ocrText.trim().isEmpty) {
        notifier.setError('Teks tidak terbaca. Pastikan pencahayaan cukup dan foto jelas.');
        return;
      }

      notifier.setOcrText(ocrText);
      notifier.setScanState(ScanState.parsing);

      final result = await _aiParser!.parseReceipt(ocrText);
      notifier.setParseResult(result);
      notifier.goToPreview();
    } on SocketException {
      notifier.setError('Tidak ada koneksi internet. AI parser membutuhkan internet.');
    } on FormatException {
      notifier.setError('AI mengembalikan format tidak valid. Silakan isi manual.');
    } catch (e) {
      notifier.setError(e.toString());
    }
  }
}

class _ScanPreviewForm extends ConsumerStatefulWidget {
  final ScanStateHolder state;

  const _ScanPreviewForm({required this.state});

  @override
  ConsumerState<_ScanPreviewForm> createState() => _ScanPreviewFormState();
}

class _ScanPreviewFormState extends ConsumerState<_ScanPreviewForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  late String _paymentMethod;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final result = widget.state.parseResult;
    _amountController = TextEditingController(
      text: result?.totalAmount != null ? result!.totalAmount.toString() : '',
    );
    _noteController = TextEditingController(text: result?.storeName ?? '');
    _selectedDate = _parseDate(result?.date) ?? DateTime.now();
    final method = result?.paymentMethod;
    _paymentMethod = (method != null && paymentMethods.contains(method)) ? method : 'cash';
  }

  DateTime? _parseDate(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final cats = categoriesAsync.valueOrNull ?? [];

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.receiptImagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(state.receiptImagePath!), height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          Text('Hasil Scan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            state.ocrText ?? 'Teks tidak terbaca',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Jumlah (Rp)', prefixText: 'Rp '),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Masukkan jumlah';
              final n = int.tryParse(v.replaceAll('.', ''));
              if (n == null || n <= 0) return 'Jumlah tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v),
            validator: (v) => v == null ? 'Pilih kategori' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(labelText: 'Metode Bayar'),
            items: paymentMethods.map((m) => DropdownMenuItem(
              value: m,
              child: Text(paymentMethodLabels[m] ?? m),
            )).toList(),
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving
                ? null
                : () => ref.read(scanNotifierProvider.notifier).goToIdle(),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final amount = int.parse(_amountController.text.replaceAll('.', ''));
    await ref.read(transactionNotifierProvider.notifier).addTransaction(
          type: 'expense',
          amount: amount,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          paymentMethod: _paymentMethod,
          receiptImagePath: widget.state.receiptImagePath,
          aiRawResponse: widget.state.parseResult?.raw,
        );

    final saveState = ref.read(transactionNotifierProvider);
    if (!mounted) return;

    if (saveState.hasError) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: ${saveState.error}')),
      );
      return;
    }

    ref.invalidate(transactionListProvider);
    ref.invalidate(monthlySummaryProvider);
    ref.read(scanNotifierProvider.notifier).goToIdle();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan')),
    );
    context.pop();
  }
}
