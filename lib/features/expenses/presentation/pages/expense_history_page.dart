import 'package:flutter/material.dart';
import 'add_expense_page.dart';
import 'expense_detail_page.dart';

class ExpenseHistoryPage extends StatefulWidget {
  const ExpenseHistoryPage({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  String _selectedFilter = 'all';
  late ScrollController _scrollController;

  // Sample data - replace with actual data from repository
  final List<Map<String, dynamic>> _expenses = <Map<String, dynamic>>[
    {
      'id': '1',
      'description': 'Makan di Restoran',
      'amount': 150.00,
      'category': 'food',
      'paidBy': 'John Doe',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'itemCount': 4,
    },
    {
      'id': '2',
      'description': 'Transportasi Uber',
      'amount': 25.50,
      'category': 'transport',
      'paidBy': 'Jane Smith',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'itemCount': null,
    },
    {
      'id': '3',
      'description': 'Tiket Bioskop',
      'amount': 60.00,
      'category': 'entertainment',
      'paidBy': 'John Doe',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'itemCount': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                  child: _buildExpensesList(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => AddExpensePage(
                groupId: widget.groupId,
                groupName: 'Keluarga Cemara',
                userId: 'user-123',
                members: <Member>[
                  Member(id: '1', name: 'John', avatarUrl: ''),
                  Member(id: '2', name: 'Jane', avatarUrl: ''),
                  Member(id: '3', name: 'Bob', avatarUrl: ''),
                ],
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFFD70F1F),
        child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildExpensesList() {
    final List<Map<String, dynamic>> filteredExpenses = _selectedFilter == 'all'
        ? _expenses
        : _expenses
            .where((Map<String, dynamic> e) => e['category'] == _selectedFilter)
            .toList();

    if (filteredExpenses.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada pengeluaran',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: filteredExpenses.length,
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> expense = filteredExpenses[index];
        return _buildExpenseItem(expense);
      },
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> expense) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => ExpenseDetailPage(
              expenseId: expense['id'] as String,
              description: expense['description'] as String,
              amount: expense['amount'] as double,
              category: expense['category'] as String,
              paidBy: expense['paidBy'] as String,
              date: expense['date'] as DateTime,
              itemCount: expense['itemCount'] as int?,
            ),
          ),
        );
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
                color: _getCategoryColor(expense['category']),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(expense['category']),
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
                    expense['description'] as String,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${expense['paidBy']} • ${_formatDate(expense['date'] as DateTime)}',
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
              _formatCurrency(expense['amount'] as double),
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

  String _formatDate(DateTime date) {
    final List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
