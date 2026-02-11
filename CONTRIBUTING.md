# Contributing to Firebase Data GUI

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Development Setup

1. Fork and clone the repository
2. Open `Package.swift` in Xcode
3. Build and run (⌘+R)

## Code Style

- Follow Swift standard naming conventions
- Use SwiftUI best practices
- Keep functions small and focused
- Add comments for complex logic
- Use meaningful variable names

## Project Structure

```
Sources/
├── App.swift              # Main app entry point with @main
├── ContentView.swift      # Root view controller
├── OnboardingView.swift   # Drag & drop onboarding UI
├── DataBrowserView.swift  # Main data browsing interface
├── FirebaseManager.swift  # Firebase REST API integration
└── Info.plist            # App metadata
```

## Making Changes

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Commit with clear messages
5. Submit a pull request

## Testing Guidelines

### Manual Testing

1. **Onboarding Flow**:
   - Test drag and drop with valid JSON
   - Test drag and drop with invalid JSON
   - Test file picker selection
   - Test error handling

2. **Data Browser**:
   - Test with empty database
   - Test with nested objects (3+ levels)
   - Test with different data types
   - Test expand/collapse functionality
   - Test with >5 items in collection

3. **Edge Cases**:
   - Very large nested objects
   - Special characters in keys/values
   - Empty collections
   - Null values

### Security Testing

- Never commit service account keys
- Test with restricted security rules
- Verify read-only mode (no write operations)

## Adding Features

When adding new features:

1. **Keep it minimal**: Only essential functionality
2. **Maintain read-only**: Never add write capabilities without discussion
3. **Update documentation**: README, BUILDING.md, etc.
4. **Consider security**: Never expose sensitive data

## Common Changes

### Adding a New View

```swift
import SwiftUI

struct MyNewView: View {
    var body: some View {
        Text("Hello")
    }
}

// Add preview for development
#if DEBUG
struct MyNewView_Previews: PreviewProvider {
    static var previews: some View {
        MyNewView()
    }
}
#endif
```

### Adding Firebase Functionality

Extend `FirebaseManager.swift`:

```swift
func fetchCustomData(at path: String) async -> Result<Any, Error> {
    // Implementation
}
```

### Modifying the UI

- Keep SwiftUI declarative
- Use `@State` for local state
- Use `@EnvironmentObject` for shared state
- Add proper accessibility labels

## Pull Request Process

1. **Title**: Clear, descriptive title
2. **Description**: What, why, and how
3. **Testing**: Describe how you tested
4. **Screenshots**: For UI changes
5. **Breaking Changes**: Clearly document

## Code Review

All submissions require review. Reviewers will check:

- Code quality and style
- Security considerations
- Performance implications
- Documentation updates
- Test coverage

## Questions?

Open an issue for discussion before major changes.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
