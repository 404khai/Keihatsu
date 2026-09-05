//
//  PluginsView.swift
//  Keihatsu
//
//  Created by admin on 6/3/26.
//


import SwiftUI

struct PluginsView: View {
    @State private var selectedTab: PluginsTab = .sources
    @State private var searchText = ""

    @State private var plugins: [PluginSource] = [
        PluginSource(name: "Atsumaru", assetName: "atsumaru", subtitle: "EN • https://atsumaru.example", status: "Installed", isEnabled: true, isPinned: true),
        PluginSource(name: "BatCave", assetName: "batcave", subtitle: "EN • https://batcave.example", status: "Available now", isEnabled: false, isPinned: false),
        PluginSource(name: "MangaFire", assetName: "mangafire", subtitle: "EN • https://mangafire.example", status: "Available now", isEnabled: false, isPinned: false),
        PluginSource(name: "ManhuaTop", assetName: "manhuatop", subtitle: "EN • https://manhuatop.example", status: "Installed", isEnabled: true, isPinned: true),
        PluginSource(name: "WeebCentral", assetName: "weebcentral", subtitle: "EN • https://weebcentral.example", status: "Installed", isEnabled: true, isPinned: true)
    ]

    private var filteredSourceItems: [PluginSource] {
        filteredAndSorted(plugins.filter(\.isEnabled))
    }

    private var filteredPluginItems: [PluginSource] {
        filteredAndSorted(plugins)
    }

    private func filteredAndSorted(_ items: [PluginSource]) -> [PluginSource] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredItems: [PluginSource]

        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { item in
                item.name.localizedCaseInsensitiveContains(query)
                || item.subtitle.localizedCaseInsensitiveContains(query)
                || item.status.localizedCaseInsensitiveContains(query)
            }
        }

        return filteredItems.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            return lhs.name < rhs.name
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Picker("Extensions Tab", selection: $selectedTab) {
                    ForEach(PluginsTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 14) {
                    switch selectedTab {
                    case .sources:
                        ForEach(filteredSourceItems) { item in
                            if let index = plugins.firstIndex(where: { $0.id == item.id }) {
                                PluginCard(item: $plugins[index])
                            }
                        }
                    case .plugins:
                        ForEach(filteredPluginItems) { item in
                            if let index = plugins.firstIndex(where: { $0.id == item.id }) {
                                PluginCard(item: $plugins[index])
                            }
                        }
                    case .migrate:
                        ForEach(filteredPluginItems) { item in
                            MigratePluginRow(item: item)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Plugins")
        .navigationBarTitleDisplayMode(.automatic)
        .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search plugins"))
//        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
//        .toolbarColorScheme(.dark, for: .navigationBar)
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
    }
}

private struct PluginCard: View {
    @Binding var item: PluginSource

    var body: some View {
        HStack(spacing: 14) {
            Image(item.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(item.status)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(item.isEnabled ? .green : .secondary)
            }

            Spacer(minLength: 0)

            VStack(spacing: 14) {
                Button {
                    item.isPinned.toggle()
                } label: {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.body)
                        .foregroundStyle(item.isPinned ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)

                Toggle("", isOn: $item.isEnabled)
                    .labelsHidden()
                    .tint(.accentColor)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        }
    }
}

private struct MigratePluginRow: View {
    let item: PluginSource

    var body: some View {
        HStack(spacing: 14) {
            Image(item.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
            } label: {
                Text("45")
                    .frame(width: 44, height: 44)
//                Image(systemName: "arrow.up.arrow.down")
//                    .font(.title2.weight(.semibold))
//                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .glassEffect(.regular.interactive())
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        }
    }
}

private enum PluginsTab: CaseIterable {
    case sources
    case plugins
    case migrate

    var title: String {
        switch self {
        case .sources: return "Sources"
        case .plugins: return "Plugins"
        case .migrate: return "Migrate"
        }
    }
}

private struct PluginSource: Identifiable {
    let id: UUID = UUID()
    let name: String
    let assetName: String
    let subtitle: String
    let status: String
    var isEnabled: Bool
    var isPinned: Bool
}

#Preview {
    NavigationStack {
        PluginsView()
    }
}
