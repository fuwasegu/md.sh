import SwiftUI

struct ReviewPanel: View {
    @Environment(AppState.self) private var appState
    @State private var editingComment: ReviewComment?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Review Comments")
                    .font(.headline)
                Spacer()
                Text("\(appState.reviewStore.comments.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .cornerRadius(10)
            }
            .padding()

            Divider()

            if appState.reviewStore.comments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No comments yet")
                        .foregroundStyle(.secondary)
                    Text("Select text in Markdown preview\nto add review comments")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Comments list
                ScrollViewReader { proxy in
                    List {
                        ForEach(appState.reviewStore.comments) { comment in
                            CommentRow(
                                comment: comment,
                                isHighlighted: appState.focusedCommentId == comment.id,
                                onEdit: { editingComment = comment },
                                onDelete: { appState.reviewStore.remove(comment) },
                                onSendToTerminal: { sendCommentToTerminal(comment) }
                            )
                            .id(comment.id)
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: appState.focusedCommentId) { _, newId in
                        if let id = newId {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(id, anchor: .center)
                            }
                            // Clear highlight after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                if appState.focusedCommentId == id {
                                    appState.focusedCommentId = nil
                                }
                            }
                        }
                    }
                }
            }

            Divider()

            // Actions
            HStack(spacing: 12) {
                Button(role: .destructive) {
                    appState.reviewStore.clear()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(appState.reviewStore.comments.isEmpty)

                Spacer()

                Button {
                    sendAllToTerminal()
                } label: {
                    Label("Send", systemImage: "terminal")
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.reviewStore.comments.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 200)
        .sheet(item: $editingComment) { comment in
            EditCommentSheet(
                comment: comment,
                onSave: { newText in
                    appState.reviewStore.update(comment, newText: newText)
                    editingComment = nil
                },
                onCancel: { editingComment = nil }
            )
        }
    }

    private func sendCommentToTerminal(_ comment: ReviewComment) {
        let text = formatCommentForTerminal(comment)
        appState.sendToTerminal(text)
    }

    private func sendAllToTerminal() {
        let text = appState.reviewStore.comments
            .map { formatCommentForTerminal($0) }
            .joined(separator: "\n\n")
        appState.sendToTerminal(text + "\n")
    }

    private func formatCommentForTerminal(_ comment: ReviewComment) -> String {
        """
        # \(comment.fileName) \(comment.lineRange)
        > \(comment.originalText.components(separatedBy: .newlines).joined(separator: "\n> "))

        \(comment.comment)
        """
    }
}

struct CommentRow: View {
    let comment: ReviewComment
    let isHighlighted: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSendToTerminal: () -> Void
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.fileName)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(comment.lineRange)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()

                if isHovering {
                    HStack(spacing: 4) {
                        Button(action: onSendToTerminal) {
                            Image(systemName: "terminal")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("Send to Terminal")

                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("Edit")

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                        .help("Delete")
                    }
                }
            }

            Text(comment.originalText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(2)

            Text(comment.comment)
                .font(.callout)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHighlighted ? Color.yellow.opacity(0.3) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct EditCommentSheet: View {
    let comment: ReviewComment
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @State private var editedText: String = ""

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Edit Comment")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.fileName)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(comment.lineRange)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(comment.originalText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TextEditor(text: $editedText)
                .font(.body)
                .frame(minHeight: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            HStack {
                Spacer()
                Button("Save") {
                    onSave(editedText)
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            editedText = comment.comment
        }
    }
}
