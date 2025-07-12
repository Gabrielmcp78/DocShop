import Foundation

struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var requirements: ProjectRequirements
    var documents: [DocumentMetaData]
    var agents: [UUID] // Store agent IDs
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

struct ProjectRequirements: Codable, Hashable {
    var targetLanguages: [ProgrammingLanguage]
    var sdkFeatures: [SDKFeature]
    var documentationRequirements: [DocumentationType]
    var testingRequirements: [TestingType]
    var performanceBenchmarks: [BenchmarkCriteria]
    var projectName: String = ""
    var projectDescription: String = ""
}

struct ProjectTask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var status: ProjectTaskStatus
    var priority: TaskPriority
    var assignedAgentID: UUID? // Store agent ID for Codable compliance
    var benchmarks: [Benchmark]
    var context: TaskContext
    
    static func generateInitialTasks(for project: Project) -> [ProjectTask] {
        // TODO: Generate tasks based on requirements and docs
        return []
    }
}

enum ProjectTaskStatus: String, Codable, Hashable, CaseIterable {
    case pending, assigned, inProgress, completed, blocked, error
}

struct Benchmark: Identifiable, Codable, Hashable {
    let id: UUID
    let criteria: BenchmarkCriteria
    var result: BenchmarkResult?
}

struct BenchmarkResult: Codable, Hashable {
    let passed: Bool
    let details: String
}

enum ProjectStatus: String, Codable, Hashable {
    case initialized, active, paused, completed, error
}

enum TaskPriority: String, Codable, Hashable, CaseIterable {
    case low, medium, high, critical
}

struct TaskContext: Codable, Hashable {
    let info: String // Placeholder for real context data
}

enum SDKFeature: String, Codable, Hashable, CaseIterable {
    case authentication, errorHandling, logging, asyncSupport, customEndpoints, codeExamples
}

enum DocumentationType: String, Codable, Hashable, CaseIterable {
    case apiReference, gettingStarted, tutorials, faq, changelog, architecture
}

enum TestingType: String, Codable, Hashable, CaseIterable {
    case unit, integration, e2e, performance, security
}

enum BenchmarkCriteria: String, Codable, Hashable, CaseIterable {
    case latency, throughput, correctness, codeQuality, docCompleteness, apiCompliance
} 
