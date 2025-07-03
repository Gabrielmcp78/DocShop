import SwiftUI
import UniformTypeIdentifiers

struct EnhancedSettingsView: View {
    @ObservedObject private var config = DocumentProcessorConfig.shared
    @ObservedObject private var library = DocLibraryIndex.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                processingSettingsSection
                
                deepCrawlSettingsSection
                
                javascriptRenderingSection
                
                aiEnhancementSection
                
                libraryManagementSection
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
    
    private var processingSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Processing Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            Toggle("Allow Duplicate Documents", isOn: $config.allowDuplicates)
            
            if !config.allowDuplicates {
                Toggle("Smart Duplicate Handling", isOn: $config.smartDuplicateHandling)
                
                if config.smartDuplicateHandling {
                    Toggle("Check for Content Updates", isOn: $config.checkForUpdates)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var deepCrawlSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deep Crawling")
                .font(.headline)
                .fontWeight(.semibold)
            
            Toggle("Enable Deep Crawling", isOn: $config.enableDeepCrawling)
            
            if config.enableDeepCrawling {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Max Crawl Depth: \(config.maxCrawlDepth)")
                        .font(.caption)
                    Slider(value: Binding(
                        get: { Double(config.maxCrawlDepth) },
                        set: { config.maxCrawlDepth = Int($0) }
                    ), in: 1...10, step: 1)
                }
                
                Toggle("Follow External Links", isOn: $config.followExternalLinks)
                
                NavigationLink(destination: DeepCrawlView()) {
                    HStack {
                        Image(systemName: "globe")
                        Text("View Deep Crawl Status")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var javascriptRenderingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("JavaScript Rendering")
                .font(.headline)
                .fontWeight(.semibold)
            
            Toggle("Enable JavaScript Rendering", isOn: $config.enableJavaScriptRendering)
            
            Text("Automatically render JavaScript-heavy documentation sites for complete content extraction")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if config.enableJavaScriptRendering {
                Toggle("Auto-detect JS requirement", isOn: $config.autoDetectJSRequirement)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var aiEnhancementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Enhancement")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Apple Intelligence Status")
                    .font(.body)
                
                Spacer()
                
                AIStatusIndicator()
            }
            
            Text("AI features enhance document processing with intelligent analysis, metadata generation, and smart link discovery")
                .font(.caption)
                .foregroundColor(.secondary)
            
            NavigationLink(destination: AISearchView()) {
                HStack {
                    Image(systemName: "brain")
                    Text("AI-Powered Search")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var libraryManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Library Management")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Documents: \(library.documents.count)")
                Spacer()
                Button("Refresh") {
                    library.refreshLibrary()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}