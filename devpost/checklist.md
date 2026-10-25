---
doc: checklist
status: approved
---

# Build Checklist

Build mode: learn

## Slices

- [x] **1. Mum can sign up, log in, and reach a Home screen**
  Becomes usable: A Flutter Android app that opens on a login/sign-up screen; after signing up or logging in it shows the Home screen with the four buttons (placeholders). Closing and reopening keeps her logged in.
  Why now: Proves the whole base end to end: Flutter project, Firebase connection, theme. Every later slice needs a signed-in user to save data under.
  PRD ref: `prd.md > Features and Behavior > Account`, `prd.md > Screens and Layout`
  Spec ref: `spec.md > Stack`, `spec.md > File Structure`, `spec.md > Look and Feel`, `spec.md > Components > Auth screen`
  Build: Scaffold the Flutter project in the repo root per the spec's file structure, add Firebase packages, connect the Firebase project (learner creates it; we run `flutterfire configure`), apply the warm kitchen theme, build the Auth screen and a Home screen with placeholder buttons.
  Verify (mechanical): `flutter analyze` is clean; `flutter build apk --debug` succeeds; app starts on the emulator or phone and the sign-up call reaches Firebase.
  Learner check: Open the app, sign up with an email and password, see Home, close the app fully and reopen it, and confirm you are still logged in. Say whether the look feels clean and kitchen-like.
  Commit: `Add Flutter app with Firebase login and Home screen`

- [x] **2. Ask "what can I cook?" and get dishes and a recipe (the kernel)**
  Becomes usable: From Home, tap Dish suggestion, answer lunch/dinner, heavy/light, base, and type the ingredients you have; see a list of dishes from Gemini; tap one for the full recipe.
  Why now: This is the unique kernel and the riskiest piece (Gemini through Firebase AI Logic on the free plan). Proving it first means any problem with the model, limits or JSON replies shows up early. It uses the "no groceries entered" path from the PRD, so it needs no stored data yet.
  PRD ref: `prd.md > Features and Behavior > Dish suggestion`, `prd.md > States and Boundaries` (nothing matches)
  Spec ref: `spec.md > Components > Gemini service`, `spec.md > Components > Dish suggestion screen and Recipe screen`, `spec.md > External Services and Dependencies`, `spec.md > Important Failure Modes`
  Build: Add `gemini_service.dart` with `suggestDishes` and `getRecipe` returning JSON, the preference questions screen, the results list, the recipe screen, a "Thinking…" state, and a retry message on failure. Model name kept in one setting.
  Verify (mechanical): `flutter analyze` clean; a unit test for parsing the dish and recipe JSON (including a malformed reply); run the app and confirm a real Gemini call returns dishes, or record the exact error.
  Learner check: Type "chicken, onion, rice, yogurt", choose dinner, light, rice, and say whether the dishes make sense for a home cook and the recipe is easy to follow.
  Commit: `Add dish suggestions and recipes from Gemini`

- [x] **2b. Dishes and recipes come from your own recipe book first**
  Becomes usable: Dish suggestions are picked instantly from the learner's own `data/dishes.csv` (1,003 dishes), matched on meal, weight, base and the ingredients typed; the recipe opens straight from the file. Gemini is used only when the recipe book has nothing that fits.
  Why now: The learner found Gemini too slow and wrote the database themselves; it makes the kernel instant and puts their own recipes in front of their family. It builds directly on slice 2 and must exist before the stock-based suggestions in slice 4.
  PRD ref: `prd.md > Features and Behavior > Dish suggestion`
  Spec ref: `spec.md > Components > Dish suggestion screen and Recipe screen`, `spec.md > Components > Gemini service`
  Build: Bundle `data/dishes.csv` as an app asset, parse it, normalise ingredient names (egg/eggs, potato/aloo, rice/basmati rice, and ignore non-ingredients such as "tarka"), filter by meal/weight/base, rank by how many main ingredients are available, skip dishes already shown, show recipes straight from the file, fall back to Gemini when nothing fits.
  Verify (mechanical): Unit tests for CSV parsing, ingredient matching, filtering, ranking and fallback; a test that loads the real `data/dishes.csv` and checks every dish has ingredients and steps; `flutter analyze` clean.
  Learner check: Ask for dinner, light, rice with "chicken, onion, rice, yogurt"; dishes should appear instantly from your recipe book and open with your own recipe. Then ask for noodles and confirm the app still returns ideas (from Gemini, since the recipe book has no noodles dishes).
  Commit: `Suggest dishes from the learner's own recipe database first`

- [x] **3. Add groceries by text, see them on Home with days until shopping**
  Becomes usable: Tap Add groceries, choose By text, enter item, quantity and weight, and set the shopping date; Home shows days until the next shopping and the remaining list with a total. Data is still there after restarting the app.
  Why now: Gives the app its memory (Firestore) and the dashboard, using plain typing, which is the safe path before photos.
  PRD ref: `prd.md > Features and Behavior > Add groceries`, `prd.md > Features and Behavior > Home dashboard`, `prd.md > States and Boundaries` (first use, persistence)
  Spec ref: `spec.md > Components > Add groceries screen`, `spec.md > Components > Home screen`, `spec.md > Components > Days-until-shopping calculation`, `spec.md > Data Model`
  Build: Add `data_service.dart` and the models, `days_left.dart`, the Add groceries screen (text option and the By picture button disabled for now), the Home dashboard with empty state and totals, and the next-shopping-date defaults.
  Verify (mechanical): Unit tests for days-until-shopping (including month-end dates) and the total; `flutter analyze` clean; add two items and confirm they appear in Firestore and reload after restart.
  Learner check: Add chicken 1 kg and rice 5 kg with a shopping date of today, check that Home shows the right days until next month's date and both items, then restart the app and confirm they are still there.
  Commit: `Add text groceries, Home dashboard and days until shopping`

- [x] **4. Suggestions use the stored groceries**
  Becomes usable: Dish suggestion skips the "what do you have?" question when groceries exist and suggests dishes from the stock.
  Why now: This makes the app personal to her month, the heart of the kernel, and it connects slices 2 and 3.
  PRD ref: `prd.md > Features and Behavior > Dish suggestion`
  Spec ref: `spec.md > The Core Journey Through the System` (step 5), `spec.md > Components > Gemini service`
  Build: Read inventory in the suggestion flow, pass it to `suggestDishes`, and keep the manual ingredient entry as the fallback when stock is empty.
  Verify (mechanical): Unit test that the request includes the stock items; run the flow once with stock and once with an empty inventory.
  Learner check: With groceries saved, ask for a suggestion and confirm you are not asked what you have, and that dishes use your saved items.
  Commit: `Use saved groceries for dish suggestions`

- [ ] **5. Log today's dish: stock goes down and dishes stop repeating**
  Becomes usable: After cooking, tap Log today's dish, pick the dish and confirm how much of each ingredient was used; stock decreases, the Daily log lists the meal, and tomorrow's suggestions avoid recent dishes.
  Why now: Completes the loop in the scope (suggest, cook, log, suggest again) and delivers the "don't repeat dishes" half of the kernel.
  PRD ref: `prd.md > Features and Behavior > Log today's dish`, `prd.md > Features and Behavior > Daily log`
  Spec ref: `spec.md > Components > Log today's dish screen and Daily log screen`, `spec.md > Data Model`
  Build: Add the Log dish and Daily log screens, subtract used amounts from inventory, save the meal, and pass the last 7 days of meals to `suggestDishes` so they are avoided.
  Verify (mechanical): Unit test that logging subtracts amounts and never goes below zero; run the flow and confirm the meal appears in the Daily log and the inventory total drops.
  Learner check: Cook a suggested dish, log it with amounts, and check the Home list went down. Ask for a suggestion again and confirm that dish is not offered.
  Commit: `Add dish logging, daily log and no-repeat suggestions`

- [ ] **6. Family profile shapes the suggestions**
  Becomes usable: Profile screen saves the number of people with age and gender, country and eating habits (spice, cuisines, who likes what); suggestions reflect them.
  Why now: Personalisation needs the earlier slices in place, and it is the next-most-visible difference in the demo.
  PRD ref: `prd.md > Features and Behavior > Profile`
  Spec ref: `spec.md > Components > Profile screen`, `spec.md > Data Model`
  Build: Add the Profile screen and storage in `users/{uid}`, and include the profile in the `suggestDishes` request.
  Verify (mechanical): Unit test that the profile is included in the request; save a profile, restart, confirm it loads.
  Learner check: Set "less spicy, likes desi food, kids like junk food" and check the dishes lean that way.
  Commit: `Add family profile and use it in suggestions`

- [ ] **7. Add groceries by photo**
  Becomes usable: In Add groceries, choose By picture, take or pick a photo, see the item name Gemini finds, correct it if needed, enter quantity and weight, and save.
  Why now: It is the biggest risk after the text path works; the text option is the safety net if the photo path has trouble.
  PRD ref: `prd.md > Features and Behavior > Add groceries`, `prd.md > States and Boundaries` (photo can't be recognised)
  Spec ref: `spec.md > Components > Gemini service` (`identifyItem`), `spec.md > Important Failure Modes`
  Build: Add `image_picker`, `identifyItem(photo)`, the photo flow with an editable name, and the "couldn't read that, please type it" fallback.
  Verify (mechanical): Unit test for parsing the item reply; run with a real photo and confirm the item name appears, or record the exact error.
  Learner check: Photograph a bag of rice or some chicken and say whether the name is right and the correction option works.
  Commit: `Add grocery entry by photo`

- [ ] **8. Estimate used amounts from a photo, then firm up the app**
  Becomes usable: When logging a dish, optionally send a photo and get estimated amounts to adjust; Firestore rules limit each user to their own data; the release APK builds for the family.
  Why now: Photo estimation is the last and most trimmable feature, and the rules and APK are what make it safe and shareable.
  PRD ref: `prd.md > Features and Behavior > Log today's dish`
  Spec ref: `spec.md > Components > Gemini service` (`estimateUsed`), `spec.md > Data Model` (security rules), `spec.md > Where It Runs and How Someone Tries It`
  Build: Add `estimateUsed`, the photo option in the log screen, write and deploy `firestore.rules`, add a README with run steps, and build the release APK.
  Verify (mechanical): `flutter analyze` and `flutter test` pass; `flutter build apk --release` succeeds; a request to another user's data is denied by the rules.
  Learner check: Log a dish with a photo and adjust the amounts, then install the APK on a second phone and sign in.
  Commit: `Add photo estimates, Firestore rules and release APK`

## Hands-on Checkpoints

- [x] Early usable behavior explored — after slice 2 (dishes and recipe from Gemini), because it is the kernel and the riskiest piece
- [ ] Final kick-the-tires exploration and feedback completed

## Final Review

- [ ] Final review complete — feedback resolved and learner confirms ready to ship

## Code Tour and App Map

- [ ] Learning activity complete — guided route, focused alternative, prior practice connected, or brief recap
- [ ] Optional edit and transfer reflection addressed — offered/declined/already covered/not applicable as appropriate
- [ ] `devpost/app-map.html` generated from finished code, checked, and shown, including a project-grounded practice to reuse

Activity and evidence: not started
Route and stops: not started
Edit outcome: not started
Reflection: not started
Activity mode: not started

## Revisions

- Redesigned the login and Home screens with a Fraunces/Nunito type pair, a main "What can I cook?" panel and a calmer layout — the first version looked generic to the learner, so the visual direction in `spec.md > Look and Feel` was applied more carefully.
- Sign-up now asks for the user's name (kept in the Firebase account) and Home greets them by it — the learner wanted a more personal greeting instead of the email address.
- Added `kotlin.incremental=false` in `android/gradle.properties` — the Flutter package cache is on C: and the project on D:, which breaks Kotlin's incremental build on Windows.
- Switched the Gemini model from `gemini-2.5-flash` to `gemini-3.8-flash` — Google's live reply said the 2.5 model is no longer available to new users, although its pricing page still lists it. Photo support of the new model still has to be confirmed before slice 7.
- The Gemini service now tries `gemini-3.8-flash` first and falls back to `gemini-3.5-flash-lite` when a model is busy, missing or slow — the new model answered "high demand" (error 500) on the first real call, so one model was not reliable enough for the kernel.
- Created the Firestore database (asia-south1) and deployed the per-user security rules during slice 2 instead of slice 8 — the learner asked for the Firebase backend to be set up now, and slice 3 needs the database. Slice 8 no longer needs to write the rules.
- Gemini calls were failing with "Firebase App Check token is invalid", not model load — App Check enforcement on the AI Logic API blocks an app that does not yet send App Check tokens. For the family test, enforcement is switched off; proper App Check (Play Integrity) is an open item before any wider sharing.
- Added slice 2b so suggestions come from the learner's own dish database first, with Gemini as backup — the learner found Gemini too slow and chose to write the database themselves (1,003 Pakistani dishes). This reverses `spec.md`'s "AI-written dishes on demand"; the recipe-saving idea is dropped.
- Added a variety rule to the recipe-book matcher (at most two dishes with identical main ingredients per result) — the first real preview returned five biryani variants for one request.
- Suggestions now read the groceries once with a direct read instead of re-listening to Home's live feed, and fall back to the text box after 8 seconds — a second listener on an already-open Firestore feed never receives the current list, which left the screen waiting forever.
