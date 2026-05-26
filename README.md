# Aura — Daily AI Wallpaper (iOS)

A SwiftUI iOS app that generates a new AI wallpaper every day using OpenAI's DALL·E 3, with a StoreKit 2 subscription paywall.

## What's in this folder

```
Aura/
  AuraApp.swift          - App entry point + environment objects
  ContentView.swift      - Root TabView (Today / Generate / History / Style)
  Models/
    WallpaperModel.swift           - Wallpaper struct + WallpaperStore
    GenerationLimitManager.swift   - Daily free-tier limit (1/day, midnight reset)
    StylePreferences.swift         - Mood / Palette / ArtStyle enums + UserDefaults
    UserSubscriptionManager.swift  - StoreKit 2 product loading, purchase, entitlements
  Views/
    AuraTheme.swift        - Dark/aurora theme, FrostedCard, aurora button style
    HomeView.swift         - Today's wallpaper full-bleed + Set as Wallpaper
    GenerateView.swift     - Style summary + custom prompt + Generate button
    HistoryView.swift      - Grid of past wallpapers + detail w/ premium download
    PreferencesView.swift  - Mood / Palette / Art Style pickers
    PaywallView.swift      - Monthly + yearly subscription upsell
  Services/
    OpenAIService.swift    - DALL·E 3 image generation (b64_json → UIImage)
    ImageStorage.swift     - JPEG save/load in app Documents/
  Resources/
    Aura.storekit                 - StoreKit Testing config (simulator)
    Info.plist.fragment.xml       - Photo library usage description keys
```

## Setting up in Xcode (3 minutes)

1. **Create a new iOS App project** in Xcode 15+:
   - Product Name: `Aura`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployments: **iOS 17.0**
   - Delete the auto-generated `ContentView.swift` and `AuraApp.swift`.

2. **Add the source files**: drag the `Aura/` folder from this repo into the project navigator. Make sure "Copy items if needed" and "Create groups" are checked.

3. **Add the StoreKit configuration**:
   - Drag `Resources/Aura.storekit` into the project.
   - Open the scheme (Product → Scheme → Edit Scheme).
   - Select **Run → Options → StoreKit Configuration** → pick `Aura.storekit`.

4. **Add Photos usage description**:
   - Target → **Info** tab → "+" → add `NSPhotoLibraryAddUsageDescription` with the string from `Info.plist.fragment.xml`.
   - Without this key, the app will crash when you tap "Set as Wallpaper".

5. **Set your API key**:
   - Open `Services/OpenAIService.swift`.
   - Replace `apiKey = "sk-REPLACE_WITH_YOUR_OPENAI_API_KEY"` with your real key for local testing.
   - ⚠️ **Do NOT ship a bundled key in production.** Proxy through your own backend.

6. **Build & run** on the iOS Simulator (any iPhone 15+ scheme).
   - The "Generate" tab will call OpenAI; the rest works offline.
   - Use **Debug → StoreKit → Manage Transactions** to simulate purchases, restores, and renewals.

## Behavior summary

- **Free tier**: 1 generation per day. Counter resets at midnight local time. Custom prompts are locked. History downloads are locked.
- **Premium tier**: unlimited generations, custom text prompts, download from history. Buying either subscription in `Aura.storekit` flips `subscription.isPremium` via `Transaction.currentEntitlements`.
- **Persistence**: preferences + daily count in `UserDefaults`; wallpapers in app Documents directory; metadata in `UserDefaults` (JSON-encoded `[Wallpaper]`).
- **Photos**: tapping "Set as Wallpaper" writes the image to Photos (via `PHPhotoLibrary.requestAuthorization` + `UIImageWriteToSavedPhotosAlbum`). iOS does not allow apps to set the system wallpaper directly — the user finishes the flow in Photos → Share → Use as Wallpaper.

## Replacing the placeholders

Search the project for `TODO` to find:

- `OpenAIService.apiKey` — your OpenAI API key.
- `UserSubscriptionManager.monthlyID` / `yearlyID` — your App Store Connect product IDs. The same IDs are baked into `Aura.storekit`; if you change one, change the other.

## App icon

The icon concept is a soft gradient orb (aurora purple → cyan → gold). Not bundled here — generate a PNG with a vector tool of your choice and add it via Assets.xcassets → AppIcon.

## License & disclaimer

This is a scaffold. The OpenAI key handling, server-side proxying, refund/grace-period flows, family sharing, and App Store review concerns (e.g. paywall copy, restore button placement) all need work before shipping.
