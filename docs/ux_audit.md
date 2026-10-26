# UX audit: What Can I Cook? (before the redesign)

Written from the code in `lib/screens`, `lib/theme.dart` and `lib/services`, and from what was seen on a
real phone during the build. Every problem is mapped to one of Nielsen's 10 usability heuristics:

| # | Heuristic | # | Heuristic |
|---|---|---|---|
| H1 | Visibility of system status | H6 | Recognition rather than recall |
| H2 | Match between system and real world | H7 | Flexibility and efficiency of use |
| H3 | User control and freedom | H8 | Aesthetic and minimalist design |
| H4 | Consistency and standards | H9 | Help users recognise, diagnose and recover from errors |
| H5 | Error prevention | H10 | Help and documentation |

**The user:** a homemaker, roughly 30 to 60, low to medium tech comfort, often holding the phone in one
hand in a bright, busy kitchen, sometimes reading Urdu and English together. The main job is "what should
I cook today?" from what is in the kitchen.

## Tap counts today (from launch, already signed in)

| Task | Taps | Path |
|---|---|---|
| **Add one grocery by typing** | **4** | Add groceries, tap the item box, tap the amount box, Add to my groceries (plus typing) |
| **Add groceries by photo** | **5+** | Add groceries, Take a photo, take and accept the photo in the camera app, fix any blank amounts, Add N items |
| **Get a dish suggestion** | **2** to see dishes, **3** to read a recipe | Get ideas, Show me dishes, tap a dish |
| **Log a cooked dish (from a recipe)** | **6+** | Get ideas, Show me dishes, tap a dish, scroll, I cooked this, type each amount, Save |
| **Log a cooked dish (from Home)** | **5+** | Daily log, Log today's dish, type the name, type each amount, Save |

The "under 3 taps from launch" target is **already met for seeing dishes (2 taps)** but missed for reading a
recipe (3) and for logging (6+).

## Across the whole app

| Problem | Heuristic | Evidence |
|---|---|---|
| No dark theme; colours are fixed constants (`cream`, `terracotta`) used directly in screens, so a dark mode cannot be added without touching every screen | H4, H8 | `lib/theme.dart`, every screen imports its colour constants |
| Font sizes are set by hand in many places (14, 15, 16, 17, 18, 21, 24, 30, 36), not from one type scale | H4, H8 | `fontSize:` appears throughout `lib/screens` |
| Loading is shown as a bare spinner on every screen, with no hint of what is coming | H1 | `CircularProgressIndicator` in 7 places |
| Save confirmations are plain snackbars with no way to undo | H3 | `SnackBar(content: Text(...))` after add, log and save |
| No sign that something is saved only on the phone and waiting to sync | H1 | offline writes show a one-time snackbar and nothing after |
| Strings are written into the code, so nothing can be translated, and Urdu (right-to-left) is not supported | H2, H4 | no `l10n`, hard-coded English everywhere |
| No first-run help and no hints | H10 | none exists |
| Screen-reader labels rely on Flutter's defaults; icon-only controls are a few (log out, delete, eye) and have tooltips, but nothing is checked | H9, H4 | no `Semantics` widgets |
| Navigation is a single scrolling Home list that pushes screens on top, with no bar to move around | H4, H7 | `HomeScreen` is the only hub |
| One measured layout warning: on a 360 dp-wide phone, the Add groceries page overflows by 34 px at normal font size. This test draws text with a wide stand-in font, so treat it as a likely issue, not proven | H8 | a temporary widget test run once for this audit |
| At 130% and 200% system font, no screen overflowed in the same test, which is a good sign | n/a | same test |

## Screen by screen

### Login (`auth_screen.dart`)
- No "forgot password": a person who cannot remember their password is stuck. (H9, H3)
- Mistakes (empty name, empty email) are explained only after pressing the button, not while typing. (H5)
- The password rule ("at least 6 characters") is a grey hint that disappears into the background. (H6)
- Good: show/hide password, kind error messages, one screen for both log in and sign up.

### Home (`home_screen.dart`)
- The days-until-shopping fact is a sentence, not something that can be seen at a glance. (H1, H6)
- "Items running low" is not shown anywhere, so she must read every row to notice. (H6)
- The last week of meals, the thing the app is built around, is hidden behind Daily log. (H6, H8)
- The main button sits near the top of the screen, away from the thumb. (Fitts's law, H7)
- Log out is a top-corner icon with no confirmation. (H5)
- Four destinations are reached by scrolling a list, with no bar to jump between them. (H4, H7)

### Add groceries (`add_groceries_screen.dart`)
- The shopping dates come before the items, though items are what she came to add. (H8)
- Typing is the default for amounts; nothing is remembered, no recent items to tap. (H6, H7)
- Units are chosen from a six-item dropdown, hiding the choices. (H6, Hick's law)
- The Add button is in the middle of a long page, not in the thumb zone. (H7, Fitts)
- Deleting an item asks "are you sure?" but cannot be undone afterwards. (H3)
- Photo results are editable, which is good, but an item with no amount is not flagged until she presses Add. (H5)
- Likely overflow on small phones (see above). (H8)

### Dish suggestions (`dish_suggestion_screen.dart`)
- A separate questions page must be completed before any dish appears, even though sensible defaults exist. (H7)
- Her last choices are forgotten every time. (H6)
- A dish card shows ingredients as text but not which ones she has and which are missing. (H6, H1)
- No indication of spice or kid-friendliness on the card, though both are in the recipe book. (H6)
- Showing different dishes is a button at the bottom; there is no pull to refresh. (H7)
- "Noodles" always returns nothing from the recipe book and silently waits for Gemini. (H1)

### Recipe (`recipe_screen.dart`)
- Steps are small text in a long scroll; reading them with floury hands is hard. (H8, Fitts)
- The screen can turn off while she is cooking. (H1)
- "I cooked this" is at the very bottom of the page. (Fitts, H7)
- Ingredients do not show what she has. (H6)

### Log today's dish (`log_dish_screen.dart`)
- Every amount is typed, with a decimal keyboard, one box per grocery item. (H5, H6, H7)
- Nothing is filled in from the recipe, even though the recipe lists quantities. (H7)
- There is no summary of what will be taken out before saving. (H1, H5)
- Saving cannot be undone. (H3)

### Daily log (`daily_log_screen.dart`)
- A mistaken entry cannot be corrected or removed. (H3)
- No way to log a dish from an entry ("we ate this again"). (H7)

### Family profile (`profile_screen.dart`)
- Spice is three chips; fine for Hick's law, but not a scale she can feel. (H2)
- Ages are free number boxes with no limit shown until she saves. (H5)
- Good: a clear note about what is sent to Gemini.

## What the redesign will fix first

1. One design system with light and dark themes and one type scale (all screens use it).
2. A bottom navigation bar: Home, Groceries, Cook, Family.
3. Dish suggestions that appear straight away, with her last choices remembered.
4. Logging with filled-in amounts, steppers, a summary, and Undo.
5. Skeleton loading, sync status, onboarding, hints, and every error with a fix action.
6. Strings moved into translation files, with Urdu and right-to-left support.
