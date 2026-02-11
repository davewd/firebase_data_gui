# Quick Start Guide

## 🚀 Getting Started in 3 Steps

### Step 1: Get Your Firebase Service Key

1. Visit [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Settings ⚙️** → **Project Settings** → **Service Accounts**
4. Click **"Generate New Private Key"**
5. Download and save the JSON file

### Step 2: Build the App

**Using Xcode:**
```bash
cd firebase_data_gui
open Package.swift
```
Then press **⌘+R** to run

**Using Terminal:**
```bash
cd firebase_data_gui
swift build
.build/debug/FirebaseDataGUI
```

### Step 3: Connect to Your Database

1. Launch the app
2. **Drag & drop** your service key JSON file
3. Start browsing your data! 🎉

## 📱 Quick Tips

### Navigation
- **Expand/Collapse**: Click chevron icons (▶/▼) to show/hide nested data
- **Disconnect**: Click the exit icon in the top-right to switch databases
- **Breadcrumbs**: Use the navigation bar to jump back to parent levels

### Understanding the UI

**Color Coding:**
- 🟢 Green = Strings (text)
- 🟠 Orange = Numbers
- 🟣 Purple = Booleans (true/false)
- ⚪ Gray = Null values
- 🔵 Blue = Keys/property names

**Icons:**
- 🔥 = Firebase connection active
- ➡️ = Exit/disconnect
- ▶ = Collapsed (click to expand)
- ▼ = Expanded (click to collapse)

### Data Limits

The app shows **only the first 5 entries** at each level:
- Root collections: First 5
- Nested objects: First 5 items
- This applies recursively to all levels

If you see "... X more items", it means there are additional entries not shown.

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| File won't drop | Make sure it's a `.json` file |
| "Invalid key" error | Verify you downloaded the service account key, not a different JSON file |
| No data appears | Check if your database has data in Firebase Console |
| Connection fails | Verify your internet connection and Firebase security rules |

## 🔒 Security Reminders

- ⚠️ Never share your service account key
- ⚠️ Never commit keys to git repositories
- ⚠️ Keys grant full access to your Firebase project
- ✅ The app operates in read-only mode
- ✅ Keys are used locally only

## 📚 More Information

- **Full Documentation**: See [README.md](README.md)
- **Build Instructions**: See [BUILDING.md](BUILDING.md)
- **UI Details**: See [SCREENSHOTS.md](SCREENSHOTS.md)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)

## 💡 Example Use Cases

1. **Debugging**: Quickly inspect production data structure
2. **Development**: Verify data format during app development
3. **Documentation**: Share database structure with team members
4. **Testing**: Check test data without writing code
5. **Exploration**: Browse unfamiliar Firebase projects

## 🎯 Common Firebase Database Rules

For the app to work, your database needs read access. Here are common configurations:

**Public Read (Development Only)**
```json
{
  "rules": {
    ".read": true,
    ".write": false
  }
}
```

**Authenticated Access (Recommended)**
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": false
  }
}
```

The service account automatically authenticates, so both configurations work.

## 🔄 Switching Between Projects

To browse a different Firebase project:
1. Click the **exit icon** (➡️) in the top-right
2. Drop your new service key
3. Done!

## ⚡ Keyboard Shortcuts

- **⌘+W**: Close window
- **⌘+Q**: Quit app
- **⌘+R**: Refresh data (in Xcode during development)

---

**Need Help?** Open an issue on [GitHub](https://github.com/davewd/firebase_data_gui)
