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
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final cats = categoriesAsync.valueOrNull ?? [];
    final notifier = ref.read(scanNotifierProvider.notifier);

    return ListView(
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
        TextField(
          decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Kategori'),
          items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: 'cash',
          decoration: const InputDecoration(labelText: 'Metode Bayar'),
          items: paymentMethods.map((m) => DropdownMenuItem(
            value: m,
            child: Text(paymentMethodLabels[m] ?? m),
          )).toList(),
          onChanged: (_) {},
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            notifier.goToIdle();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaksi berhasil disimpan')),
            );
            context.pop();
          },
          child: const Text('Simpan'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => notifier.goToIdle(),
          child: const Text('Batalkan'),
        ),
      ],
    );
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

      await _aiParser!.parseReceipt(ocrText);
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
