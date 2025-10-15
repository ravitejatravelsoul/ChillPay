import SwiftUI

struct ParticipantsWrapView: View {
    let users: [User]
    @Binding var selectedParticipants: Set<User>
    
    var body: some View {
        FlexibleView(
            data: Array(users),
            spacing: 8,
            alignment: .leading
        ) { user in
            Button(action: {
                if selectedParticipants.contains(user) {
                    selectedParticipants.remove(user)
                } else {
                    selectedParticipants.insert(user)
                }
            }) {
                HStack {
                    AvatarView(user: user)
                        .frame(width: 28, height: 28)
                    Text(user.name)
                        .font(.subheadline)
                        .foregroundColor(selectedParticipants.contains(user) ? .white : .gray)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(selectedParticipants.contains(user) ? Color.green : Color(.systemGray4))
                .cornerRadius(14)
            }
        }
    }
}

struct FlexibleView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            ForEach(Array(data.enumerated()), id: \.element.id) { (index, item) in
                content(item)
                    .padding(.trailing, spacing)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height + spacing
                        }
                        let result = width
                        if index == data.count - 1 {
                            width = 0
                        } else {
                            width -= d.width + spacing
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if index == data.count - 1 {
                            height = 0
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geo.size.height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { value in
            binding.wrappedValue = value
        }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
