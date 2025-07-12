//
//  DocumentDropView.swift
//  DocShop
//
//  Created by Gabriel McPherson on 6/28/25.
//

import SwiftUI

struct DocumentDropView: View {
    @State private var ingestedDocuments: [IngestedDocument] = []
    @State private var isImporting: Bool = false
    @State private var importError: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Drop files here or click to upload")
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }
                .onTapGesture {
                    isImporting = true
                }
            if let error = importError {
                Text(error)
                    .foregroundColor(.red)
            }
            List(ingestedDocuments) { doc in
                VStack(alignment: .leading) {
                    Text(doc.title)
                        .font(.headline)
                    Text(doc.originalFilename)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Type: \(doc.type.rawValue.capitalized)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("Imported: \(doc.importedAt.formatted())")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                Task {
                    for url in urls {
                        do {
                            let doc = try await DocumentIngestionManager.shared.ingestFile(at: url)
                            ingestedDocuments.append(doc)
                        } catch {
                            importError = error.localizedDescription
                        }
                    }
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    Task {
                        do {
                            let doc = try await DocumentIngestionManager.shared.ingestFile(at: url)
                            await MainActor.run {
                                ingestedDocuments.append(doc)
                            }
                        } catch {
                            await MainActor.run {
                                importError = error.localizedDescription
                            }
                        }
                    }
                }
            }
        }
        return true
    }
}
