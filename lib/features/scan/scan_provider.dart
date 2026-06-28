import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ScanState {
  idle,
  pickingImage,
  scanning,
  parsing,
  preview,
  saving,
  done,
  error,
}

class ScanStateHolder {
  final ScanState state;
  final String? errorMessage;
  final String? ocrText;
  final String? receiptImagePath;

  const ScanStateHolder({
    this.state = ScanState.idle,
    this.errorMessage,
    this.ocrText,
    this.receiptImagePath,
  });

  ScanStateHolder copyWith({
    ScanState? state,
    String? errorMessage,
    String? ocrText,
    String? receiptImagePath,
  }) {
    return ScanStateHolder(
      state: state ?? this.state,
      errorMessage: errorMessage,
      ocrText: ocrText ?? this.ocrText,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanStateHolder> {
  ScanNotifier() : super(const ScanStateHolder());

  void setScanState(ScanState newState) {
    state = state.copyWith(state: newState);
  }

  void setOcrText(String text) {
    state = state.copyWith(ocrText: text);
  }

  void setImagePath(String path) {
    state = state.copyWith(receiptImagePath: path);
  }

  void setError(String message) {
    state = state.copyWith(state: ScanState.error, errorMessage: message);
  }

  void goToPreview() {
    state = state.copyWith(state: ScanState.preview);
  }

  void goToIdle() {
    state = const ScanStateHolder();
  }
}

final scanNotifierProvider = StateNotifierProvider<ScanNotifier, ScanStateHolder>((ref) {
  return ScanNotifier();
});
