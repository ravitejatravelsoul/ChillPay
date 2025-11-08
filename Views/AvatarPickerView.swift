import SwiftUI

struct DiceBearStyle: Identifiable {
    var id: String { style }
    let style: String
    let display: String
}

let diceBearStyles: [DiceBearStyle] = [
    .init(style: "adventurer", display: "Adventurer"),
    .init(style: "micah", display: "Micah"),
    .init(style: "miniavs", display: "Miniavs"),
    .init(style: "thumbs", display: "Thumbs"),
    .init(style: "notionists", display: "Notionists"),
    .init(style: "bottts", display: "Bottts"),
]

struct AvatarPickerView: View {
    @Binding var avatarSeed: String   // Usually username or random slug
    @Binding var avatarStyle: String // One from diceBearStyles

    @State private var previewUrl: URL? = nil

    @State private var currentSeed: String = ""
    @State private var currentStyle: String = "adventurer"

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Choose Your Avatar")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 8)

            VStack(spacing: 12) {
                if let url = previewUrl {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Circle())
                            .frame(width: 120, height: 120)
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: 3))
                    } placeholder: {
                        ProgressView()
                            .frame(width: 120, height: 120)
                    }
                }
                HStack(spacing: 4) {
                    Text("Style:")
                    Picker("Avatar style", selection: $currentStyle) {
                        ForEach(diceBearStyles) { style in
                            Text(style.display).tag(style.style)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .font(.subheadline)

                HStack(spacing: 4) {
                    Text("Seed:") // = unique identifier
                    TextField("avatar seed", text: $currentSeed)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    Button("Random") {
                        currentSeed = UUID().uuidString.prefix(8).lowercased()
                    }
                    .font(.caption)
                }
                .font(.subheadline)
            }
            .padding(.bottom, 4)

            Text("Your avatar is generated from this style and seed and can be customized anytime.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: {
                avatarSeed = currentSeed
                avatarStyle = currentStyle
            }) {
                Text("Save Avatar")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding()
        .onAppear {
            currentSeed = avatarSeed
            currentStyle = avatarStyle.isEmpty ? "adventurer" : avatarStyle
            updatePreview()
        }
        .onChange(of: currentSeed) { _,_ in
            updatePreview()
        }
        .onChange(of: currentStyle) { _,_ in
            updatePreview()
        }
    }

    // Use PNG endpoint for preview!
    private func updatePreview() {
        let urlString = "https://api.dicebear.com/7.x/\(currentStyle)/png?seed=\(currentSeed)"
        previewUrl = URL(string: urlString)
    }
}
