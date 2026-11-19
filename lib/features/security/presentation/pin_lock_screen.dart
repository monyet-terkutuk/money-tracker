import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/pin_lock_provider.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  final bool isSetupMode;
  final VoidCallback? onSetupComplete;

  const PinLockScreen({
    super.key,
    this.isSetupMode = false,
    this.onSetupComplete,
  });

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _input = '';
  String? _firstPin;
  String? _errorText;

  void _onDigitTap(String digit) {
    if (_input.length >= 4) return;
    setState(() {
      _errorText = null;
      _input += digit;
    });
    if (_input.length == 4) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() {
      _errorText = null;
      _input = _input.substring(0, _input.length - 1);
    });
  }

  Future<void> _handleComplete() async {
    if (widget.isSetupMode) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = _input;
          _input = '';
        });
        return;
      }
      if (_firstPin == _input) {
        await ref.read(pinLockProvider.notifier).setPin(_input);
        if (mounted) {
          widget.onSetupComplete?.call();
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorText = 'PIN tidak cocok, coba lagi';
          _firstPin = null;
          _input = '';
        });
      }
      return;
    }

    final ok = ref.read(pinLockProvider.notifier).verifyPin(_input);
    if (!ok) {
      setState(() {
        _errorText = 'PIN salah';
        _input = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppPalette.accent(context);
    final secondaryText = AppPalette.secondaryTextColor(context);

    final title = widget.isSetupMode
        ? (_firstPin == null ? 'Buat PIN 4 Digit' : 'Konfirmasi PIN')
        : 'Masukkan PIN';
    final subtitle = widget.isSetupMode
        ? (_firstPin == null
            ? 'Lindungi catatan keuangan Anda'
            : 'Masukkan kembali PIN yang sama')
        : 'Buka akses ke Catat Uang';

    return Scaffold(
      appBar: widget.isSetupMode ? AppBar(title: const Text('Keamanan PIN')) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.borderColor(context)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorText ?? subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _errorText != null
                      ? AppPalette.expenseColor(context)
                      : secondaryText,
                  fontWeight:
                      _errorText != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _input.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? accent : Colors.transparent,
                      border: Border.all(
                        color: filled ? accent : AppPalette.borderColor(context),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              _buildKeypad(context, secondaryText),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context, Color secondaryText) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 72, height: 60);
              }
              if (key == 'back') {
                return SizedBox(
                  width: 72,
                  height: 60,
                  child: InkWell(
                    onTap: _onBackspace,
                    borderRadius: BorderRadius.circular(14),
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 22,
                      color: secondaryText,
                    ),
                  ),
                );
              }
              return Material(
                color: AppPalette.surfaceColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppPalette.borderColor(context)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _onDigitTap(key),
                  child: SizedBox(
                    width: 72,
                    height: 60,
                    child: Center(
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
