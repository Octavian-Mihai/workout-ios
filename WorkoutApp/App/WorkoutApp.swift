import SwiftUI
import SwiftData

private enum ScreenshotDefaults {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITEST_SCREENSHOTS")
            || ProcessInfo.processInfo.environment["UITEST_SCREENSHOTS"] == "1"
    }

    static func apply() {
        guard isActive else { return }
        UserDefaults.standard.set(AppearanceMode.dark.rawValue, forKey: "appearanceMode")
        UserDefaults.standard.set(AccentOption.red.rawValue, forKey: "accentName")
        UserDefaults.standard.synchronize()
    }
}

private let _applyScreenshotDefaults: Void = ScreenshotDefaults.apply()

@main
struct WorkoutApp: App {
    @State private var appTheme = AppTheme()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appTheme)
                .tint(ScreenshotDefaults.isActive ? AccentOption.red.color : appTheme.accent)
                .preferredColorScheme(ScreenshotDefaults.isActive ? .dark : appTheme.resolvedColorScheme)
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
