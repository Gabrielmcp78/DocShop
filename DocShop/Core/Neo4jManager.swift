import Foundation

class Neo4jManager {
    static let shared = Neo4jManager()
    private let baseURL = URL(string: "http://localhost:7474/db/docshopgraphdb/tx/commit")!
    private let username = "neo4j"
    private let password = "NowVoyager2025!"
    private init() {}
    
    // MARK: - Node Creation
    func createDocumentNode(_ document: IngestedDocument, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "CREATE (d:Document {id: $id, title: $title, author: $author, type: $type, tags: $tags, importedAt: $importedAt})"
        let params: [String: Any] = [
            "id": document.id.uuidString,
            "title": document.title,
            "author": document.author,
            "type": document.type.rawValue,
            "tags": document.tags,
            "importedAt": ISO8601DateFormatter().string(from: document.importedAt)
        ]
        runCypher(cypher, params: params, completion: completion)
    }
    
    func createChunkNode(_ chunk: DocumentChunk, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "CREATE (c:Chunk {id: $id, documentID: $documentID, type: $type, content: $content, position: $position, metadata: $metadata, tags: $tags})"
        let params: [String: Any] = [
            "id": chunk.id.uuidString,
            "documentID": chunk.documentID.uuidString,
            "type": chunk.type.rawValue,
            "content": chunk.content,
            "position": chunk.position,
            "metadata": chunk.metadata,
            "tags": chunk.tags
        ]
        runCypher(cypher, params: params, completion: completion)
    }
    
    // MARK: - Relationship Creation
    func createHasChunkRelationship(documentID: UUID, chunkID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (d:Document {id: $docID}), (c:Chunk {id: $chunkID}) CREATE (d)-[:HAS_CHUNK]->(c)"
        let params: [String: Any] = [
            "docID": documentID.uuidString,
            "chunkID": chunkID.uuidString
        ]
        runCypher(cypher, params: params, completion: completion)
    }
    
    func createLinkedToRelationship(chunkID1: UUID, chunkID2: UUID, type: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (c1:Chunk {id: $id1}), (c2:Chunk {id: $id2}) CREATE (c1)-[:LINKED_TO {type: $type}]->(c2)"
        let params: [String: Any] = [
            "id1": chunkID1.uuidString,
            "id2": chunkID2.uuidString,
            "type": type
        ]
        runCypher(cypher, params: params, completion: completion)
    }
    
    func createSatisfiesRelationship(chunkID: UUID, requirementID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (c:Chunk {id: $chunkID}), (r:Requirement {id: $reqID}) CREATE (c)-[:SATISFIES]->(r)"
        let params: [String: Any] = [
            "chunkID": chunkID.uuidString,
            "reqID": requirementID.uuidString
        ]
        runCypher(cypher, params: params, completion: completion)
    }
    
    // MARK: - Node/Relationship Update & Delete
    func updateNodeLabel(nodeID: UUID, label: String, value: String, nodeType: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (n: {nodeType} {id: $id}) SET n. {label} = $value"
        let params: [String: Any] = [
            "id": nodeID.uuidString,
            "value": value
        ]
        let statement = cypher.replacingOccurrences(of: "\u007f{nodeType}", with: nodeType).replacingOccurrences(of: "\u007f{label}", with: label)
        runCypher(statement, params: params, completion: completion)
    }
    
    func deleteNode(nodeID: UUID, nodeType: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (n: {nodeType} {id: $id}) DETACH DELETE n"
        let statement = cypher.replacingOccurrences(of: "\u007f{nodeType}", with: nodeType)
        let params: [String: Any] = ["id": nodeID.uuidString]
        runCypher(statement, params: params, completion: completion)
    }
    
    func deleteRelationship(fromID: UUID, toID: UUID, relType: String, fromType: String, toType: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (a: {fromType} {id: $fromID})-[r: {relType}]->(b: {toType} {id: $toID}) DELETE r"
        let statement = cypher
            .replacingOccurrences(of: "\u007f{fromType}", with: fromType)
            .replacingOccurrences(of: "\u007f{toType}", with: toType)
            .replacingOccurrences(of: "\u007f{relType}", with: relType)
        let params: [String: Any] = ["fromID": fromID.uuidString, "toID": toID.uuidString]
        runCypher(statement, params: params, completion: completion)
    }
    
    // MARK: - Search & Query
    func searchChunksByTag(tag: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "MATCH (c:Chunk) WHERE $tag IN c.tags RETURN c"
        let params: [String: Any] = ["tag": tag]
        runCypherQuery(cypher, params: params, completion: completion)
    }
    
    func fullTextSearchChunks(query: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "CALL db.index.fulltext.queryNodes('chunkContentIndex', $query) YIELD node RETURN node"
        let params: [String: Any] = ["query": query]
        runCypherQuery(cypher, params: params, completion: completion)
    }
    
    func traceabilityMatrix(requirementID: UUID, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "MATCH (r:Requirement {id: $reqID})<-[:SATISFIES]-(c:Chunk) RETURN c"
        let params: [String: Any] = ["reqID": requirementID.uuidString]
        runCypherQuery(cypher, params: params, completion: completion)
    }
    
    func getRelatedChunks(chunkID: UUID, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "MATCH (c:Chunk {id: $id})-[:LINKED_TO]->(related:Chunk) RETURN related"
        let params: [String: Any] = ["id": chunkID.uuidString]
        runCypherQuery(cypher, params: params, completion: completion)
    }
    
    // MARK: - Cypher Execution
    private func runCypher(_ cypher: String, params: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        let payload: [String: Any] = [
            "statements": [[
                "statement": cypher,
                "parameters": params
            ]]
        ]
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            completion(.failure(NSError(domain: "Neo4jManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Encoding error"])))
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Neo4jManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errors = json["errors"] as? [[String: Any]],
               !errors.isEmpty {
                let message = errors.first?["message"] as? String ?? "Unknown Neo4j error"
                completion(.failure(NSError(domain: "Neo4jManager", code: 2, userInfo: [NSLocalizedDescriptionKey: message])))
                return
            }
            completion(.success(()))
        }
        task.resume()
    }
    
    private func runCypherQuery(_ cypher: String, params: [String: Any], completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let payload: [String: Any] = [
            "statements": [[
                "statement": cypher,
                "parameters": params
            ]]
        ]
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            completion(.failure(NSError(domain: "Neo4jManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Encoding error"])))
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Neo4jManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let dataArr = results.first?["data"] as? [[String: Any]] {
                completion(.success(dataArr))
                return
            }
            completion(.failure(NSError(domain: "Neo4jManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])) )
        }
        task.resume()
    }
} 