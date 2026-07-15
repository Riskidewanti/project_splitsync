import 'package:equatable/equatable.dart';

enum OCRJobStatus {
  queued('queued'),
  processing('processing'),
  succeeded('succeeded'),
  failed('failed'),
  edited('edited');

  const OCRJobStatus(this.value);

  final String value;

  static OCRJobStatus fromValue(String value) {
    return OCRJobStatus.values.firstWhere(
      (OCRJobStatus status) => status.value == value,
      orElse: () => throw FormatException('Unknown OCR job status: $value'),
    );
  }
}

class OCRJobModel extends Equatable {
  const OCRJobModel({
    required this.id,
    required this.expenseId,
    required this.imagePath,
    required this.provider,
    required this.status,
    required this.parsedJson,
    required this.createdAt,
    required this.updatedAt,
    this.rawText,
    this.confidence,
    this.errorMessage,
    this.processedAt,
  });

  final String id;
  final String expenseId;
  final String imagePath;
  final String provider;
  final OCRJobStatus status;
  final String? rawText;
  final Map<String, dynamic> parsedJson;
  final double? confidence;
  final String? errorMessage;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory OCRJobModel.fromJson(Map<String, dynamic> json) {
    return OCRJobModel(
      id: _requiredString(json['id'], 'id'),
      expenseId: _requiredString(json['expense_id'], 'expense_id'),
      imagePath: _requiredString(json['image_path'], 'image_path'),
      provider: _requiredString(json['provider'], 'provider'),
      status: OCRJobStatus.fromValue(_requiredString(json['status'], 'status')),
      rawText: json['raw_text'] as String?,
      parsedJson: _jsonMap(json['parsed_json']),
      confidence: _nullableDouble(json['confidence']),
      errorMessage: json['error_message'] as String?,
      processedAt: _nullableDateTime(json['processed_at']),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'expense_id': expenseId,
      'image_path': imagePath,
      'provider': provider,
      'status': status.value,
      'raw_text': rawText,
      'parsed_json': parsedJson,
      'confidence': confidence,
      'error_message': errorMessage,
      'processed_at': processedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OCRJobModel copyWith({
    String? id,
    String? expenseId,
    String? imagePath,
    String? provider,
    OCRJobStatus? status,
    Object? rawText = _sentinel,
    Map<String, dynamic>? parsedJson,
    Object? confidence = _sentinel,
    Object? errorMessage = _sentinel,
    Object? processedAt = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OCRJobModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      imagePath: imagePath ?? this.imagePath,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      rawText: identical(rawText, _sentinel)
          ? this.rawText
          : rawText as String?,
      parsedJson: parsedJson ?? this.parsedJson,
      confidence: identical(confidence, _sentinel)
          ? this.confidence
          : confidence as double?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      processedAt: identical(processedAt, _sentinel)
          ? this.processedAt
          : processedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    expenseId,
    imagePath,
    provider,
    status,
    rawText,
    parsedJson,
    confidence,
    errorMessage,
    processedAt,
    createdAt,
    updatedAt,
  ];
}

const Object _sentinel = Object();

String _requiredString(Object? value, String key) {
  if (value is String && value.isNotEmpty) {
    return value;
  }

  throw FormatException('Missing required string field: $key');
}

DateTime _requiredDateTime(Object? value, String key) {
  final DateTime? dateTime = _nullableDateTime(value);
  if (dateTime != null) {
    return dateTime;
  }

  throw FormatException('Missing required DateTime field: $key');
}

DateTime? _nullableDateTime(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }

  throw FormatException('Invalid DateTime value: $value');
}

double? _nullableDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Invalid double value: $value');
}

Map<String, dynamic> _jsonMap(Object? value) {
  if (value == null) {
    return <String, dynamic>{};
  }

  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
  }

  throw FormatException('Invalid JSON map value: $value');
}
