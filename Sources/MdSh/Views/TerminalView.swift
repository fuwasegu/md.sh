import SwiftUI
import SwiftTerm

struct TerminalPanelView: NSViewRepresentable {
    let workingDirectory: URL?
    let font: NSFont
    let onTerminalReady: ((LocalProcessTerminalView) -> Void)?

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminal = LocalProcessTerminalView(frame: .zero)

        // Configure terminal appearance
        terminal.configureNativeColors()
        terminal.font = font

        // Start shell process
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let workDir = workingDirectory?.path ?? NSHomeDirectory()

        // Set environment with working directory and UTF-8 locale
        var env = ProcessInfo.processInfo.environment
        env["PWD"] = workDir
        env["LANG"] = "ja_JP.UTF-8"
        env["LC_ALL"] = "ja_JP.UTF-8"
        env["LC_CTYPE"] = "UTF-8"

        terminal.startProcess(
            executable: shell,
            args: ["-l"],  // Login shell
            environment: Array(env.map { "\($0.key)=\($0.value)" }),
            execName: nil
        )

        // Change to working directory
        if let dir = workingDirectory?.path {
            terminal.send(txt: "cd \"\(dir)\" && clear\n")
        }

        // Notify that terminal is ready
        onTerminalReady?(terminal)

        return terminal
    }

    func updateNSView(_ terminal: LocalProcessTerminalView, context: Context) {
        terminal.font = font
    }
}

// Terminal container with toolbar
struct TerminalContainerView: View {
    let workingDirectory: URL?
    @Environment(AppState.self) private var appState
    @State private var terminalKey = UUID()
    @State private var settings = AppSettings.shared
    @State private var terminalRef: LocalProcessTerminalView?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Terminal")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    terminalKey = UUID()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Restart Terminal")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // Terminal
            TerminalPanelView(
                workingDirectory: workingDirectory,
                font: settings.terminalFont,
                onTerminalReady: { terminal in
                    terminalRef = terminal
                    appState.terminalSendHandler = { text in
                        // Use bracketed paste mode to handle multi-line text
                        // This prevents newlines from being executed as commands
                        let bracketStart = "\u{1b}[200~"
                        let bracketEnd = "\u{1b}[201~"
                        terminal.send(txt: bracketStart + text + bracketEnd)
                    }
                }
            )
            .id(terminalKey)
        }
        .onChange(of: workingDirectory) { _, _ in
            // Reload terminal when project changes
            terminalKey = UUID()
        }
        .onDisappear {
            appState.terminalSendHandler = nil
        }
    }
}
