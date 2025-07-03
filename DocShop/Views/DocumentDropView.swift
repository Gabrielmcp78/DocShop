//
//  DocumentDropView.swift
//  DocShop
//
//  Created by Gabriel McPherson on 6/28/25.
//

import SwiftUI

struct DocumentDropView: View {
    @State private var urlString: String = ""
    @State private var urlStrings: String = ""
    @State private var showBatchImport = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showingError = false
    @State private var duplicateInfo: String?
    @State private var showingDuplicateInfo = false
    
    @ObservedObject private var processor = DocumentProcessor.shared
    @ObservedObject private var jsRenderer = JavaScriptRenderer.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📎 Import Documents")
                    .font(.headline)
                
                Spacer()
                
                Button("Batch Import") {
                    showBatchImport.toggle()
                }
                .buttonStyle(.bordered)
            }
            
            if !showBatchImport {
                // Single URL Import
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import Single Document")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Paste documentation URL...", text: $urlString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            importSingleDocument()
                        }

                    Button(action: importSingleDocument) {
                        Label("Import Document", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(urlString.isEmpty || processor.isProcessing)
                }
            } else {
                // Batch Import
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import Multiple Documents")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Enter one URL per line:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $urlStrings)
                        .frame(minHeight: 100)
                        .border(Color.gray.opacity(0.3))
                    
                    HStack {
                        Button("Import All") {
                            importMultipleDocuments()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(urlStrings.isEmpty || processor.isProcessing)
                        
                        Button("Clear") {
                            urlStrings = ""
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            // Processing Status
            if processor.isProcessing || jsRenderer.isRendering {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        if jsRenderer.isRendering {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rendering JavaScript content...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(jsRenderer.currentRenderingURL)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        } else {
                            Text(processor.currentStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ProgressView(value: jsRenderer.isRendering ? jsRenderer.renderingProgress : processor.processingProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
            
            // Processing Queue
            if !processor.processingQueue.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Processing Queue")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(processor.processingQueue.prefix(5)) { task in
                        HStack {
                            statusIcon(for: task.status)
                            Text(task.url.host ?? "Unknown")
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(statusText(for: task.status))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if processor.processingQueue.count > 5 {
                        Text("... and \(processor.processingQueue.count - 5) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Completed") {
                        processor.clearCompletedTasks()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
        .padding()
        .alert("Import Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(importError ?? "Unknown error occurred")
        }
        .alert("Duplicate Document", isPresented: $showingDuplicateInfo) {
            Button("Cancel") { }
            Button("Re-import Anyway") {
                Task {
                    do {
                        _ = try await processor.importDocument(from: urlString, forceReimport: true)
                        await MainActor.run {
                            urlString = ""
                        }
                    } catch {
                        await MainActor.run {
                            importError = error.localizedDescription
                            showingError = true
                        }
                    }
                }
            }
        } message: {
            Text(duplicateInfo ?? "Document already exists")
        }
    }
    
    private func importSingleDocument() {
        guard !urlString.isEmpty else { return }
        
        Task {
            do {
                _ = try await processor.importDocument(from: urlString)
                await MainActor.run {
                    urlString = ""
                }
            } catch {
                await MainActor.run {
                    if error.localizedDescription.contains("already exists") {
                        duplicateInfo = error.localizedDescription
                        showingDuplicateInfo = true
                    } else {
                        importError = error.localizedDescription
                        showingError = true
                    }
                }
            }
        }
    }
    
    private func importMultipleDocuments() {
        let urls = urlStrings
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !urls.isEmpty else { return }
        
        Task {
            await processor.importDocuments(from: urls)
            await MainActor.run {
                urlStrings = ""
            }
        }
    }
    
    private func statusIcon(for status: ProcessingStatus) -> some View {
        Group {
            switch status {
            case .pending:
                Image(systemName: "clock")
                    .foregroundColor(.orange)
            case .processing:
                ProgressView()
                    .scaleEffect(0.6)
            case .completed:
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func statusText(for status: ProcessingStatus) -> String {
        switch status {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .completed:
            return "Complete"
        case .failed(let error):
            return "Failed: \(error.localizedDescription)"
        }
    }
}
