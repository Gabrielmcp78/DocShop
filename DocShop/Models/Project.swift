import Foundation

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var requirements: ProjectRequirements
    var documents: [DocumentMetaData]
    var agents: [DevelopmentAgent]
    var tasks: [ProjectTask]
    var benchmarks: [Benchmark]
    var status: ProjectStatus
    var createdAt: Date
    var estimatedCompletion: Date?

    init(name: String, description: String, requirements: ProjectRequirements, documents: [DocumentMetaData]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.requirements = requirements
        self.documents = documents
        self.agents = []
        self.tasks = []
        self.benchmarks = []
        self.status = .initialized
        self.createdAt = Date()
        self.estimatedCompletion = nil
    }
}

struct ProjectRequirements: Codable {
    var targetLanguages: [ProgrammingLanguage]
    var sdkFeatures: [SDKFeature]
    var documentationRequirements: [DocumentationType]
    var testingRequirements: [TestingType]
    var performanceBenchmarks: [BenchmarkCriteria]
}

struct ProjectTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var status: ProjectTaskStatus
    var priority: TaskPriority
    var assignedAgent: DevelopmentAgent?
    var dependencies: [UUID]
    var estimatedDuration: TimeInterval
    var actualDuration: TimeInterval?
    var benchmarks: [Benchmark]
    var context: TaskContext

    static func generateInitialTasks(for project: Project) -> [ProjectTask] {
        // TODO: Generate tasks based on requirements and docs
        return []
    }
}

struct Benchmark: Codable {
    var id: UUID
    var criteria: BenchmarkCriteria
    var result: BenchmarkResult?
}

struct TaskContext: Codable {
    var keyInfo: [String]
    var relevantDocs: [DocumentMetaData]
    var requirements: ProjectRequirements
}

enum ProjectStatus: String, Codable {
    case notStarted, inProgress, completed, blocked, cancelled
}

enum ProjectTaskStatus: String, Codable, CaseIterable {
    case pending, assigned, inProgress, completed, blocked, error
}

enum TaskPriority: String, Codable, CaseIterable {
    case low, medium, high, critical
}

enum SDKFeature: String, Codable, CaseIterable {
    case authentication, errorHandling, logging, asyncSupport, customEndpoints, codeExamples
}

enum DocumentationType: String, Codable, CaseIterable {
    case apiReference, gettingStarted, tutorials, faq, changelog, architecture
}

enum TestingType: String, Codable, CaseIterable {
    case unit, integration, e2e, performance, security
}

enum BenchmarkCriteria: String, Codable, CaseIterable {
    case latency, throughput, correctness, codeQuality, docCompleteness, apiCompliance
} 