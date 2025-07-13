import SwiftUI

struct AgentPanelView: View {
    let agents: [DevelopmentAgent]
    @State private var showAssignTaskSheet = false
    @State private var selectedAgent: DevelopmentAgent?
    @State private var showMessageAlert = false
    @State private var showLogsAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agents")
                .font(.title2)
                .fontWeight(.semibold)
            if agents.isEmpty {
                Text("No agents assigned.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(agents, id: \ .id) { agent in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(agent.name)
                                .font(.headline)
                            Text(agent.specialization.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            selectedAgent = agent
                            showAssignTaskSheet = true
                        }) {
                            Label("Assign Task", systemImage: "plus.circle")
                        }
                        Button(action: {
                            selectedAgent = agent
                            showMessageAlert = true
                        }) {
                            Label("Message", systemImage: "bubble.left")
                        }
                        Button(action: {
                            selectedAgent = agent
                            showLogsAlert = true
                        }) {
                            Label("Logs", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                    Divider()
                }
            }
        }
        .padding(.vertical, 8)
        .glassy()
        .sheet(isPresented: $showAssignTaskSheet) {
            // TODO: Implement task picker and assignment logic
            Text("Assign a task to \(selectedAgent?.name ?? "") (Task picker UI goes here)")
                .padding()
        }
        .alert(isPresented: $showMessageAlert) {
            Alert(title: Text("Message Agent"), message: Text("Messaging \(selectedAgent?.name ?? "") (stub)"), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showLogsAlert) {
            Alert(title: Text("Agent Logs"), message: Text("Viewing logs for \(selectedAgent?.name ?? "") (stub)"), dismissButton: .default(Text("OK")))
        }
    }
} 