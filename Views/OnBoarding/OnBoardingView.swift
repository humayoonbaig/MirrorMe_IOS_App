import SwiftUI
import CoreLocation



// MARK: - Main Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var store: AppStore

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("isFirstLaunchh") private var isFirstLaunch: Bool = true

    @State private var currentStep: OnboardingStep = .name

    // Step 3 State
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var processedImage: UIImage? = nil
    @State private var isProcessing = false

    // Animation states
    @State private var animateGlow = false

    enum OnboardingStep: CaseIterable {
        case name, location, mannequin
    }

    private var stepIndex: Int {
        switch currentStep {
        case .name: return 0
        case .location: return 1
        case .mannequin: return 2
        }
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating decorative orbs
            decorativeOrbs

            VStack(spacing: 0) {
                // Step indicator
                stepIndicator
                    .padding(.top, 16)

                Spacer()

                // Step content
                Group {
                    switch currentStep {
                    case .name:
                        nameStepView
                    case .location:
                        locationStepView
                    case .mannequin:
                        mannequinStepView
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }

    // MARK: - Background colors per step
    private var backgroundColors: [Color] {
        switch currentStep {
        case .name:
            return [Color.petal, Color.blushLight, Color.petal]
        case .location:
            return [Color.blushLight, Color.petal, Color.blush]
        case .mannequin:
            return [Color.petal, Color.blush, Color.blushLight]
        }
    }

    // MARK: - Decorative Orbs
    private var decorativeOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [Color.rose.opacity(0.2), .clear],
                                   center: .center, startRadius: 0, endRadius: 120)
                )
                .frame(width: 240, height: 240)
                .offset(x: animateGlow ? -100 : -120, y: animateGlow ? -280 : -300)

            Circle()
                .fill(
                    RadialGradient(colors: [Color.burgundy.opacity(0.1), .clear],
                                   center: .center, startRadius: 0, endRadius: 100)
                )
                .frame(width: 200, height: 200)
                .offset(x: animateGlow ? 130 : 110, y: animateGlow ? 300 : 280)

            Circle()
                .fill(
                    RadialGradient(colors: [Color.mauve.opacity(0.1), .clear],
                                   center: .center, startRadius: 0, endRadius: 80)
                )
                .frame(width: 160, height: 160)
                .offset(x: animateGlow ? 100 : 120, y: animateGlow ? -150 : -170)
        }
        .ignoresSafeArea()
    }

    // MARK: - Step Indicator
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(index <= stepIndex
                          ? LinearGradient(colors: [.burgundy, .rose], startPoint: .leading, endPoint: .trailing)
                          : LinearGradient(colors: [Color.blushBorder, Color.blushBorder], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: index == stepIndex ? 32 : 12, height: 5)
                    .animation(.spring(response: 0.4), value: stepIndex)
            }
        }
    }

    // MARK: - Process Avatar
    private func processAvatar(_ image: UIImage) {
        isProcessing = true
        Task {
            let result = await ImagePreProcessor.removePersonBackground(image)
            await MainActor.run {
                processedImage = result
                isProcessing = false
            }
        }
    }

    // MARK: - Step 1: Name Input
    private var nameStepView: some View {
        VStack(spacing: 0) {
            // App Logo
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: Color.burgundy.opacity(0.3), radius: 12, y: 4)
                .padding(.bottom, 28)

            Text("Welcome to")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.mauve)

            Text("MirrorMe")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.burgundy, .rose],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .padding(.bottom, 8)

            Text("What should we call you?")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.mauve)
                .padding(.bottom, 32)

            // Text field card
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.rose.opacity(0.6))

                TextField("Your Name", text: $userName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.deepWine)
                    .autocorrectionDisabled()
                    .onSubmit {
                        if !userName.isEmpty { withAnimation { currentStep = .location } }
                    }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.petal)
                    .shadow(color: Color.burgundy.opacity(0.08), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: userName.isEmpty
                                ? [Color.clear, Color.clear]
                                : [Color.burgundy.opacity(0.3), Color.rose.opacity(0.2)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .padding(.horizontal, 30)
            .padding(.bottom, 36)

            if !userName.isEmpty {
                Button {
                    withAnimation { currentStep = .location }
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .modifier(PrimaryOnboardingButton(colors: [.burgundy, .rose]))
                .padding(.horizontal, 30)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: userName.isEmpty)
    }

    // MARK: - Step 2: Location Permission
    @State private var locationRequested = false

    @ObservedObject private var weatherService = WeatherService.shared

    private var locationStepView: some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.rose.opacity(0.2), Color.burgundy.opacity(0.1)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "location.fill")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [.rose, .burgundy],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(.bottom, 28)

            Text("Rain or Shine?")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.burgundy, .rose],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .padding(.bottom, 12)

            Text("Enable location to get local weather\nand plan your outfits perfectly")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.mauve)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .padding(.bottom, 36)

            // Weather illustration card
            HStack(spacing: 20) {
                weatherPill(icon: "sun.max.fill", color: .orange, label: "Sunny")
                weatherPill(icon: "cloud.rain.fill", color: .blue, label: "Rainy")
                weatherPill(icon: "snowflake", color: .cyan, label: "Cold")
            }
            .padding(.bottom, 40)

            if locationRequested {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.burgundy)
                    Text("Waiting for permission...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.mauve)
                }
                .padding(.bottom, 12)
            } else {
                Button {
                    locationRequested = true
                    weatherService.requestPermission()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Enable Location")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .modifier(PrimaryOnboardingButton(colors: [.burgundy, .rose]))
                .padding(.horizontal, 30)
                .padding(.bottom, 12)
            }

            Button {
                withAnimation { currentStep = .mannequin }
            } label: {
                Text("Skip for now")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.mauve)
            }
        }
        .onChange(of: weatherService.authorizationStatus.rawValue) { _, rawStatus in
            guard locationRequested else { return }
            let status = CLAuthorizationStatus(rawValue: rawStatus) ?? .notDetermined
            switch status {
            case .authorizedWhenInUse, .authorizedAlways, .denied, .restricted:
                withAnimation { currentStep = .mannequin }
            default:
                break
            }
        }
    }

    private func weatherPill(icon: String, color: Color, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.mauve)
        }
    }

    // MARK: - Step 3: Create Mannequin
    private var mannequinStepView: some View {
        VStack(spacing: 20) {
            // Header Section
            VStack(spacing: 10) {
                Text("Create Your Look")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.burgundy, .rose],
                                       startPoint: .leading, endPoint: .trailing)
                    )

                Text("Take a full-body photo in good lighting\nto try on clothes perfectly")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.mauve)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            // Image Container
            ZStack {
                Circle().fill(Color.rose.opacity(0.12)).frame(width: 200).blur(radius: 50).offset(x: -80, y: -80)
                Circle().fill(Color.burgundy.opacity(0.08)).frame(width: 200).blur(radius: 50).offset(x: 80, y: 80)

                ZStack {
                    GeometryReader { geo in
                        ZStack {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.petal.opacity(0.6))
                                .background(.ultraThinMaterial)

                            if isProcessing {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.burgundy)
                                    Text("Removing background...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.mauve)
                                }
                            } else if let image = processedImage {
                                Color.blush.opacity(0.3)
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .padding(10)
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "person.fill.viewfinder")
                                        .font(.system(size: 48))
                                        .foregroundStyle(
                                            LinearGradient(colors: [.burgundy, .rose],
                                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                    Text("Your mannequin photo\nwill appear here")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.mauve)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                }
                .aspectRatio(3.0/4.0, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(colors: [Color.petal.opacity(0.8), Color.rose.opacity(0.2)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.burgundy.opacity(0.1), radius: 20, y: 8)

                // Refresh button
                if processedImage != nil && !isProcessing {
                    VStack {
                        HStack {
                            Spacer()
                            Button { processedImage = nil } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.burgundy)
                                    .padding(12)
                                    .background(Color.petal, in: Circle())
                                    .shadow(color: Color.burgundy.opacity(0.15), radius: 8, y: 2)
                            }
                            .padding(12)
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 30)

            Spacer()

            // Buttons Section
            if isProcessing {
                EmptyView()
            } else if processedImage == nil {
                VStack(spacing: 14) {
                    Button { showCamera = true } label: {
                        Label("Take a Photo", systemImage: "camera.fill")
                    }
                    .modifier(PrimaryOnboardingButton(colors: [.burgundy, .rose]))

                    Button { showLibrary = true } label: {
                        Label("Upload from Gallery", systemImage: "photo.on.rectangle.angled")
                    }
                    .modifier(SecondaryOnboardingButton())
                }
                .padding(.horizontal, 30)
            } else {
                VStack(spacing: 12) {
                    Button {
                        if let img = processedImage {
                            store.saveAvatar(img)
                            withAnimation { isFirstLaunch = false }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Finish Setup")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .modifier(PrimaryOnboardingButton(colors: [.green, .emerald]))

                    Button { processedImage = nil } label: {
                        Text("Try a different photo")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.mauve)
                    }
                }
                .padding(.horizontal, 30)
            }
        }
        .padding(.top, 16)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerUIKit { img, _ in
                showCamera = false
                if let img { processAvatar(img) }
            }.ignoresSafeArea()
        }
        .sheet(isPresented: $showLibrary) {
            PhotoLibraryPicker { img, _ in
                showLibrary = false
                if let img { processAvatar(img) }
            }
        }
    }
}

// MARK: - Modifiers & Helpers
struct PrimaryOnboardingButton: ViewModifier {
    var colors: [Color]
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .shadow(color: colors.first!.opacity(0.3), radius: 10, y: 5)
    }
}

struct SecondaryOnboardingButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.deepWine)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Color.petal,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(Color.blushBorder, lineWidth: 1)
            )
    }
}

extension Color {
    static let emerald = Color(red: 16/255, green: 185/255, blue: 129/255)
}
