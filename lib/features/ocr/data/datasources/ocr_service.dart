import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  const OCRService();

  Future<String> extractText(String imagePath) async {
    if (imagePath.trim().isEmpty) {
      throw const OCRServiceException('Image path cannot be empty.');
    }

    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final TextRecognizer textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      return recognizedText.text;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        OCRServiceException('Failed to extract text from image: $error'),
        stackTrace,
      );
    } finally {
      await textRecognizer.close();
    }
  }
}

class OCRServiceException implements Exception {
  const OCRServiceException(this.message);

  final String message;

  @override
  String toString() => 'OCRServiceException: $message';
}
