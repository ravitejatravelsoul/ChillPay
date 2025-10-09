import SwiftUI

/// Displays a user’s initials inside a colored circle.
/// A deterministic color palette is chosen based on the user's id string so that each user always has
/// the same avatar color.  This view is used throughout the UI wherever avatars are needed.
struct AvatarView: View {
    let user: User
    
    /// Deterministically pick a colour based on the user's id string.
    private var color: Color {
        let hash = abs(user.id.hashValue)
        let palette: [Color] = [.blue, .green, .orange, .pink, .purple, .red, .yellow, .teal]
        return palette[hash % palette.count]
    }
    
    var body: some View {
        let initial = String(user.name.prefix(1)).uppercased()
        Text(initial)
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(Circle().fill(color))
    }
}
