import Foundation

class AgentRegistry {
    static let shared = AgentRegistry()
    private var agents: [DevelopmentAgent] = []
    
    private init() {}
    
    func register(agent: DevelopmentAgent) {
        agents.append(agent)
    }
    
    func matchAgents(for requirements: ProjectRequirements) -> [DevelopmentAgent] {
        // TODO: Match agents by specialization, platform, and capabilities
        return agents.filter { agent in
            requirements.targetLanguages.contains(where: { agent.capabilities.map { $0.rawValue }.contains($0.rawValue) })
        }
    }
    
    func allAgents() -> [DevelopmentAgent] {
        return agents
    }
} 