import SwiftUI

struct ProfileView: View {
    var body: some View {
        ProfilePageContent()
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .appEnvironment(.preview())
    }
}
