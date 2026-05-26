import Foundation
import UIKit

enum OpenAIError: LocalizedError {
    case invalidResponse
    case missingImage
    case http(Int, String)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from OpenAI."
        case .missingImage:
            return "No image returned."
        case .http(let code, let msg):
            return "OpenAI error \(code): \(msg)"
        case .missingAPIKey:
            return "Set OpenAIService.apiKey before generating."
        }
    }
}

enum OpenAIService {
    /// Read from Info.plist key `OpenAIAPIKey`, which is wired to the build-setting
    /// `$(OPENAI_API_KEY)` defined in `Aura/Resources/Secrets.xcconfig` (gitignored).
    ///
    /// To set up your key:
    ///   1. `cp Aura/Resources/Secrets.example.xcconfig Aura/Resources/Secrets.xcconfig`
    ///   2. Edit `Secrets.xcconfig` and paste your real key.
    ///   3. `xcodegen generate` → rebuild.
    ///
    /// ⚠️ For production: the key still gets embedded in the shipped .app's Info.plist —
    /// safer than hard-coding in source (no git history exposure), but anyone who
    /// inspects the .ipa can extract it. Real-world apps should proxy through a backend.
    static var apiKey: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String ?? ""
        return value
    }

    static let endpoint = URL(string: "https://api.openai.com/v1/images/generations")!

    static func generateImage(prompt: String) async throws -> UIImage {
        guard apiKey.hasPrefix("sk-") && !apiKey.contains("REPLACE_WITH_YOUR_OPENAI_API_KEY") else {
            throw OpenAIError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        // Using OpenAI's current flagship image model. `gpt-image-1` is what dall-e-3 became —
        // most sk-proj-… keys don't have dall-e-3 enabled, but do have gpt-image-1.
        // Returns b64_json by default (no `response_format` parameter exists for this model).
        let body: [String: Any] = [
            "model": "gpt-image-1",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1536",   // portrait, closest to 9:16 wallpaper
            "quality": "high"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw OpenAIError.http(http.statusCode, msg)
        }

        struct ImagesResponse: Decodable {
            struct Item: Decodable {
                let url: String?
                let b64_json: String?
            }
            let data: [Item]
        }

        let decoded = try JSONDecoder().decode(ImagesResponse.self, from: data)
        guard let item = decoded.data.first else {
            throw OpenAIError.missingImage
        }

        // Prefer URL (default for project keys). Fall back to b64 if a future request opts in.
        if let urlString = item.url, let url = URL(string: urlString) {
            let (imageBytes, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: imageBytes) else {
                throw OpenAIError.missingImage
            }
            return image
        }

        if let b64 = item.b64_json,
           let bytes = Data(base64Encoded: b64),
           let image = UIImage(data: bytes) {
            return image
        }

        throw OpenAIError.missingImage
    }
}
