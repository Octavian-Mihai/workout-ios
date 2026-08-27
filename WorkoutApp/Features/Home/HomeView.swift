import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Program.createdAt) private var programs: [Program]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]

    @State private var showSession = false
    @State private var sessionIsEmpty = false
    @State private var showTrends = false

    private var nextDay: ProgramDay? {
        NextWorkoutResolver.nextDay(activeProgram: programs.first(where: \.isActive), sessions: sessions)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    YearActivityGrid(sessions: sessions) { _ in
                        showTrends = true
                    }

                    if let program = programs.first(where: \.isActive), let day = nextDay {
                        NextWorkoutCard(program: program, day: day) {
                            sessionIsEmpty = false
                            showSession = true
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No active program")
                                .font(.headline)
                            Text("Create a program on the Workout tab and mark it active. You can still start an empty workout.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .opaqueCard()
                    }

                    Button {
                        sessionIsEmpty = true
                        showSession = true
                    } label: {
                        Label("Start empty workout", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(16)
            }
            .background(Theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Home")
            .navigationDestination(isPresented: $showSession) {
                LiveSessionView(
                    program: sessionIsEmpty ? nil : programs.first(where: \.isActive),
                    programDay: sessionIsEmpty ? nil : nextDay
                )
            }
            .navigationDestination(isPresented: $showTrends) {
                TrendsDetailView()
            }
        }
    }
}

struct NextWorkoutCard: View {
    let program: Program
    let day: ProgramDay
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next workout")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(day.name)
                        .font(.title2.weight(.bold))
                    Text(program.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if day.orderedExercises.isEmpty {
                Text("No exercises yet — add some in the program editor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(day.orderedExercises.prefix(6)) { exercise in
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            Text("\(exercise.targetSets)×\(exercise.targetReps)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                    }
                    if day.orderedExercises.count > 6 {
                        Text("+\(day.orderedExercises.count - 6) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button(action: onStart) {
                Text("Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .opaqueCard()
    }
}
