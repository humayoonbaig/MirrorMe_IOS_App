import SwiftUI



struct HomeView: View {

    @EnvironmentObject var store: AppStore
    @Binding var selectedTab: Int
    @AppStorage("userName") private var userName: String = "User"

    @State private var selectedOutfitForPreview: Outfit? = nil
    @State private var showAllCollection = false

    @ObservedObject private var weather = WeatherService.shared

    private var weatherIconColor: Color {
        let icon = weather.weatherIcon
        if icon.contains("sun") { return .orange }
        if icon.contains("snow") || icon.contains("sleet") { return .cyan }
        if icon.contains("rain") || icon.contains("drizzle") || icon.contains("heavyrain") { return .blue }
        if icon.contains("bolt") { return .yellow }
        if icon.contains("fog") { return .gray }
        return .blue
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<12: return "Good Morning,"
        case 12..<17: return "Good Afternoon,"
        case 17..<23: return "Good Evening,"
        default: return "Good Night,"
        }
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 25) {

                    // Header
                    headerSection

                    // Today's Plan
                    todayPlanHero

                    // Dashboard Stats
                    statsRow

                    // My Collection
                    VStack(alignment: .leading, spacing: 15) {

                        HStack {

                            Text("My Collection")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.deepWine)

                            Spacer()

                            Button("See All") {
                                showAllCollection = true
                            }
                            .font(.caption.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.burgundy, .rose],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }

                        .padding(.horizontal)

                        if store.savedOutfits.isEmpty {
                            emptyStateRectangle
                        } else {
                            savedOutfitsList
                        }
                    }

                    Spacer(minLength: 30)
                }
            }

            .background(Color.petal)
            .navigationBarTitleDisplayMode(.inline)

            .fullScreenCover(item: $selectedOutfitForPreview) { outfit in
                FullMannequinPopup(outfit: outfit)
            }

            .sheet(isPresented: $showAllCollection) {
                AllCollectionPopup()
            }
            .onAppear {
                weather.fetchWeatherIfAuthorized()
            }
        }
    }


    // MARK: Header Section

    var headerSection: some View {

        HStack {

            VStack(alignment: .leading, spacing: 4) {

                Text(greeting)
                    .font(.subheadline)
                    .foregroundColor(.mauve)

                Text(userName)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.deepWine)
            }

            Spacer()

            VStack(alignment: .trailing) {

                HStack(spacing: 4) {

                    Image(systemName: weather.weatherIcon)
                        .foregroundStyle(weatherIconColor)

                    Text(weather.temperature)
                        .bold()
                        .foregroundColor(.deepWine)
                }

                Text(weather.cityName)
                    .font(.caption2)
                    .foregroundColor(.mauve)
            }

            .padding(10)
            .background(
                LinearGradient(
                    colors: [Color.blushLight, Color.blush],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blushBorder, lineWidth: 1)
            )
            .onTapGesture {
                weather.toggleUnit()
            }
        }

        .padding(.horizontal)
        .padding(.top, 10)
    }


    // MARK: Today's Plan

    var todayPlanHero: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Today's Plan")
                .font(.headline)
                .foregroundColor(.deepWine)
                .padding(.horizontal)

            ZStack {

                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.burgundy, .rose],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                    .overlay {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.08))
                                .frame(width: 120, height: 120)
                                .offset(x: -60, y: -50)
                            Circle()
                                .fill(.white.opacity(0.06))
                                .frame(width: 80, height: 80)
                                .offset(x: 70, y: 40)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }

                HStack {

                    VStack(alignment: .leading, spacing: 8) {

                        Text(Date(), format: .dateTime.weekday(.wide).day().month())
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))

                        if let todayOutfit = store.outfit(for: Date()) {

                            Text(todayOutfit.name)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)

                            Button("View Details") {
                                selectedOutfitForPreview = todayOutfit
                            }

                            .font(.caption)
                            .bold()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.2))
                            .foregroundColor(.white)
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.4), lineWidth: 1)
                            )
                            .clipShape(Capsule())

                        } else {

                            Text("Nothing planned")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)

                            Button("Plan Now") {
                                selectedTab = 3
                            }

                            .font(.caption)
                            .bold()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.2))
                            .foregroundColor(.white)
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.4), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                        }
                    }

                    .padding(.leading, 24)

                    Spacer()

                    if let todayOutfit = store.outfit(for: Date()),
                       let snapshot = store.loadSnapshot(for: todayOutfit) {

                        Image(uiImage: snapshot)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .burgundy.opacity(0.4), radius: 10, y: 4)
                            .padding(.trailing, 30)
                    } else if let avatar = store.avatarImage {

                        Image(uiImage: avatar)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .burgundy.opacity(0.4), radius: 10, y: 4)
                            .padding(.trailing, 20)
                    }
                }
            }

            .padding(.horizontal)
            .shadow(color: .burgundy.opacity(0.25), radius: 12, y: 6)
        }
    }


    // MARK: Stats Row

    var statsRow: some View {

        HStack(spacing: 12) {

            Button(action: {
                selectedTab = 2
            }) {
                statCard(
                    title: "Items",
                    value: "\(store.allItemsCount)",
                    icon: "tshirt.fill",
                    gradient: [.burgundy, .rose]
                )
            }
            .buttonStyle(.plain)

            statCard(
                title: "Outfits",
                value: "\(store.savedOutfits.count)",
                icon: "sparkles",
                gradient: [.rose, .blush]
            )

            Button(action: {
                selectedTab = 3
            }) {
                statCard(
                    title: "Plan",
                    value: "Week",
                    icon: "calendar",
                    gradient: [.burgundy, .mauve]
                )
            }
            .buttonStyle(.plain)
        }

        .padding(.horizontal)
    }


    func statCard(title: String, value: String, icon: String, gradient: [Color]) -> some View {

        VStack(spacing: 8) {

            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.deepWine)

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.mauve)
        }

        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blushLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [gradient[0].opacity(0.08), gradient.last!.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blushBorder, lineWidth: 1)
        )
    }


    // MARK: Saved Outfits List

    var savedOutfitsList: some View {

        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 18) {

                ForEach(store.savedOutfits) { outfit in

                    VStack(alignment: .leading) {

                        ZStack {

                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blushLight, Color.blush],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            if let snapshot = store.loadSnapshot(for: outfit) {

                                Image(uiImage: snapshot)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(10)
                            } else if let avatar = store.avatarImage {

                                Image(uiImage: avatar)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(10)
                            }
                        }

                        .frame(width: 150, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [.rose.opacity(0.4), .blushBorder],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .burgundy.opacity(0.1), radius: 6, y: 3)

                        .onTapGesture {
                            selectedOutfitForPreview = outfit
                        }

                        Text(outfit.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.deepWine)
                            .padding(.leading, 4)
                    }

                    .contextMenu {

                        Button(role: .destructive) {

                            withAnimation {
                                store.deleteOutfit(outfit)
                            }

                        } label: {

                            Label("Delete Outfit", systemImage: "trash")
                        }
                    }
                }
            }

            .padding(.horizontal)
            .padding(.bottom, 10)
        }
    }


    // MARK: Empty State

    var emptyStateRectangle: some View {

        VStack(spacing: 12) {

            Image(systemName: "wand.and.stars")
                .font(.largeTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.burgundy, .rose],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("No saved looks yet")
                .font(.subheadline)
                .foregroundColor(.mauve)

            Button("Create First Outfit") {
                selectedTab = 1
            }
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.burgundy, .rose],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
        }

        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)

        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blushLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blushBorder, lineWidth: 1)
                )
        )

        .padding(.horizontal)
    }
}


// MARK: All Collection Popup

struct AllCollectionPopup: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: AppStore
    @State private var selectedOutfitForPreview: Outfit? = nil

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {

        NavigationStack {

            ScrollView {

                LazyVGrid(columns: columns, spacing: 20) {

                    ForEach(store.savedOutfits) { outfit in

                        VStack {

                            ZStack {

                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blushLight, Color.blush],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                if let snapshot = store.loadSnapshot(for: outfit) {

                                    Image(uiImage: snapshot)
                                        .resizable()
                                        .scaledToFit()
                                        .padding(5)
                                } else if let avatar = store.avatarImage {

                                    Image(uiImage: avatar)
                                        .resizable()
                                        .scaledToFit()
                                        .padding(5)
                                }
                            }

                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .interactive3DEffect(maxAngle: 12, enableHighlight: true)

                            Text(outfit.name)
                                .font(.caption)
                                .bold()
                                .foregroundColor(.deepWine)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedOutfitForPreview = outfit
                        }

                        .contextMenu {

                            Button(role: .destructive) {

                                withAnimation {
                                    store.deleteOutfit(outfit)
                                }

                            } label: {

                                Label("Delete Outfit", systemImage: "trash")
                            }
                        }
                    }
                }

                .padding()
            }

            .background(Color.petal)
            .navigationTitle("My Collection")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .navigationBarTrailing) {

                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.burgundy)
                }
            }
            .fullScreenCover(item: $selectedOutfitForPreview) { outfit in
                FullMannequinPopup(outfit: outfit)
            }
        }
    }
}


// MARK: Full Mannequin Popup

struct FullMannequinPopup: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: AppStore

    let outfit: Outfit

    var body: some View {

        ZStack(alignment: .topTrailing) {

            LinearGradient(
                colors: [
                    Color.petal,
                    Color.blushLight,
                    Color.blush.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {

                HStack {

                    Text(outfit.name)
                        .font(.headline)
                        .foregroundColor(.deepWine)

                    Spacer()

                    Button(action: {
                        dismiss()
                    }) {

                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.burgundy, .rose],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }

                .padding()

                Spacer()

                if let snapshot = store.loadSnapshot(for: outfit) {

                    Image(uiImage: snapshot)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .interactive3DEffect(maxAngle: 18, enableShadow: true)
                        .shadow(color: .burgundy.opacity(0.2), radius: 12)
                } else if let avatar = store.avatarImage {

                    Image(uiImage: avatar)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .interactive3DEffect(maxAngle: 18, enableShadow: true)
                        .shadow(color: .burgundy.opacity(0.2), radius: 12)
                }

                Spacer()
            }
        }
    }
}
