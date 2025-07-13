import SwiftUI
import VisualEffects

struct AISearchView: View {
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var selectedTab: SearchTab = .all
    @State private var libraryResults: [DocumentMetaData] = []
    @State private var webResults: [WebSearchResult] = []
    @State private var showPreview: Bool = false
    @State private var previewDocument: DocumentMetaData?
    @State private var previewWebResult: WebSearchResult?
    @ObservedObject private var library = DocLibraryIndex.shared
    @ObservedObject private var aiAnalyzer = AIDocumentAnalyzer.shared
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            searchBarSection
            tabPickerSection
            Divider().padding(.bottom, 2)
            resultsSection
            if let error = error {
                errorSection(error)
            }
        }
        .background(
            VisualEffectBlur(material: .underWindowBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 16, x: 0, y: 8)
        .padding(16)
        .glassy()
        .sheet(isPresented: $showPreview) {
            if let doc = previewDocument {
                DocumentDetailView(document: doc)
            } else if let web = previewWebResult {
                WebPreviewView(result: web)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.purple)
            Text("AI-Powered Search")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            if aiAnalyzer.isAIAvailable {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            } else {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            }
        }
        .padding([.top, .horizontal])
    }

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            TextField("Search your docs or the web...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .onSubmit { performSearch() }
            Button(action: performSearch) {
                if isSearching {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "magnifyingglass")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(searchQuery.isEmpty || isSearching)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var tabPickerSection: some View {
        Picker("Results", selection: $selectedTab) {
            ForEach(SearchTab.allCases, id: \.self) { tab in
                Text(tab.displayName).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    private var resultsSection: some View {
        Group {
            if isSearching {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Searching...").foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if allResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass").font(.system(size: 48)).foregroundColor(.secondary)
                    Text(searchQuery.isEmpty ? "Enter a query to search" : "No results found")
                        .font(.headline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(displayedResults.compactMap { $0 as? DocumentMetaData }, id: \DocumentMetaData.id) { doc in
                            SearchResultCard(document: doc, onPreview: {
                                previewDocument = doc; previewWebResult = nil; showPreview = true
                            })
                        }
                        ForEach(displayedResults.compactMap { $0 as? WebSearchResult }, id: \WebSearchResult.id) { web in
                            WebResultCard(result: web, onPreview: {
                                previewWebResult = web; previewDocument = nil; showPreview = true
                            }, onImport: {
                                importWebResult(web)
                            })
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorSection(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
            Text(error).font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var allResults: [Any] {
        switch selectedTab {
        case .all:
            return libraryResults as [Any] + webResults as [Any]
        case .library:
            return libraryResults as [Any]
        case .web:
            return webResults as [Any]
        }
    }

    private var displayedResults: [Any] {
        allResults
    }

    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        error = nil
        Task {
            // Library search
            library.searchDocuments(query: searchQuery)
            await MainActor.run {
                libraryResults = library.searchResults
            }
            // Web search (stub: replace with real web search integration)
            let web = await performWebSearch(query: searchQuery)
            await MainActor.run {
                webResults = web
                isSearching = false
            }
        }
    }

    private func importWebResult(_ result: WebSearchResult) {
        // TODO: Implement real import logic
        // For now, just show a success message
        error = "Imported \(result.title) (stub)"
    }

    private func performWebSearch(query: String) async -> [WebSearchResult] {
        // TODO: Integrate real web search API (Gemini, Bing, etc.)
        // For now, return an empty array
        return []
    }
}

enum SearchTab: String, CaseIterable {
    case all, library, web
    var displayName: String {
        switch self {
        case .all: return "All"
        case .library: return "Library"
        case .web: return "Web"
        }
    }
}

struct WebSearchResult: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let url: String
    let snippet: String
}

struct SearchResultCard: View {
    let document: DocumentMetaData
    let onPreview: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(document.displayTitle).font(.headline)
                Spacer()
                Button(action: onPreview) {
                    Image(systemName: "eye").foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            Text(document.summary ?? "No summary available.")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            HStack(spacing: 8) {
                if !document.tagsArray.isEmpty {
                    ForEach(document.tagsArray.prefix(3), id: \.self) { tag in
                        Text(tag).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(Color.gray.opacity(0.2)).cornerRadius(8)
                    }
                }
                Spacer()
                Button(action: { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(document.sourceURL, forType: .string) }) {
                    Image(systemName: "link").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .onTapGesture { onPreview() }
    }
}

struct WebResultCard: View {
    let result: WebSearchResult
    let onPreview: () -> Void
    let onImport: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.title).font(.headline)
                Spacer()
                Button(action: onPreview) {
                    Image(systemName: "eye").foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                Button(action: onImport) {
                    Image(systemName: "square.and.arrow.down").foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
            Text(result.snippet)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            HStack(spacing: 8) {
                Text(result.url).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                Spacer()
                Button(action: { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(result.url, forType: .string) }) {
                    Image(systemName: "link").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .onTapGesture { onPreview() }
    }
}

struct WebPreviewView: View {
    let result: WebSearchResult
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(result.title).font(.title2).fontWeight(.bold)
            Text(result.url).font(.caption).foregroundColor(.secondary)
            Divider()
            Text(result.snippet).font(.body)
            Spacer()
            Button("Open in Browser") {
                if let url = URL(string: result.url) {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}
