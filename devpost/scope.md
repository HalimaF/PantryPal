---
doc: scope
status: approved
---

# What Can I Cook?

A website that tells a homemaker what to cook today from what is actually at home, without repeating recent meals.

## The Unique Kernel
"What should I cook today, from what's in the house, without repeating what we just ate." Mothers decide this every day, often while away from home and unsure what is in the kitchen. The app remembers what was eaten recently, so dishes aren't repeated too often.

## Who It's For
Homemakers, especially mothers in middle-class Asian households, where the daily question is "what to make today?" and budgets are tight, so groceries must last the whole month. A second group she mentioned: students in rented apartments in other countries. First real users: the learner's own family.

## The Core Loop
1. Sign up or log in.
2. Home page has two buttons: "Enter your monthly groceries for personalized recommendations" and "Food suggestion."
3. She enters groceries at the start of the month (photos, with a text option).
4. Day to day, she asks for a food suggestion and picks her preference for the day (e.g. rice, bread, roti).
5. The app suggests dishes with recipes, using what's in stock and avoiding recently eaten dishes.
6. If no groceries were entered, it asks her for preferences and the ingredients she has, then suggests dishes and recipes.

She comes back because the question "what to cook?" returns every day.

## Inspiration & Identity
Not discussed yet. Details go to `3-prd`.

## Why This Matters to the Learner
Has seen this daily confusion, and the tight monthly budget, in Asian households. Wants real mothers to use it, starting with the family, and wants to find out whether the idea is good (and possibly commercial) before building a Flutter mobile app.

## What "Working" Looks Like
Her family signs up, enters a month of groceries (photos or text), asks for a food suggestion with a preference such as "roti," and gets dishes with recipes that use what is in stock. Asking again on another day doesn't repeat the recent dishes. The family uses it more than once.

## The POC Boundary
- Sign up / log in (small, fast to build).
- Grocery entry by photo, with a text option.
- Food suggestion with a daily preference, using the stock list.
- Fallback when no groceries are entered: ask preferences and available items, then suggest.
- Recipes for each suggested dish.
- Remember eaten dishes so suggestions don't repeat too often.
- Home dashboard showing days until the next grocery shopping and what is left.
- Log of the day's dish and inventory used, which updates stock.
- Profile with family details (people, ages, genders, country, eating habits) to personalise suggestions.
- Website that works well on a phone.

Learner's decision: both login and photo entry stay in. Accuracy doesn't need to be 100%; a first MVP is fine.

## Later
- Dietary rules, "use soon" priority, missing-item shopping list.
- Mobile app (Flutter, learner already has a Google Play account).
- Students living abroad as a distinct audience.
- Commercial viability.

## Explicitly Cut
- Exact quantity tracking over the month: "somewhat accurate" is accepted for the first MVP.
- A mobile app for this hackathon: the website comes first so the family can test.
