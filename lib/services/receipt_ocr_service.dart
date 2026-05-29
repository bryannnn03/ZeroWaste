import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';

/// Holds one extracted food item from a receipt.
class ExtractedItem {
  String name;
  double quantity;
  String unit;
  String category;
  DateTime expiryDate;

  ExtractedItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.expiryDate,
  });

  factory ExtractedItem.fromJson(Map<String, dynamic> json) {
    final expiryDays = (json['estimated_expiry_days'] as num?)?.toInt() ?? 7;
    final rawName = (json['name'] as String?)?.trim() ?? 'Unknown Item';
    final rawUnit = (json['unit'] as String?)?.trim() ?? '';
    return ExtractedItem(
      name: _cleanItemName(rawName),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: _normaliseUnit(rawUnit, rawName),
      category: (json['category'] as String?)?.trim() ?? 'Other',
      expiryDate: DateTime.now().add(Duration(days: expiryDays)),
    );
  }
}

// ── Name cleaner ──────────────────────────────────────────────────────────────
/// Cleans up common Malaysian receipt OCR naming issues.
/// e.g. "Ayam Ikan Mackeral" → "Ayam Brand Ikan Makarel Sardin"
///      "GDN WHT BRD" → "Gardenia White Bread"
String _cleanItemName(String raw) {
  // Expand known Malaysian brand abbreviations from receipts
  final brandExpansions = <String, String>{
    r'\bAYAM\b(?!\s+BRAND)': 'Ayam Brand',
    r'\bGDN\b': 'Gardenia',
    r'\bGARDENIA\b': 'Gardenia',
    r'\bMAGGI\b': 'Maggi',
    r'\bNESCAFE\b': 'Nescafe',
    r'\bMILO\b': 'Milo',
    r'\bF&N\b': 'F&N',
    r'\bHL\b(?=\s)': 'HL',
    r'\bDUTCH\s*LADY\b': 'Dutch Lady',
    r'\bKIKKOMAN\b': 'Kikkoman',
    r'\bLEA\s*&?\s*PERRINS\b': 'Lea & Perrins',
    r'\bWHT\b': 'White',
    r'\bBRD\b': 'Bread',
  };

  String name = raw;
  brandExpansions.forEach((pattern, replacement) {
    name = name.replaceAllMapped(
      RegExp(pattern, caseSensitive: false),
      (_) => replacement,
    );
  });

  // Title-case the result cleanly
  name = name
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  // Re-uppercase known all-caps brand tokens after title-casing
  const preserveUppercase = ['F&N', 'HL', 'UHT', 'UTH'];
  for (final token in preserveUppercase) {
    name = name.replaceAll(
      RegExp(RegExp.escape(token), caseSensitive: false),
      token,
    );
  }

  return name.trim();
}

// ── Unit normaliser ───────────────────────────────────────────────────────────
/// Normalises raw unit string, using item name as fallback context.
String _normaliseUnit(String raw, String itemName) {
  final u = raw.toLowerCase().trim();
  final n = itemName.toLowerCase();

  // ── Explicit unit from model ──────────────────────────────────────────────
  if (u == 'g' || u == 'gram' || u == 'grams')             return 'g';
  if (u == 'kg' || u == 'kilogram' || u == 'kilograms')    return 'kg';
  if (u == 'ml' || u == 'milliliter' || u == 'millilitre') return 'ml';
  if (u == 'l' || u == 'liter' || u == 'litre')            return 'L';
  if (u == 'loaf' || u == 'loaves')                        return 'loaf';
  if (u == 'tin' || u == 'can' || u == 'cans' || u == 'tins') return 'tin';
  if (u == 'packet' || u == 'pack' || u == 'packets' || u == 'packs') return 'packet';
  if (u == 'bottle' || u == 'bottles')                     return 'bottle';
  if (u == 'box' || u == 'boxes')                          return 'box';
  if (u == 'bag' || u == 'bags')                           return 'bag';
  if (u == 'bunch' || u == 'bunches')                      return 'bunch';
  if (u == 'tray' || u == 'trays')                         return 'tray';
  if (u == 'roll' || u == 'rolls')                         return 'roll';
  if (u == 'sachet' || u == 'sachets')                     return 'sachet';
  if (u == 'pcs' || u == 'pc' || u == 'piece' || u == 'pieces') {
    if (_nameImpliesPcs(n)) return 'pcs';
  }

  // ── Name-based inference ──────────────────────────────────────────────────
  if (_contains(n, ['bread', 'gardenia', 'massimo', 'loaf', 'wholemeal', 'roti sandwich'])) return 'loaf';
  if (_contains(n, ['ayam brand', 'tuna', 'sardine', 'sardin', 'mackerel', 'makarel',
      'baked beans', 'cream of mushroom', 'campbell', 'braised', 'corned beef',
      'luncheon meat', 'spam', 'condensed milk', 'evaporated milk', 'coconut milk tin'])) return 'tin';
  if (_contains(n, ['sauce', 'kicap', 'soy sauce', 'oyster sauce', 'chilli sauce',
      'tomato sauce', 'vinegar', 'oil', 'minyak', 'cordial', 'sunquick', 'ribena',
      'mineral water', 'air mineral', 'juice', 'jus', 'f&n', 'season', 'worcestershire',
      'lea & perrins', 'fish sauce', 'sos'])) return 'bottle';
  if (_contains(n, ['maggi', 'instant noodle', 'mee segera', 'mamee', 'biscuit', 'biskut',
      'chips', 'crisp', 'keropok', 'cracker', 'snack', 'kuih', 'kacang',
      'seasoning', 'perencah', 'curry powder', 'serbuk kari', 'rempah',
      'sugar sachet', 'oats', 'milo packet', 'tea bag', 'teh tarik',
      'nestum', 'quaker', 'cereal packet'])) return 'packet';
  if (_contains(n, ['cereal', 'cornflakes', 'kellogg', 'nestum box', 'tissue',
      'tea box', 'milk box', 'uht', 'dutch lady box', 'hl milk'])) return 'box';
  if (_contains(n, ['beras', 'rice', 'flour', 'tepung', 'sugar', 'gula',
      'salt', 'garam', 'frozen', 'beku', 'peas', 'mixed veg'])) return 'bag';
  if (_contains(n, ['chicken', 'ayam', 'beef', 'daging', 'lamb', 'mutton',
      'fish', 'ikan', 'prawn', 'udang', 'sotong', 'squid',
      'minced', 'fillet', 'drumstick', 'wing', 'thigh'])) return 'g';
  if (_contains(n, ['banana', 'pisang', 'grape', 'anggur', 'spring onion',
      'daun bawang', 'coriander', 'cilantro', 'daun ketumbar',
      'kangkung', 'spinach', 'bayam'])) return 'bunch';
  if (_contains(n, ['apple', 'epal', 'orange', 'limau', 'pear', 'egg', 'telur',
      'tomato', 'potato', 'kentang', 'onion', 'bawang', 'garlic', 'bawang putih',
      'carrot', 'lobak', 'corn', 'jagung', 'lemon', 'lime'])) return 'pcs';
  if (_contains(n, ['milk', 'susu', 'yogurt', 'yoghurt'])) return 'bottle';

  return u.isEmpty || u == 'pcs' ? 'pcs' : raw.trim();
}

bool _contains(String name, List<String> keywords) =>
    keywords.any((k) => name.contains(k));

bool _nameImpliesPcs(String name) =>
    _contains(name, ['egg', 'telur', 'apple', 'epal', 'orange', 'limau',
        'pear', 'onion', 'bawang', 'potato', 'kentang', 'corn', 'jagung',
        'lemon', 'lime', 'tomato', 'garlic']);

// ── Malaysian grocery filter ──────────────────────────────────────────────────
/// Non-food keywords commonly found on Malaysian supermarket receipts.
/// If ANY of these appear in the item name, the item is rejected.
const _nonFoodBlocklist = <String>[
  // ── Toiletries & personal care ──
  'toothpaste', 'toothbrush', 'ubat gigi', 'berus gigi',
  'shampoo', 'syampu', 'conditioner', 'perapi rambut',
  'soap', 'sabun', 'body wash', 'shower gel', 'pencuci badan',
  'deodorant', 'antiperspirant', 'perfume', 'minyak wangi', 'cologne',
  'lotion', 'moisturizer', 'pelembap', 'sunscreen', 'sunblock',
  'face wash', 'pencuci muka', 'facial', 'cleanser', 'toner', 'serum',
  'makeup', 'mascara', 'lipstick', 'foundation', 'concealer', 'eyeliner',
  'cotton bud', 'cotton pad', 'kapas', 'razor', 'pencukur', 'shaving',
  'sanitary', 'tuala wanita', 'sanitary pad', 'tampon', 'pantyliner',
  'hair dye', 'pewarna rambut', 'hair gel', 'hair wax', 'pomade',
  'mouthwash', 'ubat kumur', 'dental floss', 'flos gigi',
  'contact lens', 'kanta sentuh',

  // ── Baby care (non-food) ──
  'diaper', 'diapers', 'lampin', 'pampers', 'huggies', 'mamy poko', 'mamypoko',
  'baby wipe', 'baby wipes', 'tisu basah bayi',
  'baby lotion', 'baby oil', 'baby powder', 'bedak bayi',
  'baby shampoo', 'baby wash', 'baby cream',
  'pacifier', 'puting', 'teether', 'baby bottle',

  // ── Cleaning & household ──
  'detergent', 'pencuci', 'softener', 'pelembut',
  'bleach', 'peluntur', 'clorox',
  'dishwash', 'pencuci pinggan', 'fairy', 'sunlight',
  'floor cleaner', 'pencuci lantai', 'mr muscle',
  'toilet cleaner', 'pencuci tandas', 'harpic',
  'air freshener', 'penyegar udara', 'febreze', 'glade',
  'insecticide', 'racun serangga', 'mosquito', 'nyamuk', 'ridsect',
  'pest control', 'roach', 'lipas', 'ant killer',
  'sponge', 'span', 'mop', 'broom', 'penyapu', 'dustpan',
  'garbage bag', 'trash bag', 'beg sampah',
  'aluminium foil', 'cling wrap', 'plastic wrap', 'ziplock',
  'rubber glove', 'sarung tangan',

  // ── Paper products ──
  'toilet paper', 'toilet roll', 'tisu tandas',
  'kitchen towel', 'tuala dapur', 'paper towel',
  'tissue', 'tisu',

  // ── Laundry ──
  'laundry', 'dobi', 'fabric softener', 'starch', 'kanji',
  'iron spray', 'stain remover',

  // ── Pet supplies ──
  'pet food', 'cat food', 'dog food', 'makanan kucing', 'makanan anjing',
  'cat litter', 'pasir kucing', 'pet shampoo', 'whiskas', 'pedigree',

  // ── Stationery & office ──
  'ballpen', 'ball pen', 'pencil', 'pensel', 'marker pen', 'eraser', 'pemadam',
  'notebook', 'buku tulis', 'envelope', 'sampul surat',
  'glue stick', 'super glue', 'sellotape', 'pita pelekat', 'stapler', 'scissors', 'gunting',
  'battery', 'bateri',

  // ── Electronics & hardware ──
  'bulb', 'mentol', 'cable', 'kabel', 'charger', 'adapter', 'plug',
  'extension', 'socket', 'soket', 'fuse',

  // ── Clothing & textiles ──
  'sock', 'stoking', 'underwear', 'seluar dalam', 'singlet',
  'hanger', 'penyangkut',

  // ── Automotive ──
  'motor oil', 'minyak enjin', 'windshield', 'cermin',

  // ── Tobacco & non-grocery ──
  'cigarette', 'rokok', 'tobacco', 'tembakau', 'vape', 'lighter', 'pemetik api',

  // ── Common Malaysian non-food brand names ──
  'colgate', 'dettol', 'lifebuoy', 'lux soap', 'dove soap', 'dove shampoo', 'palmolive',
  'head & shoulders', 'head and shoulders', 'pantene', 'sunsilk',
  'dynamo detergent', 'breeze detergent', 'fab detergent', 'downy',
  'ajax cleaner', 'mr muscle', 'cif cleaner',
  'ridsect', 'shieldtox', 'fumakilla',
  'huggies', 'drypers', 'pet pet', 'mamypoko',
  'strepsils', 'panadol', 'axe oil', 'minyak angin', 'ubat',
  'kotex', 'laurier', 'libresse',
  'oral-b', 'oral b', 'sensodyne', 'darlie',
  'nivea', 'vaseline', 'johnson',
  'energizer', 'duracell',
  'glad', 'hefty',
  'scotch brite', 'scotch-brite', '3m',

  // ── Receipt metadata (extra safety net) ──
  'subtotal', 'sub total', 'total', 'tax', 'cukai', 'gst', 'sst',
  'change', 'baki', 'cash', 'tunai', 'credit card', 'kad kredit',
  'debit', 'rounding', 'pembundaran', 'discount', 'diskaun',
  'member', 'ahli', 'point', 'mata', 'receipt', 'resit',
  'cashier', 'juruwang', 'counter', 'kaunter',
];

/// Food-related keywords. If the item doesn't match the blocklist,
/// we additionally verify it belongs to one of the allowed food categories
/// the model was instructed to use.
const _allowedCategories = <String>[
  'produce', 'dairy', 'meat', 'seafood', 'bakery',
  'frozen', 'beverages', 'pantry', 'snacks', 'other',
];

/// Returns `true` if the item looks like a genuine food / grocery product.
bool _isFoodItem(ExtractedItem item) {
  final name = item.name.toLowerCase();

  // Reject if name is too short / empty (probably OCR noise)
  if (name.length < 2) {
    // ignore: avoid_print
    print('[GroceryFilter] REJECTED (too short): "${item.name}"');
    return false;
  }

  // Reject if the name matches any non-food keyword
  for (final keyword in _nonFoodBlocklist) {
    if (name.contains(keyword)) {
      // ignore: avoid_print
      print('[GroceryFilter] REJECTED (matched "$keyword"): "${item.name}"');
      return false;
    }
  }

  // Ensure category is one we expect (models sometimes hallucinate categories)
  if (!_allowedCategories.contains(item.category.toLowerCase())) {
    item.category = 'Other'; // fix rather than reject
  }

  // ignore: avoid_print
  print('[GroceryFilter] ACCEPTED: "${item.name}" [${item.category}]');
  return true;
}

// ── OCR Service ───────────────────────────────────────────────────────────────

/// Model descriptor used for the fallback chain.
class _Model {
  final String id;
  final String label;
  const _Model(this.id, this.label);
}

class ReceiptOcrService {
  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  /// Primary model → fallback models, tried in order.
  /// All are free-tier vision-capable models on OpenRouter.
  static const _models = [
    _Model('openrouter/auto',                         'OpenRouter Auto'),
    _Model('qwen/qwen2.5-vl-72b-instruct:free',       'Qwen 2.5 VL 72B'),
    _Model('meta-llama/llama-3.2-11b-vision-instruct:free', 'Llama 3.2 11B Vision'),
  ];

  static const _prompt = r'''
You are a grocery receipt parser specialised in Malaysian supermarket receipts (e.g. Giant, Tesco, Lotus's, Mydin, Jaya Grocer, Village Grocer, AEON, 99 Speedmart).

Extract every food or grocery item from this receipt image.
Return ONLY a raw JSON array — no markdown, no explanation, no code fences.

Each element must follow this EXACT shape:
{
  "name": "Clean readable product name",
  "quantity": 1,
  "unit": "loaf",
  "category": "Bakery",
  "estimated_expiry_days": 4
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RULE 1 — ITEM NAMES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Expand abbreviations and clean up OCR artifacts into proper readable names.
- "AYAM IKN MCK" → "Ayam Brand Ikan Makarel Sardin"
- "GDN WHT BRD 400G" → "Gardenia White Bread"
- "MLO ACTGEN 400G" → "Milo Activ-Go"
- "MGGI CKN NDL" → "Maggi Ayam Noodles"
- "HL FULL CRM 1L" → "HL Full Cream Milk 1L"
If a brand name appears without "Brand" (e.g. "AYAM"), write it as "Ayam Brand".
Always write names in Title Case.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RULE 2 — UNITS (CRITICAL — never default to pcs)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Infer the correct unit from the product name and packaging type.
NEVER return "pcs" unless the item is a loose countable item (eggs, apples, oranges).

Unit → when to use:
  loaf    → any bread sold as a loaf (Gardenia, Massimo, wholemeal bread)
  tin     → canned goods (Ayam Brand, tuna, sardines, baked beans, condensed milk, luncheon meat)
  packet  → sealed packets (Maggi noodles, biscuits, chips, seasoning, curry powder, oats)
  bottle  → bottles (sauces, cordials, mineral water, juice, cooking oil, soy sauce, milk in bottle)
  box     → boxes (cereal, UHT milk box, tissue, tea bags)
  bag     → bags (rice, flour, sugar, frozen vegetables, salt)
  g       → fresh items sold by weight (chicken, beef, fish, prawns, minced meat)
  kg      → bulk weight items (large bags of rice, potatoes by weight)
  ml      → small liquid volumes
  L       → large liquid volumes (1L, 1.5L bottles — but use "bottle" as unit, not L)
  bunch   → produce sold in bunches (bananas, kangkung, spring onions, grapes)
  tray    → eggs sold on a tray (10pcs tray, 30pcs tray)
  pcs     → ONLY for loose single items (1 apple, 1 orange, 1 egg)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RULE 3 — EXPIRY DAYS (Malaysia-specific)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Use Malaysian shelf-life defaults — NOT European or US defaults.
Malaysia has a hot and humid climate. Shelf life is shorter than Western countries.

Category defaults:
  Fresh meat / poultry (chicken, beef, lamb)  → 2 days
  Fresh seafood (fish, prawns, squid)          → 1 day
  Fresh vegetables (leafy greens, kangkung)   → 3 days
  Fresh vegetables (root veg, tomatoes)        → 5 days
  Fresh fruits (bananas, papayas)              → 3 days
  Fresh fruits (apples, oranges, imported)     → 7 days
  Eggs                                         → 14 days
  Fresh bread / Gardenia / Massimo loaf        → 4 days
  Bakery / pastry (non-packaged)               → 2 days
  Fresh dairy (milk, yogurt, fresh cheese)     → 5 days
  UHT milk (unopened)                          → 180 days
  Tofu / tauhu                                 → 2 days
  Chilled processed meat (luncheon, sausage)   → 7 days
  Frozen items (unopened)                      → 90 days
  Instant noodles / biscuits / snacks          → 180 days
  Canned goods (sardines, tuna, baked beans)   → 730 days
  Cooking oil / sauces (unopened)              → 365 days
  Rice / flour / sugar (unopened)              → 365 days
  Beverages (juice, cordial, mineral water)    → 365 days

Brand-specific overrides (use these EXACTLY):
  Gardenia / Massimo bread → 4 days
  Chilled tofu (tauhu)     → 2 days
  Fresh coconut milk       → 2 days

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RULE 4 — CATEGORIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Must be exactly one of: Produce, Dairy, Meat, Seafood, Bakery, Frozen, Beverages, Pantry, Snacks, Other.
- Canned goods → Pantry
- Sauces, cooking oil, rice, flour → Pantry
- Instant noodles, biscuits, chips → Snacks
- Fresh chicken / beef / lamb → Meat
- Fresh fish / prawns / squid → Seafood

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RULE 5 — WHAT TO SKIP (CRITICAL)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You MUST only return FOOD and BEVERAGE items. Skip ALL of the following:

Non-food household items:
  Diapers (Pampers, Huggies, Mamy Poko), baby wipes, baby lotion, baby oil, baby powder
  Toothpaste, toothbrush, mouthwash, dental floss
  Shampoo, conditioner, hair dye, hair gel
  Soap, body wash, shower gel, facial wash, lotion, moisturizer, sunscreen
  Detergent, fabric softener, bleach (Clorox)
  Dishwashing liquid (Fairy, Sunlight)
  Floor cleaner (Mr Muscle), toilet cleaner (Harpic)
  Air freshener (Febreze, Glade)
  Insecticide, mosquito coil, Ridsect
  Tissue, toilet paper, kitchen towel
  Garbage bags, cling wrap, aluminium foil, ziplock bags
  Rubber gloves, sponges, mops, brooms
  Batteries, light bulbs, cables, chargers
  Stationery (pens, pencils, notebooks, glue, tape)
  Pet food (Whiskas, Pedigree), cat litter
  Cigarettes, tobacco, vape, lighters
  Socks, underwear, hangers
  Plastic bags, paper bags

Receipt metadata:
  Subtotal, total, tax, GST, SST, rounding, change, cash, credit card
  Store name, cashier name, date, time, receipt number, member points, discounts

If in doubt whether an item is food, SKIP IT.
''';

  /// Attempts to call one model. Returns the parsed item list on success,
  /// or throws a [_OcrModelException] on a retryable model-level failure,
  /// or rethrows any non-retryable error.
  static Future<List<ExtractedItem>> _callModel(
    _Model model,
    String base64Image,
    String mime,
  ) async {
    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer ${AppConfig.openRouterApiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model.id,
            // Raised from 1500 → 3000 to handle long receipts without truncation
            'max_tokens': 3000,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': _prompt},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:$mime;base64,$base64Image'},
                  },
                ],
              }
            ],
          }),
        )
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw _OcrModelException(
              '${model.label} timed out after 45 s'),
        );

    // Rate-limited or server error → try next model
    if (response.statusCode == 429 || response.statusCode >= 500) {
      throw _OcrModelException(
          '${model.label} returned ${response.statusCode}');
    }

    // Auth error → no point retrying other models with the same key
    if (response.statusCode == 401) {
      throw Exception(
          'Invalid OpenRouter API key. Please check your key in app_config.dart.');
    }

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      final msg =
          err['error']?['message'] ?? 'Unknown error (${response.statusCode})';
      // Model-specific errors (e.g. context length, model not found) → try next
      throw _OcrModelException('${model.label}: $msg');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;

    final cleaned = content
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Some models wrap the array in an object — unwrap if needed
    dynamic raw;
    try {
      raw = jsonDecode(cleaned);
    } catch (_) {
      throw _OcrModelException('${model.label} returned unparseable JSON');
    }

    List<dynamic> jsonList;
    if (raw is List) {
      jsonList = raw;
    } else if (raw is Map && raw.containsKey('items')) {
      jsonList = raw['items'] as List<dynamic>;
    } else {
      throw _OcrModelException(
          '${model.label} returned unexpected JSON shape');
    }

    return jsonList
        .map((e) => ExtractedItem.fromJson(e as Map<String, dynamic>))
        .where(_isFoodItem)
        .toList();
  }

  /// Scans a receipt image and returns extracted food items.
  ///
  /// Tries each model in [_models] in order. Falls back to the next model
  /// on rate-limits, timeouts, server errors, or bad JSON. Only throws
  /// if ALL models fail.
  static Future<List<ExtractedItem>> extractItems(XFile image) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = image.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

    _OcrModelException? lastError;

    for (final model in _models) {
      try {
        final items = await _callModel(model, base64Image, mime);
        return items; // ✅ success
      } on _OcrModelException catch (e) {
        lastError = e;
        // Log and continue to next model
        // ignore: avoid_print
        print('[ReceiptOCR] ${e.message} — trying next model…');
        continue;
      }
      // Non-retryable exceptions (401, unexpected errors) bubble up immediately
    }

    // All models exhausted
    throw Exception(
      'All OCR models failed. Last error: ${lastError?.message ?? "unknown"}. '
      'Please check your internet connection and try again.',
    );
  }
}

/// Internal exception used to signal that a model attempt failed
/// in a way that warrants trying the next model.
class _OcrModelException implements Exception {
  final String message;
  const _OcrModelException(this.message);
}