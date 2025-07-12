import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    
    var body: some View {
        ProjectCommandDashboardView(project: project)
    }
}

#Preview {
    ProjectDetailView(project: Project(
        id: UUID(),
        name: "Sample Project",
        description: "A demo project for preview.",
        requirements: ProjectRequirements(
            targetLanguages: [.swift],
            sdkFeatures: [.authentication],
            documentationRequirements: [.apiReference],
            testingRequirements: [.unit],
            performanceBenchmarks: [.latency]
        ),
        documents: [],
        agents: [],
        tasks: [],
        benchmarks: [],
        status: .inProgress,
        createdAt: Date(),
        estimatedCompletion: nil
    ))
} 