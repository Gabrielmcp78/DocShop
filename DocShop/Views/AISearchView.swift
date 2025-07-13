import SwiftUI

struct AISearchView: View {
    @State private var searchQuery = ""
    @State private var searchSuggestions: [String] = []
    @State private var isGeneratingSuggestions = false
    @ObservedObject private var library = DocLibraryIndex.shared
    @ObservedObject private var aiAnalyzer = AIDocumentAnalyzer.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            
            searchSection
            
            if !searchSuggestions.isEmpty {
                suggestionsSection
            }
            
            if !aiAnalyzer.isAIAvailable {
                aiUnavailableSection
            }
        }
        .padding()
        .glassy()
        .navigationTitle("AI-Powered Search")
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("AI-Enhanced Search")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if aiAnalyzer.isAIAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            Text("Get intelligent search suggestions based on your documentation library")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Query")
                .font(.headline)
            
            HStack {
                TextField("What are you looking for?", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        generateSuggestions()
                    }
                
                Button(action: generateSuggestions) {
                    if isGeneratingSuggestions {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!aiAnalyzer.isAIAvailable || searchQuery.isEmpty || isGeneratingSuggestions)
            }
        }
    }
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Suggestions")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(searchSuggestions, id: \.self) { suggestion in
                    SuggestionRow(suggestion: suggestion) {
                        searchQuery = suggestion
                        generateSuggestions()
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var aiUnavailableSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("AI Features Unavailable")
                .font(.headline)
            
            VStack(spacing: 4) {
                Text("AI-powered search requires:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("• Apple Intelligence enabled")
                    Text("• Compatible device")
                    Text("• Sufficient battery")
                    Text("• Model downloaded")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.quaternarySystemFill))
        .cornerRadius(8)
    }
    
    private func generateSuggestions() {
        guard !searchQuery.isEmpty && aiAnalyzer.isAIAvailable else { return }
        
        isGeneratingSuggestions = true
        
        Task {
            let suggestions = await aiAnalyzer.generateSearchSuggestions(
                for: searchQuery,
                context: Array(library.documents.prefix(20))
            )
            
            await MainActor.run {
                searchSuggestions = suggestions
                isGeneratingSuggestions = false
            }
        }
    }
}

struct SuggestionRow: View {
    let suggestion: String
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb")
                .foregroundColor(.yellow)
                .font(.caption)
            
            Text(suggestion)
                .font(.body)
            
            Spacer()
            
            Button("Use") {
                onTap()
            }
            .buttonStyle(.bordered)
            .font(.caption)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.quaternarySystemFill))
        .cornerRadius(6)
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    AISearchView()
}