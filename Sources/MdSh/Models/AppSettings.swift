import SwiftUI

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    // Terminal settings
    var terminalFontName: String {
        didSet { UserDefaults.standard.set(terminalFontName, forKey: "terminalFontName") }
    }
    var terminalFontSize: Double {
        didSet { UserDefaults.standard.set(terminalFontSize, forKey: "terminalFontSize") }
    }

    // Preview settings
    var previewFontSize: Double {
        didSet { UserDefaults.standard.set(previewFontSize, forKey: "previewFontSize") }
    }

    private init() {
        // Load from UserDefaults with defaults
        let fontName = UserDefaults.standard.string(forKey: "terminalFontName") ?? "SF Mono"
        var fontSize = UserDefaults.standard.double(forKey: "terminalFontSize")
        if fontSize == 0 { fontSize = 13 }
        var prevSize = UserDefaults.standard.double(forKey: "previewFontSize")
        if prevSize == 0 { prevSize = 16 }

        // Initialize all properties
        self.terminalFontName = fontName
        self.terminalFontSize = fontSize
        self.previewFontSize = prevSize
    }

    var terminalFont: NSFont {
        NSFont(name: terminalFontName, size: terminalFontSize)
            ?? NSFont.monospacedSystemFont(ofSize: terminalFontSize, weight: .regular)
    }

    // Available monospace fonts
    static var availableMonospaceFonts: [String] {
        let fontManager = NSFontManager.shared
        let monospacedFonts = fontManager.availableFontFamilies.filter { family in
            if let font = NSFont(name: family, size: 12) {
                return font.isFixedPitch || family.lowercased().contains("mono") || family.lowercased().contains("code")
            }
            return false
        }
        return monospacedFonts.sorted()
    }
}
