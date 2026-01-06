import SwiftUI
import CoreText

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
        // Default to Menlo which has better CJK fallback support
        let fontName = UserDefaults.standard.string(forKey: "terminalFontName") ?? "Menlo"
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
        // Create font with CJK fallback cascade
        createFontWithCJKFallback(name: terminalFontName, size: terminalFontSize)
    }

    /// Creates a font with explicit CJK (Japanese/Chinese/Korean) fallback fonts
    private func createFontWithCJKFallback(name: String, size: Double) -> NSFont {
        let cgSize = CGFloat(size)

        // Get the base font
        guard let baseFont = NSFont(name: name, size: cgSize) else {
            return NSFont.monospacedSystemFont(ofSize: cgSize, weight: .regular)
        }

        // Create font descriptor with cascade list for CJK support
        let baseCTFont = baseFont as CTFont

        // Define CJK fallback fonts (in order of preference)
        let cjkFontNames = [
            "Hiragino Kaku Gothic ProN",  // Japanese
            "Hiragino Sans",              // Japanese (newer)
            "PingFang SC",                // Simplified Chinese
            "PingFang TC",                // Traditional Chinese
            "Apple SD Gothic Neo",        // Korean
            "Menlo"                       // Backup monospace
        ]

        // Create cascade list
        var cascadeDescriptors: [CTFontDescriptor] = []
        for fontName in cjkFontNames {
            if let descriptor = CTFontDescriptorCreateWithNameAndSize(fontName as CFString, cgSize) as CTFontDescriptor? {
                cascadeDescriptors.append(descriptor)
            }
        }

        // Create new font with cascade list
        let cascadeFont = CTFontCreateCopyWithAttributes(
            baseCTFont,
            cgSize,
            nil,
            CTFontDescriptorCreateWithAttributes([
                kCTFontCascadeListAttribute: cascadeDescriptors
            ] as CFDictionary)
        )

        return cascadeFont as NSFont
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
