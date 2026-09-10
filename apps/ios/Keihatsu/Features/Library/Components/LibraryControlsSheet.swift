import SwiftUI

struct LibraryControlsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: LibraryOptionsStore
    var body: some View {
        NavigationStack {
            Form {
                Section("Filter") {
                    Toggle("Downloaded", isOn: $store.options.downloaded)
                    Toggle("Unread", isOn: $store.options.unread)
                    Toggle("Started", isOn: $store.options.started)
                    Toggle("Bookmarked", isOn: $store.options.bookmarked)
                    Toggle("Completed", isOn: $store.options.completed)
                }
                Section("Sort") {
                    Picker("Sort by", selection: $store.options.sort) {
                        ForEach(LibrarySort.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Toggle("Ascending", isOn: $store.options.ascending)
                }
                Section("Display") {
                    Picker("Layout", selection: $store.options.layout) {
                        ForEach(LibraryLayout.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .accessibilityIdentifier("library.layout")
                    Stepper("Columns: \(store.options.columns)", value: $store.options.columns, in: 2...4)
                    Toggle("Downloaded badges", isOn: downloadedBadges)
                    Toggle("Unread badges", isOn: unreadBadges)
                    Toggle("Language badges", isOn: languageBadges)
                    Toggle("Category tabs", isOn: categoryTabs)
                    Toggle("Category counts", isOn: $store.options.showCounts)
                }
            }
            .navigationTitle("Library Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private var downloadedBadges: Binding<Bool> {
        Binding(get: { store.options.displaysDownloadedBadge }, set: { store.options.showDownloadedBadge = $0 })
    }

    private var unreadBadges: Binding<Bool> {
        Binding(get: { store.options.displaysUnreadBadge }, set: { store.options.showUnreadBadge = $0 })
    }

    private var languageBadges: Binding<Bool> {
        Binding(get: { store.options.displaysLanguageBadge }, set: { store.options.showLanguageBadge = $0 })
    }

    private var categoryTabs: Binding<Bool> {
        Binding(get: { store.options.displaysCategories }, set: { store.options.showCategories = $0 })
    }
}

struct LibraryCategoriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var collections: CollectionStore
    @State private var name = ""
    @State private var editing: UUID?
    @State private var pendingDelete: LibraryCategory?

    var body: some View {
        NavigationStack {
            List {
                Section(editing == nil ? "New category" : "Rename category") {
                    TextField("Category name", text: $name)
                    Button(editing == nil ? "Add Category" : "Save Name") {
                        if collections.saveCategory(id: editing, name: name) { name = ""; editing = nil }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if editing != nil { Button("Cancel Edit") { editing = nil; name = "" } }
                    if let error = collections.error { Text(error).foregroundStyle(.red) }
                }
                Section("Categories") {
                    Text("Default").foregroundStyle(.secondary)
                    ForEach(collections.snapshot.categories) { category in
                        HStack {
                            Button(category.name) { editing = category.id; name = category.name }
                            Spacer()
                            Text("\(collections.snapshot.library.filter { $0.categoryIDs.contains(category.id) }.count)")
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) { pendingDelete = category }
                        }
                    }
                }
                if !collections.isAccountScoped {
                    Section { Text("Guest categories stay on this device. Sign in to sync them.").font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("Delete category?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
                Button("Delete", role: .destructive) {
                    if let category = pendingDelete {
                        collections.deleteCategory(category.id)
                        if editing == category.id { editing = nil; name = "" }
                    }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: { Text("Titles with no remaining categories will appear in Default.") }
        }
    }
}
