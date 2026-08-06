# Native Android Home Screen Widget for `pj1` Expense Tracker

## Context

`pj1` is a Flutter (Dart 3.11) expense tracker. All financial data is stored in **Cloud Firestore** under `users/{uid}/...` (transactions, `settings/currency`, `settings/preferences`, budgets, debts, savings, etc.), accessed through `FinanceRepository` (`lib/services/finance_repository.dart`) and loaded into a single in-memory state object `FinanceAppState` (`lib/state/finance_app_state.dart`). Offline persistence is enabled in `main.dart` (`persistenceEnabled: true`, unlimited cache). Auth is required via `FirebaseAuth`; app lock (`AppLockGate`, PIN/biometric) wraps the home screen. Currency selection and FX rates are mirrored to SharedPreferences by `CurrencyPreferences` (`lib/services/currency_preferences.dart`). The app package is `com.sakib.expensetracker`, MainActivity is a plain `FlutterFragmentActivity` (Kotlin, Java 17, Material 3, amber seed `0xFFF59E0B`).

Build a native Android **App Widget** (Home Screen Widget) for this app that shows live Balance / Income / Expense and provides quick actions, fully driven by the app's existing data — no hardcoded values, no duplicated business logic, one source of truth.

## 1. Layout

- **Left card (Balance):** rounded card, "Balance" title + large bold amount. Currency symbol from `CurrencySettings` (e.g. `৳12,420.20`). Material You–inspired, light/dark/dynamic-color aware.
- **Right column (two stacked cards):**
  - Income card: title, value, ↑ (up) icon.
  - Expense card: title, value, ↓ (down) icon.
- Match the app's amber/orange accent (`Color(0xFFF59E0B)` seed) and Material 3 rounded style.

## 2. Widget sizes

Support `3x1`, `4x1`, `3x2`, `4x2` with true responsive re-layout (not stretching): smaller typography in 3x1; more spacing + larger balance in 4x1; larger fonts/padding/card spacing in 3x2; largest typography, padding, touch targets and visual balance in 4x2. No dead/empty space.

## 3. Interaction & deep links

- Tap **Balance** → open app dashboard (home screen, `AuthGate`/`AppLockGate`).
- Tap **Income** → open `AddTransactionPage` with the Income tab selected.
- Tap **Expense** → open `AddTransactionPage` with the Expense tab selected.

Implementation notes:
- `AddTransactionPage` (`lib/pages/add_transaction_page.dart`) currently has `const AddTransactionPage({super.key})` and `_isIncome = false`. Add an optional `initialIsIncome` (or similar) parameter and initialize `_isIncome` from it. Also expose the same preselection from the dashboard FAB path (currently `const AddTransactionPage()` at `dashboard_page.dart:362`).
- The widget launches `MainActivity` with an intent extra (`com.sakib.expensetracker.action.ADD_TRANSACTION` + `extra_income=true/false`, and a dashboard action). Add a MethodChannel (or intent-to-Flutter bridge) in `MainActivity.kt` so Flutter routes: launch normally to the dashboard, or push `AddTransactionPage(initialIsIncome: ...)` on startup.
- Respect the app lock: a widget tap should surface the lock if one is enabled, or document the chosen behavior (recommend: show lock before routing).

## 4. Data binding (single source of truth)

- **Never hardcode values.** The widget must show the exact values the app shows.
  - **Balance** = `appState.currentBalance` (`_balance`).
  - **Income** = `appState.stats[0].amount` (`_income`).
  - **Expense** = `appState.stats[1].amount` (`_expenses`).
- These come from `FinanceAppState._recomputeTotals()` (`finance_app_state.dart:1176`), which includes debt-contribution logic. **Do not re-implement this in Kotlin.** Instead, compute on the Flutter side and push a compact snapshot (formatted display strings + currency code) to the widget:
  - Recommended mechanism: write a small JSON payload (balance, income, expense — preformatted via `formatCurrency` from `lib/utils/currency_formatters.dart` for exact parity, plus currency code) to SharedPreferences whenever `FinanceAppState` notifies, and have the widget read it. Optionally also persist the last signed-in UID to SharedPreferences so the widget can detect sign-out. This keeps the single source of truth in Flutter/Dart and guarantees "the widget displays the exact values shown in the app," including any future changes to calculation logic.
  - Do not create a second database, do not query Firestore directly from Kotlin for totals, and do not duplicate `formatCurrency` formatting.

## 5. Automatic updates

Refresh only when necessary, driven by existing change signals:
- `FinanceAppState` already notifies on every relevant change (transaction added/edited/deleted/restored, debt repayments, savings contributions, imports, balance recalcs). Push an updated snapshot from its `ChangeNotifier` listener.
- Also refresh: on app launch, when the widget is added/updated (`onUpdate` in `AppWidgetProvider`), and on a conservative periodic cadence as a fallback (e.g. hourly, using `AlarmManager`/`WorkManager` only if already available — check dependencies; prefer event-driven pushes).
- Avoid polling loops and redundant broadcasts; only fire when the payload actually changed.

## 6. Currency & formatting

- Use the app's stored currency: code from Firestore `users/{uid}/settings/currency` (restored locally by `CurrencyPreferences`) and FX rates from `CurrencySettings.usdRates`.
- Because the payload is preformatted with `formatCurrency()` (`lib/utils/currency_formatters.dart` — comma thousands, trims trailing zeros, app symbol map), Kotlin renders the exact string the app renders. Do not reformat in Kotlin.

## 7. Theme

- Support light, dark, and Material You dynamic colors (API 31+).
- Use the amber/orange seed theme to match the app; ensure sufficient contrast in both themes.

## 8. Android requirements

- Native `AppWidgetProvider` + `appwidget-provider` XML in the `android/` folder of `pj1`.
- Support Android 8.0 (API 26)+. Note the project uses `flutter.minSdkVersion` (currently 21+ for local_auth) and `compileSdk = flutter.compileSdkVersion`.
- Package namespace `com.sakib.expensetracker`; MainActivity is a `FlutterFragmentActivity` — wire the widget's click intents there via a MethodChannel.
- Support resizing, launcher updates (receiver meta-data), and `android:minWidth/minHeight/resizeMode`.
- Include proper preview image / label for launcher UI.

## 9. Performance & quality

- Fast first render, minimal battery, no unnecessary DB reads, no duplicate business logic.
- Clean separation: native provider/Kotlin layer only renders the pushed snapshot; Flutter owns data + calculations.
- Handle edge cases gracefully: signed-out user (placeholder or login prompt), empty data (show `৳0.00`-style zeros), offline/stale payload, currency change, large amounts that must not overflow the card.
- Keep existing `flutter_lints` clean; run `flutter analyze` and the existing test suite (`flutter test`) after changes.

## 10. Definition of done

- Widget renders the same Balance/Income/Expense as the dashboard, updates automatically on data changes, respects currency and theme, works at all four sizes, and deep-links correctly (Balance → dashboard; Income/Expense → Add Transaction with the tab preselected). No duplicated calculation logic; a single source of truth; no hardcoded values.
