import SwiftUI

struct ContentView: View {
    @State private var selectedSidebarItem: SidebarItem? = .library
    @ObservedObject private var processor = DocumentProcessor.shared
    @ObservedObject private var library = DocLibraryIndex.shared
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            EnhancedSidebarView(selection: $selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            Group {
                switch selectedSidebarItem {
                case .library:
                    LibraryView()
                case .importItem:
                    DocumentDropView()
                case .settings:
                    EnhancedSettingsView()
                case .logs:
                    LogViewerView()
                case .status:
                    SystemStatusView()
                case .none:
                    EmptyStateView()
                }
            }
            .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if processor.isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.2)
                        Text(processor.currentStatus)
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    library.refreshLibrary()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(processor.isProcessing)
                .help("Refresh Library")
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            // Perform startup cleanup
            DocumentStorage.shared.cleanupOrphanedFiles()
        }
    }
}

enum SidebarItem: String, CaseIterable, Hashable {
    case library = "library"
    case importItem = "import"
    case settings = "settings"
    case logs = "logs"
    case status = "status"
    
    var displayName: String {
        switch self {
        case .library:
            return "Library"
        case .importItem:
            return "Import"
        case .settings:
            return "Settings"
        case .logs:
            return "Logs"
        case .status:
            return "System Status"
        }
    }
    
    var iconName: String {
        switch self {
        case .library:
            return "books.vertical"
        case .importItem:
            return "square.and.arrow.down"
        case .settings:
            return "gear"
        case .logs:
            return "list.bullet.rectangle"
        case .status:
            return "info.circle"
        }
    }
}

struct EnhancedSidebarView: View {
    @Binding var selection: SidebarItem?
    @ObservedObject private var library = DocLibraryIndex.shared
    @ObservedObject private var processor = DocumentProcessor.shared
    
    var body: some View {
        List(SidebarItem.allCases, id: \.self, selection: $selection) { item in
            NavigationLink(value: item) {
                HStack {
                    Image(systemName: item.iconName)
                        .frame(width: 20)
                        .foregroundColor(selection == item ? .white : .primary)
                    
                    Text(item.displayName)
                        .foregroundColor(selection == item ? .white : .primary)
                    
                    Spacer()
                    
                    if item == .library {
                        Text("\(library.documents.count)")
                            .font(.caption)
                            .foregroundColor(selection == item ? .white.opacity(0.4) : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(selection == item ? Color.clear.opacity(0.2) : Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    } else if item == .importItem && !processor.processingQueue.isEmpty {
                        Text("\(processor.processingQueue.count)")
                            .font(.caption)
                            .foregroundColor(selection == item ? .white.opacity(0.8) : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(selection == item ? Color.white.opacity(0.2) : Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .tag(item)
        }
        .navigationTitle("DocShop")
        .listStyle(.sidebar)
        .onAppear {
            if selection == nil {
                selection = .library
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 54))
                .foregroundColor(.secondary)
            
            Text("Welcome to DocShop")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Select an option from the sidebar to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}

