# What Can I Cook?

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
  **first from the family's own recipe book** (`data/dishes.csv`, 1,003 dishes), instantly, and only
  from Gemini when nothing in the book fits.
- **Cook and log.** After cooking, log the dish and how much of each ingredient was used (or take a
  photo of the dish for a rough guess). The groceries go down, and the dish is not suggested again
  for 7 days.
- **Family profile.** Ages, spice level, favourite cuisines and notes shape which dishes come first.
  Someone who wants mild food is never offered the hot dishes.

Amounts are approximate by design.

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
4. **Check everything:**
   ```
   flutter analyze
   flutter test
   ```

## Your own recipe book

`data/dishes.csv` has one dish per row: name, cuisine, meal, weight (light/medium/heavy), base
(rice/roti/naan/bread/paratha/none), main ingredients separated by `;`, spice, kid friendly, the
ingredients with quantities separated by `;`, and the steps separated by `|`. Add more rows any time
and rebuild the app. Use the same simple ingredient names everywhere (`onion`, not `onions`).

## Project layout

```
lib/
  main.dart              starts Firebase, shows login or Home
  theme.dart             colours and fonts
  screens/               login, home, add groceries, dish suggestions, recipe,
                         log dish, daily log, family profile
  services/              data_service (Firestore), gemini_service (AI),
                         dish_database (recipe book), ingredient_matcher, photo_picker
  logic/                 days_left (dates and totals), stock_usage (what is left after cooking)
  models/                dish, inventory_item, meal, family_profile
data/dishes.csv          the recipe book
firestore.rules          who can read and write what
test/                    132 tests
devpost/                 the plan: scope, PRD, spec, build checklist
```

## Limits

- Android only. A website or iPhone version is not built.
- Amounts and "days left" are estimates, not exact.
- Photo reading can miss small or hidden items; everything is shown for checking first.
- The recipe book is all Pakistani dishes for now.
- Signing uses the debug key, which is fine for sharing with family but not for the Play Store.

## Documentation

[Flutter](https://docs.flutter.dev) ·
[Firebase for Flutter](https://firebase.google.com/docs/flutter/setup) ·
[Firebase AI Logic](https://firebase.google.com/docs/ai-logic) ·
[Cloud Firestore](https://firebase.google.com/docs/firestore)
