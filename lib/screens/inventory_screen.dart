import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/food_item.dart';
import '../supabase_client.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/fade_in_slide.dart';
import '../utils/food_item_mapper.dart';
import '../widgets/shimmer_loading.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<FoodItem> _allItems = [];
  bool _loading = true;
  String? _error;

  String _search = '';
  String _selectedCategory = 'All';
  String _sortBy = 'urgency';
  bool _showSortMenu = false;

  static const _sortOptions = [
    {'label': 'Expiry Date', 'value': 'expiry'},
    {'label': 'Name',        'value': 'name'},
    {'label': 'Urgency',     'value': 'urgency'},
  ];
  static const _urgencyOrder = {
    UrgencyLevel.urgent: 0,
    UrgencyLevel.soon:   1,
    UrgencyLevel.ok:     2,
  };

  List<String> get _categories {
    final cats = _allItems.map((i) => i.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<FoodItem> get _filtered {
    var items = _allItems.where((item) {
      final matchesSearch   = item.name.toLowerCase().contains(_search.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    items.sort((a, b) {
      if (_sortBy == 'name')   return a.name.compareTo(b.name);
      if (_sortBy == 'expiry') return a.daysUntilExpiry.compareTo(b.daysUntilExpiry);
      return (_urgencyOrder[a.urgency] ?? 2).compareTo(_urgencyOrder[b.urgency] ?? 2);
    });

    return items;
  }

  bool get _isFiltered => _search.isNotEmpty || _selectedCategory != 'All';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await supabase
          .from('inventory')
          .select('id, name, category, quantity, unit, expiry_date')
          .eq('status', 'active')
          .order('expiry_date', ascending: true);

      var items = (response as List)
          .map((row) => rowToFoodItem(row as Map<String, dynamic>))
          .toList();

      final expiredItems = items.where((i) => i.daysUntilExpiry < 0).toList();
      if (expiredItems.isNotEmpty) {
        final expiredIds = expiredItems.map((i) => i.id).toList();

        await supabase
            .from('inventory')
            .update({'status': 'wasted'})
            .inFilter('id', expiredIds);

        final now = DateTime.now().toIso8601String();
        final notifRows = expiredItems.map((item) => {
          'title': '${item.name} has expired and has been removed',
          'message':
              '${item.name} passed its expiry date and was automatically removed '
              'from your inventory. Please remember to discard or throw out any '
              'remaining ${item.name} from your physical storage.',
          'type': 'urgent',
          'read': false,
          'created_at': now,
        }).toList();

        await supabase.from('notifications').insert(notifRows);

        items.removeWhere((i) => i.daysUntilExpiry < 0);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(LucideIcons.trash2, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${expiredItems.length} expired item${expiredItems.length > 1 ? 's' : ''} removed. '
                    'Check notifications for details.',
                  ),
                ),
              ]),
              backgroundColor: AppColors.urgentRed,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }

      if (mounted) setState(() { _allItems = items; _loading = false; });
    } catch (e, stack) {
      debugPrint('InventoryScreen._load error: $e\n$stack');
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _clearFilters() => setState(() { _search = ''; _selectedCategory = 'All'; });

  Future<void> _showAddItemSheet() async {
    final nameCtrl     = TextEditingController();
    final quantityCtrl = TextEditingController(text: '1');
    String category    = 'Produce';
    String unit        = 'pcs';
    DateTime expiry    = DateTime.now().add(const Duration(days: 7));
    final formKey      = GlobalKey<FormState>();

    const categories = [
      'Produce', 'Dairy', 'Meat', 'Seafood',
      'Bakery', 'Frozen', 'Beverages', 'Pantry', 'Snacks', 'Other',
    ];
    const units = [
      'pcs', 'g', 'kg', 'ml', 'L',
      'loaf', 'tin', 'packet', 'bottle', 'box', 'bag', 'bunch', 'tray', 'sachet',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 36, height: 4,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        const Text('Add Item',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        const Text('Manually add a food item to your inventory',
                            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 24),

                        // Name
                        const Text('Item Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameCtrl,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'e.g. Gardenia White Bread',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 14, right: 10),
                              child: Icon(LucideIcons.shoppingBag, size: 16, color: AppColors.mutedForeground),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Item name is required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Category + Unit
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: category,
                                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
                                    isExpanded: true,
                                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).toList(),
                                    onChanged: (v) => setSheet(() => category = v!),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: unit,
                                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
                                    isExpanded: true,
                                    items: units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).toList(),
                                    onChanged: (v) => setSheet(() => unit = v!),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Quantity + Expiry
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: quantityCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '1',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    ),
                                    validator: (v) {
                                      final n = int.tryParse(v ?? '');
                                      if (n == null || n <= 0) return 'Enter a valid number';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Expiry Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: ctx,
                                        initialDate: expiry,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                                        builder: (ctx, child) => Theme(
                                          data: Theme.of(ctx).copyWith(
                                            colorScheme: const ColorScheme.light(primary: AppColors.brandGreen),
                                          ),
                                          child: child!,
                                        ),
                                      );
                                      if (picked != null) setSheet(() => expiry = picked);
                                    },
                                    child: Container(
                                      height: 50,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.border, width: 1.5),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(LucideIcons.calendar, size: 14, color: AppColors.mutedForeground),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${expiry.day}/${expiry.month}/${expiry.year}',
                                            style: const TextStyle(fontSize: 14, color: AppColors.foreground, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final userId = supabase.auth.currentUser?.id;
                              final expiryStr =
                                  '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';
                              try {
                                await supabase.from('inventory').insert({
                                  'user_id': userId,
                                  'name': nameCtrl.text.trim(),
                                  'category': category,
                                  'quantity': int.parse(quantityCtrl.text.trim()),
                                  'unit': unit,
                                  'expiry_date': expiryStr,
                                  'status': 'active',
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  _load();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(children: [
                                        const Icon(LucideIcons.checkCircle, size: 16, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text('${nameCtrl.text.trim()} added to inventory'),
                                      ]),
                                      backgroundColor: AppColors.brandGreen,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add item: $e'),
                                      backgroundColor: AppColors.urgentRed,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Add to Inventory'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered     = _filtered;
    final totalItems   = _allItems.length;
    final urgentCount  = _allItems.where((i) => i.urgency == UrgencyLevel.urgent).length;
    final soonCount    = _allItems.where((i) => i.urgency == UrgencyLevel.soon).length;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemSheet,
        backgroundColor: AppColors.brandGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
      ),
      body: RefreshIndicator(
        color: AppColors.brandGreen,
        onRefresh: _load,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              FadeInSlide(
                delay: Duration.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Inventory',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: -0.5)),
                          SizedBox(height: 2),
                          Text('Manage your food items',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.brandGreen)),
                        ],
                      ),
                      if (!_loading)
                        Row(
                          children: [
                            _buildChip('$totalItems total', Colors.grey.shade100, AppColors.mutedForeground),
                            if (urgentCount > 0) ...[
                              const SizedBox(width: 6),
                              _buildChip('$urgentCount urgent', AppColors.urgentRed.withValues(alpha: 0.1), AppColors.urgentRed),
                            ],
                            if (soonCount > 0) ...[
                              const SizedBox(width: 6),
                              _buildChip('$soonCount soon', AppColors.soonOrange.withValues(alpha: 0.1), AppColors.soonOrange),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.urgentRedBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.urgentRed.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.urgentRed),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.urgentRed))),
                        GestureDetector(
                          onTap: _load,
                          child: const Text('Retry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.urgentRed)),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Search + Sort ───────────────────────────────────────────
              FadeInSlide(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  color: AppColors.pageBg,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                onChanged: (v) => setState(() => _search = v),
                                decoration: InputDecoration(
                                  hintText: 'Search items...',
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 14, right: 10),
                                    child: Icon(LucideIcons.search, size: 18, color: AppColors.mutedForeground),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  suffixIcon: _search.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () => setState(() => _search = ''),
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 12),
                                            child: Icon(LucideIcons.x, size: 14, color: AppColors.mutedForeground),
                                          ),
                                        )
                                      : null,
                                  suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _showSortMenu = !_showSortMenu),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _showSortMenu ? AppColors.brandGreen : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _showSortMenu ? AppColors.brandGreen : AppColors.border, width: 1.5),
                              ),
                              child: Icon(LucideIcons.arrowUpDown, size: 16,
                                  color: _showSortMenu ? Colors.white : AppColors.mutedForeground),
                            ),
                          ),
                        ],
                      ),
                      
                      // Sort options dropdown
                      if (_showSortMenu)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                                child: Text('SORT BY',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mutedForeground, letterSpacing: 1.5)),
                              ),
                              ..._sortOptions.map((opt) => InkWell(
                                onTap: () => setState(() { _sortBy = opt['value']!; _showSortMenu = false; }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(opt['label']!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _sortBy == opt['value'] ? AppColors.brandGreen : AppColors.foreground,
                                          )),
                                      if (_sortBy == opt['value'])
                                        Container(
                                          width: 6, height: 6,
                                          decoration: const BoxDecoration(color: AppColors.brandGreen, shape: BoxShape.circle),
                                        ),
                                    ],
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      
                      // Category chips with gradient fade overlay
                      Stack(
                        children: [
                          SizedBox(
                            height: 38,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _categories.map((cat) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedCategory = cat),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _selectedCategory == cat ? AppColors.brandGreen : AppColors.surfaceGlass,
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: _selectedCategory == cat ? AppColors.brandGreen : AppColors.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(cat,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedCategory == cat ? Colors.white : AppColors.mutedForeground,
                                          )),
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            bottom: 0,
                            right: 0,
                            width: 28,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.pageBg.withValues(alpha: 0.0),
                                      AppColors.pageBg.withValues(alpha: 0.95),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Results bar ─────────────────────────────────────────────
              if (!_loading)
                FadeInSlide(
                  delay: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground),
                            children: [
                              const TextSpan(text: 'Showing '),
                              TextSpan(text: '${filtered.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.foreground)),
                              TextSpan(text: ' ${filtered.length == 1 ? 'item' : 'items'}'),
                              if (filtered.length != totalItems)
                                TextSpan(text: ' of $totalItems'),
                            ],
                          ),
                        ),
                        if (_isFiltered)
                          GestureDetector(
                            onTap: _clearFilters,
                            child: Row(
                              children: [
                                const Icon(LucideIcons.x, size: 12, color: AppColors.urgentRed),
                                const SizedBox(width: 4),
                                const Text('Clear filters',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.urgentRed)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // ── Items list ──────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? _buildSkeleton()
                    : filtered.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              return FadeInSlide(
                                delay: Duration(milliseconds: i < 10 ? 200 + (i * 40) : 0),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InventoryItemCard(item: item),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.15), width: 1.5),
            ),
            child: const Icon(LucideIcons.packageOpen, size: 28, color: AppColors.brandGreen),
          ),
          const SizedBox(height: 18),
          const Text('No items found', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.foreground, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Try a different search or category',
              style: TextStyle(fontSize: 13, color: AppColors.mutedForeground, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _clearFilters,
            child: const Text('Clear all filters',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brandGreen, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading(
          width: double.infinity,
          height: 90,
          borderRadius: 16,
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.2)),
    );
  }
}