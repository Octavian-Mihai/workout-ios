import SwiftUI
import SwiftData

@main
struct WorkoutApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue
    @AppStorage(AccentTheme.customHexKey) private var customAccentHex = AccentTheme.defaultCustomHex

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(AccentTheme.color(accentName: accentName, customHex: customAccentHex))
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
