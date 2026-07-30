# Project Guidelines & Rules: Borrowly

## 1. Project Philosophy & Design System

- **Supabase Backend & Local Caching**: Supabase provides PostgreSQL/PostGIS geospatial queries, Google Authentication, and Real-Time WebSockets. Local state with Hive and mock data fallbacks ensure instant response times (<5ms startup).
- **Modern Hyper-Local Glassmorphism Aesthetics**:
  - Theme: Locked Light Mode (`ThemeMode.light`), warm soft background (`#FDFBF7`), dark background (`#0E1726`), primary teal (`#0D9488`), and accent amber (`#F59E0B`).
  - Typography: Google Fonts **Outfit** for clean modern headings and body text.
  - UI Components: Floating glass navigation bar (`FloatingNavigationBar`), top pill toasts (`BorrowlyToast`), status timeline pills, and 0.72 item card aspect ratios.
  - Dimmed Status Bar: Scrolled top status bar overlay container uses translucent dark dimming (`Colors.black.withValues(alpha: 0.30)` in light mode, `0.65` in dark mode).

---

## 2. Technical Stack & Architectural Principles

- **Architecture**: Strictly adhere to **MVVM (Model-View-ViewModel)** with Unidirectional Data Flow (UDF) powered by Riverpod.
- **UI Framework**: 100% **Flutter 3.x**. Prefer Stateless `ConsumerWidget` with state hoisting.
- **State Management & DI**: Use **Flutter Riverpod** (`Provider`, `StateProvider`, `AsyncNotifierProvider`).
- **Backend & Auth**: **Supabase** backend with **Google Sign-In ONLY** (`google_sign_in` package + `supabase.auth.signInWithIdToken()`).
- **Payment Model**: **Physical In-Person Cash Settlement**. Zero in-app digital payment gateways; fees and deposits are settled physically during item handover/return.
- **Navigation**: `GoRouter` with `StatefulShellRoute.indexedStack` (`app_router.dart`).
- **Centralized Back Dispatcher**:
  - Top routes pop via `canPop()`.
  - Non-Home tabs (**Activity**, **Messages**, **Profile**) return to **Home** tab via `navigationShell.goBranch(0)`.
  - Home tab double-tap within 2 seconds exits the app (`SystemNavigator.pop()`).
- **Background Performance**: Offload list sorting, string searching, and distance filtering to background Dart Isolates using `compute()`.
- **Zero-Rebuild UI Scroll Listeners**: Use `ValueNotifier<bool>` and `ValueListenableBuilder` in `MainShellScreen` to prevent scroll notifications from rebuilding active tab sub-trees.

---

## 3. Core Business Logic & Workflow Constraints

### Hyper-Local Radius Search & PostGIS
- Users filter items by maximum distance radius (in kilometers) and item category.
- Remote searches execute via Supabase PostGIS function `get_nearby_items(lat, lng, radius_km)`. Client-side fallback searches execute inside `compute(_filterAndSortItemsIsolate)`.

### Peer-to-Peer Borrowing & Approval Timeline
- Items feature daily pricing or free loan flags (`isFree`).
- Payments and refundable security deposits are settled physically during neighbor handover.
- Request statuses follow timeline stages: **Pending**, **Accepted**, **Active** (item picked up & cash handed over), **Completed** (item returned & deposit returned), and **Cancelled**.
- Creating a borrow request automatically spawns a real-time neighbor conversation thread.

### Image Memory Optimization
- Thumbnails on item cards use `memCacheWidth: 400` and `memCacheHeight: 300`.
- User avatars use `CachedNetworkImageProvider` with max height/width bounds of 36x36.

---

## 4. Coding Standards for AI Assistants

1. **Package Organization**: Keep code organized within `lib/`:
   - `app/` (Router, Theme, App Configuration)
   - `core/` (Network, Storage, Shared Widgets)
   - `features/` (Auth, Activity, Chat, Home, Item, Main Shell, Notification, Profile, Search, Splash)
2. **Preserve Documentation**: Refer to [ARCHITECTURE.md](file:///c:/Users/muham/Vscode%20Projects/Borrowly/ARCHITECTURE.md) and [WORKFLOW_GUIDELINES.md](file:///c:/Users/muham/Vscode%20Projects/Borrowly/WORKFLOW_GUIDELINES.md) when introducing new features or refactoring.
3. **Immutability & Riverpod**: Expose immutable `AsyncValue` or read-only provider states. Never mutate state variables directly from UI widgets.
4. **Static Analysis**: Always verify code edits with `flutter analyze` to ensure 0 errors.
