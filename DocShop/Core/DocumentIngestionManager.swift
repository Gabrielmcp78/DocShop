import Foundation
import PDFKit
// import Down, SwiftSoup, Yams, Vision, etc. as needed

class DocumentIngestionManager {
    static let shared = DocumentIngestionManager()
    private init() {}
    
    // MARK: - Entry Points
    func ingestFile(at url: URL) async throws -> IngestedDocument {
        let type = detectType(for: url)
        switch type {
        case .pdf:
            return try await ingestPDF(at: url)
        case .markdown:
            return try await ingestMarkdown(at: url)
        case .html:
            return try await ingestHTML(at: url)
        case .word:
            return try await ingestWord(at: url)
        case .plaintext:
            return try await ingestPlaintext(at: url)
        case .code:
            return try await ingestCode(at: url)
        case .openapi:
            return try await ingestOpenAPI(at: url)
        case .image:
            return try await ingestImage(at: url)
        case .unknown:
            throw NSError(domain: "DocShop", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown document type"])
        }
    }
    
    func ingestFromURL(_ url: URL) async throws -> IngestedDocument {
        // Download file from URL, then ingest
        // let data = try Data(contentsOf: url)
        // Save to temp file, then call ingestFile
        throw NSError(domain: "DocShop", code: 2, userInfo: [NSLocalizedDescriptionKey: "Not implemented"] )
    }
    
    func ingestFromGitRepo(_ repoURL: URL) async throws -> [IngestedDocument] {
        // Clone repo (shell out to git), enumerate files, call ingestFile for each
        throw NSError(domain: "DocShop", code: 3, userInfo: [NSLocalizedDescriptionKey: "Not implemented"] )
    }
    
    func ingestFromCloud(_ cloudURL: URL) async throws -> [IngestedDocument] {
        // Download from cloud, call ingestFile
        throw NSError(domain: "DocShop", code: 4, userInfo: [NSLocalizedDescriptionKey: "Not implemented"] )
    }
    
    // MARK: - Format-Specific Ingestion (with Neo4j persistence)
    private func ingestPDF(at url: URL) async throws -> IngestedDocument {
        guard let pdfDoc = PDFDocument(url: url) else {
            throw NSError(domain: "DocShop", code: 10, userInfo: [NSLocalizedDescriptionKey: "Failed to parse PDF"])
        }
        let title = pdfDoc.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url.lastPathComponent
        let author = pdfDoc.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown"
        let tags: [String] = [] // TODO: Extract tags from PDF metadata
        let doc = IngestedDocument(id: UUID(), type: .pdf, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        // Extract text for chunking
        let text = (0..<pdfDoc.pageCount).compactMap { pdfDoc.page(at: $0)?.string }.joined(separator: "\n\n")
        let chunks = DocumentChunker.chunkPDF(document: doc, text: text)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestMarkdown(at url: URL) async throws -> IngestedDocument {
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8) ?? ""
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let tags: [String] = [] // TODO: Extract tags from frontmatter or content
        let doc = IngestedDocument(id: UUID(), type: .markdown, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkMarkdown(document: doc, content: content)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestHTML(at url: URL) async throws -> IngestedDocument {
        let data = try Data(contentsOf: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let title = "TODO: Extract from <title> tag"
        let author = "Unknown"
        let tags: [String] = [] // TODO: Extract meta tags
        let doc = IngestedDocument(id: UUID(), type: .html, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkHTML(document: doc, html: html)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestWord(at url: URL) async throws -> IngestedDocument {
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let tags: [String] = []
        let doc = IngestedDocument(id: UUID(), type: .word, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        // TODO: Extract text and chunk
        let chunks: [DocumentChunk] = []
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestPlaintext(at url: URL) async throws -> IngestedDocument {
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8) ?? ""
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let tags: [String] = []
        let doc = IngestedDocument(id: UUID(), type: .plaintext, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkPlaintext(document: doc, content: content)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestCode(at url: URL) async throws -> IngestedDocument {
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8) ?? ""
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let tags: [String] = [] // TODO: Language detection, code tags
        let doc = IngestedDocument(id: UUID(), type: .code, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkCode(document: doc, content: content)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestOpenAPI(at url: URL) async throws -> IngestedDocument {
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let tags: [String] = []
        let doc = IngestedDocument(id: UUID(), type: .openapi, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        // TODO: Parse OpenAPI and chunk
        let chunks: [DocumentChunk] = []
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestImage(at url: URL) async throws -> IngestedDocument {
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let tags: [String] = []
        let doc = IngestedDocument(id: UUID(), type: .image, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        // TODO: OCR, chunking, and metadata extraction
        let chunks: [DocumentChunk] = []
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    // MARK: - Neo4j Persistence
    private func persistDocumentAndChunksToNeo4j(document: IngestedDocument, chunks: [DocumentChunk]) {
        Neo4jManager.shared.createDocumentNode(document) { result in
            switch result {
            case .success():
                for chunk in chunks {
                    Task {
                        do {
                            // Generate embedding
                            let embedding = try await GeminiAPI.getEmbedding(for: chunk.content)
                            // Generate tags
                            let tagsPrompt = "Analyze the following text and provide 5 relevant tags as a comma-separated list. Text: \(chunk.content)"
                            let tagsString = try await GeminiAPI.generateText(prompt: tagsPrompt, temperature: 0.2, maxTokens: 64)
                            let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            // Create chunk node with embedding and tags
                            var chunkWithAI = chunk
                            // You may want to add embedding/tags to the chunk struct and Neo4j schema
                            // For now, store tags in tags property, embedding in metadata
                            chunkWithAI.tags = tags
                            chunkWithAI.metadata["embedding"] = embedding.map { String($0) }.joined(separator: ",")
                            Neo4jManager.shared.createChunkNode(chunkWithAI) { chunkResult in
                                switch chunkResult {
                                case .success():
                                    Neo4jManager.shared.createHasChunkRelationship(documentID: document.id, chunkID: chunk.id) { relResult in
                                        if case .failure(let error) = relResult {
                                            print("Failed to create HAS_CHUNK: \(error)")
                                        }
                                    }
                                case .failure(let error):
                                    print("Failed to create chunk node: \(error)")
                                }
                            }
                        } catch {
                            print("AI enrichment failed for chunk: \(error)")
                        }
                    }
                }
            case .failure(let error):
                print("Failed to create document node: \(error)")
            }
        }
    }
    
    // MARK: - Type Detection
    private func detectType(for url: URL) -> DocumentType {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return .pdf
        case "md", "markdown": return .markdown
        case "html", "htm": return .html
        case "docx", "doc": return .word
        case "txt": return .plaintext
        case "swift", "py", "js", "java", "kt", "cpp", "c", "h": return .code
        case "yaml", "yml", "json": return .openapi
        case "png", "jpg", "jpeg", "gif", "bmp", "tiff": return .image
        default: return .unknown
        }
    }
} 
