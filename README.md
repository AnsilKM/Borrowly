# Borrowly — Hyper-Local Peer-to-Peer Marketplace

> A production-ready Flutter mobile application for peer-to-peer item sharing within a 1–5 km neighborhood radius. Built with Clean Architecture, Riverpod, GoRouter, Supabase, and Hive.

---

## 🌟 Key Product Features

- **Guest-First Browsing**: Explore nearby items freely without an account. Sign-in is required only when borrowing, listing items, messaging, or writing reviews.
- **Hyper-Local Radius Enforcement**: Physical handovers strictly bounded to a **1 km**, **2 km**, **3 km**, or **5 km (Max)** radius. Zero delivery or shipping fees.
- **FREE & Paid Neighborhood Shares**: Offer items for free or set daily rental rates ($/day) with optional refundable security deposits.
- **Direct Messaging & Meetups**: Coordinate physical pickup times and handover locations directly with local neighbors.
- **Community Reputation**: Verified neighbor badges, response times, and star rating feedback.
- **Design System**: Modern, minimalist Airbnb/Linear/Apple inspired UI with full Light and Dark mode support.

---

## 📐 Architecture & Tech Stack

Borrowly is built following **Clean Architecture**, **Feature-First Architecture**, **MVVM**, and the **Repository Pattern**.

```
lib/
├── app/                        # Application configuration (App, Theme, GoRouter)
├── core/                       # Core utilities, Error Failures, Result<T,F>, Design System
│   ├── errors/                 # Typed Failures (ServerFailure, AuthFailure, etc.)
│   ├── utils/                  # Result pattern & Responsive breakpoints
│   ├── storage/                # Hive LocalStorageService
│   ├── network/                # SupabaseService wrapper
│   └── widgets/                # Reusable UI (BorrowlyButton, BorrowlyCard, etc.)
└── features/                   # Clean Architecture Features
    ├── auth/                   # Authentication (Guest, Google, Apple)
    ├── item/                   # Item Feed, Search, Details, & Listing
    ├── borrow/                 # Borrow Request Lifecycle
    ├── chat/                   # Direct Messaging System
    ├── activity/               # Borrowed & Lent History Hub
    ├── profile/                # User Profile & Neighbor Reviews
    └── notification/           # Notification Center
```

### Tech Stack Summary
- **Framework**: Flutter & Dart (Latest Stable)
- **State Management & DI**: Riverpod (`hooks_riverpod`, `flutter_hooks`)
- **Navigation**: GoRouter
- **Backend & Auth**: Supabase Flutter
- **Local Storage**: Hive
- **Data Models**: Freezed, Json Serializable, Equatable
- **Image Caching**: Cached Network Image
- **Typography**: Google Fonts (Inter)

---

## 🎨 Color Palette & Typography

- **Primary Gold**: `#D4A017`
- **Primary Dark**: `#B8860B`
- **Primary Light**: `#F4D35E`
- **Background**: `#FAF8F2` (Light) / `#181818` (Dark)
- **Surface**: `#FFFFFF` (Light) / `#242424` (Dark)
- **Success**: `#2E7D32`
- **Typography**: Inter (Fallback: SF Pro Display)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.10.0`
- Dart SDK `>=3.0.0`

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/borrowly.git
   cd borrowly
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run code generators (optional if modifying data models):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---

## 🧪 Running Tests

Execute automated unit and widget test suites:
```bash
flutter test
```

---

## 📄 License
This project is licensed under the MIT License.
