# Patuakhali Science and Technology University

<div align="center">

## Software Development Project Report

**Course Code:** CCE-310  
**Course Title:** Software Development Project  
**Project Type:** Mobile App Development  
**Level - III, Semester – I**

---

### Submitted By

| | |
|---|---|
| **Name:** | Sakib Hasan |
| **Student ID:** | [Your ID] |
| **Registration:** | [Your Reg] |
| **Session:** | [Your Session] |
| **Faculty:** | Computer Science and Engineering |

---

### Submitted To

**Prof. Dr. Md. Samsuzzaman**  
Professor  
Department of Computer and Communication Engineering  
Faculty of Computer Science and Engineering

---

**Submission Date:** [Date]

</div>

---

<div style="page-break-after: always;"></div>

## Table of Contents

1. [Project Title](#1-project-title)
2. [Introduction & Abstract](#2-introduction--abstract)
3. [Objectives](#3-objectives)
4. [Scope](#4-scope)
5. [System Analysis & Design](#5-system-analysis--design)
   - 5.1 [Use Case Diagram](#51-use-case-diagram)
   - 5.2 [Activity Diagram](#52-activity-diagram)
   - 5.3 [Class Diagram](#53-class-diagram)
   - 5.4 [Sequence Diagram](#54-sequence-diagram)
   - 5.5 [Entity-Relationship Diagram (ERD)](#55-entity-relationship-diagram-erd)
   - 5.6 [Data Flow Diagram (DFD)](#56-data-flow-diagram-dfd)
   - 5.7 [Component Diagram](#57-component-diagram)
   - 5.8 [Deployment Diagram](#58-deployment-diagram)
6. [Methodology](#6-methodology)
7. [Technology Stack](#7-technology-stack)
8. [Project Timeline](#8-project-timeline)
9. [Risk Analysis](#9-risk-analysis)
10. [Conclusion](#10-conclusion)

---

<div style="page-break-after: always;"></div>

## 1. Project Title

<div align="center">

# Expense Tracker & Personal Finance Manager

### A Cross-Platform Mobile Application for Personal Financial Management

</div>

---

## 2. Introduction & Abstract

**Expense Tracker** is a cross-platform mobile application developed using **Flutter** and **Firebase**, designed to help individuals manage their personal finances effectively. The application provides a comprehensive suite of financial tools including transaction tracking, budget management, savings goal tracking, debt management, shopping lists, planned payments, and financial analytics.

The system implements a secure, role-less (single-user) model with cloud synchronization via Firebase Firestore, offline persistence, and biometric app-lock security. Users can track income and expenses across customizable categories, set budgets with real-time progress monitoring, manage savings goals, and receive payment reminders through local notifications.

The application supports multi-currency display with real-time exchange rates, ensuring usability across different geographical regions. All financial data is stored securely in Firebase Firestore with client-side encryption for sensitive fields, and the app maintains full functionality even when offline through Firestore's offline persistence layer.

---

## 3. Objectives

### 3.1 Primary Objective

To develop a secure, intuitive, and feature-rich personal finance management mobile application using Flutter and Firebase that empowers users to take control of their financial health.

### 3.2 Functional Objectives

| # | Objective | Description |
|---|---|---|
| F1 | Transaction Management | Add, edit, delete income/expense transactions with categories, notes, and timestamps |
| F2 | Category Customization | Create and manage custom expense/income categories with icons and colors |
| F3 | Budget Tracking | Set monthly budgets per category with visual progress indicators and overspend alerts |
| F4 | Savings Goals | Create and track savings goals with target amounts, deadlines, and progress tracking |
| F5 | Debt Management | Track borrowed and lent amounts with due dates and settlement status |
| F6 | Planned Payments | Schedule recurring or one-time future payments with local notification reminders |
| F7 | Shopping Lists | Create categorized shopping lists with cost estimation and purchase tracking |
| F8 | Multi-Currency Support | View financial data in multiple currencies with real-time exchange rates |
| F9 | Biometric App Lock | Secure the application with device biometrics (fingerprint/face) and PIN fallback |
| F10 | Financial Analytics Dashboard | Visual dashboard with summary cards, charts, and financial health indicators |

### 3.3 Non-Functional Objectives

| Category | Target |
|---|---|
| **Performance** | App cold start < 3 seconds; screen transitions < 300ms |
| **Reliability** | 99.9% uptime (Firebase-dependent); full offline functionality |
| **Security** | Firebase Auth + biometric lock + encrypted local storage |
| **Usability** | Material Design 3; intuitive navigation; accessibility support |
| **Scalability** | Firestore serverless auto-scaling; supports unlimited transactions per user |
| **Portability** | Cross-platform: Android, iOS, Web, Windows, macOS, Linux |

---

## 4. Scope

### 4.1 In-Scope

- Personal transaction management (income & expenses)
- Budget creation and real-time monitoring
- Savings goal setting and tracking
- Debt/loan tracking (borrowed & lent)
- Planned payment scheduling with reminders
- Shopping list management
- Multi-currency support with exchange rates
- Biometric app-lock security
- Financial dashboard with summary analytics
- Firebase cloud synchronization
- Offline-first architecture with local persistence

### 4.2 Out-of-Scope

- Multi-user / family account sharing
- Bank account integration / Open Banking APIs
- Investment portfolio tracking
- Tax calculation and reporting
- Invoice generation
- Cryptocurrency tracking

### 4.3 Target Platforms

| Platform | Status |
|---|---|
| Android | Primary (fully tested) |
| iOS | Supported |
| Web | Supported |
| Windows | Supported |
| macOS | Supported |
| Linux | Supported |

---

<div style="page-break-after: always;"></div>

## 5. System Analysis & Design

### 5.1 Use Case Diagram

The use case diagram below illustrates the interactions between the **User** and the Expense Tracker system, capturing all major functional requirements.

<p align="center">
  <img src="https://www.plantuml.com/plantuml/svg/XLJ1Rjim3BthAuWSklRWVS1G16tTO2lGRK6pxZeeDkC8iIL3ahCQm_vzb6GfSX1qW0yozVX8yP6yCvPhEtGjQt5dmIhGejbRg8N6oWebcJa8sNFDE-XvTU0DRkpO8hXhBfiM6UELLHeMhmRr0hY1WGxH-4rPiHCLTrIm6Ot5pcFCQE3sThB0SibO8eJ5wgr7QH1-Q8g8EldzOG3qVO2r5XtN8vHA8r1SABb1GrSKkg8ZBBvoIQaw1ccuVuZnSL_BNzvs0LjoYutI0XEIB3bkWnOUXhf1cn3JRuxoISE67uLi37nMl4re_tCXyYDkJvJ-PnQsscCzK5tMBPSIQrZpiKDvyeY02yoRlUfxIWIUXSaS9clky5FWRtZaPhzLNDTm1VUIjwCLrIankem2K2ciVzyLQO4xr2YhkG2baZlH3AHFEMXtFIQdLDxf8dTRIRwbfzxtFJohwX2XxfnY3zjYXzmIjuk_UhFKB4xWi_17r7PU0DVUMKUaF08sTt_12iKHOwdX1JiXQzGfzs2OPVxMAmeuQ_Wl55JfCJe52FElA8g2M5kFCtlH6sS9Lq-oQeVQbpEsAtnSJWq9dsXkH43Gs43MXU-00iufE842wmMk31DftqVvfluFnlVq6SO_rOjN6xXEAaAnX0Sgw4qWYJe6dgIceqBl6wEbAJcFE8TDAWLG476E2Ytc5qvHQ-e1UP4_SpqzwIzZGLYt2cavqRI6rGFNtsKxfhNr92tgQIlTUDtTogJ3IPgPnUsX_3zkdTmMTajk2OiajwH5CJF6PJ3pTRC-Io7EQcxqKybYkV87CxVV9zGqAkoE2ZnqxJy" alt="Use Case Diagram" />
</p>

<details>
<summary><b>📋 PlantUML Code: Use Case Diagram</b></summary>

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "User" as user
actor "Notification System" as sys << System >>

rectangle "Expense Tracker System" {
  
  ' Primary Core Use Cases
  usecase "Manage Transactions" as UC_Trans
  usecase "Manage Categories" as UC_Cat
  usecase "Set Budgets" as UC_Budgets
  usecase "Track Savings Goals" as UC_Goals
  usecase "Manage Debts" as UC_Debts
  usecase "Schedule Planned Payments" as UC_Schedule
  usecase "Manage Shopping Lists" as UC_Shopping
  usecase "View Dashboard & Analytics" as UC_Dash
  
  ' Settings & Preferences
  usecase "Configure Currency Settings" as UC_Currency
  usecase "Enable App Lock" as UC_Lock
  
  ' Sub-features & Extensions
  usecase "Convert Shopping List to Transaction" as UC_Convert
  usecase "Receive Payment Reminders" as UC_Remind
  usecase "Export Notification History" as UC_Export

  ' --- Relationships ---

  ' Includes
  UC_Trans .> UC_Cat : <<include>>
  UC_Budgets .> UC_Cat : <<include>>
  
  UC_Dash .> UC_Trans : <<include>>
  UC_Dash .> UC_Budgets : <<include>>
  UC_Dash .> UC_Goals : <<include>>
  UC_Dash .> UC_Debts : <<include>>

  ' Extends (Extension -> Base)
  UC_Convert .> UC_Shopping : <<extend>>
  UC_Schedule .> UC_Debts : <<extend>>
  UC_Export .> UC_Remind : <<extend>>

  ' System-driven
  UC_Schedule .> UC_Remind : <<include>>
}

' --- User Connections (Only Primary Interactions) ---
user --> UC_Trans
user --> UC_Cat
user --> UC_Budgets
user --> UC_Goals
user --> UC_Debts
user --> UC_Schedule
user --> UC_Shopping
user --> UC_Dash
user --> UC_Currency
user --> UC_Lock

' System Connections
sys --> UC_Remind

@enduml
```
</details>

---

### 5.2 Activity Diagram

The activity diagram below illustrates the **full transaction creation workflow**, from authentication through data persistence.

<p align="center">
  <img src="https://www.plantuml.com/plantuml/svg/RLBBRkCm3BphAuYUdCEYTnkBrka3AB085flq0nYPjeNAaY3HQVltfUIuARgz218r798pl4sCaUV9gd9HzNEY23wGIu0XDChqKBKXm1-lNu0S7YrrDnlWaHnKxvGs2g1kv_ncev49JWPXQ_n478s-_lkqQmHIQ2ueunsaMMjAgP_j9v_pcKu8zwD_1OhHnwO44liW5tATwTLogdg79pFaYkpX7jDuz1YxHjK7373LTXqS8hg4EbUxWkgntMuQINjmB2FovGywOZGsDSfvOOjc65cA_OA3OKlbrav-TalmJYeEFhwNnoudL3va6hIR4hiNm3MRYNAZa2bLKV79QH45V8I7jwmlVOwz_1GbzyJWIAOo9uBVqADDr2YI4wfpsayuZZEjCgyDmd7k1e7HcqcSldic77SZYQTdbDZFSrhKpYpRDLaJTVzRVd7fdF-AqHatB0IBGz_zskEfUFLe8ecXaPRjAk4Vbc5ThkVGPPEjrsXBcsNI-X_rGZD-TNvjwKm6lRH-HFso2hYirvVbWabWEAo4BA99KAFJP9krxx9xj_AO9_i1" alt="Activity Diagram" />
</p>

<details>
<summary><b>📋 PlantUML Code: Activity Diagram — Transaction Creation</b></summary>

```plantuml
@startuml
start
:User opens app;
if (App Lock enabled?) then (yes)
  :Authenticate via Biometric/PIN;
  if (Authentication successful?) then (no)
    :Show error;
    stop
  endif
endif

:Navigate to Dashboard;
:Tap "Add Transaction" (FAB);

:Enter transaction details;
note right
  - Title
  - Amount
  - Category
  - Note (optional)
  - Date/time
end note

if (Income or Expense?) then (Income)
  :Set negative = false;
else (Expense)
  :Set negative = true;
  if (Category budget exists?) then (yes)
    :Check budget status;
    if (Budget exceeded?) then (yes)
      :Show budget warning;
    endif
  endif
endif

:Save to Firestore;
if (Save successful?) then (yes)
  :Update local state;
  :Refresh Dashboard;
  :Show success feedback;
else (no)
  :Show error message;
  :Retry or cancel;
endif

stop
@enduml
```
</details>

---

### 5.3 Class Diagram

The class diagram presents the core domain models and their relationships within the Flutter application.

<p align="center">
  <img src="https://www.plantuml.com/plantuml/svg/bLPDRoCf4BtxLw1SrjcTH9DhP5dZSIQhI9ci5MVF4OQoZK932-XiFAFvxrj0Vz1q9_QSRAXNnQiFNlF5EcfSLSY9VH6gf8OMX4bgxS8v8pQLWpkcrLhy0F8vX![alt text](image.png)zngvOBbwceo2JlaoL1bAND2gpi71Vav8UI2h36KsX71qvKJJaAwOQjDjyTrjP50QA4hvNf1a4vOBxNK9Yp3lnJ3g8ETDeS7MlHEKDh5zKPhIHJig1ElSUS6NPv40OGPmBzyuG_zYpXzAmnOfmrCpyar-KxBMGpsYV23eeLWym3S6brqKAwPHsVLcFngolJjhGHbOLdp_AXCgid1zm5Pqhm2hCs-hbc1RTdBmzUAxy2b1ek7kgUziDyz8j0sK52Xy9o83Zb6T31lmkuA34FFVotm5D1c4tr_AvcQaHI5659CFKemGlC-rvnbESxFcuJzvnLCafplVCTyJLyndlrRK_axjF7AOBn5DvlrFgkCGIA9eHqh3fHBeM1ab341etSuEhOkT9v4ctWCd9ivFTXxsCPzeLoT-58NfGHNrwIVzmritB7xYLMrMZragGyl90VBZ2Zza6SfL-3_TnTEs3KulE0ytRg7bh5l5JgDy5r9gXJm5JqK23zDLTubF527ZnW_WcygkgKH3CHECrXHvy2er6D5HPnN1M_k9aOCAJN79EEtrsM90O-r8fy_L1bHU9LQ6S5wT5ULONjgWOyb75WLrBmiEjpqlADpAnJ5d1PbkNReGcQpvPwg7Jne9xO2p7nUaxmNriqoSPkJPzVjs0wNQHtYQZu24bHVGn0KfIT197SLpRPR9PXchX70yMzYwKyGsilUHdfEqXH_KBAqeOAKyoJtgK33UJ1K9VSjJcty4-di7FnzxDlFcv2rHiMqqtYrmOTAZKuxAkyKqmNaWX1CTTbpcmBtbKhVvb4fhqVW4KfjXUlKt7_QDZWlxIUEF6-Rlo7kVzInVPAQ3U5n084Miz5vcNT-CSMXIpOKYKSo34EtT58I7pySGt0xCWcoFon3dsoOvk-E1VhTLguoC7lLWi-FJSaOV7HeSc3RlsNKfSFAm1Q2GjcwWp_neUS4-uMYGurNZWxmNE8YpdQBsX-uQOHhmAb5MIJ7K8UQOvjAHRti0TqwnpBDuRmFWpSM5ESHZxR31rSOrYJRkW6FK0Z5mQp1lA8UDYChAw_DzvfH6HKCTSTFvafMEw6y0lZV-ErHmWagyIqxZOmismEl96GdJCkuZY3chufiRSrbHbVsWiBVZK_76BKL2RtqcGQAYyhj4LsJ9C-qgfzej3Fqsk4LVrv_ENtCRufYTVWu1EkVOhmXaiLFhjWULa9DKUG6hiZx3_88CXPkBqexoJyIPrTdvE9YJix-F1ky_g_nQwFe3ZxsoX_3ftbbZyxJdDBttcaUxKlfD7ZsK3cHLVeCUD_byd8-ei_NfB8TE37uwCE6rFVwFOT1LO_W-mKz0avgUGGvA6EBppFozGjr_7nvUJKsIyrZumTmiZbCiiY-fk-eo3L1sTdjy1Ky-GAALuNy7m" alt="Class Diagram" />
</p>

<details>
<summary><b>📋 PlantUML Code: Class Diagram</b></summary>

```plantuml
@startuml
skinparam classAttributeIconSize 0
skinparam classFontSize 11

class TransactionItem {
  - String id
  - String title
  - String subtitle
  - double amount
  - String icon
  - Color iconColor
  - String categoryName
  - String note
  - bool negative
  - DateTime createdAt
  + toFirestore() : Map<String, dynamic>
  + fromFirestore(doc) : TransactionItem
}

class ExpenseCategory {
  - String id
  - String name
  - IconData icon
  - Color color
  - double monthlyBudget
  - double spentThisMonth
  + remainingBudget() : double
  + budgetPercentUsed() : double
}

class BudgetCategory {
  - String id
  - String name
  - double limit
  - double spent
  - String period
  + remaining() : double
  + percentUsed() : double
  + isOverBudget() : bool
}

class SavingsGoal {
  - String id
  - String name
  - double targetAmount
  - double currentAmount
  - DateTime deadline
  - String icon
  + progressPercent() : double
  + remainingAmount() : double
  + daysLeft() : int
  + isCompleted() : bool
}

class DebtItem {
  - String id
  - String personName
  - double amount
  - String description
  - DateTime dueDate
  - bool isSettled
  - bool isLent
  + isOverdue() : bool
}

class PlannedPayment {
  - String id
  - String title
  - double amount
  - String categoryName
  - DateTime dueDate
  - bool isRecurring
  - String recurrencePattern
  - bool isPaid
  + nextDueDate() : DateTime
}

class ShoppingItem {
  - String id
  - String name
  - double estimatedPrice
  - bool isPurchased
  - String category
  + markAsPurchased()
}

class FinanceAppState <<ChangeNotifier>> {
  - _transactions : List<TransactionItem>
  - _categories : List<ExpenseCategory>
  - _budgets : List<BudgetCategory>
  - _savingsGoals : List<SavingsGoal>
  - _debts : List<DebtItem>
  - _plannedPayments : List<PlannedPayment>
  - _shoppingItems : List<ShoppingItem>
  + addTransaction(item)
  + updateTransaction(id, item)
  + deleteTransaction(id)
  + addBudget(budget)
  + updateBudget(id, budget)
  + totalIncome() : double
  + totalExpense() : double
  + netBalance() : double
}

class FinanceRepository {
  - FirebaseFirestore _firestore
  + watchTransactions() : Stream<List<TransactionItem>>
  + watchBudgets() : Stream<List<BudgetCategory>>
  + watchSavingsGoals() : Stream<List<SavingsGoal>>
  + watchDebts() : Stream<List<DebtItem>>
  + watchPlannedPayments() : Stream<List<PlannedPayment>>
  + addTransaction(item) : Future<void>
  + updateTransaction(id, item) : Future<void>
  + deleteTransaction(id) : Future<void>
}

class CurrencyPreferences {
  - {static} SharedPreferences _prefs
  + {static} hydrate() : Future<void>
  + {static} selectedCurrency() : String
  + {static} setSelectedCurrency(code)
  + {static} exchangeRates() : Map<String, double>
}

class PaymentReminderService {
  - FlutterLocalNotificationsPlugin _plugin
  + initialize()
  + schedulePaymentReminder(payment)
  + cancelReminder(id)
  + checkDuePayments()
}

class AppLockService {
  - LocalAuthentication _auth
  + authenticate() : Future<bool>
  + isLockEnabled() : Future<bool>
  + setLockEnabled(bool)
  + verifyPin(pin) : Future<bool>
}

' Relationships
FinanceAppState "1" --> "*" TransactionItem : manages
FinanceAppState "1" --> "*" ExpenseCategory : manages
FinanceAppState "1" --> "*" BudgetCategory : manages
FinanceAppState "1" --> "*" SavingsGoal : manages
FinanceAppState "1" --> "*" DebtItem : manages
FinanceAppState "1" --> "*" PlannedPayment : manages
FinanceAppState "1" --> "*" ShoppingItem : manages
FinanceAppState ..> FinanceRepository : uses
FinanceRepository --> TransactionItem : hydrates
FinanceRepository --> BudgetCategory : hydrates
FinanceRepository --> SavingsGoal : hydrates
FinanceRepository --> DebtItem : hydrates
FinanceRepository --> PlannedPayment : hydrates
TransactionItem "*" --> "0..1" ExpenseCategory : categorized by
PlannedPayment ..> PaymentReminderService : triggers
@enduml
```
</details>

---

### 5.4 Sequence Diagram

The sequence diagram illustrates the **authentication and data loading flow** when a user opens the application.

<p align="center">
  <img src="https://www.plantuml.com/plantuml/svg/jLHDRzim3BtxLn2zD3bqknT5q3PDkW1TbzKhUbPirXOcIvuaD_1-_KWfjfL-3Bli4CGadnxVeobVEY-ixngLYS8R2uyERTPIIXQo5Th3oLNRtfdYvwtmU0B20GUl49slnp87n-MrjBWJ3haI8EltC5he0gbNxWUcyFGkx05RuoJ9xGEGmsFSKfckvBwEG95jZ8wHDyBLEoDikHLL18wPBEDXmDaYM8Pp-DQY1fB8ev8l92xE8Wlb2RQiaVxbCuYs1SKvr6AdiCo4ydm-0bU79C1mFhGx9pk_Ef8Arz8qwAqiu3DiD_S4Z7gcJZn7r6I61mKGwAUKD1hMGiOUGvUfJLwRFQoiDJQKIpnsnJcBlhEQ7b6N6Vz6gzo6EBRM58WbU1Cpl0NPQwOn2gyz2q2YM1yuuhW41owyyLWucxfmBIp3iXQwGaSuYwB9mZplZOTSLffKR5ZgG9-wl3ELr3J51woayvJdbvtEyz1efRbOM2nvX4AvX6-GwwZNHZz9NwyQ6kwLfirnRcziEPiJ_8ruxh4S6UCK1yvWYZ0RBRaeVoFCuY2wea3dvkaim_J6A5wEB38G5Ty1OjeBNzG_hD2EaKOx4XLAx62u0OGhZ58O4BDJdy1Fvv-S5gshZUUZqv6pgKSUfd_nlKFRvmVmuj0bCNM0tT74Bn956u_DOl61ykkkhD3_Y-XTHFudlL77aWeLVMG-b9kB5wahTsjeLMPpMh2GlS6TJyAj4fgsSolwXdRW8szVE-Lbgp0n2QEpl_boRvrywKjBJoKqfaG5YXovnC7uWIEeDbu-z-mPDLeMbsnStB4nJ3wC4yKhlkjEgX8UDx2d2qATNn1AuKLwOBgRDzArIlG9GJWLF_9q7o3lcaROFaj5JIekwIvrZVe3" alt="Sequence Diagram" />
</p>

<details>
<summary><b>📋 PlantUML Code: Sequence Diagram — App Startup & Auth Flow</b></summary>

```plantuml
@startuml
actor User
participant "AppLockGate" as Lock
participant "AuthGate" as Auth
participant "FirebaseAuth" as FAuth
participant "FinanceAppState" as State
participant "FinanceRepository" as Repo
participant "CloudFirestore" as Firestore
participant "DashboardPage" as Dashboard

User -> Lock : Open App
activate Lock

Lock -> Lock : Check if app lock enabled
alt App Lock Enabled
  Lock -> User : Request Biometric / PIN
  User --> Lock : Authenticate
  alt Authentication Failed
    Lock --> User : Show Error
    deactivate Lock
    return
  end
end

Lock -> Auth : Proceed to Auth Gate
deactivate Lock
activate Auth

Auth -> FAuth : Check auth state
FAuth --> Auth : authStateChanges stream

alt Not Signed In
  Auth -> User : Show Login / Register Page
  User --> Auth : Enter credentials
  Auth -> FAuth : signInWithEmailAndPassword()
  FAuth --> Auth : UserCredential
end

Auth -> State : Initialize (auth success)
deactivate Auth
activate State

State -> Repo : watchTransactions()
Repo -> Firestore : collection('transactions').snapshots()
Firestore --> Repo : Stream<QuerySnapshot>
Repo --> State : Stream<List<TransactionItem>>

State -> Repo : watchBudgets()
Repo -> Firestore : collection('budgets').snapshots()
Firestore --> Repo : Stream<QuerySnapshot>
Repo --> State : Stream<List<BudgetCategory>>

State -> Repo : watchSavingsGoals() / watchDebts() / watchPlannedPayments()
Repo -> Firestore : Multiple collection snapshots
Firestore --> Repo : Streams
Repo --> State : Hydrated model lists

State -> Dashboard : notifyListeners()
deactivate State
activate Dashboard

Dashboard -> Dashboard : Build UI with live data
Dashboard --> User : Display Dashboard with Financial Summary

deactivate Dashboard
@enduml
```
</details>

---

### 5.5 Entity-Relationship Diagram (ERD)

The ER Diagram models the Firestore document collections and their logical relationships.

<p align="center">
  <img src="https://www.plantuml.com/plantuml/svg/fPNRJkCm48RlynJUtYn8Mt6FgehJiaABK0Ji0pZnq5hr8R8TQ9RoxZkkws8dhUZ2JHJ_Ct7ccncFpwoZnhLI5DyOF745nD5AmD7oc81ot7LaIIOJSlJuWxpCkODZCfrkNSlVtczIJIVjT3avQQUJa-hTUXsit9luj2Ws-ut-M31sHAWbhNyZhmNnE_d53JicfyGwmzKCrV4O7o0f5wdAk6q4xUweX5Ik3L07xDoXwBW419EDrrjZGDLTQU09_5ls5MsQMrqlVYfFpT1IQIsAj_Te7mrLbjQEQnM2TeaGOq-qNGZNE-bmVv75Ojjge56fM-MHc6unGi-3b3Dj1loyrgg_ljH2crHKscKVAPXHnvyXWkzBOvAGo_1_3Y4TzNOPan43F3mJwWEKke_XkkRz0-nFhcgDMwm8B1jG5h172P5QkRdeBbesWoI32Kem1Ougl4U8iFmyWk2IPsMp65WcD62uPYd59c34U05Oh5ywe4PqQvnzTV-mO0_q6JtjBqr5GBL1YAWpD7mU5CS79kfysARhOxV3m80ouUT3Vam7DVy8wmggJUcOVuiqVd4u3HR1QjLFATqHjAqDR_m1pqPH2rVK3L3i0pYNZ1CltORo7thAIa6L0bRIJg8KE9kWHT8csBumS0uVBlj0xy7NsRVl5it0Pk92IPq3amybMrAUv0Nd4N_Y-DVrv4ITAvVrxbmt3Nvwuq1kcdUZn2pWdIG_txs8mgMlH6du-cBOPW8ZRKqzfpOjOqpFVpNgNS8O65BgRUEknIyKizAispiZDyMYx80M_4xkGOJOvhonHRYbLwlnMB_cjzyf6M62Hhb7SY6WFVobxnE7BJfOFu1pQvnFQCNVrOk-FPntj4ggw6omUJmcVlDw3gmL0vTj4w6FVb5zSruVzC6U1hmbqQ_84l2cn-FLgeTSWT0-VAT7HGJTwOXJS85nUhyOyqw_kFgB3boDYZDGh9NY7m" alt="ER Diagram" />
</p>

<details>
<summary><b>📋 PlantUML Code: Entity-Relationship Diagram</b></summary>

```plantuml
@startuml
!define table(x) entity x << (T, white) >>
!define PK(x) <b><u>x</u></b>
!define FK(x) <i>x</i>

entity "Users" as users {
  PK(userId) : string
  --
  email : string
  displayName : string
  createdAt : timestamp
  currencyPreference : string
  appLockEnabled : bool
}

entity "Transactions" as transactions {
  PK(transactionId) : string
  --
  FK(userId) : string
  title : string
  subtitle : string
  amount : double
  categoryName : string
  icon : string
  iconColor : string
  note : string
  negative : bool
  createdAt : timestamp
}

entity "Categories" as categories {
  PK(categoryId) : string
  --
  FK(userId) : string
  name : string
  icon : string
  color : string
  type : string (income / expense)
  monthlyBudget : double
}

entity "Budgets" as budgets {
  PK(budgetId) : string
  --
  FK(userId) : string
  name : string
  limit : double
  spent : double
  period : string (monthly / weekly / yearly)
  categoryName : string
  createdAt : timestamp
}

entity "SavingsGoals" as savings {
  PK(goalId) : string
  --
  FK(userId) : string
  name : string
  targetAmount : double
  currentAmount : double
  deadline : timestamp
  icon : string
  createdAt : timestamp
}

entity "Debts" as debts {
  PK(debtId) : string
  --
  FK(userId) : string
  personName : string
  amount : double
  description : string
  dueDate : timestamp
  isSettled : bool
  isLent : bool
  createdAt : timestamp
}

entity "PlannedPayments" as planned {
  PK(paymentId) : string
  --
  FK(userId) : string
  title : string
  amount : double
  categoryName : string
  dueDate : timestamp
  isRecurring : bool
  recurrencePattern : string
  isPaid : bool
  notificationId : int
}

entity "ShoppingItems" as shopping {
  PK(itemId) : string
  --
  FK(userId) : string
  name : string
  estimatedPrice : double
  isPurchased : bool
  category : string
  createdAt : timestamp
}

entity "Notifications" as notifications {
  PK(notifId) : string
  --
  FK(userId) : string
  title : string
  body : string
  type : string
  isRead : bool
  createdAt : timestamp
}

' Relationships
users ||--o{ transactions : "has"
users ||--o{ categories : "creates"
users ||--o{ budgets : "sets"
users ||--o{ savings : "tracks"
users ||--o{ debts : "manages"
users ||--o{ planned : "schedules"
users ||--o{ shopping : "owns"
users ||--o{ notifications : "receives"

transactions }o--|| categories : "belongs to"
budgets }o--|| categories : "linked to"
planned }o--|| categories : "categorized in"
@enduml
```
</details>

---

### 5.6 Data Flow Diagram (DFD)

#### 5.6.1 Context Diagram (Level 0)

The context diagram shows the system as a single process interacting with external entities.

<p align="center">
  <img src="https://www.plantuml.com/plantuml/svg/RL9BZzCm4BxxLupA1IGg5LRBeGUqIzgWbLPijMNXGFOmTIQ9jSuuiXsWGlpt7RiFMk0KZpFVOxxnLOZeuzXR5PuC3-Yn1qyw8hUMFg1-QhqRkIwSTHvUB2_Aj-NYlwtEr-JtRMyktrqMivEsGOYm_PUlBCkBvKof8mrCbZy7ua3msKip-OhNsn2fdm062Fa8lnJ0ovLtcaA0sRpYlp2lr6-bK4THU0Za4tAKhzBMZJLCIkDfWu4gJdw8wypTx6_tmCad5qrZD4RZ-Cm4fnzA9KQOJjyVJCsJEWT12m0M6F6r28nrIn5kk75I5HYfTTvGa6ADtmst0JuwjAbUq2R2WYAQNAuiCbCDAzpsn34ZEZSCWe4RqKiNnUWziTx2obD3wKXAxUqaPzdYNBo4RkFGr_35q8y_hguj-KnS6aRM1YrSCzfjD3exs2d3FVM6PRUdfYNyralwPtA714LolMLzcaV6fhkTzB4y39-BbC2nECnTyRUqho0x8VZgJIIu6yZdjOH7fOwYPwku9xJJQ7g2Xw6Mr1FjNTDOmmG5wewompFkDUCGEXVXrWW9oxoFPzFbjQVH15sFybBt3Yi-1gJKhkaa-rkd9TRL6BgAJrzKK5VoyCRUFWC" alt="DFD Level 0" />
</p>

<details>
<summary><b>📋 PlantUML Code: DFD Context Diagram (Level 0)</b></summary>

```plantuml
@startuml
skinparam rectangleBackgroundColor #E3F2FD
skinparam rectangleBorderColor #1565C0
skinparam packageBackgroundColor #FFF3E0

rectangle "Expense Tracker\nSystem" as system

actor User as user
cloud "Firebase\nBackend" as firebase
actor "Notification\nSystem" as notif

user --> system : Transaction Data,\nBudget Info,\nCategories,\nSavings Goals,\nDebt Details,\nPlanned Payments,\nShopping Items,\nCurrency Preference

system --> user : Dashboard View,\nBudget Alerts,\nFinancial Analytics,\nPayment Reminders,\nSavings Progress

system --> firebase : Sync Transactions,\nSync Budgets,\nSync Goals,\nSync Debts,\nSync Payments\n[Firestore Write Operations]

firebase --> system : Real-time Updates,\nOffline Cache Sync\n[Firestore Snapshot Listeners]

system --> notif : Schedule Payment\nReminders

notif --> user : Local Push\nNotifications
@enduml
```
</details>

#### 5.6.2 Level 1 DFD

<details>
<summary><b>📋 PlantUML Code: DFD Level 1</b></summary>

```plantuml
@startuml
skinparam rectangleBackgroundColor #E8F5E9
skinparam rectangleBorderColor #2E7D32

actor User as user

rectangle "1.0\nAuthentication\nModule" as auth
rectangle "2.0\nTransaction\nManagement" as txn
rectangle "3.0\nBudget\nManagement" as budget
rectangle "4.0\nSavings\nTracker" as savings
rectangle "5.0\nDebt\nManager" as debt
rectangle "6.0\nPlanned Payment\nScheduler" as planned
rectangle "7.0\nShopping List\nManager" as shop
rectangle "8.0\nDashboard &\nAnalytics" as dash
rectangle "9.0\nApp Lock &\nSecurity" as lock

database "Firestore\nDatabase" as db
cloud "Notification\nService" as notif

user --> auth : Login/Register
user --> txn : CRUD Transactions
user --> budget : Set/Edit Budgets
user --> savings : Track Goals
user --> debt : Manage Debts
user --> planned : Schedule Payments
user --> shop : Manage Lists
user --> dash : View Analytics
user --> lock : Set App Lock

auth --> db : Read/Write User Profile
txn --> db : Read/Write Transactions
budget --> db : Read/Write Budgets
savings --> db : Read/Write Goals
debt --> db : Read/Write Debts
planned --> db : Read/Write Payments
shop --> db : Read/Write Items
dash --> db : Aggregate Queries

planned --> notif : Schedule Notifications
lock --> user : Biometric/PIN Challenge
@enduml
```
</details>

---

### 5.7 Component Diagram

The component diagram depicts the high-level software architecture of the Flutter application.

<details>
<summary><b>📋 PlantUML Code: Component Diagram</b></summary>

```plantuml
@startuml
skinparam componentBackgroundColor #E3F2FD
skinparam componentBorderColor #1565C0
skinparam packageBackgroundColor #F5F5F5

package "UI Layer (lib/pages/)" {
  [AuthPage] as authPage
  [DashboardPage] as dashPage
  [TransactionsPage] as txnPage
  [BudgetPage] as budgetPage
  [SavingsPage] as savingsPage
  [DebtsPage] as debtsPage
  [PlannedPaymentsPage] as plannedPage
  [ShoppingListPage] as shopPage
  [SettingsPage] as settingsPage
  [ProfilePage] as profilePage
  [CategoriesPage] as catPage
}

package "Widgets Layer (lib/widgets/)" {
  [AppLockGate] as lockGate
  [TransactionTile] as txnTile
  [PlannedPaymentCard] as ppCard
  [MorphingFAB] as fab
  [CategoryLogo] as catLogo
  [EmptyStateCard] as emptyCard
  [DataLoadingView] as loadingView
  [PINEntrySheet] as pinSheet
}

package "State Management (lib/state/)" {
  [FinanceAppState] as appState
  [FinanceAppScope] as appScope
}

package "Services Layer (lib/services/)" {
  [FinanceRepository] as repo
  [CategoryRepository] as catRepo
  [CurrencyPreferences] as currencyPref
  [ExchangeRateService] as exchangeSvc
  [AppLockService] as lockSvc
  [PaymentReminderService] as reminderSvc
}

package "Models Layer (lib/models/)" {
  [TransactionItem] as txnModel
  [ExpenseCategory] as catModel
  [BudgetCategory] as budgetModel
  [SavingsGoal] as savingsModel
  [DebtItem] as debtModel
  [PlannedPayment] as ppModel
  [ShoppingItem] as shopModel
}

package "External Services" <<Cloud>> {
  [Firebase Auth] as fbAuth
  [Cloud Firestore] as fbFirestore
  [Firebase Core] as fbCore
  database "SharedPreferences" as prefs
  [Local Auth\n(Biometrics)] as localAuth
  [Flutter Local\nNotifications] as localNotif
  [HTTP Client\n(exchange rates)] as httpClient
}

' UI -> State
authPage --> appScope
dashPage --> appScope
txnPage --> appScope
budgetPage --> appScope
savingsPage --> appScope
debtsPage --> appScope
plannedPage --> appScope
shopPage --> appScope
catPage --> appScope

' State -> Services
appScope --> appState
appState --> repo
appState --> catRepo
appState --> currencyPref

' Services -> External
repo --> fbFirestore
catRepo --> fbFirestore
currencyPref --> prefs
currencyPref --> exchangeSvc
exchangeSvc --> httpClient
lockSvc --> localAuth
reminderSvc --> localNotif
lockGate --> lockSvc
appState --> fbAuth

' Models
repo ..> txnModel
repo ..> budgetModel
repo ..> savingsModel
repo ..> debtModel
repo ..> ppModel
repo ..> shopModel
catRepo ..> catModel

' Widgets usage
txnPage --> txnTile
plannedPage --> ppCard
dashPage --> fab
dashPage --> catLogo
dashPage --> emptyCard
dashPage --> loadingView
lockGate --> pinSheet
@enduml
```
</details>

---

### 5.8 Deployment Diagram

The deployment diagram shows the physical deployment architecture of the system.

<details>
<summary><b>📋 PlantUML Code: Deployment Diagram</b></summary>

```plantuml
@startuml
skinparam nodeBackgroundColor #E8EAF6
skinparam nodeBorderColor #3949AB
skinparam componentBackgroundColor #C5CAE9

node "User Device (Android/iOS/Desktop)" {
  node "Flutter Application" {
    component "UI Layer\n(Dart/Widgets)" as ui
    component "State Management\n(ChangeNotifier)" as state
    component "Services Layer\n(Repository + Logic)" as svc
    component "Local Storage\n(SharedPreferences)" as local
    component "Biometric Module\n(local_auth)" as bio
    component "Notification Handler\n(flutter_local_notifications)" as notifHandler
  }
  
  database "Firestore\nOffline Cache" as offlineCache {
    component "Local\nPersistence Layer" as localDb
  }
}

cloud "Google Cloud Platform" {
  node "Firebase Services" {
    component "Firebase Auth\n(Authentication)" as fbAuth
    database "Cloud Firestore\n(NoSQL Database)" as firestore
    component "Firebase Storage\n(File Storage)" as fbStorage
  }
  
  node "External API" {
    component "Exchange Rate API\n( exchangerate-api.com )" as exchangeAPI
  }
}

node "Google Play Store /\nApple App Store" {
  component "App Distribution" as appStore
}

node "Development Environment" {
  component "Flutter SDK" as flutterSDK
  component "Android Studio / VS Code" as ide
  component "GitHub\n(Version Control)" as github
  component "Firebase CLI\n& Emulators" as firebaseCLI
}

' Connections
ui --> state : "Observer Pattern"
state --> svc : "Method Calls"
svc --> offlineCache : "Read/Write"
offlineCache --> localDb : "SQLite/Persistence"

svc --> fbAuth : "REST / gRPC\nHTTPS"
svc --> firestore : "WebSocket\nReal-time Sync"
svc --> fbStorage : "HTTPS\nFile Upload"
svc --> exchangeAPI : "HTTPS\nJSON"

bio --> ui : "Authentication\nResult"
notifHandler --> ui : "Notification\nTap Event"

flutterSDK --> appStore : "Build & Deploy"
ide --> github : "Git Push/Pull"
firebaseCLI --> fbAuth : "Deploy Rules"
firebaseCLI --> firestore : "Deploy Indexes"

@enduml
```
</details>

---

## 6. Methodology

### 6.1 Development Model

**Agile (Scrum)** — Selected for its iterative approach, allowing rapid prototyping, continuous feedback integration, and flexible adaptation to changing requirements.

- **Sprint Duration:** 2 weeks
- **Sprint Ceremonies:** Daily stand-ups, Sprint Planning, Sprint Review, Sprint Retrospective

### 6.2 Development Tools

| Category | Tool | Purpose |
|---|---|---|
| **IDE** | Android Studio / VS Code | Code development and debugging |
| **Version Control** | Git + GitHub | Source code management and collaboration |
| **Backend** | Firebase (Auth, Firestore, Storage) | Cloud infrastructure |
| **UI/UX Design** | Material Design 3 (built-in Flutter) | Design system and components |
| **Project Management** | GitHub Projects / Issues | Task tracking and sprint management |
| **Testing** | Flutter Test Framework | Unit, widget, and integration testing |
| **CI/CD** | GitHub Actions / Firebase App Distribution | Automated builds and distribution |

### 6.3 Development Phases

| Phase | Duration | Activities |
|---|---|---|
| **Phase 1:** Requirement Analysis | Week 1-2 | Gather requirements, define scope, create SRS document |
| **Phase 2:** System Design | Week 3-4 | Architecture design, database schema, UI wireframes, UML modeling |
| **Phase 3:** Core Development — Auth & Setup | Week 5-6 | Firebase integration, authentication, app lock, navigation shell |
| **Phase 4:** Core Development — Transactions | Week 7-8 | CRUD transactions, categories, dashboard summary |
| **Phase 5:** Core Development — Financial Tools | Week 9-10 | Budgets, savings goals, debts, planned payments, shopping lists |
| **Phase 6:** Advanced Features | Week 11-12 | Multi-currency, exchange rates, notification system, analytics |
| **Phase 7:** Testing & Optimization | Week 13-14 | Unit tests, widget tests, integration tests, performance optimization |
| **Phase 8:** Documentation & Deployment | Week 15-16 | Final report, user manual, app store deployment |

---

## 7. Technology Stack

| Layer | Technology | Version | Justification |
|---|---|---|---|
| **Framework** | Flutter | 3.x (stable) | Cross-platform from single codebase; rich widget ecosystem; hot reload |
| **Language** | Dart | ^3.11.3 | Strongly typed, null-safe, optimized for UI development |
| **Authentication** | Firebase Auth | ^6.5.6 | Secure email/password auth; supports OAuth providers; free tier |
| **Database** | Cloud Firestore | ^6.7.1 | NoSQL, real-time sync, offline persistence, serverless scaling |
| **Core** | Firebase Core | ^4.12.1 | Firebase initialization and configuration |
| **Local Notifications** | flutter_local_notifications | ^22.2.0 | Cross-platform scheduled local notifications |
| **Time Zone** | flutter_timezone + timezone | ^5.1.0, ^0.11.1 | Accurate timezone-aware scheduling |
| **Local Storage** | shared_preferences | ^2.5.4 | Key-value storage for user preferences and settings |
| **Biometrics** | local_auth | ^2.3.0 | Fingerprint and face authentication for app lock |
| **Encryption** | crypto | ^3.0.3 | SHA-256 hashing for PIN storage and data integrity |
| **HTTP Client** | http | ^1.6.0 | REST API calls for exchange rate fetching |
| **State Management** | ChangeNotifier (built-in) | — | Lightweight, no external dependency, sufficient for app scope |
| **Version Control** | Git + GitHub | — | Industry standard for source code management |

---

## 8. Project Timeline

### 8.1 Gantt Chart / Development Schedule

| Task | W1-2 | W3-4 | W5-6 | W7-8 | W9-10 | W11-12 | W13-14 | W15-16 |
|---|---|---|---|---|---|---|---|---|
| **Requirements Analysis** | ████████ | | | | | | | |
| **System Design & UML** | | ████████ | | | | | | |
| **Auth & App Setup** | | | ████████ | | | | | |
| **Transactions & Categories** | | | | ████████ | | | | |
| **Financial Tools** | | | | | ████████ | | | |
| **Advanced Features** | | | | | | ████████ | | |
| **Testing & Optimization** | | | | | | | ████████ | |
| **Documentation & Deploy** | | | | | | | | ████████ |

### 8.2 Milestones

| Milestone | Target Week | Deliverable |
|---|---|---|
| **M1:** Requirements Sign-off | Week 2 | Approved SRS document |
| **M2:** Design Approval | Week 4 | UML diagrams, wireframes, architecture doc |
| **M3:** Alpha Release | Week 8 | Working app with auth + transactions |
| **M4:** Beta Release | Week 12 | All features implemented |
| **M5:** Production Release | Week 16 | Tested, documented, deployed to app store |

---

## 9. Risk Analysis

| # | Risk | Probability | Impact | Risk Level | Mitigation Strategy |
|---|---|---|---|---|---|
| R1 | Time constraints due to project scope | High | High | **Critical** | Prioritize MVP features; use Agile sprints; defer non-essential features to v2 |
| R2 | Firebase cost scaling with increased usage | Medium | Medium | **Moderate** | Implement efficient Firestore queries; use offline persistence; monitor usage quotas |
| R3 | Offline sync conflicts | Medium | Medium | **Moderate** | Rely on Firestore built-in conflict resolution; last-write-wins strategy |
| R4 | Cross-platform UI inconsistencies | Medium | Low | **Low** | Use Flutter's platform-adaptive widgets; test on all target platforms |
| R5 | API rate limiting (exchange rates) | Low | Low | **Low** | Cache exchange rates locally; update daily instead of per-request |
| R6 | Security vulnerabilities in authentication | Low | High | **Moderate** | Use Firebase Auth best practices; implement app-level biometric lock; encrypt sensitive local data |
| R7 | Dependency version conflicts | Medium | Low | **Low** | Lock dependency versions in pubspec.yaml; test upgrades in isolation |

### Risk Matrix

| | Low Impact | Medium Impact | High Impact |
|---|---|---|---|
| **High Probability** | — | — | R1 (Critical) |
| **Medium Probability** | — | R2, R3 (Moderate) | — |
| **Low Probability** | R5 (Low) | R7 (Low) | R6 (Moderate) |

---

## 10. Conclusion

The **Expense Tracker & Personal Finance Manager** successfully delivers a comprehensive, secure, and user-friendly mobile application for personal financial management. Built with Flutter and Firebase, the application provides:

- ✅ **Complete transaction management** with customizable categories
- ✅ **Budget tracking** with real-time progress monitoring
- ✅ **Savings goal management** with deadline tracking
- ✅ **Debt and loan tracking** with due date alerts
- ✅ **Planned payment scheduling** with local notification reminders
- ✅ **Shopping list management** for organized purchasing
- ✅ **Multi-currency support** with live exchange rates
- ✅ **Biometric app-lock** for enhanced security
- ✅ **Offline-first architecture** ensuring functionality without internet
- ✅ **Cross-platform deployment** across 6 platforms from a single codebase

The application adheres to modern software engineering practices including Agile methodology, clean architecture principles, and comprehensive testing strategies. With its intuitive Material Design 3 interface and robust Firebase backend, the Expense Tracker provides a reliable and scalable solution for personal finance management.

Future enhancements planned for version 2.0 include:
- Bank account integration via Open Banking APIs
- Advanced financial analytics with AI-powered insights
- Family/group budget sharing
- Investment portfolio tracking
- Export reports to PDF/CSV
- Dark mode support

---

<div align="center">

---

*Submitted in partial fulfillment of the requirements for*  
**Course Code: CCE-310 — Software Development Project**  
*Department of Computer and Communication Engineering*  
**Patuakhali Science and Technology University**

</div>