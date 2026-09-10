import SwiftUI

struct LibraryUpdatesCalendarView: View {
    @Environment(\.keihatsuTheme) private var theme
    @State private var selectedDate = Date.now

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xxl) {
                DatePicker(
                    "Update date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(theme.spacing.lg)
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: theme.radius.large, style: .continuous)
                )

                ContentUnavailableView {
                    Label("No Scheduled Updates", systemImage: "calendar.badge.clock")
                } description: {
                    Text("Release schedules are not available from connected sources yet.")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.xxxl)
            }
            .padding(.horizontal, theme.spacing.screenPadding)
            .padding(.vertical, theme.spacing.lg)
        }
        .navigationTitle("Upcoming")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LibraryUpdatesCalendarView()
            .appEnvironment(.preview())
    }
}
