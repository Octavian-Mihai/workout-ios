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
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue
    @AppStorage(AccentTheme.customHexKey) private var customAccentHex = AccentTheme.defaultCustomHex

    private var tintColor: Color {
        if ScreenshotDefaults.isActive {
            return AccentOption.red.color
        }
        return AccentTheme.color(accentName: accentName, customHex: customAccentHex)
    }

    private var colorScheme: ColorScheme? {
        if ScreenshotDefaults.isActive {
            return .dark
        }
        return AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(tintColor)
                .preferredColorScheme(colorScheme)
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
