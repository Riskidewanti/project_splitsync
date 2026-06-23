import 'package:flutter/material.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({
    super.key,
    required this.totalAmount,
    required this.participantCount,
  });

  final double totalAmount;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 18),
        ),
        title: const Text(
          'SplitSync',
          style: TextStyle(
            color: Color(0xFFD70F1F),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              child: Column(
                children: <Widget>[
                  const Spacer(flex: 3),
                  const _SuccessIndicator(),
                  const SizedBox(height: 30),
                  const Text(
                    'Permintaan Pembagian Terkirim!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total ${_formatCurrency(totalAmount)} pengeluaran untuk $participantCount orang',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(flex: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC70F1B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
                      },
                      child: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessIndicator extends StatelessWidget {
  const _SuccessIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE93635).withValues(alpha: 0.10),
      ),
      child: Container(
        width: 74,
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE93635).withValues(alpha: 0.16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFE93635).withValues(alpha: 0.22),
              blurRadius: 22,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFC70F1B),
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

String _formatCurrency(double value) {
  final String fixed = value.toStringAsFixed(2);
  final List<String> parts = fixed.split('.');
  final String whole = parts.first;
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < whole.length; i++) {
    final int reverseIndex = whole.length - i;
    buffer.write(whole[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '\$${buffer.toString()}.${parts.last}';
}
