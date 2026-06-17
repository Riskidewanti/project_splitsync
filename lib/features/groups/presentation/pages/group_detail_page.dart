import 'package:flutter/material.dart';

class GroupDetailPage extends StatelessWidget {
  const GroupDetailPage({super.key});

  static const Color _primaryColor = Color(0xFFC70F1B);
  static const Color _backgroundColor = Color(0xFFFBF7F4);
  static const Color _textDarkColor = Color(0xFF1F2933);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _greenColor = Color(0xFF00A86B);

  static const List<_BalanceMember> _balances = <_BalanceMember>[
    _BalanceMember(
      name: 'Kamu',
      initial: 'Y',
      status: 'Berhutang Rp 120.500',
      avatarColor: Color(0xFFE0323D),
      statusColor: _primaryColor,
      textColor: Colors.white,
    ),
    _BalanceMember(
      name: 'Alex M.',
      initial: 'A',
      status: 'Mendapat Rp 340.000',
      avatarColor: Color(0xFFD9EAFE),
      statusColor: _greenColor,
      textColor: _textDarkColor,
    ),
    _BalanceMember(
      name: 'Sam T.',
      initial: 'S',
      status: 'Berhutang Rp 219.500',
      avatarColor: Color(0xFFD9EAFE),
      statusColor: _primaryColor,
      textColor: _textDarkColor,
    ),
  ];

  static const List<_ExpenseItem> _expenses = <_ExpenseItem>[
    _ExpenseItem(
      title: 'Le Jules Verne',
      subtitle: 'Alex membayar • Oct 12',
      amount: 'Rp 420.000',
      note: 'Kamu Hutang Rp 140.000',
      noteColor: _textDarkColor,
      icon: Icons.restaurant,
    ),
    _ExpenseItem(
      title: 'EasyJet Flights',
      subtitle: 'Sam membayar • Oct 10',
      amount: 'Rp 850.000',
      note: 'Tidak Ikut',
      noteColor: _greenColor,
      icon: Icons.flight,
    ),
    _ExpenseItem(
      title: 'Eurostar Tickets',
      subtitle: 'Kamu membayar • Oct 08',
      amount: 'Rp 320.000',
      note: 'Kamu meminjamkan Rp 213.33',
      noteColor: _greenColor,
      icon: Icons.train,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        toolbarHeight: 96,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 18),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: _textDarkColor, size: 24),
          ),
        ),
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 18),
          child: Text(
            'Detail Group',
            style: TextStyle(
              color: _textDarkColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderColor),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(23, 18, 23, 112),
              children: <Widget>[
                const _SummaryCard(),
                const SizedBox(height: 12),
                const _ActionButtons(),
                const SizedBox(height: 32),
                const _SectionTitle(title: 'Saldo'),
                const SizedBox(height: 8),
                const _BalanceList(balances: _balances),
                const SizedBox(height: 32),
                const _ExpenseHeader(),
                const SizedBox(height: 14),
                _ExpenseList(expenses: _expenses),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        elevation: 5,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: const Icon(Icons.add, size: 34),
      ),
    );
  }
}

class _BalanceMember {
  const _BalanceMember({
    required this.name,
    required this.initial,
    required this.status,
    required this.avatarColor,
    required this.statusColor,
    required this.textColor,
  });

  final String name;
  final String initial;
  final String status;
  final Color avatarColor;
  final Color statusColor;
  final Color textColor;
}

class _ExpenseItem {
  const _ExpenseItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.note,
    required this.noteColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String note;
  final Color noteColor;
  final IconData icon;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GroupDetailPage._borderColor),
      ),
      child: Column(
        children: <Widget>[
          const Text(
            'TOTAL PENGELUARAN GRUP',
            style: TextStyle(
              color: Color(0xFF5C6670),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Rp 4.250.000',
              style: TextStyle(
                color: GroupDetailPage._textDarkColor,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDDEBFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '↑ Kamu Menerima Rp 1.020.500',
              style: TextStyle(
                color: GroupDetailPage._primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: GroupDetailPage._primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.payments_outlined, size: 19),
              label: const Text(
                'Selesaikan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: GroupDetailPage._textDarkColor,
                side: const BorderSide(color: GroupDetailPage._borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.file_download_outlined, size: 19),
              label: const Text(
                'Laporan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: GroupDetailPage._textDarkColor,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BalanceList extends StatelessWidget {
  const _BalanceList({required this.balances});

  final List<_BalanceMember> balances;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int index = 0; index < balances.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: 12),
            _BalanceCard(member: balances[index]),
          ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.member});

  final _BalanceMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 103,
        minWidth: 110,
        maxWidth: 110,
      ),
      padding: const EdgeInsets.fromLTRB(9, 13, 9, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GroupDetailPage._borderColor),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 18,
              backgroundColor: member.avatarColor,
              child: Text(
                member.initial,
                style: TextStyle(
                  color: member.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GroupDetailPage._textDarkColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              member.status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: member.statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseHeader extends StatelessWidget {
  const _ExpenseHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: _SectionTitle(title: 'Pengeluaran Terkini')),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: GroupDetailPage._primaryColor,
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Lihat semua',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses});

  final List<_ExpenseItem> expenses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 72),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView.builder(
          itemCount: expenses.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemBuilder: (BuildContext context, int index) {
            return _ExpenseTile(
              expense: expenses[index],
              showDivider: index != expenses.length - 1,
            );
          },
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.showDivider});

  final _ExpenseItem expense;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 13),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: GroupDetailPage._borderColor),
              )
            : null,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Icon(
              expense.icon,
              color: GroupDetailPage._textDarkColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GroupDetailPage._textDarkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                expense.amount,
                style: const TextStyle(
                  color: GroupDetailPage._textDarkColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: Text(
                  expense.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: expense.noteColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
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
