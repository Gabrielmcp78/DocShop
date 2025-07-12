import SwiftUI

struct ProjectCreationView: View {
    @Binding var isPresented: Bool
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedLanguages: Set<ProgrammingLanguage> = []
    @State private var selectedFeatures: Set<SDKFeature> = []
    @State private var selectedDocs: Set<DocumentationType> = []
    @State private var selectedTests: Set<TestingType> = []
    @State private var selectedBenchmarks: Set<BenchmarkCriteria> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Info")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                }
                Section(header: Text("Languages")) {
                    ForEach(ProgrammingLanguage.allCases, id: \ .self) { lang in
                        Toggle(lang.rawValue.capitalized, isOn: Binding(
                            get: { selectedLanguages.contains(lang) },
                            set: { isOn in
                                if isOn { selectedLanguages.insert(lang) } else { selectedLanguages.remove(lang) }
                            }
                        ))
                    }
                }
                Section(header: Text("SDK Features")) {
                    ForEach(SDKFeature.allCases, id: \ .self) { feature in
                        Toggle(feature.rawValue.capitalized, isOn: Binding(
                            get: { selectedFeatures.contains(feature) },
                            set: { isOn in
                                if isOn { selectedFeatures.insert(feature) } else { selectedFeatures.remove(feature) }
                            }
                        ))
                    }
                }
                Section(header: Text("Documentation")) {
                    ForEach(DocumentationType.allCases, id: \ .self) { doc in
                        Toggle(doc.rawValue.capitalized, isOn: Binding(
                            get: { selectedDocs.contains(doc) },
                            set: { isOn in
                                if isOn { selectedDocs.insert(doc) } else { selectedDocs.remove(doc) }
                            }
                        ))
                    }
                }
                Section(header: Text("Testing")) {
                    ForEach(TestingType.allCases, id: \ .self) { test in
                        Toggle(test.rawValue.capitalized, isOn: Binding(
                            get: { selectedTests.contains(test) },
                            set: { isOn in
                                if isOn { selectedTests.insert(test) } else { selectedTests.remove(test) }
                            }
                        ))
                    }
                }
                Section(header: Text("Benchmarks")) {
                    ForEach(BenchmarkCriteria.allCases, id: \ .self) { bench in
                        Toggle(bench.rawValue.capitalized, isOn: Binding(
                            get: { selectedBenchmarks.contains(bench) },
                            set: { isOn in
                                if isOn { selectedBenchmarks.insert(bench) } else { selectedBenchmarks.remove(bench) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        // TODO: Actually create the project and add to orchestrator
                        isPresented = false
                    }.disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ProjectCreationView(isPresented: .constant(true))
} 