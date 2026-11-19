import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../scan/ai_parser_service.dart';
import '../../scan/quick_parser.dart';
import '../domain/category_providers.dart';
import '../domain/transaction_providers.dart';

class QuickInputSheet extends ConsumerStatefulWidget {
  const QuickInputSheet({super.key});

  @override
  ConsumerState<QuickInputSheet> createState() => _QuickInputSheetState();
}

class _QuickInputSheetState extends ConsumerState<QuickInputSheet> {
  final _controller = TextEditingController();
  final _aiParser = AiParserService();
  bool _parsing = false;
  bool _saving = false;
  List<QuickParsedTransaction> _parsed = [];
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _parsing = true;
      _error = null;
    });

    try {
      final cats = await ref.read(categoryListProvider.future);
      final expNames =
          cats.where((c) => c.type == 'expense').map((c) => c.name).toList();
      final incNames =
          cats.where((c) => c.type == 'income').map((c) => c.name).toList();

      final results = await _aiParser.parseQuickText(
        text,
        expenseCategories: expNames,
        incomeCategories: incNames,
      );

      if (!mounted) return;
      setState(() {
        _parsed = results;
        _parsing = false;
        if (results.isEmpty) {
          _error = 'Tidak ada nominal yang terbaca. Contoh: "kopi 25rb qris"';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _parsing = false;
        _error = e.toString();
      });
    }
  }

  String _resolveCategoryId(
    QuickParsedTransaction item,
    List<Category> cats,
  ) {
    final sameType = cats.where((c) => c.type == item.type).toList();
    if (sameType.isEmpty) {
      return cats.first.id;
    }
    if (item.categoryName != null) {
      final target = item.categoryName!.trim().toLowerCase();
      final match = sameType
          .where((c) => c.name.toLowerCase() == target)
          .firstOrNull;
      if (match != null) return match.id;
    }
    final fallback = sameType
        .where((c) => c.name.toLowerCase() == 'lainnya')
        .firstOrNull;
    return (fallback ?? sameType.first).id;
  }

  Future<void> _saveAll() async {
    if (_parsed.isEmpty) return;
    setState(() => _saving = true);

    final cats = await ref.read(categoryListProvider.future);
    final notifier = ref.read(transactionNotifierProvider.notifier);
    final now = DateTime.now();

    for (final item in _parsed) {
      await notifier.addTransaction(
        type: item.type,
        amount: item.amount,
        categoryId: _resolveCategoryId(item, cats),
        date: now,
        note: item.note,
        paymentMethod: item.paymentMethod,
      );
    }

    ref.invalidate(transactionListProvider);
    ref.invalidate(monthlySummaryProvider);
    ref.invalidate(monthlyInsightProvider);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_parsed.length} transaksi berhasil disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Input Cepat 1 Kalimat',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Tulis satu atau beberapa transaksi sekaligus, dipisah koma.',
                style: TextStyle(fontSize: 12, color: secondaryText),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 2,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _parse(),
                decoration: const InputDecoration(
                  hintText: 'Contoh: parkir 5rb cash, makan siang 28rb qris',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _parsing ? null : _parse,
                icon: _parsing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(_parsing ? 'Memproses...' : 'Proses Kalimat'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPalette.expenseColor(context),
                  ),
                ),
              ],
              if (_parsed.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Pratinjau (${_parsed.length} transaksi)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final entry in _parsed.asMap().entries)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppPalette.borderColor(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value.note,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${entry.value.categoryName ?? (entry.value.type == 'income' ? 'Pemasukan' : 'Pengeluaran')} · ${paymentMethodLabels[entry.value.paymentMethod] ?? entry.value.paymentMethod}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.value.type == 'income' ? '+' : '-'}${formatCurrency(entry.value.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: entry.value.type == 'income'
                                ? AppPalette.incomeColor(context)
                                : AppPalette.expenseColor(context),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            setState(() => _parsed.removeAt(entry.key));
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _saveAll,
                  child: Text(
                    _saving ? 'Menyimpan...' : 'Simpan Semua (${_parsed.length})',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
