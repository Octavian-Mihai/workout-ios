import SwiftUI
import SwiftData

struct RootTabView: View {
    @StateObject private var sessionStore = ActiveSessionStore()
    @StateObject private var health = HealthKitService()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppTheme.self) private var appTheme
    @AppStorage("restTimerHaptics") private var restTimerHaptics = true

    private var accent: Color {
        appTheme.accent
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            WorkoutTabView()
                .tabItem { Label("Workout", systemImage: "figure.strengthtraining.traditional") }

            RunningView()
                .tabItem { Label("Running", systemImage: "figure.run") }

            InfoView()
                .tabItem { Label("Info", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environmentObject(sessionStore)
        .environmentObject(health)
        .fullScreenCover(isPresented: Binding(
            get: { sessionStore.isPresented && sessionStore.controller != nil },
            set: { presented in
                if presented {
                    sessionStore.isPresented = true
                } else {
                    sessionStore.minimize()
                }
            }
        )) {
            if let controller = sessionStore.controller {
                NavigationStack {
                    LiveSessionView(
                        controller: controller,
                        onMinimize: { sessionStore.minimize() },
                        onFinished: { sessionStore.finish() },
                        onDiscard: { sessionStore.discard() }
                    )
                }
                .environment(\.modelContext, modelContext)
                .environmentObject(sessionStore)
                .tint(accent)
            }
        }
        .overlay(alignment: .bottom) {
            if sessionStore.isMinimized, let controller = sessionStore.controller {
                ResumeSessionPill(
                    controller: controller,
                    accent: accent,
                    hapticsEnabled: restTimerHaptics
                ) {
                    sessionStore.resume()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 56)
            }
        }
        .task {
            if health.isAvailable {
                await health.requestAndLoad()
            }
        }
    }
}

struct ResumeSessionPill: View {
    @ObservedObject var controller: SessionController
    let accent: Color
    var hapticsEnabled: Bool
    var onResume: () -> Void

    var body: some View {
        Button(action: onResume) {
            HStack(spacing: 10) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(controller.programDay?.name ?? "Empty workout")
                        .font(.subheadline.weight(.semibold))
                    if controller.timerRunning {
                        Text("Rest \(Formatters.duration(controller.restRemaining))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(controller.loggedSetCount) sets · tap to resume")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .padding(12)
            .opaqueCard()
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: hapticsEnabled ? controller.restCompletedPulse : 0)
        .onChange(of: controller.restCompletedPulse) { _, pulse in
            if pulse > 0 {
                RestTimerSound.play()
            }
        }
    }
}
