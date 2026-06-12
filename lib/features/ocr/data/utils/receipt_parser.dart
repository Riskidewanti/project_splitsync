class ReceiptParser {
  const ReceiptParser();

  Map<String, dynamic> parse(String rawText) {
    final List<String> lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();

    return <String, dynamic>{
      'merchant': _extractMerchant(lines),
      'total': _extractTotal(lines),
      'items': _extractItems(lines),
    };
  }

  String _extractMerchant(List<String> lines) {
    if (lines.isEmpty) {
      return '';
    }

    return lines.firstWhere(
      (String line) => !_isIgnoredLine(line) && !_containsAmount(line),
      orElse: () => lines.first,
    );
  }

  int _extractTotal(List<String> lines) {
    for (final String line in lines.reversed) {
      final String normalized = line.toLowerCase();
      final bool isTotalLine =
          normalized.contains('grand total') ||
          normalized.contains('total') ||
          normalized.contains('jumlah') ||
          normalized.contains('bayar');

      if (isTotalLine) {
        final int? amount = _lastAmountInLine(line);
        if (amount != null) {
          return amount;
        }
      }
    }

    final Iterable<int> allAmounts = lines
        .map(_lastAmountInLine)
        .whereType<int>();

    if (allAmounts.isEmpty) {
      return 0;
    }

    return allAmounts.reduce((int highest, int amount) {
      return amount > highest ? amount : highest;
    });
  }

  List<Map<String, dynamic>> _extractItems(List<String> lines) {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];

    for (final String line in lines) {
      if (_isIgnoredLine(line) || _isTotalLikeLine(line)) {
        continue;
      }

      final int? price = _lastAmountInLine(line);
      if (price == null || price <= 0) {
        continue;
      }

      final String name = _cleanItemName(line);
      if (name.isEmpty || _looksLikeMetadata(name)) {
        continue;
      }

      items.add(<String, dynamic>{'name': name, 'price': price});
    }

    return items;
  }

  String _cleanItemName(String line) {
    final String withoutAmount = line.replaceFirst(_amountAtEndPattern, '');
    final String withoutQtyPrefix = withoutAmount.replaceFirst(
      RegExp(r'^\s*\d+\s*[xX]\s*'),
      '',
    );

    return withoutQtyPrefix
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'[:\-]+$'), '')
        .trim();
  }

  bool _containsAmount(String line) {
    return _amountPattern.hasMatch(line);
  }

  bool _isIgnoredLine(String line) {
    final String normalized = line.toLowerCase();

    return normalized.contains('telp') ||
        normalized.contains('phone') ||
        normalized.contains('alamat') ||
        normalized.contains('address') ||
        normalized.contains('tanggal') ||
        normalized.contains('date') ||
        normalized.contains('time') ||
        normalized.contains('kasir') ||
        normalized.contains('cashier') ||
        normalized.contains('receipt') ||
        normalized.contains('struk') ||
        normalized.contains('invoice');
  }

  bool _isTotalLikeLine(String line) {
    final String normalized = line.toLowerCase();

    return normalized.contains('subtotal') ||
        normalized.contains('sub total') ||
        normalized.contains('total') ||
        normalized.contains('grand total') ||
        normalized.contains('jumlah') ||
        normalized.contains('pajak') ||
        normalized.contains('tax') ||
        normalized.contains('service') ||
        normalized.contains('discount') ||
        normalized.contains('diskon') ||
        normalized.contains('bayar') ||
        normalized.contains('kembali') ||
        normalized.contains('change');
  }

  bool _looksLikeMetadata(String value) {
    final String normalized = value.toLowerCase();

    return normalized.length < 2 ||
        normalized.contains('rp') ||
        RegExp(r'^\d+$').hasMatch(normalized);
  }

  int? _lastAmountInLine(String line) {
    final Iterable<RegExpMatch> matches = _amountPattern.allMatches(line);
    if (matches.isEmpty) {
      return null;
    }

    return _parseAmount(matches.last.group(0));
  }

  int? _parseAmount(String? value) {
    if (value == null) {
      return null;
    }

    final String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    return int.tryParse(digitsOnly);
  }

  static final RegExp _amountPattern = RegExp(
    r'(?:Rp\s*)?\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?|(?:Rp\s*)?\d{4,}',
    caseSensitive: false,
  );

  static final RegExp _amountAtEndPattern = RegExp(
    r'\s*(?:Rp\s*)?\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?\s*$|\s*(?:Rp\s*)?\d{4,}\s*$',
    caseSensitive: false,
  );
}
