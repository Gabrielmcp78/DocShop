import SwiftUI

struct DeepCrawlView: View {
    @ObservedObject private var crawler = DeepCrawler.shared
    @ObservedObject private var config = DocumentProcessorConfig.shared
    @State private var showingSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            
            if config.enableDeepCrawling {
                if crawler.isCrawling {
                    crawlingProgressSection
                } else {
                    crawlResultsSection
                }
                
                discoveredLinksSection
            } else {
                disabledSection
            }
        }
        .padding()
        .navigationTitle("Deep Crawl")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Settings") {
                    showingSettings = true
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            DeepCrawlSettingsView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Deep Documentation Crawl")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if crawler.isCrawling {
                    Button("Stop Crawl") {
                        crawler.stopCrawl()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                } else if !crawler.crawledPages.isEmpty {
                    Button("Clear Results") {
                        crawler.clearCrawlData()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Text("Automatically discover and archive interconnected documentation")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var disabledSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe.badge.chevron.backward")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Deep Crawling Disabled")
                .font(.headline)
            
            Text("Enable deep crawling in settings to automatically discover and archive related documentation pages.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Enable Deep Crawling") {
                config.enableDeepCrawling = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var crawlingProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crawl in Progress")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(crawler.currentCrawlStatus)
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(Int(crawler.crawlProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: crawler.crawlProgress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            
            HStack {
                Label("\(crawler.crawledPages.count)", systemImage: "doc.text")
                    .font(.caption)
                
                Label("\(crawler.discoveredLinks.count)", systemImage: "link")
                    .font(.caption)
                
                Spacer()
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var crawlResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crawl Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(crawler.crawledPages.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Pages Crawled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(crawler.discoveredLinks.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Links Found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var discoveredLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Discovered Links")
                    .font(.headline)
                
                Spacer()
                
                if !crawler.discoveredLinks.isEmpty {
                    Menu("Filter") {
                        Button("All Links") { /* TODO: Implement filtering */ }
                        Button("Internal Only") { /* TODO: Implement filtering */ }
                        Button("External Only") { /* TODO: Implement filtering */ }
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if crawler.discoveredLinks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No links discovered yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Start importing documentation to see discovered links")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(crawler.discoveredLinks) { link in
                            DiscoveredLinkRow(link: link)
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct DiscoveredLinkRow: View {
    let link: CrawlLink
    @ObservedObject private var processor = DocumentProcessor.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(link.displayText)
                    .font(.body)
                    .lineLimit(2)
                
                Text(link.url.absoluteString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Label("Depth \(link.depth)", systemImage: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Label(link.linkType.displayName, systemImage: linkTypeIcon(for: link.linkType))
                        .font(.caption2)
                        .foregroundColor(linkTypeColor(for: link.linkType))
                }
            }
            
            Spacer()
            
            Button("Import") {
                Task {
                    try? await processor.importDocument(from: link.url.absoluteString)
                }
            }
            .buttonStyle(.bordered)
            .disabled(processor.isProcessing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.quaternarySystemFill))
        .cornerRadius(6)
    }
    
    private func linkTypeIcon(for type: LinkType) -> String {
        switch type {
        case .internal:
            return "house"
        case .subdomain:
            return "building.2"
        case .external:
            return "globe"
        case .unknown:
            return "questionmark"
        }
    }
    
    private func linkTypeColor(for type: LinkType) -> Color {
        switch type {
        case .internal:
            return .green
        case .subdomain:
            return .blue
        case .external:
            return .orange
        case .unknown:
            return .gray
        }
    }
}

struct DeepCrawlSettingsView: View {
    @ObservedObject private var config = DocumentProcessorConfig.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Deep Crawling") {
                    Toggle("Enable Deep Crawling", isOn: $config.enableDeepCrawling)
                    
                    if config.enableDeepCrawling {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Max Crawl Depth: \(config.maxCrawlDepth)")
                            Slider(value: Binding(
                                get: { Double(config.maxCrawlDepth) },
                                set: { config.maxCrawlDepth = Int($0) }
                            ), in: 1...10, step: 1)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Max Pages Per Domain: \(config.maxPagesPerDomain)")
                            Slider(value: Binding(
                                get: { Double(config.maxPagesPerDomain) },
                                set: { config.maxPagesPerDomain = Int($0) }
                            ), in: 10...200, step: 10)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Crawl Delay: \(String(format: "%.1f", config.crawlDelay))s")
                            Slider(value: $config.crawlDelay, in: 0.1...5.0, step: 0.1)
                        }
                        
                        Toggle("Follow External Links", isOn: $config.followExternalLinks)
                    }
                }
                
                Section("Information") {
                    Text("Deep crawling automatically discovers and imports related documentation pages by following links from the initial page you import.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Deep Crawl Settings")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DeepCrawlView()
}
