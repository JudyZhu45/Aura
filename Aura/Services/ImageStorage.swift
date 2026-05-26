import UIKit

enum ImageStorageError: LocalizedError {
    case encodingFailed
    var errorDescription: String? { "Could not encode image as JPEG." }
}

enum ImageStorage {
    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    @discardableResult
    static func save(_ image: UIImage, filename: String) throws -> URL {
        let url = documentsURL.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.92) else {
            throw ImageStorageError.encodingFailed
        }
        try data.write(to: url, options: .atomic)
        return url
    }

    static func load(filename: String) -> UIImage? {
        let url = documentsURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
