# Pantry Pal

An Android app that helps a homemaker answer the daily question **"what should I cook today?"** from
what is actually in the kitchen, without repeating what the family ate this week.

Built for the Devpost *Build With AI: Basics* hackathon. The idea came from a problem seen in many
Asian households: mothers decide this every day, on a tight monthly budget, often while away from
home and unsure what is left.

## What it does

- **Groceries.** Add the month's shopping by typing it or by taking a photo. A photo can hold several
  items; the app reads each one's name (with its brand, like *Shan Chaat Masala*), and the quantity
  when the packaging shows it. Everything can be corrected before it is saved.
- **Home dashboard.** Days until the next shopping day, what is left, and a total, so mum can judge
  for herself whether it will last.
- **Dish suggestions.** Pick lunch or dinner, light or heavy, and rice, roti or bread. Dishes come
  **first from the family's own recipe book** (`data/dishes.csv`, 3,003 dishes), instantly, and only
  from Gemini when nothing in the book fits.
- **Cook and log.** After cooking, log the dish and how much of each ingredient was used (or take a
  photo of the dish for a rough guess). The groceries go down, and the dish is not suggested again
  for 7 days.
- **Settings and languages.** English and Urdu (اردو), switched in Settings; Urdu is laid out right to
  left. Name, privacy note and log out live there too.
- **Family profile.** Ages, spice level, favourite cuisines and notes shape which dishes come first.
  Someone who wants mild food is never offered the hot dishes.

Amounts are approximate by design.

## Design

Made for a busy cook with her phone in one hand, so the rules are plain:

- **Four tabs** (Home, Groceries, Cook, Family) at thumb height; no menus to dig through.
- **One type scale** (26 / 19 / 16 / 13) and an 8 dp grid; body text is never below 16, and every
  tap target is at least 48 dp.
- **Colour never carries meaning alone**: warnings and states always have an icon and words. Text
  colours are tested to meet WCAG AA contrast (4.5:1) in `test/ui/design_system_test.dart`.
- **Recognition over recall**: Cook remembers the last meal, weight and base; Family saves by
  itself and says "Saved just now" instead of asking her to find a Save button.
- **Honest labels**: every dish says whether it came from her recipe book or from the AI.
- **Reduced motion**: shimmer and entrance animations stop when the phone asks for less motion.

The audit that started this is in [docs/ux_audit.md](docs/ux_audit.md).

## How it works

| Piece | What it does |
|---|---|
| **Flutter** (Android) | The app |
| **Firebase Authentication** | Email and password sign-in |
| **Cloud Firestore** | One private space per person: groceries, meals, profile |
| **Gemini** via **Firebase AI Logic** | Reads grocery and dish photos; suggests dishes when the recipe book has none |

The AI key never sits inside the app: Gemini is reached through Firebase. Only your own account can
read or write your data (see [firestore.rules](firestore.rules)).

**What is sent to Gemini:** photos you choose to read, your grocery names and amounts, and a short
summary of your family (size, spice, tastes). It never gets exact ages, genders, names or email.
On the free tier, Google may use this content to improve its products.

## Try it

You need Flutter, an Android phone or emulator, and a Firebase project.

1. **Firebase setup** (once):
   - Create a Firebase project and add an Android app with the package name `com.haleema.what_can_i_cook`.
   - Turn on **Authentication → Email/Password** and create a **Cloud Firestore** database.
   - Turn on **AI Logic → Gemini Developer API** (the free tier needs no card).
   - Under **App Check**, either leave Firebase AI Logic unenforced for a family test, or set up
     Play Integrity before sharing widely.
   - Run `flutterfire configure` to create `lib/firebase_options.dart` and
     `android/app/google-services.json`, then deploy the rules: `firebase deploy --only firestore`.
2. **Run it:**
   ```
   flutter pub get
   flutter run
   ```
3. **Build the file to share with family:**
   ```
   flutter build apk --release
   ```
   The file is `build/app/outputs/flutter-apk/app-release.apk`. Send it to an Android phone and open it.
4. **A sample account to look around** (optional). This creates an account on *your* Firebase project
   and fills it with a family, groceries and a week of meals:
   ```
   powershell -File scripts/seed_test_account.ps1 -Email you@example.com -Password choose-one
   ```
5. **Check everything:**
   ```
   flutter analyze
   flutter test
   ```
6. **Run every test and save the reports** (the phone must be connected and unlocked):
   ```
   powershell -File scripts/run_all_tests.ps1
   ```
   Reports are saved in `test-reports/` (not in git):
   `flutter-test.txt` and `.json` (the quick checks), `patrol/index.html`, `maestro-report.html`.
   Use `-LaptopOnly` to skip the phone checks. The phone checks clear the app's data, so you are
   logged out afterwards.

## Tests

| What | How many | Runs on | Good for |
|---|---|---|---|
| `flutter test` (`test/`) | 338 | the laptop, about 30 s | edge cases: dates, amounts, matching, every screen, the real saving logic against a stand-in Firestore, every kind of Gemini failure |
| Maestro (`maestro/`) | 5 flows | the phone | tapping through the finished app, written as short YAML |
| Patrol (`patrol_test/`) | 5 tests | the phone | the same, written in Dart inside a test build |

The quick checks cover about 87% of the code lines. What they cannot reach is the real camera and
gallery, and anything that needs a real login (the phone tests would write to the live Firebase).

## Your own recipe book

`data/dishes.csv` has one dish per row: name, cuisine, meal, weight (light/medium/heavy), base
(rice/roti/naan/bread/paratha/none), main ingredients separated by `;`, spice, kid friendly, the
ingredients with quantities separated by `;`, and the steps separated by `|`. Add more rows any time
and rebuild the app. Use the same simple ingredient names everywhere (`onion`, not `onions`).

## Project layout

```
lib/
  main.dart              starts Firebase, shows login or the app
  theme.dart             light and dark themes, colours, type scale
  ui/                    the shared design system: buttons, cards, chips, steppers, states
  l10n/                  English and Urdu text (app_en.arb, app_ur.arb)
  state/                 remembered choices and the chosen language
  screens/               sign in, app shell (bottom tabs), home, groceries, cook, recipe,
                         log dish, daily log, family, settings
  services/              data_service (Firestore), gemini_service (AI),
                         dish_database (recipe book), ingredient_matcher, photo_picker
  logic/                 days_left (dates and totals), stock_usage (what is left after cooking)
  models/                dish, inventory_item, meal, family_profile
data/dishes.csv          the recipe book
firestore.rules          who can read and write what
test/                    338 quick tests (plus patrol_test/ and maestro/ for the phone)
devpost/                 the plan: scope, PRD, spec, build checklist
```

## Limits

- Android only. A website or iPhone version is not built.
- Amounts and "days left" are estimates, not exact.
- Photo reading can miss small or hidden items; everything is shown for checking first.
- The recipe book is all Pakistani dishes for now.
- Urdu covers Sign in, Home, Groceries, Cook, Family and Settings. The recipe page, the log-a-dish
  page and the daily log are still English, as are dish names and AI-written recipe text.
- Dark mode is built but switched off until every screen has moved to the new design.
- Signing uses the debug key, which is fine for sharing with family but not for the Play Store.

## Documentation

[Flutter](https://docs.flutter.dev) ·
[Firebase for Flutter](https://firebase.google.com/docs/flutter/setup) ·
[Firebase AI Logic](https://firebase.google.com/docs/ai-logic) ·
[Cloud Firestore](https://firebase.google.com/docs/firestore)
