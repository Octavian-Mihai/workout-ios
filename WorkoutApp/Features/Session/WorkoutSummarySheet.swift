import SwiftUI
import UIKit
import UniformTypeIdentifiers

private struct WorkoutSummaryPNG: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.data
        }
    }
}

struct WorkoutSummarySheet: View {
    let model: WorkoutSummaryModel
    let accent: Color
    let unit: WeightUnit
    var onDone: () -> Void

    @Environment(AppTheme.self) private var theme
    @State private var shareItem: WorkoutSummaryPNG?

    var body: some View {
        NavigationStack {
            ScrollView {
                WorkoutSummaryView(model: model, accent: accent, unit: unit)
                    .environment(theme)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    .padding(20)
                    .frame(maxWidth: .infinity)
            }
            .background(theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Workout complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDone)
                }
                ToolbarItem(placement: .primaryAction) {
                    if let shareItem {
                        ShareLink(
                            item: shareItem,
                            preview: SharePreview("Workout Summary", image: previewImage)
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                shareItem = renderedPNG()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var previewImage: Image {
        if let data = shareItem?.data, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "figure.strengthtraining.traditional")
    }

    @MainActor
    private func renderedPNG() -> WorkoutSummaryPNG? {
        let scheme = theme.resolvedColorScheme ?? .light
        let content = WorkoutSummaryView(model: model, accent: accent, unit: unit)
            .environment(theme)
            .environment(\.colorScheme, scheme)
        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else { return nil }
        return WorkoutSummaryPNG(data: data)
    }
}
