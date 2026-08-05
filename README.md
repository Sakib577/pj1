# Expense Tracker & Personal Finance Manager

A cross-platform personal finance app built with Flutter and Firebase for tracking transactions, budgets, savings goals, debts, planned payments, and shopping lists.

## Features

- **Transactions** — add/edit/delete income & expense entries with categories, notes, and timestamps
- **Categories** — custom expense/income categories with icons, colors, and subcategories
- **Budgets** — per-category and rolling-period budgets with progress and overspend alerts
- **Savings Goals** — target amounts, deadlines, and contribution-linked progress
- **Debts** — track borrowed/lent amounts with due dates and settlement status
- **Planned Payments** — scheduled payments with local notification reminders
- **Shopping Lists** — categorized lists with cost estimates and purchase tracking
- **Analytics** — statistics dashboard with adaptive trend lines (spending, income vs expense, cash flow with net line, savings trend, balance history), category donut, spending patterns, top expenses, budget progress, cash-flow forecast, and next-month estimates
- **Reports** — formal accounting statements (Cash Flow Statement, Income Statement, Balance Sheet, Budget vs Actual, Debt, Savings & Net Worth) for a selectable period
- **Export** — vector PDF and CSV export of reports and transaction history via the share sheet
- **Multi-Currency** — display currency selection with real-time exchange rates
- **Security** — Firebase Auth, biometric app lock with PIN fallback, encrypted local storage
- **Offline-first** — full functionality via Firestore offline persistence

## Tech Stack

Flutter (Dart), Firebase Auth, Cloud Firestore, fl_chart, pdf, share_plus, flutter_local_notifications, local_auth, shared_preferences, http.

## Getting Started

```bash
flutter pub get
flutter run
```

Requires a Firebase project with `firebase_options.dart` configured (Auth, Firestore) and Google services files for the target platforms.

## Testing

```bash
flutter analyze
flutter test
```

Full project report: [`docs/project_report.md`](docs/project_report.md).
