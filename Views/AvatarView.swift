import SwiftUI

struct AvatarView: View {
    let user: User
    var size: CGFloat = 32

    var body: some View {
        avatarContent()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }

    // ---------------------------------------------------------
    // MARK: - MAIN VIEW DECISION (NO GROUP / NO CLOSURES)
    // ---------------------------------------------------------
    @ViewBuilder
    private func avatarContent() -> some View {
        if hasValidDiceBear() {
            RemoteAvatarImage(url: dicebearURL()!,
                              fallbackColor: user.avatarColor)
        }
        else if let emoji = user.avatar, emoji.isEmpty == false {
            Text(emoji)
                .font(.system(size: size * 0.7))
                .frame(width: size, height: size)
        }
        else {
            Circle()
                .fill(user.avatarColor)
                .overlay(
                    Text(user.initial)
                        .foregroundColor(.white)
                        .font(.system(size: size * 0.45, weight: .bold))
                )
        }
    }

    // ---------------------------------------------------------
    // MARK: - Helpers
    // ---------------------------------------------------------
    private func hasValidDiceBear() -> Bool {
        if let s = user.avatarSeed,
           let st = user.avatarStyle,
           !s.isEmpty,
           !st.isEmpty {
            return true
        }
        return false
    }

    private func dicebearURL() -> URL? {
        guard let seed = user.avatarSeed,
              let style = user.avatarStyle else { return nil }

        let url = "https://api.dicebear.com/7.x/\(style)/png?seed=\(seed)&size=256"
        return URL(string: url)
    }
}

// -------------------------------------------------------------
// MARK: - Remote Image Loader (No AsyncImage)
// -------------------------------------------------------------
struct RemoteAvatarImage: View {
    let url: URL
    let fallbackColor: Color

    @State private var imageData: Data? = nil

    var body: some View {
        ZStack {
            if let data = imageData,
               let uiImg = UIImage(data: data) {

                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(fallbackColor)
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                self.imageData = data
            }
        }.resume()
    }
}
