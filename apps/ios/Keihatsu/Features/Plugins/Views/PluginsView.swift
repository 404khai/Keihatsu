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
    @State private var selectedPlugin: PluginSource?
    @State private var pendingBrowseSource: Source?

    @EnvironmentObject private var sources: SourcePreferencesStore
    @EnvironmentObject private var navigation: AppNavigation
    @State private var availableOnly = false

    private var plugins: [PluginSource] {
        sources.sortedSources.map { source in
            PluginSource(source: source, isEnabled: sources.isEnabled(source), isPinned: sources.isPinned(source), isAvailable: sources.isAvailable(source))
        }
    }

    private var filteredSourceItems: [PluginSource] {
        filteredAndSorted(plugins.filter(\.isEnabled))
    }

    private var filteredPluginItems: [PluginSource] {
        filteredAndSorted(plugins)
    }

    private func filteredAndSorted(_ items: [PluginSource]) -> [PluginSource] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let items = availableOnly ? items.filter(\.isAvailable) : items
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

                if sources.isLoading { ProgressView("Loading sources…") }
                if let error = sources.error {
                    CatalogueMessage(message: error) { Task { await sources.load(force: true) } }
                }
                VStack(spacing: 14) {
                    switch selectedTab {
                    case .sources:
                        if filteredSourceItems.isEmpty && !sources.isLoading {
                            CatalogueMessage(message: "No enabled sources. Add an available source from Extensions.")
                            Button("Browse Sources") { selectedTab = .plugins }
                        }
                        ForEach(filteredSourceItems) { item in
                            PluginCard(item: item) { selectedPlugin = item }
                        }
                    case .plugins:
                        Text("Enable available sources below. Downloadable extensions are not available yet.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        ForEach(filteredPluginItems) { item in
                            PluginCard(item: item) { selectedPlugin = item }
                        }
                    case .migrate:
                        Text("Source migration is not available yet.").font(.subheadline).foregroundStyle(.secondary)
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
        .task { await sources.load() }
        .refreshable { await sources.load(force: true) }
        .navigationTitle("Extensions")
        .navigationBarTitleDisplayMode(.automatic)
        .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search extensions"))
//        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
//        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Available sources only", isOn: $availableOnly)
                } label: { Image(systemName: "line.3.horizontal.decrease") }
                .accessibilityLabel("Filter sources")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button { selectedTab = .plugins } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add source")
            }
        }
        .sheet(item: $selectedPlugin, onDismiss: {
            if let source = pendingBrowseSource {
                pendingBrowseSource = nil
                navigation.extensionsPath.append(source)
            }
        }) { item in
            ExtensionDetailsSheet(
                source: item.source,
                isEnabled: item.isEnabled,
                onDisable: { sources.setEnabled(false, source: item.source) },
                onBrowse: { pendingBrowseSource = item.source }
            )
        }
        .navigationDestination(for: Source.self) { source in
            ExtensionBrowseView(source: source, repository: environment.services.catalogue)
        }
    }

    @EnvironmentObject private var environment: AppEnvironment
}

private struct PluginCard: View {
    let item: PluginSource
    let showDetails: () -> Void
    @EnvironmentObject private var sources: SourcePreferencesStore

    var body: some View {
        HStack(spacing: 14) {
            ExtensionImageView(sourceID: item.source.id, url: item.source.iconURL, size: 60, cornerRadius: 14)

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
                    sources.setPinned(!item.isPinned, source: item.source)
                } label: {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.body)
                        .foregroundStyle(item.isPinned ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.isPinned ? "Unpin \(item.name)" : "Pin \(item.name)")

                Toggle("Enable \(item.name)", isOn: Binding(get: { item.isEnabled }, set: { sources.setEnabled($0, source: item.source) }))
                    .disabled(!item.isAvailable)
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
        .contentShape(Rectangle())
        .onTapGesture(perform: showDetails)
    }
}

private struct MigratePluginRow: View {
    let item: PluginSource

    var body: some View {
        HStack(spacing: 14) {
            CatalogueCover(url: item.source.iconURL)
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
                Image(systemName: "arrow.up.arrow.down")
                    .frame(width: 44, height: 44)
//                Image(systemName: "arrow.up.arrow.down")
//                    .font(.title2.weight(.semibold))
//                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .disabled(true)
            .accessibilityLabel("Migration unavailable")
            .glassEffect(.regular)
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
        case .plugins: return "Extensions"
        case .migrate: return "Migrate"
        }
    }
}

private struct PluginSource: Identifiable {
    let source: Source
    let isEnabled: Bool
    let isPinned: Bool
    let isAvailable: Bool
    var id: String { source.id }
    var name: String { source.name }
    var subtitle: String { source.language.uppercased() + " • " + (source.baseURL?.absoluteString ?? "") }
    var status: String { !isAvailable ? "Coming soon" : isEnabled ? "Enabled" : "Available" }
}

#Preview {
    NavigationStack {
        PluginsView()
            .appEnvironment(.preview())
    }
}
