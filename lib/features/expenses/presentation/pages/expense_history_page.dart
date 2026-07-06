import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/expense_model.dart';
import 'add_expense_page.dart';
import 'expense_detail_page.dart';

class ExpenseHistoryPage extends StatefulWidget {
  const ExpenseHistoryPage({
    super.key,
    this.groupId,
  });

  final String? groupId;

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  String _selectedFilter = 'all';
  late ScrollController _scrollController;
  late Future<List<ExpenseModel>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _expensesFuture = _fetchExpenses();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<ExpenseModel>> _fetchExpenses() async {
    final client = Supabase.instance.client;

    try {
      List<dynamic> response;

      if (widget.groupId != null && widget.groupId!.isNotEmpty) {
        // Fetch expenses for a specific group
        response = await client
            .from('expenses')
            .select()
            .eq('group_id', widget.groupId!)
            .order('created_at', ascending: false);
      } else {
        // Fetch all expenses (global view from reports page)
        response = await client
            .from('expenses')
            .select()
            .order('created_at', ascending: false);
      }

      return response
          .map((dynamic row) => row as Map<String, dynamic>)
          .map(ExpenseModel.fromJson)
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat data pengeluaran: ${e.message}');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _expensesFuture = _fetchExpenses();
    });
    await _expensesFuture;
  }

  List<ExpenseModel> _applyFilter(List<ExpenseModel> expenses) {
    if (_selectedFilter == 'all') return expenses;
    return expenses
        .where((ExpenseModel e) => e.category.value == _selectedFilter)
        .toList();
  }

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Riwayat Pengeluaran',
                        style: TextStyle(
                          color: Color(0xFF1D2430),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFilterTabs(),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => AddExpensePage(
                groupId: widget.groupId ?? '',
                groupName: 'Keluarga Cemara',
                userId: Supabase.instance.client.auth.currentUser?.id ?? '',
                members: <Member>[],
              ),
            ),
          );
          // Refresh after returning from add page
          _refresh();
        },
        backgroundColor: const Color(0xFFD70F1F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<ExpenseModel>>(
      future: _expensesFuture,
      builder: (BuildContext context, AsyncSnapshot<List<ExpenseModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD70F1F)),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final List<ExpenseModel> allExpenses = snapshot.data ?? <ExpenseModel>[];
        final List<ExpenseModel> filtered = _applyFilter(allExpenses);

        if (filtered.isEmpty) {
          return RefreshIndicator(
            color: const Color(0xFFD70F1F),
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const <Widget>[
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFFBDB8B5),
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tidak ada pengeluaran',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFFD70F1F),
          onRefresh: _refresh,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: filtered.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildExpenseItem(filtered[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFD70F1F),
              size: 46,
            ),
            const SizedBox(height: 14),
            const Text(
              'Gagal memuat data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF242A36),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF807A78),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD70F1F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final List<MapEntry<String, String>> filters = <MapEntry<String, String>>[
      const MapEntry<String, String>('all', 'Semua'),
      const MapEntry<String, String>('food', 'Makanan'),
      const MapEntry<String, String>('transport', 'Transportasi'),
      const MapEntry<String, String>('entertainment', 'Hiburan'),
      const MapEntry<String, String>('other', 'Lainnya'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final MapEntry<String, String> filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _selectedFilter == filter.key,
                label: Text(filter.value),
                onSelected: (bool selected) {
                  setState(() {
                    _selectedFilter = filter.key;
                  });
                },
                backgroundColor: const Color(0xFFF4F5F7),
                selectedColor: const Color(0xFFFFEEF0),
                labelStyle: TextStyle(
                  color: _selectedFilter == filter.key
                      ? const Color(0xFFD71920)
                      : const Color(0xFF4B5563),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(ExpenseModel expense) {
    return GestureDetector(
      onTap: () async {
        final bool? changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (BuildContext context) => ExpenseDetailPage(
              expenseId: expense.id,
              description: expense.description,
              amount: expense.amount,
              category: expense.category.value,
              paidBy: expense.paidBy,
              date: expense.createdAt,
              itemCount: expense.itemCount,
            ),
          ),
        );
        if (changed == true) {
          _refresh();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E5EA)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(expense.category.value),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(expense.category.value),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    expense.description,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_shortenPayerId(expense.paidBy)} • ${_formatDate(expense.createdAt)}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatCurrency(expense.amount),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    const Map<String, Color> colors = <String, Color>{
      'food': Color(0xFF4B9F99),
      'transport': Color(0xFF5B7FBD),
      'entertainment': Color(0xFFD4A574),
      'utilities': Color(0xFF8B5CF6),
      'shopping': Color(0xFFEA580C),
      'other': Color(0xFF6B7280),
    };
    return colors[category] ?? const Color(0xFF6B7280);
  }

  IconData _getCategoryIcon(String category) {
    const Map<String, IconData> icons = <String, IconData>{
      'food': Icons.restaurant_outlined,
      'transport': Icons.directions_car_outlined,
      'entertainment': Icons.theaters_outlined,
      'utilities': Icons.flash_on_outlined,
      'shopping': Icons.shopping_bag_outlined,
      'other': Icons.category_outlined,
    };
    return icons[category] ?? Icons.category_outlined;
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(value);
  }

  String _formatDate(DateTime date) {
    final List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Shortens a UUID payer ID to a more readable format.
  /// If it's already a readable name, returns as-is.
  String _shortenPayerId(String payerId) {
    // If it looks like a UUID, show a shortened version
    if (RegExp(r'^[0-9a-fA-F]{8}-').hasMatch(payerId)) {
      return 'User ${payerId.substring(0, 6)}';
    }
    return payerId;
  }
}
