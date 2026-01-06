import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            TerminalSettingsView()
                .tabItem {
                    Label("Terminal", systemImage: "terminal")
                }

            PreviewSettingsView()
                .tabItem {
                    Label("Preview", systemImage: "doc.text")
                }
        }
        .frame(width: 450, height: 250)
    }
}

struct TerminalSettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var availableFonts: [String] = []

    var body: some View {
        Form {
            Section {
                Picker("Font:", selection: $settings.terminalFontName) {
                    ForEach(availableFonts, id: \.self) { font in
                        Text(font)
                            .font(.custom(font, size: 13))
                            .tag(font)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Size:")
                    Slider(value: $settings.terminalFontSize, in: 9...24, step: 1) {
                        Text("Font Size")
                    }
                    Text("\(Int(settings.terminalFontSize)) pt")
                        .frame(width: 45, alignment: .trailing)
                        .monospacedDigit()
                }
            } header: {
                Text("Font")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Preview:")
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The quick brown fox jumps over the lazy dog")
                        Text("日本語テスト: こんにちは世界 🎉")
                    }
                    .font(.custom(settings.terminalFontName, size: settings.terminalFontSize))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black)
                    .foregroundStyle(.green)
                    .cornerRadius(4)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            availableFonts = AppSettings.availableMonospaceFonts
            // Ensure current font is in list
            if !availableFonts.contains(settings.terminalFontName) {
                availableFonts.insert(settings.terminalFontName, at: 0)
            }
        }
    }
}

struct PreviewSettingsView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Base Font Size:")
                    Slider(value: $settings.previewFontSize, in: 12...24, step: 1) {
                        Text("Font Size")
                    }
                    Text("\(Int(settings.previewFontSize)) pt")
                        .frame(width: 45, alignment: .trailing)
                        .monospacedDigit()
                }
            } header: {
                Text("Markdown Preview")
            }
        }
        .formStyle(.grouped)
    }
}
