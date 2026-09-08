import SwiftUI
import UIKit

struct ExercisePhotoView: View {
    let assetName: String
    let caption: String
    var symbolName: String = "photo"
    var showCaption: Bool = true

    @Environment(AppTheme.self) private var theme

    private var catalogImage: UIImage? {
        UIImage(named: assetName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let catalogImage {
                    Image(uiImage: catalogImage)
                        .resizable()
                        .scaledToFill()
                        .accessibilityLabel(caption)
                } else {
                    ZStack {
                        theme.mutedFill
                        VStack(spacing: 8) {
                            Image(systemName: symbolName)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(theme.accent.opacity(0.9))
                            Text("Photo coming soon")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(caption), photo coming soon")
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if showCaption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
