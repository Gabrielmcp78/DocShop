import Foundation

protocol AgentExecutor {
    func execute(task: ProjectTask, for agent: DevelopmentAgent, completion: @escaping (TaskResult) -> Void)
}

class LocalAgentExecutor: AgentExecutor {
    func execute(task: ProjectTask, for agent: DevelopmentAgent, completion: @escaping (TaskResult) -> Void) {
        // TODO: Implement local execution logic
        completion(TaskResult(success: true, output: "Local execution stub", error: nil))
    }
}

class RemoteAgentExecutor: AgentExecutor {
    func execute(task: ProjectTask, for agent: DevelopmentAgent, completion: @escaping (TaskResult) -> Void) {
        // TODO: Implement remote (REST/gRPC) execution logic
        completion(TaskResult(success: true, output: "Remote execution stub", error: nil))
    }
} 