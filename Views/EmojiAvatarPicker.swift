import SwiftUI

let emojiAvatars = ["🦄", "🐱", "🐶", "🐻", "🐯", "🐸", "🐼", "🦊", "🐵", "🐧", "🐤", "🦁", "🐮", "🐷", "🐨", "🦋", "🐞", "🦖", "🦩", "🕊️", "🌸", "🍕", "⚽️", "🎸", "🚗", "🚀", "🎮", "🏄‍♂️", "🎧", "📚", "💎", "🌈", "🔥", "⭐️", "💡"]

struct EmojiAvatarPicker: View {
    @Binding var selectedAvatar: String?
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 16), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(emojiAvatars, id: \.self) { emoji in
                Button {
                    selectedAvatar = emoji
                } label: {
                    ZStack {
                        Circle()
                            .fill(selectedAvatar == emoji ? ChillTheme.accent.opacity(0.25) : Color.clear)
                            .frame(width: 48, height: 48)
                        Text(emoji)
                            .font(.system(size: 32))
                        if selectedAvatar == emoji {
                            Circle()
                                .stroke(ChillTheme.accent, lineWidth: 3)
                                .frame(width: 48, height: 48)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}
