import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle).bold()
            Text("Profile info, settings, and payment platform integration coming soon!")
                .foregroundColor(.secondary)
            // TODO: Profile info, avatar upload, settings, payment integrations
        }
        .padding()
    }
}
