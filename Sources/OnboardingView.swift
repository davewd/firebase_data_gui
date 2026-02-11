import SwiftUI
import UniformTypeIdentifiers

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var isDropTargeted = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Firebase Data GUI")
                .font(.system(size: 36, weight: .bold))
            
            Text("Drop your Firebase service account JSON key to begin")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Note: Your database must allow public read access")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.top, 4)
            
            // Drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isDropTargeted ? Color.blue : Color.gray.opacity(0.5),
                        style: StrokeStyle(lineWidth: 3, dash: [10])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isDropTargeted ? Color.blue.opacity(0.1) : Color.clear)
                    )
                    .frame(width: 400, height: 250)
                
                VStack(spacing: 16) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(isDropTargeted ? .blue : .gray)
                    
                    Text("Drop JSON Service Key Here")
                        .font(.headline)
                        .foregroundColor(isDropTargeted ? .blue : .gray)
                    
                    Text("or click to select")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers: providers)
                return true
            }
            .onTapGesture {
                selectFile()
            }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Text("Read-only mode • Limited to 5 entries per collection")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            guard let url = url else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load file"
                }
                return
            }
            
            DispatchQueue.main.async {
                self.loadServiceKey(from: url)
            }
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]
        panel.message = "Select Firebase Service Account JSON Key"
        
        if panel.runModal() == .OK, let url = panel.url {
            loadServiceKey(from: url)
        }
    }
    
    private func loadServiceKey(from url: URL) {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                errorMessage = "Error: Invalid JSON format"
                isLoading = false
                return
            }
            
            // Validate it's a Firebase service account key
            guard let projectId = json["project_id"] as? String,
                  !projectId.isEmpty,
                  let privateKey = json["private_key"] as? String,
                  !privateKey.isEmpty,
                  let clientEmail = json["client_email"] as? String,
                  !clientEmail.isEmpty else {
                errorMessage = "Error: Invalid Firebase service account key format. Missing required fields."
                isLoading = false
                return
            }
            
            // Initialize Firebase
            let manager = FirebaseManager()
            let databaseURL = (json["database_url"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            let serviceAccount = FirebaseManager.ServiceAccount(
                projectId: projectId,
                privateKey: privateKey,
                clientEmail: clientEmail,
                databaseURL: databaseURL
            )
            manager.initialize(with: serviceAccount)
            appState.firebaseManager = manager
            appState.isAuthenticated = true
            
        } catch {
            errorMessage = "Error: Failed to read file - \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppState())
            .frame(width: 600, height: 500)
    }
}
#endif
