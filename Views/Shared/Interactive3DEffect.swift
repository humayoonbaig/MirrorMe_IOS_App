import SwiftUI

// MARK: - Interactive 3D Tilt Effect
// Gives a pseudo-3D parallax feel when the user drags/rotates
// their finger over an image. Applies rotation3DEffect on X and Y axes
// plus a subtle scale and shadow shift to sell the depth illusion.
//
// Uses a background GeometryReader to read size without disrupting layout.

struct Interactive3DEffect: ViewModifier {
    /// Maximum rotation angle in degrees
    var maxAngle: Double = 15
    /// Whether to add a shifting shadow for extra depth
    var enableShadow: Bool = true
    /// Whether to add a subtle specular highlight
    var enableHighlight: Bool = true

    @State private var viewSize: CGSize = CGSize(width: 200, height: 200)
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    // Normalized values from -1 to 1
    private var normalizedX: Double {
        guard viewSize.width > 0 else { return 0 }
        return min(max(dragOffset.width / (viewSize.width / 2), -1), 1)
    }
    private var normalizedY: Double {
        guard viewSize.height > 0 else { return 0 }
        return min(max(dragOffset.height / (viewSize.height / 2), -1), 1)
    }

    func body(content: Content) -> some View {
        content
            // Read size without affecting layout
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { viewSize = geo.size }
                        .onChange(of: geo.size) { _, newSize in
                            viewSize = newSize
                        }
                }
            )
            .rotation3DEffect(
                .degrees(-normalizedY * maxAngle),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(normalizedX * maxAngle),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .scaleEffect(isDragging ? 1.03 : 1.0)
            .overlay {
                if enableHighlight && isDragging {
                    LinearGradient(
                        colors: [
                            .white.opacity(0.15 * (1 + normalizedX)),
                            .clear
                        ],
                        startPoint: UnitPoint(
                            x: 0.5 + normalizedX * 0.3,
                            y: 0.5 + normalizedY * 0.3
                        ),
                        endPoint: UnitPoint(
                            x: 0.5 - normalizedX * 0.3,
                            y: 0.5 - normalizedY * 0.3
                        )
                    )
                    .allowsHitTesting(false)
                }
            }
            .shadow(
                color: enableShadow && isDragging
                    ? Color.black.opacity(0.2)
                    : Color.clear,
                radius: 12,
                x: -normalizedX * 8,
                y: -normalizedY * 8
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let centerX = viewSize.width / 2
                        let centerY = viewSize.height / 2
                        withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.7)) {
                            isDragging = true
                            dragOffset = CGSize(
                                width: value.location.x - centerX,
                                height: value.location.y - centerY
                            )
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            isDragging = false
                            dragOffset = .zero
                        }
                    }
            )
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.7), value: dragOffset)
    }
}

extension View {
    /// Adds an interactive 3D tilt effect — drag/swipe on the view to rotate it in 3D space.
    func interactive3DEffect(
        maxAngle: Double = 15,
        enableShadow: Bool = true,
        enableHighlight: Bool = true
    ) -> some View {
        modifier(Interactive3DEffect(
            maxAngle: maxAngle,
            enableShadow: enableShadow,
            enableHighlight: enableHighlight
        ))
    }
}
