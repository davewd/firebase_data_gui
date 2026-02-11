# Firebase Data GUI - User Interface

This document describes the user interface of the Firebase Data GUI application.

## Onboarding Screen

The onboarding screen is the first thing users see when launching the app.

### Features:
- **Title**: "Firebase Data GUI" prominently displayed
- **Subtitle**: "Drop your Firebase service account JSON key to begin"
- **Drop Zone**: 
  - Large dashed rectangle (400x250px)
  - Icon showing document with plus sign
  - Text: "Drop JSON Service Key Here"
  - Sub-text: "or click to select"
  - Interactive hover state (turns blue when dragging over)
- **Loading Indicator**: Shows when processing the key file
- **Error Display**: Red text with light red background for errors
- **Footer Text**: "Read-only mode • Limited to 5 entries per collection"

### User Actions:
1. **Drag & Drop**: Users can drag a .json file from Finder onto the drop zone
2. **Click to Select**: Users can click the drop zone to open a file picker
3. **Automatic Validation**: The app validates the JSON structure
4. **Automatic Connection**: Upon successful validation, automatically connects to Firebase

## Data Browser Screen

After successful authentication, users see the data browser interface.

### Layout:
- **Navigation Split View** (Sidebar + Detail)

### Sidebar Components:

1. **Header Bar**:
   - Firebase flame icon (orange)
   - "Firebase Data" text
   - Disconnect button (arrow icon)

2. **Breadcrumb Navigation**:
   - Shows current path (e.g., "Root > users > user1")
   - Clickable breadcrumbs to navigate back
   - Horizontal scrollable if path is long

3. **Data Content Area**:
   - Scrollable list of data entries
   - Each entry shows:
     - Expand/collapse chevron for nested objects
     - Key name (blue, monospaced font)
     - Colon separator
     - Value or type indicator
   - Color-coded values:
     - Strings: green (with quotes)
     - Numbers: orange
     - Booleans: purple
     - Null: gray
     - Objects: Shows item count
     - Arrays: Shows item count

### Detail Pane:
- Title: "Read-only Firebase Realtime Database Viewer"
- Subtitle: "Limited to 5 entries per collection"

### Interactive Features:

1. **Expandable Nested Objects**:
   - Click chevron to expand/collapse
   - Smooth animation
   - Indentation shows nesting level
   - Alternating background colors for readability

2. **Limited Entry Display**:
   - Maximum 5 entries shown per collection/object
   - "... X more items" indicator if more exist

3. **Visual Hierarchy**:
   - Indentation increases by 20px per level
   - Background color alternates between clear and light gray
   - Monospaced font for data values

## Color Scheme

The app uses native macOS colors for system integration:

- **Background**: System window background color
- **Text**: System primary and secondary text colors
- **Accents**:
  - Blue: Keys, interactive elements
  - Green: String values
  - Orange: Number values, Firebase flame icon
  - Purple: Boolean values
  - Red: Errors
  - Gray: Null values, secondary text

## Typography

- **App Title**: System font, 36pt, bold
- **Section Headers**: Headline weight
- **Data Keys**: Monospaced, medium weight
- **Data Values**: Monospaced, regular weight
- **Captions**: Small, secondary color

## Window Properties

- **Minimum Size**: 800x600 pixels
- **Title Bar**: Hidden for cleaner appearance
- **Resizable**: Yes, content size based

## Accessibility

- All interactive elements have accessibility labels
- Color is not the only indicator (icons and text used too)
- Keyboard navigation supported
- VoiceOver compatible

## User Experience Flow

```
Launch App
    ↓
Onboarding Screen
    ↓
Drop/Select Service Key
    ↓
Validation & Loading
    ↓
Data Browser Screen
    ↓
Browse Data (expand/collapse)
    ↓
Disconnect (returns to Onboarding)
```

## Error States

1. **Invalid JSON File**: "Invalid Firebase service account key format"
2. **Network Error**: "Failed to fetch data: [error details]"
3. **Empty Database**: "No data available"
4. **Connection Failed**: Shows error with red exclamation icon

## Loading States

- Circular progress indicator during:
  - Service key validation
  - Initial data fetch
  - Navigation between data paths

## Platform Integration

- Uses native macOS file picker
- Drag and drop from Finder
- System colors for light/dark mode
- Native window controls
- macOS-style buttons and controls
