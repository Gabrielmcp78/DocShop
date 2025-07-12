import Foundation

class ContextManager: ObservableObject {
    private var projectContexts: [UUID: ProjectContext] = [:]
    private var agentContexts: [UUID: AgentContext] = [:]
    
    func createProjectContext(_ project: Project) async -> ProjectContext {
        // TODO: Extract info from docs, requirements, relationships
        fatalError("Not implemented")
    }
    
    func injectContext(to agent: DevelopmentAgent, context: AgentContext) async {
        // TODO: Send focused context to agent, update understanding
        fatalError("Not implemented")
    }
    
    func monitorContextAlignment(_ agent: DevelopmentAgent) async -> ContextAlignment {
        // TODO: Check if agent is following context, detect drift
        fatalError("Not implemented")
    }
}

// MARK: - Supporting Types

struct ProjectContext {
    let projectID: UUID
    let keyInfo: [String]
    let requirements: ProjectRequirements
}

struct AgentContext {
    let agentID: UUID
    let currentTask: ProjectTask?
    let relevantDocs: [DocumentMetaData]
    let requirements: ProjectRequirements
}

enum ContextAlignment: String, Codable {
    case aligned, drifting, lost
} 