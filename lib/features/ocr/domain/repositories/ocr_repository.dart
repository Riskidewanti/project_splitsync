import '../../data/models/ocr_job_model.dart';

abstract class OCRRepository {
  Future<OCRJobModel> createOCRJob({
    required String expenseId,
    required String imagePath,
    String provider = 'tesseract',
  });

  Future<OCRJobModel?> getOCRJobByExpenseId(String expenseId);

  Future<OCRJobModel> updateOCRStatus({
    required String ocrJobId,
    required OCRJobStatus status,
    String? errorMessage,
  });

  Future<OCRJobModel> saveOCRResult({
    required String ocrJobId,
    required String rawText,
    required Map<String, dynamic> parsedJson,
    double? confidence,
  });
}
