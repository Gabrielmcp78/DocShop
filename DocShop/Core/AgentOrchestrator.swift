import Foundation
import Combine

@MainActor
class AgentOrchestrator: ObservableObject {
    static let shared = AgentOrchestrator()
    
    @Published var activeAgents: [DevelopmentAgent] = []
    @Published var projectQueue: [ProjectTask] = []
    @Published var systemStatus: OrchestrationStatus = .idle
    
    private let taskDistributor = TaskDistributor()
    private let progressTracker = ProgressTracker()
    private let contextManager = ContextManager()
    private let benchmarkEngine = BenchmarkEngine()
    
    private init() {}
    
    func createProject(from documents: [DocumentMetaData], requirements: ProjectRequirements) async -> Project {
        let project = Project(
            id: UUID(),
            name: requirements.projectName,
            description: requirements.projectDescription,
            requirements: requirements,
            documents: documents,
            agents: [],
            tasks: [],
            benchmarks: [],
            status: .initialized,
            createdAt: Date(),
            estimatedCompletion: nil
        )
        // Register and assign agents
        let agents = AgentRegistry.shared.matchAgents(for: requirements)
        var projectWithAgents = project
        projectWithAgents.agents = agents
        // Generate initial tasks
        let tasks = ProjectTask.generateInitialTasks(for: projectWithAgents)
        projectWithAgents.tasks = tasks
        // Assign tasks to agents
        TaskDistributor().distribute(tasks: tasks, to: agents)
        // Add to queue
        projectQueue.append(projectWithAgents)
        return projectWithAgents
    }
    
    func assignTaskToAgent(_ task: ProjectTask, agent: DevelopmentAgent) async {
        // TODO: Assign development tasks to agents, inject context, start progress monitoring
        fatalError("Not implemented")
    }
    
    func monitorAgentProgress() async {
        // TODO: Real-time progress tracking, context reinjection, benchmark validation
        fatalError("Not implemented")
    }

    func assign(task: ProjectTask, to agent: DevelopmentAgent) {
        // Find the project and update the task's assigned agent
        for (projectIndex, var project) in projectQueue.enumerated() {
            if let taskIndex = project.tasks.firstIndex(where: { $0.id == task.id }) {
                project.tasks[taskIndex].assignedAgent = agent
                projectQueue[projectIndex] = project
                break
            }
        }
    }

    func updateStatus(for task: ProjectTask, to status: ProjectTaskStatus) {
        for (projectIndex, var project) in projectQueue.enumerated() {
            if let taskIndex = project.tasks.firstIndex(where: { $0.id == task.id }) {
                project.tasks[taskIndex].status = status
                projectQueue[projectIndex] = project
                break
            }
        }
    }
}

// MARK: - Supporting Types

enum OrchestrationStatus: String, Codable {
    case idle, running, paused, error
} 