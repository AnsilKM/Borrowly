# Borrowly — Hyper-Local Peer-to-Peer Borrowing Platform

> A production-ready Flutter mobile application for hyper-local peer-to-peer item sharing and borrowing within a 1–5 km neighborhood radius. Built with Clean MVVM Architecture, Riverpod, GoRouter, Supabase PostGIS, Google Sign-In, and Hive.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 🌟 Key Product Features

- 📍 **Hyper-Local Radius Search**: Query nearby items within a strict **1 km**, **2 km**, **3 km**, or **5 km** radius powered by Supabase PostGIS spatial indexes (`get_nearby_items`).
- 🔑 **Google Sign-In Authentication**: Single-click Google authentication (`google_sign_in`) integrated directly with Supabase Auth (`signInWithIdToken`).
- 🤝 **Physical Cash Handover Settlement**: Zero digital payment gateway fees. Rental rates and refundable security deposits are settled physically in cash during neighbor item pickup/return.
- 💬 **Real-Time Neighbor Messaging**: Instant WebSocket chat threads for coordinating pickup times and physical handover locations.
- ⚡ **Background Isolate Performance**: Heavy item filtering, distance calculations, and string search indexing execute off the UI thread using Dart `compute()` isolates for 60/120 FPS scrolling.
- 🎨 **Glassmorphic Design System**: Outfit typography, warm `#FDFBF7` surface canvas, floating glass navigation bar, top pill toasts, and dynamic status bar translucent dimming.

---

## 📐 Architecture & Tech Stack

Borrowly follows **Model-View-ViewModel (MVVM)**, **Feature-Sliced Architecture**, and **Unidirectional Data Flow (UDF)** powered by Flutter Riverpod.

```
lib/
├── app/                        # Application configuration (App, Theme, GoRouter, Routes)
├── core/                       # Core utilities, Hive storage, Supabase client & UI components
│   ├── network/                # SupabaseService client wrapper
│   ├── storage/                # Hive LocalStorageService
│   └── widgets/                # Reusable UI controls (BorrowlyCard, BorrowlyButton, BorrowlyToast)
└── features/                   # Feature-Sliced Domain Modules
    ├── auth/                   # Google Sign-In, Auth State Notifiers & Profile Setup
    ├── item/                   # Item Feed, Radius Filtering, Details & Add Item
    ├── borrow/                 # Borrow Request Lifecycle (Pending -> Accepted -> Active -> Completed)
    ├── chat/                   # Real-Time Neighbor WebSocket Chat
    ├── activity/               # Request History & Timeline Status Pills
    ├── profile/                # User Settings & Logout Confirmation Modal
    ├── notification/           # Notification Center & Unread Badges
    └── main_shell/             # Stateful Navigation Shell & Back Dispatcher
```

### Tech Stack Summary
- **UI Framework**: Flutter 3.x & Dart 3.x
- **State Management & DI**: Flutter Riverpod (`flutter_riverpod`)
- **Navigation & Routing**: GoRouter 13.x with `StatefulShellRoute.indexedStack`
- **Backend & Remote Sync**: Supabase Flutter (Postgres, PostGIS, Real-Time WebSockets)
- **Authentication**: Google Sign-In (`google_sign_in`)
- **Local Storage**: Hive & Hive Flutter
- **Async Execution**: Dart Background Isolates (`compute()`)
- **Image Caching**: `cached_network_image` with strict dimension limits
- **Typography**: Google Fonts (Outfit)

---

## 📚 Documentation & Architecture Guides

Detailed architectural specification and story workflow documents:
- 📖 [ARCHITECTURE.md](ARCHITECTURE.md) — System architecture, high-level MVVM/UDF diagrams, and database ER schemas.
- 📋 [WORKFLOW_GUIDELINES.md](WORKFLOW_GUIDELINES.md) — Story-driven BMAD guidelines and core business domain workflows.
- 🤖 [.agents/AGENTS.md](.agents/AGENTS.md) — Coding standards and workspace rules for AI assistants.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.10.0`
- Dart SDK `>=3.0.0`

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/AnsilKM/Borrowly.git
   cd Borrowly
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run static analysis:
   ```bash
   flutter analyze
   ```
4. Launch application:
   ```bash
   flutter run
   ```

---

## 📑 Short GitHub Description

> **Borrowly**: A hyper-local peer-to-peer neighborhood item sharing application built with Flutter, Riverpod, GoRouter, Supabase PostGIS, and Google Sign-In. Features physical cash handover settlement, real-time WebSocket chat, and background isolate performance.

---

## 📄 License
This project is licensed under the MIT License.
