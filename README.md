# ZeroWaste

A Flutter app that helps you stop throwing food away. You track what's in your fridge, get warned before things expire, scan receipts to skip manual entry, and let an AI suggest meals from whatever's about to go bad.

Built with Flutter, Supabase, and OpenRouter.

---

## What it does

**Inventory tracking** — Add food items with quantities and expiry dates. The app colour-codes them by urgency: red for expiring today or tomorrow, yellow for the next few days, green for everything else.

**Receipt scanning** — Take a photo of a grocery receipt. The app sends it to a vision model, extracts the items, estimates expiry dates, and loads them into a review screen before saving. Works reasonably well on clear receipts; blurry photos give mixed results.

**AI meal suggestions** — Tap "generate recipe" and the app grabs your soonest-expiring items, builds a prompt, and asks an LLM for a specific recipe you can actually cook. Results get saved so you can refer back to them.

**Expiry notifications** — On app open, it checks your inventory and logs alerts for items expiring today, tomorrow, within 3 days, and within 7 days. Each alert fires once per day per timeframe, not every time you open the app.

**Urgency dashboard** — A filtered view showing only the items that need attention. Sorted by nearest expiry date.

---

## Tech stack

- **Flutter 3.x** — iOS and Android from one codebase
- **Supabase** — handles auth, the database, and real-time subscriptions
- **OpenRouter** — routes AI requests to free models (Llama 3, Gemma 3). Falls back through four models if one fails
- **image_picker** — camera and gallery access for receipt scanning
- **Google Fonts** — Plus Jakarta Sans throughout
- **http** — plain Dart HTTP client for API calls

---

## Setup

### You'll need

- Flutter SDK 3.0+
- A Supabase project
- An OpenRouter API key (free tier works)

### Steps

**1. Clone and install**
```bash
git clone https://github.com/bryannnn03/ZeroWaste.git
cd ZeroWaste
flutter pub get
```

**2. Add your credentials**

Open `lib/config/app_config.dart` and fill these in:
```dart
class AppConfig {
  static const String supabaseUrl      = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey  = 'YOUR_SUPABASE_ANON_KEY';
  static const String openRouterApiKey = 'YOUR_OPENROUTER_API_KEY';
}
```

> Do not commit this file with real keys in it.

**3. Create the Supabase tables**

Run this in your Supabase SQL editor:

```sql
-- Inventory
create table inventory (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users not null,
  name        text not null,
  category    text,
  quantity    numeric default 1,
  unit        text,
  expiry_date date,
  status      text default 'active',
  created_at  timestamptz default now()
);

-- Meal recommendations
create table meal_recommendations (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references auth.users not null,
  title        text,
  ingredients  jsonb,
  instructions text,
  created_at   timestamptz default now()
);

-- Notifications
create table notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users not null,
  message    text,
  type       text,
  is_read    boolean default false,
  dedup_key  text,
  created_at timestamptz default now()
);

-- Row-level security (each user only sees their own rows)
alter table inventory            enable row level security;
alter table meal_recommendations enable row level security;
alter table notifications        enable row level security;

create policy "own inventory"     on inventory            for all using (auth.uid() = user_id);
create policy "own meals"         on meal_recommendations for all using (auth.uid() = user_id);
create policy "own notifications" on notifications        for all using (auth.uid() = user_id);
```

**4. Run it**
```bash
flutter run
```

---

## Project structure

```
lib/
├── config/
│   └── app_config.dart              # credentials — do not commit with real keys
├── models/
│   ├── food_item.dart               # FoodItem + UrgencyLevel enum
│   ├── meal_suggestion.dart
│   └── user_profile.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── main_shell.dart              # bottom nav + tab state
│   ├── home_screen.dart
│   ├── inventory_screen.dart
│   ├── scan_screen.dart
│   ├── meals_screen.dart
│   ├── notifications_screen.dart
│   └── urgency_dashboard_screen.dart
├── services/
│   ├── ai_recipe_service.dart       # OpenRouter calls + 4-model fallback
│   ├── receipt_ocr_service.dart     # vision model + item parsing
│   └── notification_service.dart   # expiry checks + deduplication
├── theme/
│   └── app_theme.dart
├── utils/
│   └── food_item_mapper.dart        # single function: DB row -> FoodItem
├── widgets/                         # reusable cards and components
└── main.dart
```

---

## Running tests

```bash
flutter test
```

The main unit test file is `test/food_item_mapper_test.dart`. It checks that urgency levels are calculated correctly (urgent for 0-2 days, soon for 3-5, ok for anything beyond that).

---

## Known limitations

- Receipt OCR accuracy depends heavily on photo quality. Poor lighting or crumpled receipts will produce bad extractions.
- The OpenRouter API key sits in the client bundle right now. Should be moved to a Supabase Edge Function before any real production use.
- No pagination on the inventory query yet. Fine for personal use, less fine if you somehow have thousands of items.

---

## Planned

- Barcode scanning for faster item entry
- Weekly waste summary
- Shopping list from low-stock items
- Push notifications via FCM

---

## Built for

DSE399/04 Project 2 — Bachelor in Software Engineering (Honours), Application Development track.