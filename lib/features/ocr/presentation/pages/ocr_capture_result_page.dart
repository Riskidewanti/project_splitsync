import 'dart:io';
import 'dart:ui' show PathMetric, PathMetrics;

import 'package:flutter/material.dart';

import '../../../../core/config/env.dart';
import '../../../../core/services/gemini_receipt_service.dart';
import '../../data/datasources/ocr_service.dart';
import '../../data/utils/receipt_parser.dart';
import 'edit_items_page.dart';
import 'ocr_result_page.dart';

class OCRCaptureResultPage extends StatefulWidget {
  const OCRCaptureResultPage({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<OCRCaptureResultPage> createState() => _OCRCaptureResultPageState();
}

class _OCRCaptureResultPageState extends State<OCRCaptureResultPage> {
  final OCRService _ocrService = const OCRService();
  final ReceiptParser _receiptParser = const ReceiptParser();
  final GeminiReceiptService _geminiService = GeminiReceiptService(
    apiKey: Env.geminiApiKey,
  );
  bool _isRunningOCR = false;

  Future<void> _handleFinish() async {
    if (_isRunningOCR) {
      return;
    }

    setState(() {
      _isRunningOCR = true;
    });

    try {
      final String extractedText = await _ocrService.extractText(
        widget.imagePath,
      );
      print('===== OCR RAW TEXT =====');
      print(extractedText);
      print('========================');
      late final Map<String, dynamic> parsedResult;
      try {
        debugPrint(
          'Gemini API key configured: ${Env.geminiApiKey.isNotEmpty}',
        );
        parsedResult = await _geminiService.parseReceipt(extractedText);
      } catch (error) {
        print('Gemini receipt parsing failed: $error');
        parsedResult = _receiptParser.parse(extractedText);
      }
      print('===== OCR PARSED RESULT =====');
      print(parsedResult);
      print('=============================');
      final String merchant = _parsedMerchant(parsedResult['merchant']);
      final double total = _parsedTotal(parsedResult['total']);
      final Object? parsedItemsValue = parsedResult['items'];
      debugPrint(
        'OCRCaptureResultPage parsedResult[items] '
        'type=${parsedItemsValue.runtimeType} '
        'length=${parsedItemsValue is List ? parsedItemsValue.length : 'not-list'}',
      );
      final List<ReceiptItem> items = _parsedItems(parsedResult['items']);

      debugPrint('Raw OCR text:\n$extractedText');
      debugPrint('Parsed receipt result: $parsedResult');
      debugPrint('OCRCaptureResultPage ReceiptItem length=${items.length}');
      debugPrint('Parsed receipt items: $items');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('OCR completed successfully')),
        );

      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            debugPrint(
              'OCRCaptureResultPage -> OCRResultPage items length=${items.length}',
            );
            return OCRResultPage(
              merchant: merchant,
              total: total,
              date: DateTime(2023, 10, 24),
              category: 'Ditempat',
              items: items,
            );
          },
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isRunningOCR = false;
        });
      }
    }
  }

  String _parsedMerchant(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return 'Unknown Merchant';
  }

  double _parsedTotal(Object? value) {
    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  List<ReceiptItem> _parsedItems(Object? value) {
    if (value is! List) {
      debugPrint(
        'OCRCaptureResultPage _parsedItems received ${value.runtimeType}; returning 0 items',
      );
      return const <ReceiptItem>[];
    }

    double parseAmount(Object? amount) {
      if (amount is int) {
        return amount.toDouble();
      }
      if (amount is double) {
        return amount;
      }
      if (amount is num) {
        return amount.toDouble();
      }
      if (amount is String) {
        final String text = amount
            .trim()
            .replaceAll(RegExp(r'[^0-9,.-]'), '')
            .replaceAll(RegExp(r'^-+'), '');
        if (text.isEmpty) {
          return 0;
        }

        final bool hasThousandsGrouping = RegExp(
          r'^\d{1,3}([.,]\d{3})+(?:[.,]\d{2})?$',
        ).hasMatch(text);
        if (hasThousandsGrouping) {
          return double.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }

        final double? parsed = double.tryParse(text.replaceAll(',', '.'));
        if (parsed != null) {
          return parsed;
        }

        return double.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }

      return 0;
    }

    int parseQuantity(Object? quantity) {
      if (quantity is int && quantity > 0) {
        return quantity;
      }
      if (quantity is num && quantity > 0) {
        return quantity.round();
      }
      if (quantity is String) {
        final int? parsed = int.tryParse(quantity.trim());
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }

      return 1;
    }

    final List<ReceiptItem> receiptItems = <ReceiptItem>[];
    for (final Object? rawItem in value) {
      if (rawItem is! Map) {
        debugPrint(
          'OCRCaptureResultPage _parsedItems skipped ${rawItem.runtimeType}',
        );
        continue;
      }

      final Object? nameValue = rawItem['name'] ?? rawItem['item_name'];
      final Object? priceValue = rawItem['price'] ?? rawItem['total'];
      final String name = nameValue?.toString().trim() ?? '';
      final double price = parseAmount(priceValue);
      final int quantity = parseQuantity(rawItem['quantity']);

      if (name.isEmpty || price <= 0) {
        debugPrint(
          'OCRCaptureResultPage _parsedItems skipped item name="$name" price=$price raw=$rawItem',
        );
        continue;
      }

      receiptItems.add(
        ReceiptItem(name: name, quantity: quantity, price: price),
      );
    }

    debugPrint(
      'OCRCaptureResultPage _parsedItems input length=${value.length}, '
      'output ReceiptItem length=${receiptItems.length}',
    );
    return receiptItems;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text(
          'SplitSync',
          style: TextStyle(
            color: Color(0xFFD70F1F),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double previewWidth = (constraints.maxWidth * 0.84)
                        .clamp(280.0, 520.0);
                    final double previewHeight = (constraints.maxHeight * 0.72)
                        .clamp(340.0, 620.0);

                    return Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Positioned(
                          top: 18,
                          child: _InstructionChip(
                            colorScheme: colorScheme,
                            text: 'Atur nota di dalam kotak',
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0, 0.08),
                          child: SizedBox(
                            width: previewWidth,
                            height: previewHeight,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                _ReceiptImagePreview(
                                  imagePath: widget.imagePath,
                                ),
                                const _CropOverlay(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            _BottomActions(
              colorScheme: colorScheme,
              isRunningOCR: _isRunningOCR,
              onFinish: _handleFinish,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionChip extends StatelessWidget {
  const _InstructionChip({required this.colorScheme, required this.text});

  final ColorScheme colorScheme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.fit_screen, size: 15, color: colorScheme.error),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF3D4652),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptImagePreview extends StatelessWidget {
  const _ReceiptImagePreview({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final String trimmedPath = imagePath.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.82,
            colors: <Color>[Color(0xFF463A3E), Color(0xFF151316)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: trimmedPath.isEmpty
              ? const _InvalidReceiptPreview()
              : Image.file(
                  File(trimmedPath),
                  fit: BoxFit.contain,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const _InvalidReceiptPreview();
                      },
                ),
        ),
      ),
    );
  }
}

class _InvalidReceiptPreview extends StatelessWidget {
  const _InvalidReceiptPreview();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.receipt_long_outlined, color: Colors.white54, size: 88),
    );
  }
}

class _CropOverlay extends StatelessWidget {
  const _CropOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(child: CustomPaint(painter: _DashedCropPainter())),
        const Positioned(top: -7, left: -7, child: _CropHandle()),
        const Positioned(top: -7, right: -7, child: _CropHandle()),
        const Positioned(bottom: -7, left: -7, child: _CropHandle()),
        const Positioned(bottom: -7, right: -7, child: _CropHandle()),
      ],
    );
  }
}

class _DashedCropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFFF2E37)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final RRect rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );

    _drawDashedRRect(canvas, rect, paint);
  }

  void _drawDashedRRect(Canvas canvas, RRect rect, Paint paint) {
    const double dashWidth = 5;
    const double dashGap = 4;

    final Path path = Path()..addRRect(rect);
    final PathMetrics metrics = path.computeMetrics();

    for (final PathMetric metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double nextDistance = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, nextDistance.clamp(0, metric.length)),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CropHandle extends StatelessWidget {
  const _CropHandle();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFF2E37),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const SizedBox.square(dimension: 18),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.colorScheme,
    required this.isRunningOCR,
    required this.onFinish,
  });

  final ColorScheme colorScheme;
  final bool isRunningOCR;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE93635),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE93635),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: isRunningOCR ? null : onFinish,
              icon: isRunningOCR
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: const Text(
                'Selesai',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF1F1F3),
                foregroundColor: const Color(0xFF555B63),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text(
                'Foto Ulang',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
