import SwiftUI

struct ReaderCommentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let chapterName: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Comments", systemImage: "text.bubble")
            } description: {
                Text("Discussion for \(chapterName) will connect with account comments in Phase 5.")
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
