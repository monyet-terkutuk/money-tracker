import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(isDark ? 0.16 : 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC9A86A).withOpacity(0.45),
                  ),
                ),
                child: Icon(
                  Icons.document_scanner_rounded,
                  size: 38,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pindai Struk Belanja',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gunakan kamera atau galeri untuk mengekstrak nominal, tanggal, dan kategori secara otomatis dengan AI.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Ambil Foto Struk'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pilih dari Galeri'),
                ),
              ),
            ],
          ),
        ),
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

      final cats = await ref.read(expenseCategoriesProvider.future);
      final categoryNames = cats.map((c) => c.name).toList();
      final result = await _aiParser!.parseReceipt(
        ocrText,
        categories: categoryNames,
      );
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
  bool _autoSelectedCategory = false;
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

    if (!_autoSelectedCategory && cats.isNotEmpty) {
      _autoSelectedCategory = true;
      final suggested = state.parseResult?.suggestedCategory?.trim().toLowerCase();
      if (suggested != null && suggested.isNotEmpty) {
        final match = cats.where((c) => c.name.toLowerCase() == suggested).firstOrNull;
        if (match != null) {
          _selectedCategoryId = match.id;
        }
      }
    }

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
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Masukkan jumlah';
              final n = parseFormattedAmount(v);
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
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori')),
      );
      return;
    }

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
