# Borrowly — Workflow Guidelines & Story-Driven Development

## Table of Contents

1. [Overview & Core Principles](#overview--core-principles)
2. [Story-Driven Development Process](#story-driven-development-process)
3. [Story Structure (BMAD Format for Flutter)](#story-structure-bmad-format-for-flutter)
4. [Feature Development & Flutter Implementation Workflow](#feature-development--flutter-implementation-workflow)
5. [Core Business Domain Workflows](#core-business-domain-workflows)
   - [Workflow 1: Google Sign-In Authentication & Session Initialization](#workflow-1-google-sign-in-authentication--session-initialization)
   - [Workflow 2: Hyper-Local Radius Search & PostGIS Spatial Filtering](#workflow-2-hyper-local-radius-search--postgis-spatial-filtering)
   - [Workflow 3: Peer-to-Peer Borrow Request & Physical Cash Handover](#workflow-3-peer-to-peer-borrow-request--physical-cash-handover)
   - [Workflow 4: Real-Time Neighbor Messaging & Pickup Coordination](#workflow-4-real-time-neighbor-messaging--pickup-coordination)
   - [Workflow 5: Stateful Shell Branch Navigation & Back Dispatcher](#workflow-5-stateful-shell-branch-navigation--back-dispatcher)
6. [Story ID Conventions & Folder Structure](#story-id-conventions--folder-structure)
7. [Best Practices for Flutter, Riverpod & Supabase](#best-practices-for-flutter-riverpod--supabase)

---

## Overview & Core Principles

Every feature in **Borrowly** follows a **story-driven development process** to ensure zero-lag rendering, stateful shell navigation predictability, and glassmorphic aesthetic consistency across all screens.

### Core Principles

- **Google Sign-In Authentication** — One-tap Google authentication integrated directly with Supabase Auth.
- **Physical In-Person Cash Handovers** — Zero in-app gateway complexity; daily price and deposit figures are tracked in-app, with payments settled physically during pickup/return.
- **Supabase PostGIS Spatial Queries** — Hyper-local distance calculation (< 5ms response) powered by PostgreSQL spatial indexes.
- **Story-First Development** — Complex features must define BMAD stories and user flows before writing code.
- **Riverpod UI State Completeness** — Every screen must support four distinct async state states: `data` (Content), `loading` (Skeleton Shimmer), `error` (Empty/Error State), and `refreshing`.
- **Glassmorphic Design System** — Warm background tint (`#FDFBF7`), Outfit typography, teal primary (`#0D9488`), amber accent (`#F59E0B`), floating glass navigation bar, and top pill toasts.

---

## Story-Driven Development Process

### Phase 1: Planning & Flow Mapping

1. **Feature Scope & Domain Tagging**:
   - Classify the feature into a domain: `auth`, `item`, `borrow`, `chat`, `navigation`.
2. **User Flow Mapping**:
   - Map user entry, Google Sign-In authentication, UI state shifts, Riverpod `AsyncValue` updates, repository calls, and exit paths.
3. **Atomic Story Breakdown**:
   - Break down capabilities into atomic stories using `<DOMAIN>-<NUMBER>` (e.g., `ATH-0001`, `ITM-0001`, `BRW-0002`).

### Phase 2: BMAD Documentation

1. Create a story document under `docs/stories/<domain>/story-<ID>-<title-slug>.md`.
2. Structure the story using the **BMAD Format**:
   - **B**usiness Context (User requirement & community outcome)
   - **M**ockup / Visual Reference (Layout, glassmorphism, responsive grid specs)
   - **A**cceptance Criteria (Riverpod state behavior, Supabase query expectations, back navigation)
   - **D**efinition of Done (Testing with `flutter analyze`, manual verification, documentation update)

---

## Core Business Domain Workflows

### Workflow 1: Google Sign-In Authentication & Session Initialization

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as LoginScreen
    participant Notifier as AuthNotifier
    participant Google as GoogleSignIn SDK
    participant Supabase as Supabase Auth

    User->>UI: Tap 'Continue with Google'
    UI->>Notifier: signInWithGoogle()
    Notifier->>Google: googleSignIn.signIn()
    Google-->>Notifier: GoogleSignInAccount (ID Token & Access Token)
    Notifier->>Supabase: supabase.auth.signInWithIdToken(idToken, accessToken)
    Supabase-->>Notifier: UserSession & AuthResponse
    Notifier-->>UI: State updated -> Redirect to HomeScreen
```

---

### Workflow 2: Hyper-Local Radius Search & PostGIS Spatial Filtering

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as SearchScreen
    participant Notifier as SearchItemsNotifier
    participant Repo as ItemRepository
    participant DB as Supabase PostGIS (get_nearby_items)

    User->>UI: Adjust Radius Slider (e.g. 5.0 km) & Search Query
    UI->>Notifier: search(query, radius, category, pricing, sortBy)
    Notifier->>Repo: searchItems(...)
    Repo->>DB: RPC 'get_nearby_items'(lat, lng, radius_km)
    DB-->>Repo: Filtered List<ItemEntity>
    Repo-->>Notifier: List<ItemEntity>
    Notifier-->>UI: AsyncValue.data(items)
    UI-->>User: Render 0.72 Aspect Ratio Grid with 60/120 FPS smoothness
```

---

### Workflow 3: Peer-to-Peer Borrow Request & Physical Cash Handover

```mermaid
flowchart TD
    A[View Item Details] --> B{User Logged In?}
    B -->|No| C[Prompt Google Sign-In]
    B -->|Yes| D[Select Borrow Start & End Dates]
    D --> E[Calculate Total Price + Deposit Amount]
    E --> F[Tap 'Request to Borrow (In-Person Cash Settlement)']
    F --> G[Log BorrowRequestEntity to Supabase DB]
    G --> H[Spawn Real-Time Chat Thread]
    H --> I[Render Timeline in ActivityScreen]
    I --> J{Owner Action}
    J -->|Accept| K[Status: 🟢 Accepted / Pending Physical Pickup]
    K --> L[Neighbors Meet & Settle Cash Physically]
    L --> M[Status: 🟢 Active / Item Picked Up]
    M --> N[Return Item & Hand Back Refundable Deposit]
    N --> O[Status: 🟢 Completed]
```

---

### Workflow 4: Real-Time Neighbor Messaging & Pickup Coordination

- **Chat Thread Initiation**:
  - Automatically triggered upon creating a borrow request.
- **Real-Time Supabase WebSockets**:
  - Messages stream instantly via Supabase WebSocket channels.
- **Physical Pickup Coordination**:
  - Chat banner displays shared handover location (e.g. *"Oakwood Drive (0.8 km)"*).

---

### Workflow 5: Stateful Shell Branch Navigation & Back Dispatcher

```mermaid
flowchart LR
    A[User Presses System Back Button] --> B{Can Top Route Pop?}
    B -->|Yes| C[context.pop()]
    B -->|No| D{Active Tab == Home?}
    D -->|No (Activity / Messages / Profile)| E[goBranch(0) -> Return to Home]
    D -->|Yes (Home Tab)| F{Pressed within 2 seconds?}
    F -->|No| G[Show Top Pill Toast: 'Press back again to exit']
    F -->|Yes| H[Exit Application SystemNavigator.pop()]
```

---

## Story ID Conventions & Folder Structure

```
docs/stories/
├── auth/
│   ├── README.md
│   └── story-ATH-0001-google-sign-in.md
├── item/
│   ├── README.md
│   └── story-ITM-0001-radius-search-postgis.md
├── borrow/
│   ├── README.md
│   └── story-BRW-0001-physical-cash-handover-timeline.md
├── chat/
│   ├── README.md
│   └── story-MSG-0001-neighbor-handover-chat.md
└── navigation/
    ├── README.md
    └── story-NAV-0001-stateful-shell-back-dispatcher.md
```

---

## Best Practices for Flutter, Riverpod & Supabase

1. **Google Auth Handling**: Always obtain both `idToken` and `accessToken` from `GoogleSignInAccount` before invoking `supabase.auth.signInWithIdToken()`.
2. **Physical Payment State Discipline**: State transitions must proceed strictly from `pending` $\rightarrow$ `accepted` $\rightarrow$ `active` (item handed over) $\rightarrow$ `completed` (item returned & deposit handed back).
3. **State Hoisting**: Keep presentational widgets stateless; pass data and callbacks down from parent `ConsumerWidget`.
4. **Background Isolate Offloading**: Use `compute()` for client-side search indexing or heavy parsing when offline.
