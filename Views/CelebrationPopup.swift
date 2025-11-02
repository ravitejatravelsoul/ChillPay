import SwiftUI
import AVFoundation

struct CelebrationPopup: View {
    @Binding var show: Bool
    var message: String

    @State private var player: AVAudioPlayer?
    @State private var dismissTask: DispatchWorkItem?

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
                    ConfettiEmitterView(show: $show)
                        .ignoresSafeArea()
                )
                .onAppear {
                    playCelebrationSound()
                    scheduleDismiss()
                }
                .onDisappear {
                    dismissTask?.cancel()
                }
                .onTapGesture {
                    show = false
                }
            }
        }
        .animation(.spring(), value: show)
    }

    private func playCelebrationSound() {
        print("DEBUG: playCelebrationSound called")
        guard let url = Bundle.main.url(forResource: "celebration", withExtension: "wav") else {
            print("DEBUG: Sound file not found in bundle!")
            return
        }
        print("DEBUG: Sound file found at \(url)")
        do {
            player = try AVAudioPlayer(contentsOf: url)
            print("DEBUG: AVAudioPlayer initialized")
            player?.volume = 0.7
            let played = player?.play() ?? false
            print("DEBUG: AVAudioPlayer play() called, result: \(played)")
        } catch {
            print("DEBUG: Error initializing AVAudioPlayer: \(error)")
        }
    }

    private func scheduleDismiss() {
        let task = DispatchWorkItem {
            show = false
        }
        dismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: task)
    }
}

// --- Confetti with varied shapes and colors ---
struct ConfettiEmitterView: UIViewRepresentable {
    @Binding var show: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width/2, y: 0)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        emitter.beginTime = CACurrentMediaTime()
        emitter.timeOffset = 0

        emitter.birthRate = show ? 1 : 0

        var cells: [CAEmitterCell] = []
        let colors: [UIColor] = [.systemRed, .systemGreen, .systemBlue, .systemYellow, .systemPurple, .systemPink, .systemOrange, .systemTeal]
        let shapes: [ConfettiShape] = [.rectangle, .triangle, .star, .circle]
        for color in colors {
            for shape in shapes {
                let cell = CAEmitterCell()
                cell.birthRate = 10
                cell.lifetime = 2.5
                cell.velocity = 180
                cell.velocityRange = 60
                cell.emissionLongitude = .pi
                cell.spin = 4.0
                cell.spinRange = 2.0
                cell.scale = 0.18
                cell.scaleRange = 0.1
                cell.contents = shape.image(color: color, diameter: 14)
                cell.alphaSpeed = -0.25
                cell.yAcceleration = 90
                cells.append(cell)
            }
        }
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        // Stop confetti when popup is dismissed
        if !show, let emitter = uiView.layer.sublayers?.first(where: { $0 is CAEmitterLayer }) as? CAEmitterLayer {
            emitter.birthRate = 0
        }
    }

    enum ConfettiShape {
        case rectangle, triangle, star, circle

        func image(color: UIColor, diameter: CGFloat) -> CGImage? {
            let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(color.cgColor)
            switch self {
            case .rectangle:
                context?.fill(CGRect(x: 0, y: diameter/4, width: diameter, height: diameter/2))
            case .triangle:
                context?.beginPath()
                context?.move(to: CGPoint(x: diameter/2, y: 0))
                context?.addLine(to: CGPoint(x: diameter, y: diameter))
                context?.addLine(to: CGPoint(x: 0, y: diameter))
                context?.closePath()
                context?.fillPath()
            case .star:
                drawStar(in: context, rect: rect, color: color)
            case .circle:
                context?.fillEllipse(in: rect)
            }
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image?.cgImage
        }

        private func drawStar(in context: CGContext?, rect: CGRect, color: UIColor) {
            guard let context else { return }
            let starPath = UIBezierPath()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let pointsOnStar = 5
            let radius: CGFloat = rect.width / 2
            let extrusion: CGFloat = radius / 2.5
            let angle = CGFloat.pi * 2 / CGFloat(pointsOnStar)
            for i in 0..<pointsOnStar {
                let theta = angle * CGFloat(i) - CGFloat.pi / 2
                let x = center.x + radius * cos(theta)
                let y = center.y + radius * sin(theta)
                if i == 0 {
                    starPath.move(to: CGPoint(x: x, y: y))
                } else {
                    starPath.addLine(to: CGPoint(x: x, y: y))
                }
                let midTheta = theta + angle / 2
                let midX = center.x + extrusion * cos(midTheta)
                let midY = center.y + extrusion * sin(midTheta)
                starPath.addLine(to: CGPoint(x: midX, y: midY))
            }
            starPath.close()
            context.setFillColor(color.cgColor)
            context.addPath(starPath.cgPath)
            context.fillPath()
        }
    }
}
