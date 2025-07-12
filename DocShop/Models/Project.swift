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
    var assignedAgentID: UUID?
    var status: TaskStatus
    var priority: TaskPriority
    var dependencies: [UUID]
    var estimatedDuration: TimeInterval
    var actualDuration: TimeInterval?
    var benchmarks: [Benchmark]
    var context: TaskContext
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

enum TaskStatus: String, Codable {
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