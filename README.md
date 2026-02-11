# Firebase Data GUI

A simple macOS application for viewing Firebase Realtime Database data in a read-only GUI. This app allows you to drop a Firebase service account JSON key file and browse your database structure with nested records.

## Features

- 🔥 **Firebase Integration**: Connects to Firebase Realtime Database using REST API
- 🎯 **Drag & Drop**: Simple onboarding - just drop your service account JSON key file
- 📊 **Nested Data View**: Browse JSON object-oriented database with expandable tree structure
- ⚡ **Limited Download**: Fetches only the first 5 entries per collection to save bandwidth
- 🔒 **Read-Only**: Safe browsing without risk of modifying your data
- 💻 **Native macOS**: Built with SwiftUI for a modern, native macOS experience

## Important: Firebase Security Rules

⚠️ **This app requires your Firebase Realtime Database to have public read access configured.**

The current implementation uses Firebase's REST API without OAuth authentication for simplicity. Your database security rules must allow unauthenticated read access:

```json
{
  "rules": {
    ".read": true,
    ".write": false
  }
}
```

**For production databases with sensitive data**, this approach is not recommended. The service account key is validated but not currently used for authentication. Future versions may implement OAuth 2.0 token generation for authenticated access.

**Recommended Use Cases:**
- Development/staging databases
- Public read-only data
- Non-sensitive data
- Database structure inspection

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later (for building from source)
- A Firebase project with Realtime Database
- A Firebase service account JSON key file

## Getting Your Firebase Service Account Key

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on the gear icon (⚙️) → Project Settings
4. Navigate to the "Service Accounts" tab
5. Click "Generate New Private Key"
6. Save the downloaded JSON file securely

## Building from Source

```bash
# Clone the repository
git clone https://github.com/davewd/firebase_data_gui.git
cd firebase_data_gui

# Open in Xcode
open Package.swift
# OR
swift build
```

## Usage

1. Launch the Firebase Data GUI application
2. On the onboarding screen, either:
   - **Drag and drop** your Firebase service account JSON key file onto the drop zone
   - **Click** the drop zone to select the file manually
3. The app will automatically connect to your Firebase Realtime Database
4. Browse your data:
   - Expand nested objects by clicking the chevron icons
   - View different data types with color-coded syntax
   - Navigate through your database structure

## Features in Detail

### Read-Only Mode
The application operates in read-only mode, meaning:
- You can view all your data safely
- No accidental modifications can occur
- Perfect for data inspection and debugging

### Limited Data Fetching
To improve performance and reduce bandwidth:
- Only the first 5 entries of each collection are fetched
- This applies at every nesting level
- Ideal for inspecting database structure without downloading everything

### Data Type Support
The viewer supports and displays:
- **Strings** (green)
- **Numbers** (orange)
- **Booleans** (purple)
- **Null values** (gray)
- **Nested objects** (expandable)
- **Arrays** (with item count)

## Project Structure

```
firebase_data_gui/
├── Package.swift           # Swift Package Manager configuration
├── Sources/
│   ├── App.swift          # Main app entry point
│   ├── ContentView.swift  # Root view switcher
│   ├── OnboardingView.swift      # Drag & drop onboarding screen
│   ├── DataBrowserView.swift     # Main data browsing interface
│   ├── FirebaseManager.swift     # Firebase connection manager
│   └── Info.plist         # App metadata
└── README.md
```

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **Firebase REST API**: Direct HTTP communication with Firebase Realtime Database
- **Async/Await**: Modern Swift concurrency for data fetching
- **Observable Objects**: Reactive state management

## Security Notes

⚠️ **Important Security Considerations:**

- Service account keys provide full access to your Firebase project
- Never commit service account keys to version control
- Store keys securely and never share them
- The app does not store or transmit your keys anywhere
- Keys are only used locally to authenticate with Firebase

## Firebase Security Rules

For the app to work, your Firebase Realtime Database needs read access configured. The current implementation uses the REST API without OAuth authentication, so you need to allow read access:

**Public Read (Development/Testing)**
```json
{
  "rules": {
    ".read": true,
    ".write": false
  }
}
```

**Note:** For production use with sensitive data, you may want to implement OAuth 2.0 token generation from the service account credentials. The current implementation prioritizes simplicity and is suitable for development databases or public read-only data.

## Troubleshooting

### "Invalid Firebase service account key format"
- Ensure you downloaded the correct JSON file from Firebase Console
- The file should contain `project_id`, `private_key`, and `client_email` fields

### "Failed to fetch data"
- Check your internet connection
- Verify your Firebase Realtime Database has security rules that allow read access
- Ensure your database URL is correct (default: `https://PROJECT_ID-default-rtdb.firebaseio.com`)

### No data showing
- Your database might be empty
- Check Firebase Console to verify data exists
- Security rules might be blocking access

## Future Enhancements

Potential features for future versions:
- [ ] Write capabilities with confirmation dialogs
- [ ] Search functionality across the database
- [ ] Export data to JSON/CSV
- [ ] Multiple database instance support
- [ ] Custom query builders
- [ ] Real-time data updates
- [ ] Adjustable entry limit settings

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/davewd/firebase_data_gui).

