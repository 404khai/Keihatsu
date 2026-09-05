import SwiftUI

struct LibraryView: View {
    let animation: Namespace.ID
    @State private var selectedCategory: LibraryCategory = .defaultCategory
    @State private var searchText = ""

    private let itemsByCategory: [LibraryCategory: [ImageModel]] = [
        .defaultCategory: [
            images[0],
            images[1],
            images[2],
            images[10],
            images[8],
            images[3],
            images[6]
        ],
        .thriller: [
            images[4],
            images[5],
            images[7]
        ],
        .romance: [
            images[11],
            images[9]
        ]
    ]

    private var currentItems: [ImageModel] {
        let items = itemsByCategory[selectedCategory] ?? []
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }

        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(query)
            || item.category.localizedCaseInsensitiveContains(query)
            || item.metadataLine.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(LibraryCategory.allCases, id: \.self) { category in
                        Text(category.label(count: itemsByCategory[category]?.count ?? 0))
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3),
                    spacing: 18
                ) {
                    ForEach(currentItems) { item in
                        NavigationLink(value: item) {
                            LibraryCard(item: item)
                        }
                        .buttonStyle(.plain)
                        .matchedTransitionSource(id: item.id, in: animation)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Library")
        .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search library"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: ImageModel.self) { item in
            CarouselDetailView(item: item, animation: animation)
        }
    }
}

private struct LibraryCard: View {
    let item: ImageModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 210)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(item.title)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(12)
        }
    }
}

private enum LibraryCategory: CaseIterable {
    case defaultCategory
    case thriller
    case romance

    func label(count: Int) -> String {
        switch self {
        case .defaultCategory:
            return "Default(\(count))"
        case .thriller:
            return "Thriller(\(count))"
        case .romance:
            return "Romance(\(count))"
        }
    }
}

#Preview {
    @Previewable @Namespace var animation
    NavigationStack {
        LibraryView(animation: animation)
    }
}
