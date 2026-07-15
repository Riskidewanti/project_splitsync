import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'person_payment_pin_page.dart';

class PersonPaymentCheckoutPage extends StatefulWidget {
  const PersonPaymentCheckoutPage({
    super.key,
    this.debtId = '',
    this.userId = '',
  });

  final String debtId;
  final String userId;

  @override
  State<PersonPaymentCheckoutPage> createState() =>
      _PersonPaymentCheckoutPageState();
}

class _PersonPaymentCheckoutPageState extends State<PersonPaymentCheckoutPage> {
  static const Color _primary = Color(0xFF8D000B);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF8E7F7F);
  static const Color _surface = Color(0xFFFFFAF7);
  static const Color _soft = Color(0xFFF5F3FF);
  static const Color _line = Color(0xFFF0E7E7);

  final TextEditingController _noteController = TextEditingController();
  _PaymentMethod _selectedMethod = _PaymentMethod.venmo;
  _PaymentDebt? _debt;
  bool _isLoading = true;
  bool _isConfirming = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDebt();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadDebt() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String currentUserId = await _resolveCurrentUserId();
      final Map<String, dynamic>? row = await _fetchDebtRow(currentUserId);
      if (row == null) {
        throw const _CheckoutException(
          'Tidak ada tagihan yang perlu dilunasi.',
        );
      }

      final _PaymentDebt debt = _PaymentDebt.fromRow(row);
      if (!mounted) return;
      setState(() {
        _debt = debt;
        _noteController.text = debt.note.isEmpty
            ? 'Thanks for covering the dinner!'
            : debt.note;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _readError(error);
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchDebtRow(String currentUserId) async {
    final String selectQuery =
        'id,requester_id,debtor_id,amount,currency,note,status,debtor_name,'
        'debtor_handle,debtor_avatar_url,created_at,requester:requester_id(id,user_name,email,avatar_url)';

    PostgrestFilterBuilder<List<Map<String, dynamic>>> query = Supabase
        .instance
        .client
        .from('personal_expense_debts')
        .select(selectQuery)
        .eq('status', 'pending');

    if (_isUuid(widget.debtId)) {
      query = query.eq('id', widget.debtId);
    } else {
      query = query.eq('debtor_id', currentUserId);
    }

    final List<dynamic> rows = await query
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<String> _resolveCurrentUserId() async {
    if (_isUuid(widget.userId)) return widget.userId;

    final String? authUserId = Supabase.instance.client.auth.currentUser?.id;
    if (_isUuid(authUserId ?? '')) return authUserId!;

    final Map<String, dynamic>? row = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .limit(1)
        .maybeSingle();
    final String profileId = (row?['id'] ?? '').toString();
    if (_isUuid(profileId)) return profileId;

    throw const _CheckoutException(
      'Akun aktif belum ditemukan. Silakan login ulang.',
    );
  }

  Future<void> _confirmPayment() async {
    final _PaymentDebt? debt = _debt;
    if (debt == null || _isConfirming) return;

    setState(() => _isConfirming = true);

    final bool? paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PersonPaymentPinPage(
          debtId: debt.id,
          userId: widget.userId,
          note: _noteController.text.trim().isEmpty
              ? debt.note
              : _noteController.text.trim(),
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isConfirming = false);

    if (paid == true) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Pembayaran dikonfirmasi')),
        );
      Navigator.of(context).maybePop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _PaymentDebt? debt = _debt;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, size: 22),
        ),
        centerTitle: true,
        title: const Text(
          'Lunasi Pembayaran',
          style: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _errorMessage != null
            ? _ErrorState(message: _errorMessage!, onRetry: _loadDebt)
            : Column(
                children: <Widget>[
                  Expanded(
                    child: RefreshIndicator(
                      color: _primary,
                      onRefresh: _loadDebt,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
                        children: <Widget>[
                          _HeroDebtCard(debt: debt!),
                          const SizedBox(height: 26),
                          const _SectionLabel('Pilih Metode Pembayaran'),
                          const SizedBox(height: 12),
                          for (final _PaymentMethod method
                              in _PaymentMethod.values) ...<Widget>[
                            _PaymentMethodTile(
                              method: method,
                              selected: _selectedMethod == method,
                              onTap: () {
                                setState(() => _selectedMethod = method);
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 18),
                          const _SectionLabel('Rincian Pelunasan'),
                          const SizedBox(height: 12),
                          _SettlementDetailsCard(debt: debt),
                          const SizedBox(height: 24),
                          const _SectionLabel('Tambah catatan (Optional)'),
                          const SizedBox(height: 12),
                          _NoteField(controller: _noteController),
                        ],
                      ),
                    ),
                  ),
                  _BottomConfirmBar(
                    isLoading: _isConfirming,
                    onConfirm: _confirmPayment,
                  ),
                ],
              ),
      ),
    );
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String _readError(Object error) {
    final String message = error.toString();
    if (error is _CheckoutException) return error.message;
    if (message.contains('personal_expense_debts') ||
        message.contains('PGRST205')) {
      return 'Tabel personal_expense_debts belum tersedia di Supabase.';
    }
    if (message.contains('row-level security') || message.contains('42501')) {
      return 'Policy Supabase belum mengizinkan membaca atau update tagihan.';
    }
    return 'Gagal memuat pembayaran: $error';
  }
}

class _HeroDebtCard extends StatelessWidget {
  const _HeroDebtCard({required this.debt});

  final _PaymentDebt debt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 26,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFEAE8E4),
                foregroundImage: debt.requesterAvatarUrl.isEmpty
                    ? null
                    : NetworkImage(debt.requesterAvatarUrl),
                child: debt.requesterAvatarUrl.isEmpty
                    ? Text(
                        debt.initials,
                        style: const TextStyle(
                          color: _PersonPaymentCheckoutPageState._primary,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -1,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: _PersonPaymentCheckoutPageState._primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Menyelesaikan Tagihan\ndengan ${debt.requesterName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _PersonPaymentCheckoutPageState._muted,
              fontSize: 13,
              height: 1.28,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatRupiah(debt.amount),
            style: const TextStyle(
              color: _PersonPaymentCheckoutPageState._primary,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: _PersonPaymentCheckoutPageState._soft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Anda berutang kepada ${debt.shortRequesterName}',
              style: const TextStyle(
                color: Color(0xFF736D7F),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _PersonPaymentCheckoutPageState._primary
                  : Colors.transparent,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: _PersonPaymentCheckoutPageState._soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  method.icon,
                  color: _PersonPaymentCheckoutPageState._primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      method.title,
                      style: const TextStyle(
                        color: _PersonPaymentCheckoutPageState._ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      method.subtitle,
                      style: const TextStyle(
                        color: _PersonPaymentCheckoutPageState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettlementDetailsCard extends StatelessWidget {
  const _SettlementDetailsCard({required this.debt});

  final _PaymentDebt debt;

  @override
  Widget build(BuildContext context) {
    final List<_DetailLine> lines = debt.detailLines;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          for (final _DetailLine line in lines) ...<Widget>[
            _DetailRow(label: line.label, amount: line.amount),
            const SizedBox(height: 15),
          ],
          Container(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0E7E7))),
            ),
            child: _DetailRow(
              label: 'Total yang Harus Dilunasi',
              amount: debt.amount,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  final String label;
  final double amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlight
                  ? _PersonPaymentCheckoutPageState._primary
                  : const Color(0xFF625D66),
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          _formatRupiah(amount),
          style: TextStyle(
            color: highlight
                ? _PersonPaymentCheckoutPageState._primary
                : _PersonPaymentCheckoutPageState._ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _PersonPaymentCheckoutPageState._line),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Thanks for covering the dinner!',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
        ),
        style: const TextStyle(
          color: _PersonPaymentCheckoutPageState._ink,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BottomConfirmBar extends StatelessWidget {
  const _BottomConfirmBar({required this.isLoading, required this.onConfirm});

  final bool isLoading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 51,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _PersonPaymentCheckoutPageState._primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _PersonPaymentCheckoutPageState._primary
                .withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: isLoading ? null : onConfirm,
          label: Text(
            isLoading ? 'Memproses...' : 'Konfirmasi Pembayaran',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          iconAlignment: IconAlignment.end,
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.send_outlined, size: 16),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _PersonPaymentCheckoutPageState._primary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              color: _PersonPaymentCheckoutPageState._primary,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _PersonPaymentCheckoutPageState._muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _PaymentDebt {
  const _PaymentDebt({
    required this.id,
    required this.requesterName,
    required this.requesterAvatarUrl,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String requesterName;
  final String requesterAvatarUrl;
  final double amount;
  final String note;
  final DateTime? createdAt;

  factory _PaymentDebt.fromRow(Map<String, dynamic> row) {
    final Object? requester = row['requester'];
    final Map<String, dynamic>? requesterMap = requester is Map<String, dynamic>
        ? requester
        : null;
    final String email = (requesterMap?['email'] ?? '').toString();
    final String name = _firstNotEmpty(<Object?>[
      requesterMap?['user_name'],
      email.contains('@') ? email.split('@').first : email,
      'Sam Miller',
    ]);

    return _PaymentDebt(
      id: (row['id'] ?? '').toString(),
      requesterName: name,
      requesterAvatarUrl: (requesterMap?['avatar_url'] ?? '').toString(),
      amount: _toDouble(row['amount']),
      note: (row['note'] ?? '').toString(),
      createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()),
    );
  }

  String get shortRequesterName {
    final String first = requesterName.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? requesterName : first;
  }

  String get initials {
    final List<String> parts = requesterName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'SS';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<_DetailLine> get detailLines {
    final String label = note.isEmpty ? 'Tagihan personal' : note;
    if (amount <= 0) return const <_DetailLine>[];
    if (note.isNotEmpty && note.contains('|')) {
      final List<String> parts = note
          .split('|')
          .map((String part) => part.trim())
          .where((String part) => part.isNotEmpty)
          .toList();
      final double splitAmount = amount / parts.length;
      return <_DetailLine>[
        for (final String part in parts)
          _DetailLine(label: part, amount: splitAmount),
      ];
    }
    if (amount >= 20000) {
      final double first = (amount * 0.56).roundToDouble();
      return <_DetailLine>[
        _DetailLine(label: label, amount: first),
        _DetailLine(label: 'Biaya tambahan', amount: amount - first),
      ];
    }
    return <_DetailLine>[_DetailLine(label: label, amount: amount)];
  }
}

class _DetailLine {
  const _DetailLine({required this.label, required this.amount});

  final String label;
  final double amount;
}

enum _PaymentMethod {
  venmo(Icons.payments_outlined, 'Venmo', '@alex-miller-92'),
  paypal(Icons.account_balance_wallet_outlined, 'PayPal', 'alex@example.com'),
  bank(Icons.account_balance_outlined, 'Bank Transfer', 'Chase .... 4821');

  const _PaymentMethod(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

class _CheckoutException implements Exception {
  const _CheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _firstNotEmpty(List<Object?> values) {
  for (final Object? value in values) {
    final String text = (value ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }
  return 'SplitSync User';
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}

String _formatRupiah(num value) {
  final int rounded = value.round();
  final String digits = rounded.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int index = 0; index < digits.length; index++) {
    final int reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${rounded < 0 ? '-Rp ' : 'Rp '}${buffer.toString()}';
}
