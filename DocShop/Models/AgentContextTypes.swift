import Foundation

struct ProjectContext: Codable {
    let projectID: UUID
    let keyInfo: [String]
    let requirements: ProjectRequirements
}

struct AgentContext: Codable {
    let agentID: UUID
    let currentTask: ProjectTask?
    let relevantDocs: [DocumentMetaData]
    let requirements: ProjectRequirements
}

enum ContextAlignment: String, Codable {
    case aligned, drifting, lost
} 