import SwiftUI
import UIKit

enum AccentOption: String, CaseIterable, Identifiable {
    case orange, blue, teal, green, purple, indigo, red

    var id: String { rawValue }

    /// Five presets shown in Settings (columns 1–4 and 6; column 5 is custom).
    static let presets: [AccentOption] = [.orange, .blue, .green, .purple, .red]

    static func resolved(rawValue: String) -> AccentOption {
        if rawValue == "coral" { return .orange }
        return AccentOption(rawValue: rawValue) ?? .orange
    }

    var title: String {
        switch self {
        case .orange: return "Orange"
        case .blue: return "Blue"
        case .teal: return "Teal"
        case .green: return "Green"
        case .purple: return "Purple"
        case .indigo: return "Indigo"
        case .red: return "Red"
        }
    }

    var color: Color {
        switch self {
        case .orange: return Color(red: 0.98, green: 0.42, blue: 0.18)
        case .blue: return Color(red: 0.20, green: 0.48, blue: 0.96)
        case .teal: return Color(red: 0.12, green: 0.65, blue: 0.62)
        case .green: return Color(red: 0.22, green: 0.70, blue: 0.38)
        case .purple: return Color(red: 0.56, green: 0.35, blue: 0.90)
        case .indigo: return Color(red: 0.35, green: 0.40, blue: 0.85)
        case .red: return Color(red: 0.90, green: 0.22, blue: 0.25)
        }
    }
}

enum AccentTheme {
    static let customName = "custom"
    static let customHexKey = "customAccentHex"
    static let defaultCustomHex = "FA6B2E"

    static func color(accentName: String, customHex: String) -> Color {
        if accentName == customName {
            return Color(hex: customHex.isEmpty ? defaultCustomHex : customHex) ?? AccentOption.orange.color
        }
        return AccentOption.resolved(rawValue: accentName).color
    }

    static func isCustom(_ accentName: String) -> Bool {
        accentName == customName
    }
}

enum BackgroundOption: String, CaseIterable, Identifiable {
    case system, charcoal, navy, warmGray, forest, slate

    var id: String { rawValue }

    static let presets: [BackgroundOption] = [.system, .charcoal, .navy, .warmGray, .forest, .slate]

    static func resolved(rawValue: String) -> BackgroundOption? {
        BackgroundOption(rawValue: rawValue)
    }

    var title: String {
        switch self {
        case .system: return "System"
        case .charcoal: return "Charcoal"
        case .navy: return "Navy"
        case .warmGray: return "Warm Gray"
        case .forest: return "Forest"
        case .slate: return "Slate"
        }
    }

    var color: Color {
        switch self {
        case .system: return Color(.systemGroupedBackground)
        case .charcoal: return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .navy: return Color(red: 0.07, green: 0.12, blue: 0.22)
        case .warmGray: return Color(red: 0.20, green: 0.18, blue: 0.16)
        case .forest: return Color(red: 0.10, green: 0.18, blue: 0.12)
        case .slate: return Color(red: 0.14, green: 0.18, blue: 0.24)
        }
    }
}

enum BackgroundTheme {
    static let customName = "custom"
    static let systemName = "system"
    static let backgroundNameKey = "backgroundName"
    static let customHexKey = "customBackgroundHex"
    static let defaultCustomHex = "1C1C1E"

    static func baseColor(backgroundName: String, customHex: String) -> Color? {
        if backgroundName == systemName { return nil }
        if backgroundName == customName {
            return Color(hex: customHex.isEmpty ? defaultCustomHex : customHex)
                ?? Color(hex: defaultCustomHex)!
        }
        return BackgroundOption.resolved(rawValue: backgroundName)?.color
    }

    static func isSystem(_ backgroundName: String) -> Bool {
        backgroundName == systemName
    }

    static func isCustom(_ backgroundName: String) -> Bool {
        backgroundName == customName
    }
}

extension Color {
    init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    var relativeLuminance: Double {
        let ui = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)
    }

    func blended(with other: Color, amount: Double) -> Color {
        let ui1 = UIColor(self)
        let ui2 = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        ui1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        ui2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = CGFloat(min(max(amount, 0), 1))
        return Color(
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t)
        )
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb

    var id: String { rawValue }

    var title: String { rawValue.uppercased() }

    func fromKg(_ kg: Double) -> Double {
        self == .kg ? kg : kg * 2.2046226218
    }

    func toKg(_ value: Double) -> Double {
        self == .kg ? value : value / 2.2046226218
    }

    func format(_ kg: Double, decimals: Int = 2) -> String {
        "\(formatNumber(kg, decimals: decimals)) \(rawValue)"
    }

    func formatNumber(_ kg: Double, decimals: Int = 2) -> String {
        Formatters.trimmedNumber(fromKg(kg), decimals: decimals)
    }
}

enum DistanceUnit: String, CaseIterable, Identifiable {
    case km, mi

    var id: String { rawValue }

    var title: String { self == .km ? "km" : "mi" }

    func fromMeters(_ meters: Double) -> Double {
        self == .km ? meters / 1000.0 : meters / 1609.344
    }

    func paceMinutesPerUnit(duration: TimeInterval, meters: Double) -> Double? {
        let distance = fromMeters(meters)
        guard distance > 0, duration > 0 else { return nil }
        return (duration / 60.0) / distance
    }
}

@Observable
final class AppTheme {
    static let appearanceModeKey = "appearanceMode"

    var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: Self.appearanceModeKey) }
    }

    var backgroundName: String {
        didSet { UserDefaults.standard.set(backgroundName, forKey: BackgroundTheme.backgroundNameKey) }
    }

    var customBackgroundHex: String {
        didSet { UserDefaults.standard.set(customBackgroundHex, forKey: BackgroundTheme.customHexKey) }
    }

    var accentName: String {
        didSet { UserDefaults.standard.set(accentName, forKey: "accentName") }
    }

    var customAccentHex: String {
        didSet { UserDefaults.standard.set(customAccentHex, forKey: AccentTheme.customHexKey) }
    }

    init() {
        let defaults = UserDefaults.standard
        appearanceMode = AppearanceMode(rawValue: defaults.string(forKey: Self.appearanceModeKey) ?? "") ?? .system
        backgroundName = defaults.string(forKey: BackgroundTheme.backgroundNameKey) ?? BackgroundTheme.systemName
        customBackgroundHex = defaults.string(forKey: BackgroundTheme.customHexKey) ?? BackgroundTheme.defaultCustomHex
        accentName = defaults.string(forKey: "accentName") ?? AccentOption.orange.rawValue
        customAccentHex = defaults.string(forKey: AccentTheme.customHexKey) ?? AccentTheme.defaultCustomHex
        if accentName == "coral" { accentName = AccentOption.orange.rawValue }
    }

    var accent: Color {
        AccentTheme.color(accentName: accentName, customHex: customAccentHex)
    }

    var resolvedColorScheme: ColorScheme? {
        switch appearanceMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            guard !BackgroundTheme.isSystem(backgroundName),
                  let base = BackgroundTheme.baseColor(backgroundName: backgroundName, customHex: customBackgroundHex)
            else { return nil }
            let lum = base.relativeLuminance
            if lum < 0.35 { return .dark }
            if lum > 0.65 { return .light }
            return nil
        }
    }

    var groupedBackground: Color {
        if BackgroundTheme.isSystem(backgroundName) {
            return Color(.systemGroupedBackground)
        }
        return BackgroundTheme.baseColor(backgroundName: backgroundName, customHex: customBackgroundHex)
            ?? Color(.systemGroupedBackground)
    }

    var cardFill: Color {
        if BackgroundTheme.isSystem(backgroundName) {
            return Color(.secondarySystemBackground)
        }
        let base = groupedBackground
        let lum = base.relativeLuminance
        if lum < 0.5 {
            return base.blended(with: .white, amount: 0.10)
        }
        return base.blended(with: .black, amount: 0.06)
    }

    var cardBorder: Color {
        if BackgroundTheme.isSystem(backgroundName) {
            return Color.primary.opacity(0.10)
        }
        let lum = groupedBackground.relativeLuminance
        if lum < 0.5 {
            return Color.white.opacity(0.12)
        }
        return Color.black.opacity(0.10)
    }

    var mutedFill: Color {
        if BackgroundTheme.isSystem(backgroundName) {
            return Color.primary.opacity(0.10)
        }
        let lum = groupedBackground.relativeLuminance
        if lum < 0.5 {
            return Color.white.opacity(0.12)
        }
        return Color.black.opacity(0.08)
    }

    var mutedText: Color { Color.secondary }

    func foregroundPrimary(for colorScheme: ColorScheme) -> Color {
        if !BackgroundTheme.isSystem(backgroundName) {
            return groupedBackground.relativeLuminance < 0.5
                ? Color.white
                : Color(red: 0.11, green: 0.11, blue: 0.12)
        }
        switch appearanceMode {
        case .dark:
            return Color.white
        case .light:
            return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .system:
            return colorScheme == .dark
                ? Color.white
                : Color(red: 0.11, green: 0.11, blue: 0.12)
        }
    }

    func foregroundSecondary(for colorScheme: ColorScheme) -> Color {
        foregroundPrimary(for: colorScheme).opacity(0.62)
    }
}

enum Theme {
    static let cardCorner: CGFloat = 16

    static var background: Color { Color(.systemBackground) }
    static var mutedText: Color { Color.secondary }
}

struct OpaqueCard: ViewModifier {
    @Environment(AppTheme.self) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.cardFill, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(theme.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func opaqueCard() -> some View {
        modifier(OpaqueCard())
    }
}

enum RIRPalette {
    static func color(for rir: Int, accent _: Color) -> Color {
        switch rir {
        case ...1: return Color(red: 0.90, green: 0.22, blue: 0.25)
        case 2, 3: return Color(red: 0.88, green: 0.50, blue: 0.08)
        case 4: return Color(red: 0.22, green: 0.70, blue: 0.38)
        default: return Color(red: 0.25, green: 0.55, blue: 0.90)
        }
    }

    static func label(for rir: Int) -> String {
        switch rir {
        case ...1: return "High"
        case 2, 3: return "Hard"
        case 4: return "Productive"
        default: return "Easy"
        }
    }

    static func display(_ rir: Int) -> String {
        rir >= 5 ? "5+" : "\(rir)"
    }
}
