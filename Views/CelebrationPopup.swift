import SwiftUI
import AVFoundation

struct CelebrationPopup: View {
    @Binding var show: Bool
    var message: String

    @State private var player: AVAudioPlayer?

    var body: some View {
        ZStack {
            if show {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("🎉 Settled Up! 🎉")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                        .bold()
                        .padding(.top, 30)
                    Text(message)
                        .font(.title2)
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    ConfettiEmitterView()
                        .ignoresSafeArea()
                )
                .onAppear {
                    playCelebrationSound()
                }
                .onTapGesture {
                    show = false
                }
            }
        }
        .animation(.spring(), value: show)
    }

    private func playCelebrationSound() {
        guard let url = Bundle.main.url(forResource: "celebration", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.1
            player?.play()
        } catch { }
    }
}

// Simple confetti emitter using UIKit bridge
struct ConfettiEmitterView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width/2, y: 0)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        emitter.beginTime = CACurrentMediaTime()
        emitter.timeOffset = 0

        var cells: [CAEmitterCell] = []
        for color in [UIColor.systemRed, .systemGreen, .systemBlue, .systemYellow, .systemPurple, .systemPink] {
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 3.5
            cell.velocity = 250
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.spin = 3.5
            cell.scale = 0.8
            cell.scaleRange = 0.4
            cell.contents = UIImage(systemName: "circle.fill")?.withTintColor(color, renderingMode: .alwaysOriginal).cgImage
            cells.append(cell)
        }
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
