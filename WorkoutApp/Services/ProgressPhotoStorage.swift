import UIKit

enum ProgressPhotoStorage {
    static let folderName = "ProgressPhotos"

    static var directoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(folderName, isDirectory: true)
    }

    static func saveJPEG(_ data: Data, compressionQuality: CGFloat = 0.85) throws -> String {
        try ensureDirectory()
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: compressionQuality) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let filename = UUID().uuidString + ".jpg"
        let url = directoryURL.appendingPathComponent(filename)
        try jpeg.write(to: url, options: .atomic)
        return filename
    }

    static func loadImage(filename: String) -> UIImage? {
        let url = directoryURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(filename: String?) {
        guard let filename, !filename.isEmpty else { return }
        let url = directoryURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    private static func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}
