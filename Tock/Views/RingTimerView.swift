import SwiftUI

struct RingTimerView: View {
    let progress: Double
    let displayTime: TimeInterval
    let color: Color
    let phaseLabel: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            VStack(spacing: 4) {
                Text(formatTimer(displayTime))
                    .font(.system(size: 38, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                Text(phaseLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
    }
}
