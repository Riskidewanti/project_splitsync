String formatRupiah(num amount) {
  final int roundedAmount = amount.round();
  final String digits = roundedAmount.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    final int reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  final String prefix = roundedAmount < 0 ? '-Rp ' : 'Rp ';
  return prefix + buffer.toString();
}
