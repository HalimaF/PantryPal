---
doc: spec
status: approved
---

# What Can I Cook? — Technical Spec

## How This Works, In Plain Language
The app is an **Android app** built with **Flutter**, the tool you already know. It talks to two Google services, and nothing else.

- **Firebase Authentication** handles sign-up and login. It remembers who mum is.
- **Firestore**, Firebase's online database, is like a spreadsheet kept in the cloud, one set of sheets per person. It stores her groceries (the inventory), her family details (the profile), and the log of what she cooked. Because it's online, she can open the app on her phone at the shop and see what's at home.
- **Gemini** is the AI. The app sends it a photo or a question and gets an answer back: "this photo is chicken," or "here are 5 dishes you can make." Gemini is reached through **Firebase AI Logic**, so the secret key never sits inside the app.

Why this shape: three pieces, all from Google, all designed to work with Flutter. You've used Firebase before, so the only new piece is the Gemini calls. There is no server of our own to build or host.

## The Core Journey Through the System
PRD ref: `prd.md > The Core Journey`.

1. **Sign up / log in** → Firebase Auth checks her email and password → the app opens Home.
2. **Home** → the app reads her `inventory` and her next shopping date from Firestore → counts the days from today to that date and lists what is left, with a total.
3. **Add groceries (photo)** → she picks a photo → the app sends it to Gemini → Gemini replies with an item name ("chicken") → she confirms or corrects it and types the quantity and weight → the app saves a new item in Firestore → the Home list updates. When she adds a new shopping, she sets the shopping date and the next shopping date (default: same day next month).
4. **Add groceries (text)** → she types name, quantity and weight → saved to Firestore.
5. **Dish suggestion** → she answers lunch/dinner, heavy/light, base → the app sends Gemini her stock, her profile and her last 7 days of meals → Gemini replies with a list of dishes → the app shows them.
6. **Recipe** → she taps a dish → the app asks Gemini for the full recipe → shows ingredients and steps.
7. **Log today's dish** → she picks the dish and types how much of each ingredient was used (or sends a photo and Gemini estimates; she can adjust) → the app saves the meal and subtracts the amounts from `inventory` → Home's remaining list updates and the dish shows in the Daily log.
8. Next day, step 5 repeats, and the last meals are sent along so Gemini avoids them.

## Stack
| Piece | Choice | Why / tradeoff |
|---|---|---|
| App | Flutter (Dart), Android | Learner's established tool; setup already exists. Tradeoff: family installs an APK rather than opening a link. |
| Login | Firebase Authentication (email + password) | Learner has used Firebase. |
| Database | Cloud Firestore | Same project as Auth; online, so data follows her phone. |
| AI | Gemini via Firebase AI Logic (`firebase_ai` package) | Learner accepted one AI service for photos and recipes. The API key stays out of the app. |
| Photos | `image_picker` package | Camera or gallery picker. |
| State | Plain Flutter widgets reading Firestore streams (`StreamBuilder`) | No extra state library needed for a small app. |

Docs:
- Flutter: https://docs.flutter.dev
- Firebase for Flutter: https://firebase.google.com/docs/flutter/setup
- Firebase Authentication: https://firebase.google.com/docs/auth/flutter/start
- Cloud Firestore: https://firebase.google.com/docs/firestore/quickstart
- Firebase AI Logic: https://firebase.google.com/docs/ai-logic
- Firebase AI Logic pricing: https://firebase.google.com/docs/ai-logic/pricing
- Gemini API pricing and limits: https://ai.google.dev/gemini-api/docs/pricing and https://ai.google.dev/gemini-api/docs/rate-limits

**Checked against Google's pages (2026-10-25):**
- The Gemini API free tier exists and needs no payment method. Models listed as free with image input include `gemini-2.5-flash`, `gemini-2.5-flash-lite` and `gemini-3.5-flash-lite` ([pricing](https://ai.google.dev/gemini-api/docs/pricing)).
- Firebase AI Logic works on the free Spark plan as long as no billing account is linked; preview and media-generating models may need billing ([Firebase AI Logic pricing](https://firebase.google.com/docs/ai-logic/pricing)).
- **Free tier data use:** Google says free-tier content is used to improve its products.
- **Chosen model:** `gemini-3.8-flash`, kept in one setting so it can be swapped. `gemini-2.5-flash` was tried first and Google rejected it as "no longer available to new users". Whether `gemini-3.8-flash` accepts photos is not stated on the pricing page; `gemini-3.5-flash-lite` is listed with image input and is the fallback for photo steps.

**Still unverified, check first in the build (step 1):**
- That the chosen model answers a photo request through Firebase AI Logic in this project.
- Free-tier request limits. Google publishes no fixed numbers; they show live at https://aistudio.google.com/rate-limit.
- Exact package versions (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_ai`, `image_picker`).

## Where It Runs and How Someone Tries It
- **Runtime:** an Android phone or the Android emulator, with the Firebase project online.
- **Needs:** Flutter SDK, Android Studio or a phone with USB debugging, a Firebase project with Auth (email/password) and Firestore enabled, and Firebase AI Logic enabled with the Gemini Developer API.
- **Start:** `flutter pub get`, then `flutter run`.
- **Install on family phones:** `flutter build apk --release`, then share the APK file. A Play Store testing track is a later option; the learner has a Play account.
- **Demo recording:** screen-record the phone or emulator: sign up, add groceries by photo and text, ask for a suggestion, open a recipe, log the dish, and show Home's remaining list change.
- **Submission:** needs a short demo video and a public GitHub repo. Deployment is optional and isn't needed here.
- **Secrets:** Firebase config files are not passwords, but keep them out of the repo if you prefer (`google-services.json`); never commit any API key. Firestore rules (below) protect the data.

## Look and Feel
PRD ref: `prd.md > Look and Feel`. Clean, simple, a bit like a kitchen.
- **Colours:** warm cream background, terracotta accent, soft green for "good" states. Light theme first.
- **Type:** a friendly rounded sans-serif; large text and big tap targets, phone-first and one-handed.
- **Density:** spacious, few words per screen; icons beside labels.
- **Tone of copy:** short and kind, like "Add your groceries" rather than technical wording.
- **Flutter note:** Material 3 theming handles this fully with a custom colour scheme; no custom design system is needed.

## Components

### Auth screen
Sign-up / log-in with a toggle. Talks to Firebase Auth.
PRD ref: `prd.md > Features and Behavior > Account`.

### Home screen
Shows days until the next grocery shopping, the list of what is left with a total, and the buttons (Add groceries, Dish suggestion, Daily log, Profile). Reads `inventory` and the next shopping date.
PRD ref: `prd.md > Features and Behavior > Home dashboard`.

### Add groceries screen
Two options: by picture or by text. Photo flow calls the Gemini "identify item" request, then asks for quantity and weight. Saves to `inventory`.
PRD ref: `prd.md > Features and Behavior > Add groceries`.

### Dish suggestion screen and Recipe screen
Preference questions, then the Gemini "suggest dishes" request. Tapping a dish makes the Gemini "recipe" request. If the inventory is empty, the first step asks which ingredients she has.
PRD ref: `prd.md > Features and Behavior > Dish suggestion`.

### Log today's dish screen and Daily log screen
Choose the dish, confirm ingredient amounts (typed, or estimated by Gemini from a photo), save the meal, subtract from stock. The Daily log lists meals newest first.
PRD ref: `prd.md > Features and Behavior > Log today's dish`, `prd.md > Features and Behavior > Daily log`.

### Profile screen
Number of people with age and gender, country, and eating habits (spice level, cuisines, who likes what). Saved in Firestore and sent to Gemini with every suggestion.
PRD ref: `prd.md > Features and Behavior > Profile`.

### Gemini service
One file with four functions, each returning structured JSON (not free text) so the app can read it reliably:
1. `identifyItem(photo)` → `{ "name": "chicken" }`
2. `suggestDishes(preferences, stock, profile, recentMeals)` → list of `{ "name", "why", "mainIngredients" }`
3. `getRecipe(dishName, stock, profile)` → `{ "ingredients": [...], "steps": [...] }`
4. `estimateUsed(dishName, recipe, photo?)` → list of `{ "item", "amount", "unit" }`

PRD ref: all of `prd.md > Features and Behavior`.

### Days-until-shopping calculation
Plain code, no AI. Days = next shopping date minus today (e.g. shopping on the 28th, next on the 28th of next month). The Home screen also lists each item's remaining quantity and a total, so mum can judge whether it will last. This is the learner's own definition.
PRD ref: `prd.md > Features and Behavior > Home dashboard`.

## Data Model
Everything lives in Firestore under the signed-in user. When she leaves and comes back, it is all still there.

- `users/{uid}` — profile: `people` (list of `{age, gender}`), `country`, `habits` (text), `spice` level, `lastShoppingDate`, `nextShoppingDate`.
- `users/{uid}/inventory/{itemId}` — `name`, `quantity`, `unit`, `weightKg` (remaining), `addedAt`.
- `users/{uid}/meals/{mealId}` — `date`, `dishName`, `used` (list of `{item, amount, unit}`), `slot` (lunch/dinner).

**Security rules (to write in the build):** a signed-in user can read and write only documents under their own `users/{uid}`.

## File Structure
```
what_can_i_cook/
├── lib/
│   ├── main.dart              # starts Firebase, decides Auth screen vs Home
│   ├── theme.dart             # colours, fonts, Material 3 theme
│   ├── screens/
│   │   ├── auth_screen.dart
│   │   ├── home_screen.dart
│   │   ├── add_groceries_screen.dart
│   │   ├── dish_suggestion_screen.dart
│   │   ├── recipe_screen.dart
│   │   ├── log_dish_screen.dart
│   │   ├── daily_log_screen.dart
│   │   └── profile_screen.dart
│   ├── services/
│   │   ├── gemini_service.dart   # the four Gemini requests
│   │   └── data_service.dart     # reads/writes Firestore
│   ├── models/                   # InventoryItem, Meal, Profile
│   └── logic/
│       └── days_left.dart        # days until next shopping
├── test/
│   └── days_left_test.dart       # checks the calculation
├── android/                      # Flutter's Android project (+ Firebase config)
├── firestore.rules               # per-user access rules
├── pubspec.yaml                  # dependencies
├── devpost/                      # Devpost learning workspace
└── README.md
```

## External Services and Dependencies
- **Firebase Authentication** — email/password. Docs: https://firebase.google.com/docs/auth/flutter/start. Free tier; no card needed on the Spark plan.
- **Cloud Firestore** — documents above. Docs: https://firebase.google.com/docs/firestore/quickstart. Free quota is ample for a family test (unverified; check).
- **Gemini via Firebase AI Logic** — called through the `firebase_ai` Flutter package (no raw endpoint or key in the app). Photo is sent as image bytes with a text prompt; response requested as JSON. Docs: https://firebase.google.com/docs/ai-logic. The free tier exists and does not need billing, but model availability and limits for image input are **unverified**. Search results: [Firebase AI Logic pricing](https://firebase.google.com/docs/ai-logic/pricing), [Gemini API rate limits](https://ai.google.dev/gemini-api/docs/rate-limits).
- **Privacy note:** Google states free-tier content is used to improve its products, so family photos and details sent to Gemini fall under that. Fine for a family test; reconsider before a wider launch.

## Important Failure Modes
- **Gemini is slow, rate-limited or down** → the app first tries the second model (`gemini-3.8-flash`, then `gemini-3.5-flash-lite`); if both fail,  show "Thinking…", then a friendly message with a Retry button; the text option for groceries still works.
- **Gemini returns something that isn't valid JSON, or a wrong item** → catch the error, ask once more, then show "We couldn't read that, please type it." Always show the item name for her to correct.
- **No internet** → a clear message; nothing is half-saved because writes are one document at a time.
- **No dish fits the stock** → the empty message from `prd.md > States and Boundaries`.

## What Was Simplified and Why
- **Email/password login** only, no social login or password reset flow — shortest path that keeps your decision to include login.
- **Plain widgets and Firestore streams** instead of a state library — fewer things to learn for a small app.
- **Calendar-based days until the next shopping, plus the remaining list** instead of predicting how long food will last — your own definition; mum judges the rest. The fuller version would predict from usage or shelf life.
- **Recipes created by AI on demand** instead of a stored recipe database — no data to prepare, and it adapts to her stock.
- **Android only** — your family is on Android.

## Decisions and Open Issues
**Learner choices**
- Flutter Android app directly, instead of a website first — setup already exists and the family uses Android. This reverses the earlier website-first plan.
- Firebase for login and storage — already used before.
- Gemini as the single AI service for photos and recipes — fewer services; Hugging Face food models don't cover Asian dishes or raw groceries.

**Derived by the agent (confirm or change)**
- Next shopping date defaulting to the same day next month (editable).
- The Firestore data layout and per-user security rules.
- The four Gemini requests returning JSON.

**Learner uncertainty:** none identified; the learner was comfortable with the plan.

**Open issues**
- Verify the chosen Gemini model works through Firebase AI Logic, and check live limits (see Stack).
- Dietary rules (halal, vegetarian) remain unchosen from `prd.md > Open Questions`.
- App name is still the working title.
- Whether family photos and details sent through the free tier are acceptable: Google says free-tier data is used to improve its products.
