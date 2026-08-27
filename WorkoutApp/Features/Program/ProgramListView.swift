import SwiftUI
import SwiftData

struct ProgramListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Program.createdAt) private var programs: [Program]
    @State private var createdUUID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Programs")
                    .font(.headline)
                Spacer()
                Button {
                    createProgram()
                } label: {
                    Label("Create", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
            }

            if programs.isEmpty {
                Text("No programs yet. Create one and add rotating days. Only user-built programs are used — nothing is shipped as a starter split.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(programs) { program in
                    HStack(alignment: .center, spacing: 12) {
                        NavigationLink {
                            ProgramEditorView(program: program)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(program.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("\(program.orderedDays.count) day rotation")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Toggle("Active", isOn: Binding(
                            get: { program.isActive },
                            set: { newValue in setActive(program, newValue) }
                        ))
                        .labelsHidden()
                    }
                    .padding(12)
                    .opaqueCard()
                    .contextMenu {
                        Button("Set active") { setActive(program, true) }
                        Button("Delete", role: .destructive) {
                            modelContext.delete(program)
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { createdUUID != nil },
            set: { if !$0 { createdUUID = nil } }
        )) {
            if let uuid = createdUUID, let program = programs.first(where: { $0.uuid == uuid }) {
                ProgramEditorView(program: program)
            }
        }
    }

    private func createProgram() {
        if let current = programs.first(where: \.isActive) {
            current.isActive = false
        }
        let program = Program(name: "New program", isActive: true)
        modelContext.insert(program)
        try? modelContext.save()
        createdUUID = program.uuid
    }

    private func setActive(_ program: Program, _ isActive: Bool) {
        if isActive {
            for item in programs {
                item.isActive = (item.persistentModelID == program.persistentModelID)
            }
        } else {
            program.isActive = false
        }
        try? modelContext.save()
    }
}
