import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer;

  OcrService() : _recognizer = TextRecognizer();

  Future<String> recognizeText(InputImage inputImage) async {
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  void dispose() {
    _recognizer.close();
  }
}
