import SwiftUI

struct DataBrowserView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPath: String = "/"
    @State private var navigationStack: [String] = ["/"]
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with navigation
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Firebase Data")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        appState.isAuthenticated = false
                        appState.firebaseManager = nil
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .buttonStyle(.plain)
                    .help("Disconnect")
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                
                Divider()
                
                // Navigation breadcrumbs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(navigationStack.enumerated()), id: \.offset) { index, path in
                            Button(action: {
                                navigateTo(index: index)
                            }) {
                                Text(path == "/" ? "Root" : path)
                                    .font(.caption)
                                    .foregroundColor(index == navigationStack.count - 1 ? .primary : .secondary)
                            }
                            .buttonStyle(.plain)
                            
                            if index < navigationStack.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 30)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                
                Divider()
                
                // Data view
                if let manager = appState.firebaseManager {
                    DataContentView(manager: manager, currentPath: selectedPath)
                } else {
                    Text("No data available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        } detail: {
            VStack {
                Text("Read-only Firebase Realtime Database Viewer")
                    .font(.title2)
                    .padding()
                
                Text("Limited to 5 entries per collection")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .navigationTitle("Firebase Data GUI")
        .task {
            await appState.firebaseManager?.fetchRootData()
        }
    }
    
    private func navigateTo(index: Int) {
        navigationStack = Array(navigationStack.prefix(index + 1))
        selectedPath = navigationStack.last ?? "/"
    }
}

struct DataContentView: View {
    @ObservedObject var manager: FirebaseManager
    let currentPath: String
    
    var body: some View {
        Group {
            if manager.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                    Text("Loading data...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                }
            } else if let error = manager.error {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                    Button(action: {
                        copyTextToClipboard(error)
                    }) {
                        Label("Copy Error", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if manager.data.isEmpty {
                            Text("No data available")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(Array(manager.data.keys.sorted().prefix(5)), id: \.self) { key in
                                DataRowView(key: key, value: manager.data[key]!, level: 0)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DataRowView: View {
    let key: String
    let value: Any
    let level: Int
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // Indentation
                if level > 0 {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: CGFloat(level * 20))
                }
                
                // Expansion toggle for nested objects
                if isNestedObject {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .frame(width: 12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12)
                }
                
                // Key
                Text(key)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text(":")
                    .foregroundColor(.secondary)
                
                // Value preview
                if !isNestedObject {
                    Text(valuePreview)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(valueColor)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(level % 2 == 0 ? Color.clear : Color(nsColor: .controlBackgroundColor).opacity(0.3))
            )
            
            // Expanded nested content
            if isExpanded, let dict = value as? [String: Any] {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(dict.keys.sorted().prefix(5)), id: \.self) { nestedKey in
                        DataRowView(key: nestedKey, value: dict[nestedKey]!, level: level + 1)
                    }
                    
                    if dict.count > 5 {
                        HStack {
                            if level > 0 {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: CGFloat((level + 1) * 20))
                            }
                            Text("... \(dict.count - 5) more items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding(.leading, 8)
                    }
                }
            }
        }
    }
    
    private var isNestedObject: Bool {
        return value is [String: Any] || value is [Any]
    }
    
    private var valuePreview: String {
        switch value {
        case let bool as Bool:
            return "\(bool)"
        case let number as NSNumber:
            return "\(number)"
        case let string as String:
            return "\"\(string)\""
        case is NSNull:
            return "null"
        case let array as [Any]:
            return "[\(array.count) items]"
        case let dict as [String: Any]:
            return "{\(dict.count) items}"
        default:
            return "\(value)"
        }
    }
    
    private var valueColor: Color {
        switch value {
        case is Bool:
            return .purple
        case is NSNumber:
            return .orange
        case is String:
            return .green
        case is NSNull:
            return .gray
        default:
            return .primary
        }
    }
}

#if DEBUG
struct DataBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.isAuthenticated = true
        let manager = FirebaseManager()
        appState.firebaseManager = manager
        
        return DataBrowserView()
            .environmentObject(appState)
    }
}
#endif
