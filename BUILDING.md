# Building and Running the Firebase Data GUI

## Prerequisites

1. **macOS System Requirements**
   - macOS 13.0 (Ventura) or later
   - Xcode 14.0 or later

2. **Firebase Setup**
   - A Firebase project with Realtime Database enabled
   - A service account key file (JSON)

## Building the Application

### Option 1: Using Xcode

1. Open the project:
   ```bash
   cd firebase_data_gui
   open Package.swift
   ```

2. In Xcode:
   - Select "My Mac" as the build destination
   - Press ⌘+B to build
   - Press ⌘+R to run

### Option 2: Using Swift Package Manager (Command Line)

```bash
cd firebase_data_gui
swift build -c release

# Run the app
.build/release/FirebaseDataGUI
```

## Creating a macOS App Bundle

To create a distributable .app bundle:

```bash
# Build in release mode
swift build -c release

# The executable will be at:
# .build/release/FirebaseDataGUI
```

For a proper .app bundle, use Xcode:
1. Open Package.swift in Xcode
2. Product → Archive
3. Distribute App → Copy App

## Testing the Application

### 1. Prepare Test Data

Create a test Firebase project with some sample data:

```json
{
  "users": {
    "user1": {
      "name": "John Doe",
      "email": "john@example.com",
      "age": 30
    },
    "user2": {
      "name": "Jane Smith",
      "email": "jane@example.com",
      "age": 25
    }
  },
  "posts": {
    "post1": {
      "title": "First Post",
      "content": "Hello World",
      "author": "user1"
    }
  }
}
```

### 2. Get Service Account Key

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Save the JSON file

### 3. Test the App

1. Launch the app
2. Drag and drop the service account JSON file
3. Verify the data loads correctly
4. Test expanding/collapsing nested objects
5. Verify only 5 entries show per collection

## Firebase Security Rules

For read-only access, ensure your Firebase Realtime Database rules allow reading:

```json
{
  "rules": {
    ".read": true,
    ".write": false
  }
}
```

Or for authenticated service account access:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": false
  }
}
```

## Troubleshooting Build Issues

### Swift Version

Check your Swift version:
```bash
swift --version
```

Should be 5.9 or later.

### Clean Build

If you encounter build issues:
```bash
swift package clean
swift build
```

### Xcode Issues

```bash
rm -rf .build
rm Package.resolved
xcodebuild clean
```

## Development Tips

### Hot Reload

Xcode supports SwiftUI previews. Add preview code to views:

```swift
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppState())
    }
}
```

### Debugging

- Use `print()` statements in Swift code
- Set breakpoints in Xcode
- View console output for errors

### Testing with Different Databases

The app supports any Firebase Realtime Database. Simply use different service account keys to switch between projects.
