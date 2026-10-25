---
doc: prd
status: approved
---

# What Can I Cook? — Product Requirements

A website for homemakers, starting with the learner's own family, that tracks the month's groceries and suggests what to cook today from what is actually at home, without repeating recent dishes.
Source: `scope.md > The Unique Kernel`, `scope.md > The Core Loop`.

## The Core Journey
1. Mum signs up or logs in.
2. She lands on the **Home dashboard**, which shows how many days are left until the next grocery shopping, and the total of what is left at home, with an **Add groceries** button above it.
3. At the start of the month she taps **Add groceries**. On the next page she chooses **by picture** or **by text**.
   - Picture: she photographs an item (e.g. chicken), and then enters its quantity/weight (e.g. 1 kg).
   - Text: she types the item name, a quantity and its weight (e.g. "chicken, 2 pieces, 1 kg").
4. Once groceries are logged, the Home page shows a **Dish suggestion** button.
5. She taps it and answers a few questions: lunch or dinner, heavy or light, and a base such as rice, bread, roti or noodles. (If no groceries were logged, the page first asks what she has at home.)
6. The app shows a list of suggested dishes, chosen from her stock, her family's habits and what was eaten recently.
7. She taps a dish and sees the **full recipe** with the making process.
8. After cooking, she taps **Log today's dish**. The app asks how much of each main ingredient was used. She types an estimate, or the app guesses from a photo of the dish. The stock list updates.
9. Next day she asks again and gets different dishes. Success: the family uses it more than once (`scope.md > What "Working" Looks Like`).

## Screens and Layout
- **Login / Sign up** — email and password, one screen with a switch between the two.
- **Home dashboard** — top: **Add groceries** button. Middle: "X days until next groceries (28th)" and the list of what is left, with a total, so she can judge for herself. Below: **Dish suggestion** (shown once groceries are logged), **Daily log**, and a link to **Profile**.
- **Add groceries** — two options, **By picture** and **By text**, then the item list entered so far.
- **Dish suggestion** — questions page, then results list.
- **Recipe** — the chosen dish, ingredients and step-by-step making process.
- **Log today's dish** — pick the dish cooked, confirm ingredients used and the estimated quantity of each.
- **Daily log** — history of dishes cooked and inventory used each day.
- **Profile** — settings and family details (see Features).

Navigation: Home links to every other screen, and each screen has a way back to Home.

## Look and Feel
- Clean and simple, easy to understand at a glance, with some "kitchen" warmth (learner's words).
- The learner is not a designer and delegated the visual choices: colours, fonts and layout are the builder's to propose within "clean, simple, kitchen-like."
- Phone-first: big buttons, little text, usable one-handed.

## Features and Behavior

### Account
- As a homemaker, I want to sign up and log in so that my groceries, family details and history are mine.
  - [ ] A new person can sign up, then land on Home.
  - [ ] A returning person can log in and see their saved data.
  - [ ] A wrong password shows a clear message.

### Home dashboard
- As a mum, I want to see how many days until my next grocery shopping, and what is left, so I can plan the month and estimate on my own.
  - [ ] Shows "X days until next groceries" counted from today to the next shopping date (e.g. shopping on the 28th, next on the 28th of next month).
  - [ ] Shows each item with its remaining quantity, plus a total of what is left.
  - [ ] **Add groceries** is above the dashboard.
  - [ ] Before any groceries are added, it shows an empty state that points to **Add groceries**.

### Add groceries
- As a mum, I want to add groceries by photo so that typing isn't tiring.
  - [ ] I take or choose a photo; the app names the item it sees.
  - [ ] I then enter the quantity and weight (e.g. chicken, 1 kg).
  - [ ] I can correct the item name if it's wrong.
  - [ ] I set the shopping date (default: today); the next shopping date defaults to the same day next month, and I can change it.
- As a mum, I want a text option so I can add anything the photo can't read.
  - [ ] I type item, quantity and weight, then save.
  - [ ] The item appears in the inventory list.

### Dish suggestion
- As a mum who is away from home, I want to ask what I can cook so that I don't have to remember my stock.
  - [ ] If groceries are logged, it goes straight to preferences: meal (lunch/dinner), heavy or light, and base (rice, bread, roti, noodles…).
  - [ ] If groceries are not logged, it first asks what ingredients she has, then the same preferences.
  - [ ] The result is a list of dishes using ingredients in stock.
  - [ ] Dishes eaten recently do not appear again.
  - [ ] Suggestions respect the profile's eating habits (spice level, cuisines, who likes what).
  - [ ] Tapping a dish opens the full recipe with ingredients and the making process.

### Log today's dish
- As a mum, I want to log what I cooked so that stock and history stay current.
  - [ ] I choose the dish cooked.
  - [ ] The app asks how much of each main ingredient was used (an estimate, e.g. chicken: how many grams?).
  - [ ] Alternatively, the app estimates quantities from a photo of the dish, and I can adjust them.
  - [ ] After saving, inventory goes down and the remaining list updates.
  - [ ] The dish and ingredients used appear in the **Daily log**.

### Daily log
- [ ] Lists each day's dish and the inventory used, newest first.

### Profile
- As a mum, I want to enter my family details so that suggestions fit them.
  - [ ] Number of people, with age and gender for each.
  - [ ] Country.
  - [ ] Eating habits: for example, prefers less spicy food, likes Chinese or Pakistani (desi) cuisine, men like desi food, kids like junk food.
  - [ ] Saved details change the dishes suggested.

## States and Boundaries
- **First use / empty home** — "No groceries yet. Add your monthly groceries to see your days until the next shopping and what is left." The Dish suggestion button asks what she has at home instead of using stock.
- **Photo can't be recognised** — the app says so and offers the text option; she can always type the item. *(Assumption — see Open Questions.)*
- **Nothing matches** — if no dish fits the stock and preferences, show a clear message and suggest adding groceries or relaxing a preference. *(Assumption.)*
- **Persistence** — accounts, inventory, profile, and logged dishes are saved per user and are still there on the next visit.
- **Accuracy** — remaining quantities are estimates, not exact (learner: "it can't be 100% accurate"). The app should say "approximately."
- **Privacy** — each user sees only their own data. Family details (ages, genders) are personal data. *(Assumption.)*

## Product Decisions
- Website first, family tests it, then a Flutter app if it's good — the learner wants to validate before investing in a mobile app.
- Days are counted by the calendar, not predicted: "days left" means days until the next grocery shopping, and the app also shows what is left so mum can estimate herself — the learner's own definition.
- Keep both login and photo entry in the first version — login "can be done fast", and photos make typing less tiring.
- Heart of the app is "what to cook" with no repeated dishes — the learner's main priority.
- A daily dish log is part of the first version — it's how the app knows what was eaten and what stock is gone.
- Used quantities come from asking the user (or a photo estimate) — the learner chose "ask quantity used, or take an assumption from a picture."
- The profile includes family size, ages, genders, country and eating habits — to personalise suggestions. Learner explained spice level, cuisine preference and kids liking junk food.
- Visual design is delegated: clean, simple, kitchen-like.

## What We're Building
Login and signup; Home dashboard with days until next shopping and the remaining stock; Add groceries by picture or text with quantities; Dish suggestion with preference questions and a no-inventory fallback; recipe pages; Log today's dish with ingredient amounts; Daily log; Profile with family details and eating habits; phone-friendly website.

## Deferred From the POC
- Exact quantity tracking and precise remaining quantities — the first version is approximate by design.
- Mobile app (Flutter) — only after the family test.
- Languages other than English — not discussed; may matter for mothers.
- Other features suggested but not chosen: "use soon" priority for fast-spoiling items, missing-ingredient shopping list.

## Possible Later Enhancements
- Prefer dishes that use up fast-spoiling ingredients first.
- Shopping list for missing items.
- A version for students living in rented apartments abroad.
- Commercial/paid features.

## Non-Goals
- Not a native mobile app in this hackathon — website first for faster family testing.
- No promise of exact inventory — accuracy is deliberately approximate.
- Not a general recipe website — it's built around the user's own stock.

## Open Questions
- **Where dish suggestions and recipes come from** (AI-generated vs. a stored recipe set) and how photos are read — settle in `4-spec`.
- **Dietary rules** such as halal or vegetarian — suggested in scope review but not chosen; the learner can add them to the profile if wanted.
- **App name** — "What Can I Cook?" is a working title; the learner may rename it.
