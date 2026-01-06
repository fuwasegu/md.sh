import AppKit
import SwiftTerm

/// LocalProcessTerminalView subclass with IME composition text display
class IMETerminalView: LocalProcessTerminalView {
    /// Overlay view to display IME composition text
    private var imeOverlay: NSTextField?

    /// Currently composing text
    private var markedString: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupIMEOverlay()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupIMEOverlay()
    }

    private func setupIMEOverlay() {
        let field = NSTextField(labelWithString: "")
        field.backgroundColor = NSColor.darkGray
        field.textColor = NSColor.white
        field.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        field.isBordered = false
        field.isHidden = true
        field.wantsLayer = true
        field.layer?.cornerRadius = 4
        addSubview(field)
        imeOverlay = field
    }

    // MARK: - NSTextInputClient overrides

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        let text: String
        if let attributedString = string as? NSAttributedString {
            text = attributedString.string
        } else if let plainString = string as? String {
            text = plainString
        } else {
            text = ""
        }

        markedString = text

        if text.isEmpty {
            hideIMEOverlay()
        } else {
            showIMEOverlay(text: text)
        }
    }

    override func unmarkText() {
        markedString = ""
        hideIMEOverlay()
    }

    override func hasMarkedText() -> Bool {
        return !markedString.isEmpty
    }

    override func markedRange() -> NSRange {
        if markedString.isEmpty {
            return NSRange(location: NSNotFound, length: 0)
        }
        return NSRange(location: 0, length: markedString.utf16.count)
    }

    override func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        return [.underlineStyle, .underlineColor]
    }

    // MARK: - IME Overlay

    private func showIMEOverlay(text: String) {
        guard let overlay = imeOverlay else { return }

        overlay.stringValue = text
        overlay.sizeToFit()

        let width = max(50, overlay.frame.width + 16)
        let height = overlay.frame.height + 8

        // Fixed position at bottom-left for now
        overlay.frame = NSRect(x: 10, y: 10, width: width, height: height)
        overlay.isHidden = false
    }

    private func hideIMEOverlay() {
        imeOverlay?.isHidden = true
    }

    /// Update overlay font to match terminal font
    func updateOverlayFont(_ newFont: NSFont) {
        imeOverlay?.font = newFont
    }
}
