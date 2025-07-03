import SwiftUI
import UniformTypeIdentifiers

struct DocumentDetailView: View {
    let document: DocumentMetaData
    @State private var content: String = ""
    @State private var isLoading = true
    @State private var error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(document.displayTitle)
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Label(document.sourceURL, systemImage: "link")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(document.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(document.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Content
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading document...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Failed to load document")
                        .font(.headline)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        loadContent()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Raw markdown content - fully selectable and copyable
                        Text(content)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu("Export") {
                            Button("Copy to Clipboard") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(content, forType: .string)
                            }
                            
                            Button("Save As...") {
                                saveToFile()
                            }
                            
                            Button("Open in External Editor") {
                                openInExternalEditor()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadContent()
        }
    }
    
    private func loadContent() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let fileURL = URL(fileURLWithPath: document.filePath)
                let loadedContent = try DocumentStorage.shared.loadDocument(at: fileURL)
                
                await MainActor.run {
                    self.content = loadedContent
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveToFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "\(document.displayTitle).md"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to save file: \(error)")
                }
            }
        }
    }
    
    private func openInExternalEditor() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(document.displayTitle).md")
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(tempURL)
        } catch {
            print("Failed to open in external editor: \(error)")
        }
    }
}

#Preview {
    DocumentDetailView(
        document: DocumentMetaData(
            title: "Sample Document",
            sourceURL: "https://example.com",
            filePath: "/tmp/sample.md",
            fileSize: 1024
        )
    )
}
