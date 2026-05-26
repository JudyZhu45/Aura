import Foundation

enum Mood: String, CaseIterable, Identifiable, Codable {
    case calm = "Calm"
    case energetic = "Energetic"
    case dark = "Dark"
    case dreamy = "Dreamy"
    case cozy = "Cozy"
    case ethereal = "Ethereal"
    case mysterious = "Mysterious"
    case serene = "Serene"
    var id: String { rawValue }

    /// Richer descriptor that goes into the OpenAI prompt — gives gpt-image-1
    /// more to grab onto than just the bare word.
    var promptHint: String {
        switch self {
        case .calm:        return "calm, gentle, soothing"
        case .energetic:   return "energetic, bold, dynamic"
        case .dark:        return "dark, moody, shadowy"
        case .dreamy:      return "dreamy, hazy, soft-focus"
        case .cozy:        return "cozy, warm, inviting"
        case .ethereal:    return "ethereal, otherworldly, luminous"
        case .mysterious:  return "mysterious, enigmatic, intriguing"
        case .serene:      return "serene, peaceful, balanced"
        }
    }
}

enum Palette: String, CaseIterable, Identifiable, Codable {
    case warm = "Warm"
    case cool = "Cool"
    case monochrome = "Monochrome"
    case vivid = "Vivid"
    case pastel = "Pastel"
    case neon = "Neon"
    case earthy = "Earthy"
    case sunset = "Sunset"
    var id: String { rawValue }

    var promptHint: String {
        switch self {
        case .warm:        return "warm reds, oranges, and ambers"
        case .cool:        return "cool blues, teals, and indigos"
        case .monochrome:  return "monochrome black, white, and grey tones"
        case .vivid:       return "vivid saturated rainbow colors"
        case .pastel:      return "soft pastel pinks, lavenders, mint, and butter-yellow"
        case .neon:        return "electric neon pinks, cyans, and purples"
        case .earthy:      return "earthy browns, mossy greens, and stone greys"
        case .sunset:      return "sunset oranges, magentas, deep purples"
        }
    }
}

enum ArtStyle: String, CaseIterable, Identifiable, Codable {
    case abstract = "Abstract"
    case nature = "Nature"
    case geometric = "Geometric"
    case surreal = "Surreal"
    case minimalist = "Minimalist"
    case cosmic = "Cosmic"
    case watercolor = "Watercolor"
    case cyberpunk = "Cyberpunk"
    var id: String { rawValue }

    var promptHint: String {
        switch self {
        case .abstract:    return "abstract painterly composition with flowing shapes"
        case .nature:      return "natural landscape with organic textures"
        case .geometric:   return "clean geometric shapes and patterns"
        case .surreal:     return "surreal dreamlike scene with impossible imagery"
        case .minimalist:  return "minimalist, lots of negative space, a few precise elements"
        case .cosmic:      return "cosmic nebula, stars, deep space"
        case .watercolor:  return "watercolor painting with soft washes and visible paper texture"
        case .cyberpunk:   return "cyberpunk neon-lit cityscape with futuristic detail"
        }
    }
}

@MainActor
final class StylePreferences: ObservableObject {
    @Published var mood: Mood {
        didSet { UserDefaults.standard.set(mood.rawValue, forKey: "aura.mood") }
    }
    @Published var palette: Palette {
        didSet { UserDefaults.standard.set(palette.rawValue, forKey: "aura.palette") }
    }
    @Published var artStyle: ArtStyle {
        didSet { UserDefaults.standard.set(artStyle.rawValue, forKey: "aura.artStyle") }
    }

    init() {
        self.mood = Mood(rawValue: UserDefaults.standard.string(forKey: "aura.mood") ?? "") ?? .calm
        self.palette = Palette(rawValue: UserDefaults.standard.string(forKey: "aura.palette") ?? "") ?? .cool
        self.artStyle = ArtStyle(rawValue: UserDefaults.standard.string(forKey: "aura.artStyle") ?? "") ?? .abstract
    }

    func composePrompt(custom: String? = nil) -> String {
        let base = "A \(mood.promptHint), \(artStyle.promptHint), with \(palette.promptHint). 9:16 vertical phone wallpaper, highly detailed, no text, no watermarks, no logos"
        if let custom, !custom.trimmingCharacters(in: .whitespaces).isEmpty {
            return "\(base). Subject: \(custom)"
        }
        return base
    }
}
