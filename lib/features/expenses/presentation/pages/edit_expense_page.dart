import 'package:flutter/material.dart';

class EditExpensePage extends StatefulWidget {
  const EditExpensePage({
    super.key,
    required this.expenseId,
    required this.initialDescription,
    required this.initialAmount,
    required this.initialCategory,
    this.initialNote,
    this.initialTags = const <String>[],
  });

  final String expenseId;
  final String initialDescription;
  final double initialAmount;
  final String initialCategory;
  final String? initialNote;
  final List<String> initialTags;

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _selectedCategory;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _amountController = TextEditingController(
      text: widget.initialAmount.toString(),
    );
    _noteController = TextEditingController(text: widget.initialNote);
    _selectedCategory = widget.initialCategory;
    _tags = List<String>.from(widget.initialTags);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _noteController.dispose();
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    children: <Widget>[
                      const Text(
                        'Edit Pengeluaran',
                        style: TextStyle(
                          color: Color(0xFF1D2430),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ubah detail pengeluaran',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDescriptionField(),
                      const SizedBox(height: 16),
                      _buildAmountField(),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(),
                      const SizedBox(height: 16),
                      _buildNoteField(),
                      const SizedBox(height: 16),
                      _buildTagsSection(),
                    ],
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Nama pengeluaran',
        prefixIcon: const Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFF6B7280),
          size: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD70F1F)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Jumlah',
        prefixIcon: const Icon(
          Icons.attach_money_outlined,
          color: Color(0xFF6B7280),
          size: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD70F1F)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final List<String> categories = <String>[
      'food',
      'transport',
      'entertainment',
      'utilities',
      'shopping',
      'other',
    ];

    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      items: categories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(_categoryLabel(category)),
        );
      }).toList(),
      onChanged: (String? value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Kategori',
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: Color(0xFF6B7280),
          size: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD70F1F)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Catatan (opsional)',
        prefixIcon: const Icon(
          Icons.notes_outlined,
          color: Color(0xFF6B7280),
          size: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD70F1F)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Tags',
          style: TextStyle(
            color: Color(0xFF1D2430),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String tag in _tags) _buildTagChip(tag, removable: true),
            _buildAddTagButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildTagChip(String label, {bool removable = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E5EA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (removable) ...<Widget>[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() => _tags.remove(label));
              },
              child: const Icon(
                Icons.close,
                size: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddTagButton() {
    return GestureDetector(
      onTap: _showAddTagDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0B5B5)),
        ),
        child: const Text(
          '+ Tag',
          style: TextStyle(
            color: Color(0xFFD71920),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _showAddTagDialog() {
    final TextEditingController tagController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Tag'),
          content: TextField(
            controller: tagController,
            decoration: const InputDecoration(hintText: 'Masukkan tag'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (tagController.text.isNotEmpty) {
                  setState(() {
                    _tags.add(tagController.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
            height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E5EA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _handleDelete,
                child: const Text(
                  'Hapus',
                  style: TextStyle(
                    color: Color(0xFFD71920),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
            height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC70F1B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _handleUpdate,
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpdate() {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan isi semua field yang diperlukan'),
        ),
      );
      return;
    }

    // TODO: Integrate with use case to update expense
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengeluaran berhasil diperbarui')),
    );

    Navigator.pop(context);
  }

  void _handleDelete() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Pengeluaran'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus pengeluaran ini?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Integrate with use case to delete expense
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pengeluaran berhasil dihapus')),
                );
                Navigator.pop(context);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _categoryLabel(String category) {
    const Map<String, String> labels = <String, String>{
      'food': 'Makanan',
      'transport': 'Transportasi',
      'entertainment': 'Hiburan',
      'utilities': 'Utilitas',
      'shopping': 'Belanja',
      'other': 'Lainnya',
    };
    return labels[category] ?? category;
  }
}
