import Foundation
import Combine
// Import context types from Models

class ContextManager: ObservableObject {
    private var projectContexts: [UUID: ProjectContext] = [:]
    private var agentContexts: [UUID: AgentContext] = [:]
    
    func createProjectContext(_ project: Project) async -> ProjectContext {
        // Extract info from docs, requirements, relationships
        let docSummaries = project.documents.map { $0.summary }
        let requirements = project.requirements
        let relationships = project.relatedProjects.map { $0.id }
        let context = ProjectContext(projectID: project.id, documentSummaries: docSummaries, requirements: requirements, relatedProjectIDs: relationships)
        DispatchQueue.main.async {
            self.projectContexts[project.id] = context
        }
        return context
    }
    
    func injectContext(to agent: DevelopmentAgent, context: AgentContext) async {
        // Send focused context to agent, update understanding
        agent.receiveContext(context)
        DispatchQueue.main.async {
            self.agentContexts[agent.id] = context
        }
    }
    
    func monitorContextAlignment(_ agent: DevelopmentAgent) async -> ContextAlignment {
        // Simulate context alignment check (e.g., compare agent state to context)
        await Task.sleep(200_000_000) // 0.2s
        let aligned = Bool.random()
        let details = aligned ? "Agent is following context." : "Agent is drifting from context."
        return ContextAlignment(isAligned: aligned, details: details)
    }
} 

struct ProjectContext: Codable {
    let projectID: UUID
    let documentSummaries: [String]
    let requirements: [String]
    let relatedProjectIDs: [UUID]
}

struct AgentContext: Codable {
    let agentID: UUID
    let focus: String
    let knowledge: [String]
}

struct ContextAlignment: Codable {
    let isAligned: Bool
    let details: String
} 
