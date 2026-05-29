import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/receipt_ocr_service.dart';
import '../supabase_client.dart';

class ReceiptReviewScreen extends StatefulWidget {
  final List<ExtractedItem> items;
  const ReceiptReviewScreen({super.key, required this.items});

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  late List<ExtractedItem> _items;
  bool _saving = false;

  static const _categories = [
    'Produce', 'Dairy', 'Meat', 'Seafood',
    'Bakery', 'Frozen', 'Beverages', 'Pantry', 'Snacks', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _items = List<ExtractedItem>.from(widget.items);
  }

  Future<void> _saveAll() async {
    if (_items.isEmpty) return;
    setState(() => _saving = true);

    try {
      final userId = supabase.auth.currentUser?.id;

      // 1. Create a receipt record first so inventory items have a traceable source.
      final receiptInsert = await supabase
          .from('receipts')
          .insert({'user_id': userId})
          .select('id')
          .single();
      final receiptId = receiptInsert['id'] as String?;

      // 2. Build inventory rows with the receipt foreign key.
      final rows = _items.map((item) {
        final expiryStr =
            '${item.expiryDate.year}-${item.expiryDate.month.toString().padLeft(2, '0')}-${item.expiryDate.day.toString().padLeft(2, '0')}';
        return {
          'user_id': userId,
          'receipt_id': receiptId,
          'name': item.name,
          'category': item.category,
          'quantity': item.quantity.round(),
          'unit': item.unit,
          'expiry_date': expiryStr,
        };
      }).toList();

      await supabase.from('inventory').insert(rows);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(LucideIcons.checkCircle, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text('${_items.length} item${_items.length == 1 ? '' : 's'} added to inventory!'),
          ]),
          backgroundColor: AppColors.brandGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      // Pop back past scan screen to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(LucideIcons.alertCircle, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to save: $e')),
            ]),
            backgroundColor: AppColors.urgentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _items[index].expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.brandGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _items[index].expiryDate = picked);
    }
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _addBlankItem() {
    setState(() {
      _items.add(ExtractedItem(
        name: '',
        quantity: 1,
        unit: 'pcs',
        category: 'Other',
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandGreenGradientStart,
                  AppColors.brandGreenGradientEnd,
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                          ),
                          child: const Icon(LucideIcons.chevronLeft,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.clipboardList,
                              size: 28, color: AppColors.brandGreen),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Review Items',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Edit details before adding to inventory',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Item count badge ─────────────────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.package, size: 14, color: AppColors.brandGreen),
                  const SizedBox(width: 6),
                  Text(
                    '${_items.length} item${_items.length == 1 ? '' : 's'} found',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Items list ───────────────────────────────────────────────────
          Expanded(
            child: _items.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) => _ItemCard(
                      key: ValueKey(identityHashCode(_items[i])),
                      item: _items[i],
                      index: i,
                      categories: _categories,
                      onDelete: () => _deleteItem(i),
                      onPickDate: () => _pickDate(i),
                      onCategoryChanged: (cat) =>
                          setState(() => _items[i].category = cat),
                      onNameChanged: (v) => _items[i].name = v,
                      onQuantityChanged: (v) {
                        final n = double.tryParse(v);
                        if (n != null) _items[i].quantity = n;
                      },
                      onUnitChanged: (v) => _items[i].unit = v,
                    ),
                  ),
          ),

          // ── Bottom bar ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                // Add item button
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _addBlankItem,
                    icon: const Icon(LucideIcons.plus, size: 16, color: AppColors.brandGreen),
                    label: const Text('Add',
                        style: TextStyle(fontSize: 14, color: AppColors.brandGreen, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      side: BorderSide(color: AppColors.brandGreen.withValues(alpha: 0.3), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_saving || _items.isEmpty) ? null : _saveAll,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.checkCircle2,
                                    size: 16, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Add to Inventory', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: const Icon(LucideIcons.packageOpen, size: 28, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            const Text(
              'No items left',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.foreground, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the Add button below to add items manually.',
              style: TextStyle(fontSize: 13, color: AppColors.mutedForeground, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item card ────────────────────────────────────────────────────────────────

class _ItemCard extends StatefulWidget {
  final ExtractedItem item;
  final int index;
  final List<String> categories;
  final VoidCallback onDelete;
  final VoidCallback onPickDate;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onQuantityChanged;
  final ValueChanged<String> onUnitChanged;

  const _ItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.categories,
    required this.onDelete,
    required this.onPickDate,
    required this.onCategoryChanged,
    required this.onNameChanged,
    required this.onQuantityChanged,
    required this.onUnitChanged,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _unitCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(
      text: widget.item.quantity % 1 == 0
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toString(),
    );
    _unitCtrl = TextEditingController(text: widget.item.unit);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _handleDelete() {
    _animCtrl.reverse().then((_) {
      widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: index badge + name field + delete
                Row(
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: const BoxDecoration(
                        color: AppColors.mintBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${widget.index + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandGreen)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _nameCtrl,
                        onChanged: widget.onNameChanged,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Item name',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _handleDelete,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.urgentRedBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.trash2,
                            size: 14, color: AppColors.urgentRed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: qty + unit + category
                Row(
                  children: [
                    // Quantity
                    SizedBox(
                      width: 68,
                      child: TextFormField(
                        controller: _qtyCtrl,
                        onChanged: widget.onQuantityChanged,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          labelStyle: const TextStyle(
                              fontSize: 11, color: AppColors.mutedForeground, fontWeight: FontWeight.w600),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Unit
                    SizedBox(
                      width: 76,
                      child: TextFormField(
                        controller: _unitCtrl,
                        onChanged: widget.onUnitChanged,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle: const TextStyle(
                              fontSize: 11, color: AppColors.mutedForeground, fontWeight: FontWeight.w600),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Category dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: widget.categories.contains(widget.item.category)
                            ? widget.item.category
                            : 'Other',
                        isDense: true,
                        style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: const TextStyle(
                              fontSize: 11, color: AppColors.mutedForeground, fontWeight: FontWeight.w600),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
                          ),
                        ),
                        items: widget.categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => v != null ? widget.onCategoryChanged(v) : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 3: expiry date picker
                GestureDetector(
                  onTap: widget.onPickDate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.brandGreen.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendarDays,
                            size: 14, color: AppColors.brandGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Expires: ${_fmtDate(widget.item.expiryDate)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandGreen,
                          ),
                        ),
                        const Spacer(),
                        const Icon(LucideIcons.pencil,
                            size: 12, color: AppColors.brandGreen),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
