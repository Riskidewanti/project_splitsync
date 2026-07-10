import 'package:flutter/material.dart';
import 'package:splitsync/authentication/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../screens/profile_setting/profile_settings_page.dart';
import '../screens/home/home_page.dart';
import '../features/groups/presentation/pages/group_home_page.dart';
import '../features/expenses/presentation/pages/expense_history_page.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseReport {
  const ExpenseReport({
    required this.id,
    required this.title,
    required this.category,
    required this.groupName,
    required this.amount,
    required this.createdAt,
    required this.isShared,
  });

  final String id;
  final String title;
  final String category;
  final String groupName;
  final num amount;
  final DateTime createdAt;
  final bool isShared;
}

class ReportSummary {
  const ReportSummary({
    required this.totalThisMonth,
    required this.lastMonthTotal,
    required this.dailyTotals,
    required this.weeklyTotals,
    required this.categoryTotals,
    required this.biggestTransactions,
    required this.transactionCount,
    required this.averageExpense,
    required this.sharedExpenseCount,
  });

  final num totalThisMonth;
  final num lastMonthTotal;
  final List<num> dailyTotals;
  final List<num> weeklyTotals;
  final Map<String, num> categoryTotals;
  final List<ExpenseReport> biggestTransactions;
  final int transactionCount;
  final num averageExpense;
  final int sharedExpenseCount;

  double get changePercent {
    if (lastMonthTotal == 0) return totalThisMonth == 0 ? 0 : 100;
    return ((totalThisMonth - lastMonthTotal) / lastMonthTotal) * 100;
  }
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Future<ReportSummary> _summaryFuture;
  var _selectedTab = _ReportTab.daily;

  @override
  void initState() {
    super.initState();
    print("REPORT PAGE INIT");
    _summaryFuture = _ReportsRepository.fetchSummary();
  }

  Future<void> _refresh() async {
    setState(() {
      _summaryFuture = _ReportsRepository.fetchSummary();
    });
    await _summaryFuture;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ReportsHeader(responsive: responsive),
            Expanded(
              child: FutureBuilder<ReportSummary>(
                future: _summaryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC8152B),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ReportsErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    );
                  }

                  final summary = snapshot.requireData;

                  final isEmpty =
                      summary.totalThisMonth == 0 &&
                      summary.biggestTransactions.isEmpty;

                  return RefreshIndicator(
                    color: const Color(0xFFC8152B),
                    onRefresh: _refresh,
                    child: isEmpty
                        ? _EmptyReportState(onRefresh: _refresh)
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              responsive.clamp(42, 24, 44),
                              responsive.space(32),
                              responsive.clamp(42, 24, 44),
                              responsive.space(110),
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 430,
                                ),
                                child: Column(
                                  children: [
                                    _TotalSummary(summary: summary),
                                    SizedBox(height: responsive.space(32)),
                                    _ReportTabs(
                                      selected: _selectedTab,
                                      onChanged: (tab) {
                                        setState(() => _selectedTab = tab);
                                      },
                                    ),
                                    SizedBox(height: responsive.space(28)),
                                    _TrendCard(
                                      values: _selectedTab == _ReportTab.daily
                                          ? summary.dailyTotals
                                          : summary.weeklyTotals,
                                      labels: _selectedTab == _ReportTab.daily
                                          ? const [
                                              'Sen',
                                              'Sel',
                                              'Rab',
                                              'Kam',
                                              'Jum',
                                              'Sab',
                                              'Min',
                                            ]
                                          : const ['M1', 'M2', 'M3', 'M4'],
                                    ),
                                    SizedBox(height: responsive.space(22)),
                                    _CategoryCard(summary: summary),
                                    SizedBox(height: responsive.space(22)),
                                    _BiggestTransactionsCard(summary: summary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _ReportsBottomNav(),
    );
  }
}

enum _ReportTab { daily, weekly }

class _ReportsRepository {
  const _ReportsRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<ReportSummary> fetchSummary() async {
    final rows = await _fetchExpenseRows();

    print('=== FETCH SUMMARY ===');
    print('Rows from _fetchExpenseRows: ${rows.length}');

    final expenses = rows.map(_expenseFromRow).toList();
    final now = DateTime.now();
    final thisMonth = expenses.where((expense) {
      return expense.createdAt.year == now.year &&
          expense.createdAt.month == now.month;
    }).toList();
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = expenses.where((expense) {
      return expense.createdAt.year == lastMonthDate.year &&
          expense.createdAt.month == lastMonthDate.month;
    }).toList();

    thisMonth.sort((a, b) => b.amount.compareTo(a.amount));

    return ReportSummary(
      totalThisMonth: _sum(thisMonth),
      lastMonthTotal: _sum(lastMonth),
      dailyTotals: _dailyTotals(thisMonth, now),
      weeklyTotals: _weeklyTotals(thisMonth, now),
      categoryTotals: _categoryTotals(thisMonth),
      biggestTransactions: thisMonth.take(5).toList(),

      transactionCount: thisMonth.length,

      averageExpense: thisMonth.isEmpty
          ? 0
          : _sum(thisMonth) / thisMonth.length,

      sharedExpenseCount: thisMonth.where((e) => e.isShared).length,
    );
  }

  static Future<List<Map<String, dynamic>>> _fetchExpenseRows() async {
    try {
      final session = await AuthService.currentSession();

      if (session == null) {
        return [];
      }

      final rows = await _client
          .from('expenses')
          .select('''
          *,
          groups(name)
        ''')
          .eq('created_by', session.id)
          .order('created_at', ascending: false);

      debugPrint("USER : ${session.id}");
      debugPrint("ROWS : ${rows.length}");

      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  static ExpenseReport _expenseFromRow(Map<String, dynamic> row) {
    final amount =
        _number(row['total_amount']) ??
        _number(row['amount']) ??
        _number(row['nominal']) ??
        0;
    final title = _firstText(row, const [
      'title',
      'name',
      'description',
      'note',
    ], fallback: 'Pengeluaran');
    final category = _firstText(row, const [
      'category',
      'category_name',
      'type',
    ], fallback: 'Lainnya');
    final group = row['groups'];

    final groupName = group is Map<String, dynamic>
        ? (group['name'] ?? 'Pribadi').toString()
        : 'Pribadi';
    final createdAt =
        DateTime.tryParse((row['created_at'] ?? '').toString()) ??
        DateTime.now();

    return ExpenseReport(
      id: (row['id'] ?? title).toString(),
      title: title,
      category: category,
      groupName: groupName,
      amount: amount,
      createdAt: createdAt,
      isShared:
          row['group_id'] != null ||
          row['is_shared'] == true ||
          groupName.toLowerCase() != 'pribadi',
    );
  }

  static num _sum(List<ExpenseReport> expenses) {
    return expenses.fold<num>(0, (total, expense) => total + expense.amount);
  }

  static List<num> _dailyTotals(List<ExpenseReport> expenses, DateTime now) {
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      return _sum(
        expenses
            .where(
              (expense) =>
                  expense.createdAt.year == day.year &&
                  expense.createdAt.month == day.month &&
                  expense.createdAt.day == day.day,
            )
            .toList(),
      );
    });
  }

  static List<num> _weeklyTotals(List<ExpenseReport> expenses, DateTime now) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return List.generate(4, (index) {
      final startDay = 1 + (index * 7);
      final endDay = (startDay + 6 > daysInMonth) ? daysInMonth : startDay + 6;

      return _sum(
        expenses
            .where(
              (expense) =>
                  expense.createdAt.year == now.year &&
                  expense.createdAt.month == now.month &&
                  expense.createdAt.day >= startDay &&
                  expense.createdAt.day <= endDay,
            )
            .toList(),
      );
    });
  }

  static Map<String, num> _categoryTotals(List<ExpenseReport> expenses) {
    final totals = <String, num>{};
    for (final expense in expenses) {
      final normalized = _normalizeCategory(expense.category);
      totals[normalized] = (totals[normalized] ?? 0) + expense.amount;
    }
    return totals;
  }

  static String _normalizeCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('makan') ||
        lower.contains('food') ||
        lower.contains('minum')) {
      return 'Makanan & Minuman';
    }
    if (lower.contains('transport') ||
        lower.contains('taxi') ||
        lower.contains('uber')) {
      return 'Transportasi';
    }
    if (lower.contains('belanja') || lower.contains('shop')) {
      return 'Belanja';
    }
    return 'Lainnya';
  }

  static num? _number(Object? value) {
    if (value is num) return value;
    if (value == null) return null;
    return num.tryParse(value.toString());
  }

  static String _firstText(
    Map<String, dynamic> row,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = (row[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }
}

class _ReportsResponsive {
  const _ReportsResponsive(this.size);

  final Size size;

  factory _ReportsResponsive.of(BuildContext context) {
    return _ReportsResponsive(MediaQuery.sizeOf(context));
  }

  bool get isNarrow => size.width < 380;

  double get scale {
    final widthScale = size.width / 393;
    final heightScale = size.height / 852;
    return widthScale < heightScale
        ? widthScale.clamp(0.82, 1.08)
        : heightScale.clamp(0.82, 1.08);
  }

  double space(double value) => value * scale;

  double font(double value) {
    final factor = isNarrow ? 0.9 : scale;
    return (value * factor).clamp(value * 0.82, value * 1.08);
  }

  double clamp(double value, double min, double max) {
    return space(value).clamp(min, max);
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({required this.responsive});

  final _ReportsResponsive responsive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: responsive.clamp(112, 96, 116),
      padding: EdgeInsets.symmetric(horizontal: responsive.clamp(30, 24, 34)),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'SplitSync',
            style: TextStyle(
              color: const Color(0xFFC8152B),
              fontSize: responsive.font(30),
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
            icon: Icon(
              Icons.notifications_none_rounded,
              color: const Color(0xFF604444),
              size: responsive.clamp(28, 25, 30),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalSummary extends StatelessWidget {
  const _TotalSummary({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    final change = summary.changePercent;
    return Column(
      children: [
        Text(
          'TOTAL PENGELUARAN BULAN INI',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF78706F),
            fontSize: responsive.font(15),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: responsive.space(10)),
        FittedBox(
          child: Text(
            _formatRupiah(summary.totalThisMonth),
            style: TextStyle(
              color: const Color(0xFFA4161D),
              fontSize: responsive.font(44),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: responsive.space(12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.clamp(10, 9, 12),
                vertical: responsive.clamp(5, 4, 6),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7E7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${change >= 0 ? '↗' : '↘'} ${change.abs().toStringAsFixed(0)}% dari bulan lalu',
                style: TextStyle(
                  color: const Color(0xFFE63C3C),
                  fontSize: responsive.font(15),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: responsive.space(10)),
            Text(
              _monthLabel(DateTime.now()),
              style: TextStyle(
                color: const Color(0xFF78706F),
                fontSize: responsive.font(15),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.space(28)),

        Row(
          children: [
            Expanded(
              child: _SummaryInfoCard(
                title: "Transaksi",
                value: summary.transactionCount.toString(),
              ),
            ),
            SizedBox(width: responsive.space(12)),
            Expanded(
              child: _SummaryInfoCard(
                title: "Rata-rata",
                value: _formatRupiah(summary.averageExpense),
              ),
            ),
          ],
        ),

        SizedBox(height: responsive.space(12)),

        Row(
          children: [
            Expanded(
              child: _SummaryInfoCard(
                title: "Shared Bill",
                value: summary.sharedExpenseCount.toString(),
              ),
            ),
            SizedBox(width: responsive.space(12)),
            Expanded(
              child: _SummaryInfoCard(
                title: "Bulan",
                value: _monthLabel(DateTime.now()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReportTabs extends StatelessWidget {
  const _ReportTabs({required this.selected, required this.onChanged});

  final _ReportTab selected;
  final ValueChanged<_ReportTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TabButton(
                label: 'Harian',
                active: selected == _ReportTab.daily,
                onTap: () => onChanged(_ReportTab.daily),
              ),
            ),
            Expanded(
              child: _TabButton(
                label: 'Mingguan',
                active: selected == _ReportTab.weekly,
                onTap: () => onChanged(_ReportTab.weekly),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.space(10)),
        Container(height: 1, color: const Color(0xFFE0DDDA)),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFFC8152B) : const Color(0xFF6E6867),
              fontSize: responsive.font(19),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: responsive.space(14)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 3,
            width: double.infinity,
            color: active ? const Color(0xFFC8152B) : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

// class _TrendCard extends StatelessWidget {
//   const _TrendCard({required this.values, required this.labels});

//   final List<num> values;
//   final List<String> labels;

//   @override
//   Widget build(BuildContext context) {
//     final responsive = _ReportsResponsive.of(context);
//     final maxValue = values.fold<num>(
//       0,
//       (max, value) => value > max ? value : max,
//     );
//     return _ReportCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _CardTitle('Tren Pengeluaran'),
//           SizedBox(height: responsive.space(42)),
//           SizedBox(
//             height: responsive.clamp(150, 130, 160),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: List.generate(values.length, (index) {
//                 final value = values[index];
//                 final ratio = maxValue == 0
//                     ? 0.36
//                     : (value / maxValue).clamp(0.28, 1.0);
//                 final active = value == maxValue && maxValue > 0;
//                 return Expanded(
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: responsive.clamp(5, 3, 6),
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         Expanded(
//                           child: Align(
//                             alignment: Alignment.bottomCenter,
//                             child: FractionallySizedBox(
//                               heightFactor: ratio.toDouble(),
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: active
//                                       ? const Color(0xFF8C0010)
//                                       : const Color(0xFFE4E0DC),
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: responsive.space(14)),
//                         Text(
//                           labels[index],
//                           style: TextStyle(
//                             color: const Color(0xFF695D5C),
//                             fontSize: responsive.font(13),
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.values, required this.labels});

  final List<num> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);

    final maxValue = values.isEmpty
        ? 1
        : values.reduce((a, b) => a > b ? a : b).toDouble();

    if (values.every((e) => e == 0)) {
      return _ReportCard(
        child: Column(
          children: [
            const _CardTitle("Tren Pengeluaran"),
            SizedBox(height: responsive.space(40)),
            const Icon(
              Icons.insert_chart_outlined,
              size: 55,
              color: Colors.grey,
            ),
            SizedBox(height: responsive.space(12)),
            const Text(
              "Belum ada data transaksi",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle("Tren Pengeluaran"),
          SizedBox(height: responsive.space(24)),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxValue == 0 ? 1 : maxValue / 5,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      interval: maxValue == 0 ? 1 : maxValue / 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatChartValue(value),
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= labels.length) {
                          return const SizedBox();
                        }

                        return Text(
                          labels[value.toInt()],
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  values.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index].toDouble(),
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    final total = summary.categoryTotals.values.fold<num>(
      0,
      (sum, value) => sum + value,
    );
    final ordered = _orderedCategories(summary.categoryTotals);
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle('Kategori Teratas'),
          SizedBox(height: responsive.space(26)),
          for (final entry in ordered) ...[
            _CategoryRow(
              label: entry.key,
              amount: entry.value,
              percent: total == 0 ? 0 : (entry.value / total),
            ),
            SizedBox(height: responsive.space(22)),
          ],
        ],
      ),
    );
  }

  List<MapEntry<String, num>> _orderedCategories(Map<String, num> totals) {
    final defaults = {
      'Makanan & Minuman': totals['Makanan & Minuman'] ?? 0,
      'Transportasi': totals['Transportasi'] ?? 0,
      'Belanja': totals['Belanja'] ?? 0,
      'Lainnya': totals['Lainnya'] ?? 0,
    };
    final entries = defaults.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.amount,
    required this.percent,
  });

  final String label;
  final num amount;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    final icon = switch (label) {
      'Makanan & Minuman' => Icons.restaurant_rounded,
      'Transportasi' => Icons.directions_car_rounded,
      'Belanja' => Icons.shopping_bag_outlined,
      _ => Icons.more_horiz_rounded,
    };
    final fill = percent.clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFA4161D),
              size: responsive.clamp(22, 20, 24),
            ),
            SizedBox(width: responsive.space(10)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF242A36),
                  fontSize: responsive.font(16),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${(percent * 100).round()}%',
              style: TextStyle(
                color: const Color(0xFF242A36),
                fontSize: responsive.font(16),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.space(10)),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: responsive.clamp(8, 7, 9),
            backgroundColor: const Color(0xFFE4E0DC),
            valueColor: AlwaysStoppedAnimation<Color>(
              amount == 0 ? const Color(0xFFD6C1C1) : const Color(0xFFA4161D),
            ),
          ),
        ),
      ],
    );
  }
}

class _BiggestTransactionsCard extends StatelessWidget {
  const _BiggestTransactionsCard({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    final transactions = summary.biggestTransactions;
    return _ReportCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: _CardTitle('Transaksi Terbesar')),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    SmoothTransitionRoute(page: const ExpenseHistoryPage()),
                  );
                },
                child: Text(
                  'Lihat Semua ›',
                  style: TextStyle(
                    color: const Color(0xFF8C0010),
                    fontSize: responsive.font(15),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.space(26)),
          if (transactions.isEmpty)
            _EmptyTransactions(responsive: responsive)
          else
            for (final transaction in transactions) ...[
              _TransactionRow(expense: transaction),
              SizedBox(height: responsive.space(26)),
            ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.expense});

  final ExpenseReport expense;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    final icon = _iconForCategory(expense.category);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: responsive.clamp(22, 20, 24),
          backgroundColor: const Color(0xFFFFD8D8),
          child: Icon(
            icon,
            color: const Color(0xFF8C0010),
            size: responsive.clamp(23, 20, 24),
          ),
        ),
        SizedBox(width: responsive.space(16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF242A36),
                  fontSize: responsive.font(16),
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              SizedBox(height: responsive.space(4)),
              Text(
                '${_dateLabel(expense.createdAt)} • ${expense.groupName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF807A78),
                  fontSize: responsive.font(14),
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: responsive.space(10)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatRupiah(expense.amount).replaceFirst(' ', '\n'),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFFA4161D),
                fontSize: responsive.font(15),
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            SizedBox(height: responsive.space(7)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECE9E5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                expense.isShared ? 'TAGIHAN\nBERSAMA' : 'PRIBADI',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF706A67),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _iconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('makan') || lower.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('belanja') || lower.contains('shop')) {
      return Icons.shopping_cart_rounded;
    }
    if (lower.contains('transport')) return Icons.directions_car_rounded;
    return Icons.payments_outlined;
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.clamp(24, 20, 26)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xFF242A36),
        fontSize: responsive.font(22),
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SummaryInfoCard extends StatelessWidget {
  const _SummaryInfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: responsive.space(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.font(13),
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: responsive.space(6)),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: responsive.font(17),
              fontWeight: FontWeight.bold,
              color: const Color(0xFFA4161D),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.responsive});

  final _ReportsResponsive responsive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.space(24)),
      child: Text(
        'Belum ada pengeluaran tercatat bulan ini.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFF807A78),
          fontSize: responsive.font(15),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyReportState extends StatelessWidget {
  const _EmptyReportState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: responsive.space(120)),
        const Icon(
          Icons.insert_chart_outlined,
          size: 80,
          color: Color(0xFFC8152B),
        ),
        SizedBox(height: responsive.space(20)),
        Center(
          child: Text(
            "Belum ada transaksi",
            style: TextStyle(
              fontSize: responsive.font(22),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: responsive.space(10)),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Tambahkan pengeluaran pertamamu agar laporan dapat ditampilkan.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.font(15),
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportsErrorState extends StatelessWidget {
  const _ReportsErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final responsive = _ReportsResponsive.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.space(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFC8152B),
              size: 46,
            ),
            SizedBox(height: responsive.space(14)),
            Text(
              'Laporan belum bisa dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF242A36),
                fontSize: responsive.font(20),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: responsive.space(8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF807A78),
                fontSize: responsive.font(14),
              ),
            ),
            SizedBox(height: responsive.space(16)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8152B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class SmoothTransitionRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothTransitionRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOutCubic;
          final CurvedAnimation curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );
          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.02),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      );
}

class _ReportsBottomNav extends StatelessWidget {
  const _ReportsBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.bottomNavHeight,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomNavItem(
            icon: Icons.home_rounded,
            label: 'Beranda',
            onTap: () => Navigator.of(
              context,
            ).pushReplacement(SmoothTransitionRoute(page: const HomePage())),
          ),
          _BottomNavItem(
            icon: Icons.groups_rounded,
            label: 'Grup',
            onTap: () => Navigator.of(context).pushReplacement(
              SmoothTransitionRoute(page: const GroupHomePage()),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFC8152B),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
          ),
          const _BottomNavItem(
            icon: Icons.insert_chart_rounded,
            label: 'Laporan',
            active: true,
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            onTap: () => Navigator.of(context).pushReplacement(
              SmoothTransitionRoute(page: const ProfileSettingsPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFC8152B) : const Color(0xFF6C6968);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: active
            ? BoxDecoration(
                color: const Color(0xFFFFD8D8),
                borderRadius: BorderRadius.circular(AppRadius.md),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRupiah(num value) {
  final rounded = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final remaining = rounded.length - i;
    buffer.write(rounded[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return 'Rp ${buffer.toString()}';
}

String _monthLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String _formatChartValue(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return '${(value / 1000).round()}K';
  }

  return value.toStringAsFixed(0);
}
