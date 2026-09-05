import SwiftUI

struct HistoryView: View {
    @State private var sections: [HistorySection] = HistorySection.sampleData
    @State private var selectionMode: Bool = false
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var deletePrompt: DeletePrompt?
    @State private var searchText = ""

    private var filteredSections: [HistorySection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sections }

        return sections.compactMap { section in
            let items = section.items.filter { item in
                item.title.localizedCaseInsensitiveContains(query)
                || item.chapter.localizedCaseInsensitiveContains(query)
                || item.time.localizedCaseInsensitiveContains(query)
                || section.date.localizedCaseInsensitiveContains(query)
            }

            guard !items.isEmpty else { return nil }
            return HistorySection(id: section.id, date: section.date, items: items)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                ForEach(filteredSections) { section in
                    VStack(alignment: .leading, spacing: 18) {
                        Text(section.date)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.primary.opacity(0.8))

                        VStack(spacing: 18) {
                            ForEach(section.items) { item in
                                HistoryRow(
                                    item: item,
                                    showCheckboxes: selectionMode,
                                    isSelected: selectedItemIDs.contains(item.id),
                                    onToggleSelection: {
                                        toggleSelection(for: item.id)
                                    },
                                    onDelete: {
                                        deletePrompt = DeletePrompt.single(item: item)
                                    }
                                )
                                .onTapGesture {
                                    guard selectionMode else { return }
                                    toggleSelection(for: item.id)
                                }
                                .onLongPressGesture {
                                    selectionMode = true
                                    selectedItemIDs = [item.id]
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("History")
        .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search history"))
        .overlay {
            if filteredSections.isEmpty {
                ContentUnavailableView(
                    "No History Found",
                    systemImage: "clock.badge.questionmark",
                    description: Text("Try searching another title, chapter, date, or time.")
                )
            }
        }
        .toolbar {
            if selectionMode {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        selectionMode = false
                        selectedItemIDs.removeAll()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if selectionMode {
                        if !selectedItemIDs.isEmpty {
                            deletePrompt = DeletePrompt.multiple(ids: selectedItemIDs)
                        }
                    } else {
                        selectionMode = true
                    }
                } label: {
                    Image(systemName: "trash.fill")
                }
            }
        }
        .alert(item: $deletePrompt) { prompt in
            Alert(
                title: Text("Delete Entry"),
                message: Text(prompt.message),
                primaryButton: .destructive(Text("Delete")) {
                    performDelete(for: prompt)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func toggleSelection(for id: UUID) {
        if selectedItemIDs.contains(id) {
            selectedItemIDs.remove(id)
        } else {
            selectedItemIDs.insert(id)
        }
    }

    private func performDelete(for prompt: DeletePrompt) {
        switch prompt.kind {
        case .single(let id):
            deleteItems(withIDs: [id])
        case .multiple(let ids):
            deleteItems(withIDs: ids)
        }
    }

    private func deleteItems(withIDs ids: Set<UUID>) {
        sections = sections.compactMap { section in
            let remainingItems = section.items.filter { !ids.contains($0.id) }
            guard !remainingItems.isEmpty else { return nil }
            return HistorySection(id: section.id, date: section.date, items: remainingItems)
        }

        selectedItemIDs.subtract(ids)

        if selectedItemIDs.isEmpty {
            selectionMode = false
        }
    }
}

private struct HistoryRow: View {
    let item: HistoryItem
    let showCheckboxes: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            if showCheckboxes {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.plain)
            }

            Image(item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 78, height: 116)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text(item.title)
                    .font(.system(size: 18, weight: .medium))
                    .lineLimit(1)

                Text("\(item.chapter)")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                Text("\(item.time)")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if !showCheckboxes {
                HStack(spacing: 24) {
                    Button {
                    } label: {
                        Image(systemName: "book.closed")
                    }

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash.fill")
                    }
                }
                .font(.title2)
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        }
    }
}

private struct HistorySection: Identifiable {
    let id: UUID
    let date: String
    let items: [HistoryItem]

    static let sampleData: [HistorySection] = [
        HistorySection(date: "Today", items: [
            HistoryItem(image: "Image1", title: "The Regressed Mercenary's Machinations", chapter: "Chapter 110", time: "02:28"),
            HistoryItem(image: "Image11", title: "Graymark", chapter: "Chapter 84", time: "08:42")
        ]),
        HistorySection(date: "27 May, 2026", items: [
            HistoryItem(image: "Image12", title: "My Bias on the Last Train", chapter: "Chapter 57", time: "11:16"),
            HistoryItem(image: "Image7", title: "Return of the SSS Class Ranker", chapter: "Chapter 139", time: "19:04")
        ]),
        HistorySection(date: "26 May, 2026", items: [
            HistoryItem(image: "Image9", title: "Pick Me Up Infinite Gacha", chapter: "Chapter 112", time: "17:31"),
            HistoryItem(image: "Image6", title: "Superhuman Battlefield", chapter: "Chapter 91", time: "22:12")
        ]),
        HistorySection(date: "25 May, 2026", items: [
            HistoryItem(image: "Image8", title: "Legend of the Northern Blade", chapter: "Chapter 112", time: "17:31"),
            HistoryItem(image: "Image10", title: "Regressed Bastard of the Sword Clan", chapter: "Chapter 57", time: "11:16"),
        ]),
        HistorySection(date: "24 May, 2026", items: [
            HistoryItem(image: "Image4", title: "Player", chapter: "Chapter 38", time: "09:18"),
            HistoryItem(image: "Image5", title: "Ordeal", chapter: "Chapter 71", time: "21:47")
        ])
    ]

    init(id: UUID = UUID(), date: String, items: [HistoryItem]) {
        self.id = id
        self.date = date
        self.items = items
    }
}

private struct HistoryItem: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let chapter: String
    let time: String
}

private struct DeletePrompt: Identifiable {
    enum Kind {
        case single(UUID)
        case multiple(Set<UUID>)
    }

    let id = UUID()
    let kind: Kind
    let message: String

    static func single(item: HistoryItem) -> DeletePrompt {
        DeletePrompt(
            kind: .single(item.id),
            message: "Are you sure you want to delete \(item.title) from your history?"
        )
    }

    static func multiple(ids: Set<UUID>) -> DeletePrompt {
        DeletePrompt(
            kind: .multiple(ids),
            message: "Are you sure you want to delete \(ids.count) selected history entries?"
        )
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}

