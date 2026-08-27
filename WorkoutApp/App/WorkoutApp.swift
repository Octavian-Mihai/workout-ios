import SwiftUI
import SwiftData

@main
struct WorkoutApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(AccentOption(rawValue: accentName)?.color ?? AccentOption.orange.color)
                .preferredColorScheme(AppearanceMode(rawValue: appearanceMode)?.colorScheme)
        }
        .modelContainer(for: [
            Program.self,
            ProgramDay.self,
            DayExercise.self,
            WorkoutSession.self,
            SetLog.self,
            BodyWeightEntry.self
        ])
    }
}
