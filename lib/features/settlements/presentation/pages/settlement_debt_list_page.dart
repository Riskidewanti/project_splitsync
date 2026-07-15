import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../authentication/auth_service.dart';

class SettlementDebtListPage extends StatefulWidget {
  const SettlementDebtListPage({super.key, this.userId = ''});

  final String userId;

  @override
  State<SettlementDebtListPage> createState() => _SettlementDebtListPageState();
}

class _SettlementDebtListPageState extends State<SettlementDebtListPage> {
  static const Color _primary = Color(0xFF93000C);
  static const Color _accent = Color(0xFFC8101B);
  static const Color _ink = Color(0xFF0F1C2E);
  static const Color _muted = Color(0xFF777178);
  static const Color _surface = Color(0xFFFFFAF7);
  static const Color _line = Color(0xFFE8E1E1);

  final List<_DebtItem> _debts = <_DebtItem>[];
  final Set<String> _settlingIds = <String>{};
  bool _isLoading = true;
  bool _canMarkAsPaid = true;
  String _currentUserId = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final session = await AuthService.currentSession();

    _currentUserId = session?.id ?? '';

    debugPrint("LOGIN USER = $_currentUserId");

    await _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<dynamic> rows = await _fetchDebtRows();
      final List<_DebtItem> debts = rows
          .whereType<Map<String, dynamic>>()
          .map(_debtFromRow)
          .whereType<_DebtItem>()
          .toList();
      debts.sort(
        (_DebtItem first, _DebtItem second) =>
            second.amount.compareTo(first.amount),
      );

      if (!mounted) return;
      setState(() {
        _debts
          ..clear()
          ..addAll(debts);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _readErrorMessage(error);
      });
    }
  }

  Future<List<dynamic>> _fetchDebtRows() async {
    try {
      final List<dynamic> rows = await _baseDebtQuery(
        Supabase.instance.client
            .from('split_bill')
            .select(
              'id,user_id,exact_amount,category,currency,created_at,is_paid,profiles:user_id(full_name,display_name,name,avatar_url,photo_url)',
            ),
        onlyUnpaid: true,
      );

      debugPrint("==============================");
      debugPrint("ROWS = ${rows.length}");
      for (final r in rows) {
        debugPrint("ROW -> ${r['user_id']}  amount=${r['exact_amount']}");
      }
      debugPrint(rows.toString());
      debugPrint("==============================");

      _canMarkAsPaid = true;
      return rows;
    } catch (error) {
      final bool missingPaidColumns =
          error.toString().contains('is_paid') ||
          error.toString().contains('paid_at');

      if (!missingPaidColumns) {
        final List<dynamic> rows = await _baseDebtQuery(
          Supabase.instance.client
              .from('split_bill')
              .select(
                'id,user_id,exact_amount,category,currency,created_at,is_paid',
              ),
          onlyUnpaid: true,
        );
        _canMarkAsPaid = true;
        return rows;
      }

      final List<dynamic> rows = await _baseDebtQuery(
        Supabase.instance.client
            .from('split_bill')
            .select('id,user_id,exact_amount,category,currency,created_at'),
        onlyUnpaid: false,
      );
      _canMarkAsPaid = false;
      return rows;
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _baseDebtQuery(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query, {
    required bool onlyUnpaid,
  }) {
    PostgrestFilterBuilder<List<Map<String, dynamic>>> filtered = query.gt(
      'exact_amount',
      0,
    );

    if (onlyUnpaid) {
      filtered = filtered.eq('is_paid', false);
    }

    debugPrint("SESSION USER = $_currentUserId");

    if (_isUuid(_currentUserId)) {
      return filtered.eq('user_id', _currentUserId);
    }

    return filtered.eq('user_id', '__INVALID__');
  }

  _DebtItem? _debtFromRow(Map<String, dynamic> row) {
    final String id = (row['id'] ?? '').toString();
    final double amount = _toDouble(row['exact_amount']);
    if (id.isEmpty || amount <= 0) return null;

    final Object? profile = row['profiles'] ?? row['profile'] ?? row['users'];
    final Map<String, dynamic>? profileMap = profile is Map<String, dynamic>
        ? profile
        : null;
    final String userId = (row['user_id'] ?? '').toString();
    final String category = _firstNotEmpty(<Object?>[
      row['category'],
      'Pembayaran',
    ]);

    return _DebtItem(
      id: id,
      userId: userId,
      name: _firstNotEmpty(<Object?>[
        profileMap?['full_name'],
        profileMap?['display_name'],
        profileMap?['name'],
        'Teman ${userId.length >= 4 ? userId.substring(0, 4) : userId}',
      ]),
      avatarUrl: _firstNotEmpty(<Object?>[
        profileMap?['avatar_url'],
        profileMap?['photo_url'],
      ], fallback: ''),
      description: _descriptionFor(category, row['created_at']),
      category: category,
      amount: amount,
    );
  }

  Future<void> _settleDebt(_DebtItem debt) async {
    if (_settlingIds.contains(debt.id)) return;

    setState(() => _settlingIds.add(debt.id));

    try {
      debugPrint(
        "SUPABASE CURRENT USER = ${Supabase.instance.client.auth.currentUser?.id}",
      );

      debugPrint(
        "SUPABASE SESSION = ${Supabase.instance.client.auth.currentSession != null}",
      );

      debugPrint(
        "SUPABASE TOKEN = ${Supabase.instance.client.auth.currentSession?.accessToken != null}",
      );
      final check = await Supabase.instance.client
          .from('split_bill')
          .select()
          .eq('id', debt.id);

      debugPrint("CHECK BEFORE = $check");

      // TAMBAHKAN INI
      debugPrint(
        "SUPABASE CURRENT USER = ${Supabase.instance.client.auth.currentUser?.id}",
      );

      debugPrint(
        "SUPABASE SESSION = ${Supabase.instance.client.auth.currentSession != null}",
      );

      debugPrint(
        "SUPABASE ACCESS TOKEN = ${Supabase.instance.client.auth.currentSession?.accessToken}",
      );

      final deleted = await Supabase.instance.client
          .from('split_bill')
          .delete()
          .eq('id', debt.id)
          .select();

      debugPrint("DELETE = $deleted");

      final after = await Supabase.instance.client
          .from('split_bill')
          .select()
          .eq('id', debt.id);

      debugPrint("CHECK AFTER = $after");

      await _loadDebts();

      if (!mounted) return;

      setState(() {
        _settlingIds.remove(debt.id);
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${debt.name} berhasil dilunasi')),
        );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _settlingIds.remove(debt.id);
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_readErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalDebt = _debts.fold<double>(
      0,
      (double total, _DebtItem item) => total + item.amount,
    );

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Lunasi Pembayaran',
          style: TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _accent,
          onRefresh: _loadDebts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
            children: <Widget>[
              _DebtSummaryCard(total: totalDebt, priorityCount: _debts.length),
              const SizedBox(height: 14),
              const Text(
                'Daftar Hutang',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(
                    child: CircularProgressIndicator(color: _accent),
                  ),
                )
              else if (_errorMessage != null)
                _MessageState(
                  icon: Icons.error_outline,
                  title: 'Gagal memuat hutang',
                  message: _errorMessage!,
                  actionLabel: 'Coba Lagi',
                  onAction: _loadDebts,
                )
              else if (_debts.isEmpty)
                const _MessageState(
                  icon: Icons.check_circle_outline,
                  title: 'Tidak ada hutang',
                  message: 'Tidak ada hutang yang perlu dilunasi',
                )
              else
                for (int index = 0; index < _debts.length; index++) ...<Widget>[
                  _DebtTile(
                    debt: _debts[index],
                    isPriority: index == 1,
                    isSettling: _settlingIds.contains(_debts[index].id),
                    onSettle: () => _settleDebt(_debts[index]),
                  ),
                  const SizedBox(height: 11),
                ],
            ],
          ),
        ),
      ),
    );
  }

  String _descriptionFor(String category, Object? createdAt) {
    final DateTime? date = DateTime.tryParse((createdAt ?? '').toString());
    final String label = category.isEmpty ? 'Pembayaran' : category;
    if (date == null) return label;
    return '$label - ${date.day}/${date.month}/${date.year}';
  }

  String _firstNotEmpty(List<Object?> values, {String fallback = 'Teman'}) {
    for (final Object? value in values) {
      final String text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String _readErrorMessage(Object error) {
    final String message = error.toString();
    if (message.contains('is_paid') || message.contains('paid_at')) {
      return 'Kolom is_paid/paid_at belum ada. Jalankan migration split_bill terbaru di Supabase.';
    }
    if (message.contains('row-level security')) {
      return 'Policy RLS split_bill belum mengizinkan baca/update data.';
    }
    return 'Gagal memuat data: $error';
  }
}

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard({required this.total, required this.priorityCount});

  final double total;
  final int priorityCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 101,
      decoration: BoxDecoration(
        color: _SettlementDebtListPageState._primary,
        borderRadius: BorderRadius.circular(5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _SettlementDebtListPageState._primary.withValues(
              alpha: 0.16,
            ),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 36,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(9),
                  topRight: Radius.circular(5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Total Hutang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRupiah(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: _SettlementDebtListPageState._primary,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$priorityCount Prioritas',
                        style: const TextStyle(
                          color: _SettlementDebtListPageState._primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.debt,
    required this.isPriority,
    required this.isSettling,
    required this.onSettle,
  });

  final _DebtItem debt;
  final bool isPriority;
  final bool isSettling;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPriority
              ? _SettlementDebtListPageState._primary
              : Colors.transparent,
          width: isPriority ? 1.2 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _DebtAvatar(debt: debt, isPriority: isPriority),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  debt.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _SettlementDebtListPageState._ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  debt.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _SettlementDebtListPageState._muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _formatRupiah(debt.amount),
                style: const TextStyle(
                  color: _SettlementDebtListPageState._primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 68,
                height: 28,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: _SettlementDebtListPageState._primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: isSettling ? null : onSettle,
                  child: isSettling
                      ? const SizedBox.square(
                          dimension: 13,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Lunasi',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtAvatar extends StatelessWidget {
  const _DebtAvatar({required this.debt, required this.isPriority});

  final _DebtItem debt;
  final bool isPriority;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEDE7DD),
          foregroundImage: debt.avatarUrl.isEmpty
              ? null
              : NetworkImage(debt.avatarUrl),
          child: Text(
            debt.name.characters.first.toUpperCase(),
            style: const TextStyle(
              color: _SettlementDebtListPageState._primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 12,
            height: 12,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPriority ? Icons.flight_takeoff : Icons.receipt_long,
              color: _SettlementDebtListPageState._primary,
              size: 9,
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 36),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SettlementDebtListPageState._line),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: _SettlementDebtListPageState._accent, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _SettlementDebtListPageState._ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _SettlementDebtListPageState._muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _DebtItem {
  const _DebtItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.description,
    required this.category,
    required this.amount,
  });

  final String id;
  final String userId;
  final String name;
  final String avatarUrl;
  final String description;
  final String category;
  final double amount;
}

String _formatRupiah(double value) {
  final bool hasDecimals = value % 1 != 0;
  final String fixed = hasDecimals
      ? value.toStringAsFixed(2)
      : value.round().toString();
  final List<String> parts = fixed.split('.');
  final String digits = parts.first;
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    final int reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  if (parts.length > 1) {
    return 'Rp ${buffer.toString()}.${parts.last}';
  }

  return 'Rp ${buffer.toString()}';
}
