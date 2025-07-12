import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(project.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(project.description)
                    .font(.body)
                HStack {
                    Text("Status: ")
                        .font(.headline)
                    Text(project.status.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Divider()
                Text("Agents")
                    .font(.title2)
                AgentDashboardView(agents: project.agents)
                Divider()
                Text("Tasks")
                    .font(.title2)
                TaskQueueView(tasks: project.tasks)
                Divider()
                Text("Benchmarks")
                    .font(.title2)
                ForEach(project.benchmarks, id: \ .id) { benchmark in
                    HStack {
                        Text(benchmark.criteria.rawValue.capitalized)
                        Spacer()
                        if let result = benchmark.result {
                            Text(result.passed ? "Passed" : "Failed")
                                .foregroundColor(result.passed ? .green : .red)
                        } else {
                            Text("Pending")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(project.name)
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