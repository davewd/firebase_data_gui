# App Architecture and Design

## Overview

Firebase Data GUI is a native macOS application built with SwiftUI that provides a read-only interface for browsing Firebase Realtime Database data.

## Architecture Layers

```
┌─────────────────────────────────────────┐
│         SwiftUI Views Layer             │
│  (OnboardingView, DataBrowserView)      │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│       State Management Layer            │
│     (AppState, FirebaseManager)         │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│         Network Layer                   │
│      (URLSession, REST API)             │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│      Firebase Realtime Database         │
└─────────────────────────────────────────┘
```

## Component Breakdown

### 1. App Entry Point (`App.swift`)
```swift
FirebaseDataGUIApp (@main)
├── AppState (StateObject)
└── WindowGroup
    └── ContentView
```

**Responsibilities:**
- App lifecycle management
- Global state initialization
- Window configuration

### 2. Root View (`ContentView.swift`)
```swift
ContentView
├── if authenticated → DataBrowserView
└── else → OnboardingView
```

**Responsibilities:**
- Route between onboarding and data browser
- Observe authentication state

### 3. Onboarding View (`OnboardingView.swift`)
```
┌──────────────────────────────────────────┐
│     Firebase Data GUI                    │
│                                          │
│  Drop your Firebase service account      │
│         JSON key to begin                │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │                                    │ │
│  │         📄 ➕                      │ │
│  │                                    │ │
│  │   Drop JSON Service Key Here       │ │
│  │      or click to select            │ │
│  │                                    │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Read-only mode • 5 entries per collection │
└──────────────────────────────────────────┘
```

**Features:**
- Drag & drop zone (`.onDrop`)
- Click to browse (`NSOpenPanel`)
- Service key validation
- Error display
- Loading indicator

### 4. Data Browser View (`DataBrowserView.swift`)
```
┌─────────────────────────────────────────────────┐
│ 🔥 Firebase Data              [Exit] │
├─────────────────────────────────────────────────┤
│ Root > users > user1                            │
├─────────────────────────────────────────────────┤
│                                                 │
│  ▼ users : {5 items}                           │
│      ▶ user1 : {3 items}                       │
│      ▶ user2 : {3 items}                       │
│      ▶ user3 : {3 items}                       │
│      ▶ user4 : {3 items}                       │
│      ▶ user5 : {3 items}                       │
│      ... 45 more items                          │
│                                                 │
│  ▼ posts : {2 items}                           │
│      ▼ post1 : {3 items}                       │
│          title : "First Post"                   │
│          content : "Hello World"                │
│          author : "user1"                       │
│      ▶ post2 : {3 items}                       │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Components:**
- Header with disconnect button
- Breadcrumb navigation
- Scrollable data list
- Recursive data row view

### 5. Firebase Manager (`FirebaseManager.swift`)

**Class Structure:**
```swift
FirebaseManager: ObservableObject
├── @Published data: [String: Any]
├── @Published isLoading: Bool
├── @Published error: String?
├── serviceAccount: ServiceAccount?
├── func initialize(with: URL)
├── func fetchRootData() async
└── func fetchData(at: String) async
```

**Responsibilities:**
- Parse service account credentials
- Make REST API calls to Firebase
- Manage authentication
- Limit results to 5 entries
- Handle errors

## Data Flow

### Authentication Flow
```
1. User drops JSON file
   ↓
2. OnboardingView reads file
   ↓
3. Validates structure (project_id, private_key, client_email)
   ↓
4. Creates FirebaseManager
   ↓
5. Calls manager.initialize(with: fileURL)
   ↓
6. Updates AppState.isAuthenticated = true
   ↓
7. ContentView shows DataBrowserView
```

### Data Fetching Flow
```
1. DataBrowserView appears
   ↓
2. Calls manager.fetchRootData()
   ↓
3. FirebaseManager constructs URL
   ↓
4. Makes GET request: /.json?shallow=true
   ↓
5. Gets top-level keys
   ↓
6. For first 5 keys, fetches details
   ↓
7. Makes GET requests: /{key}.json?limitToFirst=5
   ↓
8. Updates @Published data
   ↓
9. SwiftUI re-renders view
```

## REST API Usage

The app uses Firebase's REST API:

**Endpoints:**
- `GET /.json?shallow=true` - Get top-level keys
- `GET /{path}.json?limitToFirst=5` - Get data with limit

**Query Parameters:**
- `shallow=true` - Only return keys, not values
- `limitToFirst=5` - Limit results to first 5 entries

**Authentication:**
Uses OAuth 2.0 access tokens derived from the service account key, attached to each REST request.

## UI/UX Design Principles

### 1. **Simplicity First**
- Minimal UI chrome
- Clear visual hierarchy
- Intuitive navigation

### 2. **Safety by Default**
- Read-only mode (no write operations)
- Service keys never stored
- Clear disconnect mechanism

### 3. **Performance Conscious**
- Lazy loading with limits
- Async/await for non-blocking UI
- Efficient data structures

### 4. **Native macOS Experience**
- SwiftUI native controls
- System colors (light/dark mode)
- Standard keyboard shortcuts
- Drag & drop integration

## Technology Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI |
| Language | Swift 5.9+ |
| Platform | macOS 13+ |
| State Management | Combine (@Published, @ObservableObject) |
| Networking | URLSession |
| API | Firebase REST API |
| Build System | Swift Package Manager |

## Security Considerations

### What We Do:
✅ Read-only operations only
✅ Local-only service key usage
✅ No key storage or transmission
✅ Input validation on service keys

### What We Don't Do:
❌ No write operations
❌ No key persistence
❌ No third-party data sharing
❌ No analytics or tracking

## Future Enhancement Opportunities

### Phase 2 (Optional):
- [ ] Real-time data updates (WebSocket)
- [ ] Export to JSON/CSV
- [ ] Advanced search/filter
- [ ] Multiple database tabs
- [ ] Custom query builder

### Phase 3 (Optional):
- [ ] Write mode (with confirmations)
- [ ] Undo/redo support
- [ ] Data validation rules
- [ ] Schema visualization
- [ ] Performance monitoring

## Code Quality Metrics

| Metric | Value |
|--------|-------|
| Total Swift Files | 5 |
| Total Lines of Code | ~624 |
| Average File Size | ~125 lines |
| Max Function Length | ~50 lines |
| Cyclomatic Complexity | Low |
| Test Coverage | N/A (GUI app) |

## Development Workflow

```bash
# 1. Clone repository
git clone https://github.com/davewd/firebase_data_gui.git

# 2. Open in Xcode
open Package.swift

# 3. Run in debug mode (⌘+R)

# 4. Make changes and see live previews

# 5. Build release (⌘+B)
```

## Deployment

The app can be distributed as:
1. **Source code** - Users build themselves
2. **.app bundle** - Drag to Applications
3. **DMG installer** - Professional distribution
4. **Mac App Store** - Requires Apple Developer account

---

This architecture provides a solid foundation that can be extended while maintaining simplicity and security.
