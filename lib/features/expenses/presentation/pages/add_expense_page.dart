import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:splitsync/features/expenses/data/datasources/supabase_expense_datasource.dart';
import 'package:splitsync/features/expenses/presentation/pages/split_calculation_page.dart';

class Member {
  Member({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.isSelected = false,
  });

  final String id;
  final String name;
  final String avatarUrl;
  bool isSelected;
}

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.userId,
    required this.members,
  });

  final String groupId;
  final String groupName;
  final String userId;
  final List<Member> members;

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  static const Color _primary = Color(0xFF8D000B);
  static const Color _ink = Color(0xFF102033);
  static const Color _muted = Color(0xFF8F8585);
  static const Color _surface = Color(0xFFFFFAF7);
  static const Color _soft = Color(0xFFF0F1FF);
  static const Color _peach = Color(0xFFFFB7AF);

  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late List<Member> _members;
  String _selectedCategory = 'food';
  final DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController(text: '0');
    _members = widget.members.map((Member member) {
      return Member(
        id: member.id,
        name: member.name,
        avatarUrl: member.avatarUrl,
        isSelected: member.isSelected,
      );
    }).toList();
    _loadFriendsFromSupabase();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, size: 24),
        ),
        centerTitle: true,
        title: const Text(
          'Tambah Pengeluaran',
          style: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildAmountSection(),
              const SizedBox(height: 28),
              _buildCategorySection(),
              const SizedBox(height: 28),
              _buildSplitDenganSection(),
              const SizedBox(height: 30),
              _buildDateGroupSection(),
              const SizedBox(height: 38),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadFriendsFromSupabase() async {
    setState(() => _isLoadingMembers = true);

    if (!_isUuid(widget.groupId) || !_isUuid(widget.userId)) {
      setState(() {
        _members = <Member>[];
        _isLoadingMembers = false;
      });
      return;
    }

    try {
      final List<dynamic> rows = await _fetchFriendRows();

      final List<Member> friends = rows
          .map((dynamic row) => row as Map<String, dynamic>)
          .map(_memberFromGroupMemberRow)
          .where((Member? member) => member != null)
          .cast<Member>()
          .toList();

      if (!mounted) return;
      setState(() {
        _members = friends;
        _isLoadingMembers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _members = <Member>[];
        _isLoadingMembers = false;
      });
    }
  }

  Future<List<dynamic>> _fetchFriendRows() async {
    final SupabaseQueryBuilder table = Supabase.instance.client.from(
      'group_members',
    );

    try {
      return await table
          .select(
            'id,user_id,status,profiles:user_id(full_name,display_name,name,avatar_url,photo_url)',
          )
          .eq('group_id', widget.groupId)
          .eq('status', 'active')
          .neq('user_id', widget.userId);
    } catch (_) {
      return await Supabase.instance.client
          .from('group_members')
          .select()
          .eq('group_id', widget.groupId)
          .eq('status', 'active')
          .neq('user_id', widget.userId);
    }
  }

  Member? _memberFromGroupMemberRow(Map<String, dynamic> row) {
    final String id = (row['user_id'] ?? row['id'] ?? '').toString();
    if (id.isEmpty) return null;

    final Object? profile = row['profiles'] ?? row['users'] ?? row['user'];
    final Map<String, dynamic>? profileMap = profile is Map<String, dynamic>
        ? profile
        : null;

    final String name = _firstNotEmpty(<Object?>[
      profileMap?['full_name'],
      profileMap?['display_name'],
      profileMap?['name'],
      row['name'],
      'Teman ${id.length >= 4 ? id.substring(0, 4) : id}',
    ]);

    final String avatarUrl = _firstNotEmpty(<Object?>[
      profileMap?['avatar_url'],
      profileMap?['photo_url'],
      row['avatar_url'],
    ], fallback: '');

    return Member(id: id, name: name, avatarUrl: avatarUrl);
  }

  String _firstNotEmpty(List<Object?> values, {String fallback = 'Teman'}) {
    for (final Object? value in values) {
      final String text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Text(
          'Masukkan Jumlah',
          style: TextStyle(color: _muted, fontSize: 14),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            const Text(
              'Rp',
              style: TextStyle(
                color: _primary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 24),
            Flexible(
              child: IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Untuk apa pengeluaran ini?',
            style: TextStyle(
              color: _ink.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'cth: makan malam di Lu Jules Verne',
            hintStyle: const TextStyle(color: Color(0xFFC9C0BE), fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 17,
            ),
          ),
          style: const TextStyle(color: _ink, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    final List<_CategoryItem> categories = <_CategoryItem>[
      const _CategoryItem('food', 'Makan', Icons.restaurant),
      const _CategoryItem('transport', 'Transport', Icons.commute),
      const _CategoryItem('travel', 'Travel', Icons.flight),
      const _CategoryItem('shopping', 'Belanja', Icons.shopping_bag_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Category', style: _sectionLabelStyle()),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: categories.map((_CategoryItem category) {
            final bool selected = _selectedCategory == category.id;
            return SizedBox(
              width: 68,
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = category.id),
                child: Column(
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: selected ? _primary : _soft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category.icon,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF6D5757),
                        size: 23,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? _primary : const Color(0xFFC7BEBA),
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSplitDenganSection() {
    final List<Member> visibleMembers = _members.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Split Dengan', style: _sectionLabelStyle()),
            if (_members.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    for (final Member member in _members) {
                      member.isSelected = true;
                    }
                  });
                },
                child: const Text(
                  'Pilih semua',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoadingMembers)
          const SizedBox(
            height: 88,
            child: Center(child: CircularProgressIndicator(color: _primary)),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final Member member in visibleMembers)
                SizedBox(width: 84, child: _buildMemberAvatar(member)),
              SizedBox(width: 84, child: _buildAddMemberButton()),
            ],
          ),
      ],
    );
  }

  Widget _buildMemberAvatar(Member member) {
    return GestureDetector(
      onTap: () => setState(() => member.isSelected = !member.isSelected),
      child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: member.isSelected ? _primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipOval(child: _buildAvatarImage(member)),
              ),
              if (member.isSelected)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: member.isSelected ? _ink : const Color(0xFFBFB7B3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(Member member) {
    if (member.avatarUrl.isNotEmpty) {
      return Image.network(
        member.avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialAvatar(member),
      );
    }

    return _buildInitialAvatar(member);
  }

  Widget _buildInitialAvatar(Member member) {
    return Container(
      color: const Color(0xFF737373),
      alignment: Alignment.center,
      child: Text(
        member.name.isEmpty ? '?' : member.name.characters.first.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAddMemberButton() {
    return GestureDetector(
      onTap: _showAddMemberDialog,
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _peach,
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(Icons.person_add_alt_1, color: _peach, size: 24),
          ),
          const SizedBox(height: 9),
          const Text(
            'Tambah\nTeman',
            textAlign: TextAlign.center,
            style: TextStyle(color: _peach, fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Teman'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nama teman'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final String name = nameController.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  _members.add(
                    Member(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      avatarUrl: '',
                      isSelected: true,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateGroupSection() {
    final String dateStr =
        'Hari ini, ${_getMonthName(_selectedDate.month)} ${_selectedDate.day}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.calendar_today, color: _primary, size: 19),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              dateStr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF4B3C3C),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.groups, color: _primary, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF4B3C3C),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: _isLoading ? null : _handleSubmit,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.receipt_long, size: 18),
        label: Text(
          _isLoading ? 'Menyimpan...' : 'Simpan Pengeluaran',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan jumlah yang valid')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi deskripsi pengeluaran')),
      );
      return;
    }

    final List<Member> selectedMembers = _members
        .where((Member member) => member.isSelected)
        .toList();

    setState(() => _isLoading = true);

    bool canContinue = false;

    try {
      final SupabaseExpenseDatasource datasource = SupabaseExpenseDatasource(
        Supabase.instance.client,
      );

      await datasource.createExpense(
        groupId: widget.groupId,
        paidBy: widget.userId,
        amount: amount,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
      );

      canContinue = true;
    } catch (e) {
      canContinue = _isUuidInputError(e);
      if (!canContinue && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted || !canContinue) return;

    final double splitAmount = amount / (selectedMembers.length + 1);
    final List<SplitMember> splitMembers = <SplitMember>[
      SplitMember(name: 'You', avatarText: 'Y', amount: splitAmount),
      ...selectedMembers.map(
        (Member member) => SplitMember(
          name: member.name,
          avatarText: member.name.characters.first.toUpperCase(),
          amount: splitAmount,
        ),
      ),
    ];

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SplitCalculationPage(
          merchantName: _descriptionController.text.trim(),
          expenseDate: _selectedDate,
          items: <ReceiptItem>[
            ReceiptItem(
              name: _descriptionController.text.trim(),
              quantity: 1,
              price: amount,
            ),
          ],
          subtotal: amount,
          tax: 0,
          serviceFee: 0,
          totalAmount: amount,
          members: splitMembers,
          currentUserId: widget.userId,
        ),
      ),
    );
  }

  bool _isUuidInputError(Object error) {
    final String message = error.toString();
    return message.contains('22P02') ||
        message.contains('invalid input syntax for type uuid');
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  TextStyle _sectionLabelStyle() {
    return TextStyle(
      color: _ink.withValues(alpha: 0.72),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
  }

  String _getMonthName(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _CategoryItem {
  const _CategoryItem(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}
