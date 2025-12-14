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

    /// Internally track the currently selected seed and style.
    @State private var currentSeed: String = ""
    @State private var currentStyle: String = "adventurer"
    @State private var candidateSeeds: [String] = []
    @State private var savedMessage: String? = nil
    @State private var isSaving: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Live preview of the selected avatar
            VStack {
                if let url = previewURL(for: currentSeed, style: currentStyle) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(ChillTheme.accent, lineWidth: 3))
                    } placeholder: {
                        ProgressView()
                            .frame(width: 120, height: 120)
                    }
                }
                Text(currentStyle.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Style picker as a segmented control menu
            Picker("Style", selection: $currentStyle) {
                ForEach(diceBearStyles) { style in
                    Text(style.display).tag(style.style)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Grid of candidate seeds for quick selection
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(candidateSeeds, id: \.self) { seed in
                    Button(action: {
                        currentSeed = seed
                    }) {
                        VStack {
                            if let url = previewURL(for: seed, style: currentStyle) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 72, height: 72)
                                }
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(currentSeed == seed ? ChillTheme.accent : Color.clear, lineWidth: 3)
                        )
                    }
                }
            }
            .padding(.horizontal)

            // Shuffle button to regenerate candidate seeds
            Button(action: generateCandidates) {
                HStack {
                    Image(systemName: "shuffle")
                    Text("Shuffle")
                }
                .font(.headline)
                .foregroundColor(ChillTheme.accent)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(ChillTheme.card)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ChillTheme.accent, lineWidth: 1)
                )
            }

            // Save Avatar button and feedback
            Button(action: saveAvatar) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ChillTheme.accent))
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text(savedMessage ?? "Save Avatar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(isSaving ? ChillTheme.card : ChillTheme.accent)
            .foregroundColor(.white)
            .cornerRadius(14)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .onAppear {
            // Initialize state with bindings
            currentSeed = avatarSeed.isEmpty ? UUID().uuidString.prefix(8).lowercased() : avatarSeed
            currentStyle = avatarStyle.isEmpty ? "adventurer" : avatarStyle
            generateCandidates()
        }
        .onChange(of: currentStyle) { _, _ in
            // When style changes, refresh candidate previews
            generateCandidates()
        }
    }

    /// Generates a new set of candidate seeds including the currently selected seed. Called on appear and when shuffling.
    private func generateCandidates() {
        // Always include the current seed at the beginning
        var seeds: [String] = [currentSeed]
        while seeds.count < 6 {
            let newSeed = UUID().uuidString.prefix(8).lowercased()
            if !seeds.contains(String(newSeed)) {
                seeds.append(String(newSeed))
            }
        }
        self.candidateSeeds = seeds
    }

    /// Constructs a URL for a DiceBear avatar preview given a seed and style.
    private func previewURL(for seed: String, style: String) -> URL? {
        let urlString = "https://api.dicebear.com/7.x/\(style)/png?seed=\(seed)"
        return URL(string: urlString)
    }

    /// Handles saving the currently selected avatar back to the binding values and shows feedback. If a user is logged in,
    /// also persists the new avatar to Firestore via AuthService.
    private func saveAvatar() {
        guard !isSaving else { return }
        isSaving = true
        // Update bindings immediately
        avatarSeed = currentSeed
        avatarStyle = currentStyle
        // If there is a logged in user, persist to Firestore
        if AuthService.shared.user != nil {
            AuthService.shared.updateDiceBearAvatar(seed: currentSeed, style: currentStyle)
        }
        // Provide success feedback
        savedMessage = "Saved ✅"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.savedMessage = nil
            self.isSaving = false
        }
    }
}
