class ReceiptParser {
  const ReceiptParser();

  static const int _maximumReceiptAmount = 100000000;

  Map<String, dynamic> parse(String rawText) {
    final List<String> lines = rawText
        .split(RegExp(r'\r?\n'))
        .map(_normalizeLine)
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

    _MerchantCandidate? bestCandidate;
    for (int index = 0; index < lines.length; index += 1) {
      final String line = lines[index];
      if (!_isLikelyMerchantLine(line)) {
        continue;
      }

      final _MerchantCandidate candidate = _MerchantCandidate(
        line,
        _merchantCandidateScore(line, index),
      );
      if (bestCandidate == null || candidate.score > bestCandidate.score) {
        bestCandidate = candidate;
      }
    }

    return bestCandidate?.name ?? '';
  }

  int _extractTotal(List<String> lines) {
    final List<RegExp> totalPatterns = <RegExp>[
      RegExp(r'\bgrand\s+total\b', caseSensitive: false),
      RegExp(r'\btotal\s+belanja\b', caseSensitive: false),
      RegExp(r'\btotal\s+bayar\b', caseSensitive: false),
      RegExp(r'^\s*total\s*(?:[:\-]|\s|$)', caseSensitive: false),
    ];

    for (final RegExp pattern in totalPatterns) {
      for (int index = lines.length - 1; index >= 0; index -= 1) {
        final String line = lines[index];
        if (!pattern.hasMatch(line)) {
          continue;
        }

        if (_shouldIgnoreForAmounts(line) || _isSubtotalLine(line)) {
          continue;
        }

        final int? amount = _lastAmountInLine(line);
        if (amount != null) {
          return amount;
        }

        final int? followingAmount = _amountAfterTotalLabel(lines, index);
        if (followingAmount != null) {
          return followingAmount;
        }
      }
    }

    return 0;
  }

  int? _amountAfterTotalLabel(List<String> lines, int totalLineIndex) {
    for (int index = totalLineIndex + 1;
        index < lines.length && index <= totalLineIndex + 2;
        index += 1) {
      final String line = lines[index];
      if (_isTotalLikeLine(line) || _isPaymentOrChangeLine(line)) {
        break;
      }

      final int? amount = _lastAmountInLine(line);
      if (amount != null) {
        return amount;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _extractItems(List<String> lines) {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];

    for (final String line in lines) {
      if (_shouldIgnoreForItems(line)) {
        continue;
      }

      final int? price = _lastAmountInLine(line, requireTrailing: true);
      if (price == null || price <= 0) {
        continue;
      }

      final String name = _cleanItemName(line);
      if (!_isValidItemName(name)) {
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
    final String withoutLeadingCode = withoutQtyPrefix.replaceFirst(
      RegExp(r'^\s*[A-Z0-9]{1,6}\s+'),
      '',
    );

    return withoutLeadingCode
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'^[\-:|.\s]+|[\-:|.\s]+$'), '')
        .trim();
  }

  bool _containsAmount(String line) {
    return _lastAmountInLine(line) != null;
  }

  bool _isLikelyMerchantLine(String line) {
    final String normalized = line.toLowerCase();

    if (line.length < 3 || line.length > 42) {
      return false;
    }

    if (_containsAmount(line) ||
        _isReceiptMetadataLine(line) ||
        _isMerchantMetadataLabel(line)) {
      return false;
    }

    if (_isAddressOrBranchLine(line) || _isCustomerCareLine(line)) {
      return false;
    }

    if (normalized.contains('receipt') ||
        normalized.contains('struk') ||
        normalized.contains('invoice') ||
        normalized.contains('copy')) {
      return false;
    }

    final int letterCount = RegExp(r'[A-Za-z]').allMatches(line).length;
    final int digitCount = RegExp(r'\d').allMatches(line).length;

    return letterCount >= 3 && letterCount >= digitCount;
  }

  int _merchantCandidateScore(String line, int index) {
    final String normalized = line.toLowerCase();
    int score = 0;

    if (index < 10) {
      score += 20 - index;
    }

    if (_isKnownStoreName(normalized)) {
      score += 80;
    }

    if (RegExp(r"^[A-Z0-9 &.'-]+$").hasMatch(line)) {
      score += 12;
    }

    if (normalized.contains('coffee') ||
        normalized.contains('store') ||
        normalized.contains('mart') ||
        normalized.contains('market')) {
      score += 16;
    }

    if (line.contains(':')) {
      score -= 25;
    }

    score -= RegExp(r'\d').allMatches(line).length * 2;

    return score;
  }

  bool _isKnownStoreName(String normalized) {
    return normalized.contains('tomoro coffee') ||
        normalized.contains('starbucks') ||
        normalized.contains('indomaret');
  }

  bool _isMerchantMetadataLabel(String line) {
    final String normalized = line
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized == 'channel' ||
        normalized.startsWith('channel ') ||
        normalized == 'cashier' ||
        normalized.startsWith('cashier ') ||
        normalized == 'order' ||
        normalized.startsWith('order ') ||
        normalized == 'date' ||
        normalized.startsWith('date ') ||
        normalized == 'payment' ||
        normalized.startsWith('payment ') ||
        normalized == 'receipt' ||
        normalized.startsWith('receipt ') ||
        normalized == 'invoice' ||
        normalized.startsWith('invoice ');
  }

  bool _shouldIgnoreForItems(String line) {
    return _isReceiptMetadataLine(line) ||
        _isTotalLikeLine(line) ||
        _isPaymentOrChangeLine(line) ||
        _isFooterLine(line) ||
        _isCustomerCareLine(line) ||
        _isAddressOrBranchLine(line);
  }

  bool _shouldIgnoreForAmounts(String line) {
    return _isPhoneLine(line) ||
        _isDateOrTimeLine(line) ||
        _isTransactionIdLine(line) ||
        _isCustomerCareLine(line) ||
        _isFooterLine(line);
  }

  bool _isReceiptMetadataLine(String line) {
    final String normalized = line.toLowerCase();

    return _isPhoneLine(line) ||
        _isDateOrTimeLine(line) ||
        _isTransactionIdLine(line) ||
        normalized.contains('telp') ||
        normalized.contains('telepon') ||
        normalized.contains('phone') ||
        normalized.contains('tanggal') ||
        normalized.contains('date') ||
        normalized.contains('time') ||
        normalized.contains('jam') ||
        normalized.contains('kasir') ||
        normalized.contains('cashier') ||
        normalized.contains('receipt') ||
        normalized.contains('struk') ||
        normalized.contains('invoice') ||
        normalized.contains('nota');
  }

  bool _isPhoneLine(String line) {
    final String normalized = line.toLowerCase();
    final String digitsOnly = line.replaceAll(RegExp(r'[^0-9]'), '');

    return normalized.contains('telp') ||
        normalized.contains('telepon') ||
        normalized.contains('phone') ||
        normalized.contains('wa ') ||
        normalized.contains('whatsapp') ||
        RegExp(r'(?:\+?62|0)\d[\d\s\-]{7,}\d').hasMatch(line) ||
        (digitsOnly.length >= 10 &&
            (digitsOnly.startsWith('0') || digitsOnly.startsWith('62')));
  }

  bool _isDateOrTimeLine(String line) {
    final String normalized = line.toLowerCase();

    return normalized.contains('tanggal') ||
        normalized.contains('date') ||
        normalized.contains('time') ||
        normalized.contains('jam') ||
        RegExp(r'\b\d{1,2}[\-/]\d{1,2}[\-/]\d{2,4}\b').hasMatch(line) ||
        RegExp(r'\b\d{4}[\-/]\d{1,2}[\-/]\d{1,2}\b').hasMatch(line) ||
        RegExp(r'\b\d{1,2}:\d{2}(?::\d{2})?\b').hasMatch(line) ||
        RegExp(r'\b\d{8}\b').hasMatch(line);
  }

  bool _isTransactionIdLine(String line) {
    final String normalized = line.toLowerCase();
    final String digitsOnly = line.replaceAll(RegExp(r'[^0-9]'), '');

    return normalized.contains('transaction') ||
        normalized.contains('transaksi') ||
        normalized.contains('trx') ||
        normalized.contains('no.') ||
        normalized.contains('no ') ||
        normalized.contains('nomor') ||
        normalized.contains('order') ||
        normalized.contains('id') ||
        normalized.contains('ref') ||
        normalized.contains('auth') ||
        normalized.contains('batch') ||
        normalized.contains('trace') ||
        normalized.contains('faktur') ||
        normalized.contains('bill') ||
        digitsOnly.length >= 12;
  }

  bool _isCustomerCareLine(String line) {
    final String normalized = line.toLowerCase();

    return normalized.contains('customer care') ||
        normalized.contains('call center') ||
        normalized.contains('layanan pelanggan') ||
        normalized.contains('hubungi') ||
        normalized.contains('kritik') ||
        normalized.contains('saran') ||
        normalized.contains('cs ');
  }

  bool _isFooterLine(String line) {
    final String normalized = line.toLowerCase();

    return normalized.contains('terima kasih') ||
        normalized.contains('thank you') ||
        normalized.contains('thanks') ||
        normalized.contains('selamat') ||
        normalized.contains('kunjungan') ||
        normalized.contains('www.') ||
        normalized.contains('.com') ||
        normalized.contains('instagram') ||
        normalized.contains('facebook') ||
        normalized.contains('promo') ||
        normalized.contains('member') ||
        normalized.contains('poin') ||
        normalized.contains('point');
  }

  bool _isAddressOrBranchLine(String line) {
    final String normalized = line.toLowerCase();

    return normalized.contains('alamat') ||
        normalized.contains('address') ||
        normalized.contains('jalan ') ||
        normalized.contains('jl.') ||
        normalized.contains('jln') ||
        normalized.contains('mall') ||
        normalized.contains('lantai') ||
        normalized.contains('lt.') ||
        normalized.contains('cabang') ||
        normalized.contains('branch');
  }

  bool _isPaymentOrChangeLine(String line) {
    final String normalized = line.toLowerCase();

    return normalized.contains('tunai') ||
        normalized.contains('cash') ||
        normalized.contains('debit') ||
        normalized.contains('credit') ||
        normalized.contains('kartu') ||
        normalized.contains('qris') ||
        normalized.contains('gopay') ||
        normalized.contains('ovo') ||
        normalized.contains('dana') ||
        normalized.contains('shopeepay') ||
        normalized.contains('kembali') ||
        normalized.contains('change') ||
        normalized.contains('paid') ||
        normalized.contains('payment');
  }

  bool _isTotalLikeLine(String line) {
    final String normalized = line.toLowerCase();

    return normalized.contains('subtotal') ||
        normalized.contains('sub total') ||
        normalized.contains('grand total') ||
        normalized.contains('total belanja') ||
        normalized.contains('total bayar') ||
        RegExp(r'^\s*total\b').hasMatch(normalized) ||
        normalized.contains('jumlah') ||
        normalized.contains('pajak') ||
        normalized.contains('tax') ||
        normalized.contains('service') ||
        normalized.contains('discount') ||
        normalized.contains('diskon') ||
        normalized.contains('bayar');
  }

  bool _isSubtotalLine(String line) {
    final String normalized = line.toLowerCase();
    return normalized.contains('subtotal') || normalized.contains('sub total');
  }

  bool _isValidItemName(String value) {
    final String normalized = value.toLowerCase();
    final int letterCount = RegExp(r'[A-Za-z]').allMatches(value).length;

    return normalized.length >= 2 &&
        letterCount >= 2 &&
        !normalized.contains('rp') &&
        !RegExp(r'^\d+$').hasMatch(normalized) &&
        !_isReceiptMetadataLine(value) &&
        !_isTotalLikeLine(value) &&
        !_isPaymentOrChangeLine(value) &&
        !_isFooterLine(value) &&
        !_isCustomerCareLine(value);
  }

  int? _lastAmountInLine(String line, {bool requireTrailing = false}) {
    if (_shouldIgnoreForAmounts(line)) {
      return null;
    }

    final Iterable<RegExpMatch> matches = _amountPattern.allMatches(line);
    if (matches.isEmpty) {
      return null;
    }

    for (final RegExpMatch match in matches.toList().reversed) {
      if (requireTrailing && !_isTrailingMatch(line, match)) {
        continue;
      }

      final String? value = match.group(0);
      if (value == null || _looksLikePhoneOrIdAmount(value)) {
        continue;
      }

      final int? amount = _parseAmount(value);
      if (amount != null && amount > 0 && amount <= _maximumReceiptAmount) {
        return amount;
      }
    }

    return null;
  }

  bool _isTrailingMatch(String line, RegExpMatch match) {
    final String tail = line.substring(match.end).trim();
    return tail.isEmpty || RegExp(r'^[,.;:)]*$').hasMatch(tail);
  }

  bool _looksLikePhoneOrIdAmount(String value) {
    final String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    final bool hasGrouping = RegExp(r'\d[.,]\d').hasMatch(value);
    final bool hasCurrency = value.toLowerCase().contains('rp');

    if (digitsOnly.length >= 10 && !hasGrouping && !hasCurrency) {
      return true;
    }

    if (digitsOnly.length >= 12) {
      return true;
    }

    return false;
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

  static String _normalizeLine(String line) {
    return line.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static final RegExp _amountPattern = RegExp(
    r'(?:Rp\s*)?\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?|(?:Rp\s*)?\d{4,9}',
    caseSensitive: false,
  );

  static final RegExp _amountAtEndPattern = RegExp(
    r'\s*(?:Rp\s*)?\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?\s*$|\s*(?:Rp\s*)?\d{4,9}\s*$',
    caseSensitive: false,
  );
}

class _MerchantCandidate {
  const _MerchantCandidate(this.name, this.score);

  final String name;
  final int score;
}
