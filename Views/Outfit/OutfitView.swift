import SwiftUI



// MARK: - Try-On Combo Lookup
struct TryOnLookup {
    enum Shirt   { case white, grey, darkBlue }
    enum Bottom  { case khaki, blackJeans, blueJeans }
    enum Shoes   { case barefoot, blackChelsea, puma }

    private static func searchString(for item: ClothingItem?) -> String {
        guard let item else { return "" }
        return [item.name, item.builtInImageName, item.imageFileName, item.originalFileName, item.brand]
            .joined(separator: " ")
            .lowercased()
    }

    static func shirtKey(for item: ClothingItem?) -> Shirt {
        guard item != nil else { return .white }
        let s = searchString(for: item)
        if s.contains("dark_blue_shirt") { return .darkBlue }
        if s.contains("grey_shirt")      { return .grey }
        if s.contains("dark blue") || s.contains("dark") || s.contains("navy") { return .darkBlue }
        if s.contains("grey") || s.contains("gray") { return .grey }
        if s.contains("blue") && s.contains("shirt") { return .darkBlue }
        return .white
    }

    static func bottomKey(for item: ClothingItem?) -> Bottom {
        guard item != nil else { return .khaki }
        let s = searchString(for: item)
        if s.contains("black_jeans") { return .blackJeans }
        if s.contains("blue_jeans")  { return .blueJeans }
        if s.contains("black") { return .blackJeans }
        if s.contains("blue")  { return .blueJeans }
        return .khaki
    }

    static func shoesKey(for item: ClothingItem?) -> Shoes {
        guard item != nil else { return .barefoot }
        let s = searchString(for: item)
        if s.contains("puma") || s.contains("sneaker") || s.contains("trainer") || s.contains("running") || s.contains("puma_shoes") { return .puma }
        if s.contains("black_chelsea_shoes") || s.contains("chelsea") || s.contains("boot") || s.contains("black") || s.contains("leather") { return .blackChelsea }
        return .barefoot
    }

    static func assetName(shirt: Shirt, bottom: Bottom, shoes: Shoes) -> String {
        switch (shirt, bottom, shoes) {
        case (.white, .khaki,      .barefoot):     return "Human_Mannequin"
        case (.white, .khaki,      .blackChelsea): return "Black Boots AI"
        case (.white, .khaki,      .puma):         return "Puma Shoes AI"
        case (.white, .blackJeans, .barefoot):     return "Black Jeans AI"
        case (.white, .blackJeans, .blackChelsea): return "Black Jeans AI"
        case (.white, .blackJeans, .puma):         return "Black Jeans AI"
        case (.white, .blueJeans,  .barefoot):     return "Blue Jeans AI"
        case (.white, .blueJeans,  .blackChelsea): return "Blue Jeans AI"
        case (.white, .blueJeans,  .puma):         return "Blue Jeans AI"
        case (.grey, .khaki,      .barefoot):     return "Grey Shirt AI"
        case (.grey, .khaki,      .blackChelsea): return "Black Boots AI"
        case (.grey, .khaki,      .puma):         return "Puma Shoes AI"
        case (.grey, .blackJeans, .barefoot):     return "Grey Shirt_Black Jeans AI"
        case (.grey, .blackJeans, .blackChelsea): return "Grey Shirt_Black Jeans_Black Shoes AI"
        case (.grey, .blackJeans, .puma):         return "Grey Shirt_Black Jeans_Puma Shoes AI"
        case (.grey, .blueJeans,  .barefoot):     return "Grey Shirt_Blu Jeans AI"
        case (.grey, .blueJeans,  .blackChelsea): return "Grey SHhirt_Blue Jeans_Black Boots AI"
        case (.grey, .blueJeans,  .puma):         return "Grey Shirt_Blue Jeans_Puma Shoes AI"
        case (.darkBlue, .khaki,      .barefoot):     return "Dark Blue Shirt AI"
        case (.darkBlue, .khaki,      .blackChelsea): return "Dark Blue_Black Shirt_Black Boots AI"
        case (.darkBlue, .khaki,      .puma):         return "Dark Blue Shirt AI"
        case (.darkBlue, .blackJeans, .barefoot):     return "Dark Blue Shirt_Black Jeans AI"
        case (.darkBlue, .blackJeans, .blackChelsea): return "Dark Blue_Black Shirt_Black Boots AI"
        case (.darkBlue, .blackJeans, .puma):         return "Dark Blue Shirt_Black Jeans_Puma Shoes AI"
        case (.darkBlue, .blueJeans,  .barefoot):     return "Dark Blue Shirt_Blue Jeans AI"
        case (.darkBlue, .blueJeans,  .blackChelsea): return "Dark Blue Shirt_Blue Jeans_Black Boots AI"
        case (.darkBlue, .blueJeans,  .puma):         return "Dark Blue Shirt_Blue Jeans_Puma Shoes AI"
        }
    }

    static func resolve(selections: [ClothingCategory: ClothingItem]) -> String {
        let shirt  = shirtKey(for: selections[.top])
        let bottom = bottomKey(for: selections[.bottom])
        let shoes  = shoesKey(for: selections[.shoes])
        return assetName(shirt: shirt, bottom: bottom, shoes: shoes)
    }
}

// MARK: - UI Support: Shimmer Effect
struct ShimmerView: View {
    @State private var startPoint: UnitPoint = .init(x: -1.8, y: -1.2)
    @State private var endPoint: UnitPoint = .init(x: 0, y: -0.2)

    var body: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(0.3), .clear],
            startPoint: startPoint,
            endPoint: endPoint
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                startPoint = .init(x: 1, y: 1)
                endPoint = .init(x: 2.2, y: 2.2)
            }
        }
    }
}

// MARK: - OutfitView
struct OutfitView: View {
    @EnvironmentObject var store: AppStore
    @Binding var selectedTab: Int
    @Binding var previousTab: Int
    @State private var activeCategory: ClothingCategory? = nil
    @State private var showAvatarMenu = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showSaveOutfit  = false
    @State private var processedComposite: UIImage? = nil
    @State private var isProcessingComposite = false
    @State private var processingStage: String = ""
    @State private var processingProgress: CGFloat = 0
    @State private var showSavedBanner = false
    @State private var outfitCountBeforeSave = 0

    var sortedSelections: [(ClothingCategory, ClothingItem)] {
        store.selectedItems.sorted { $0.key.layerOrder < $1.key.layerOrder }
    }

    var compositeAssetName: String {
        TryOnLookup.resolve(selections: store.selectedItems)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                heroCanvas
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                selectedItemsStrip
                    .padding(.top, 10)

                categoryPills
                    .padding(.top, 10)

                confirmButton
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 16)
            }
            .background(Color.petal)
            .navigationTitle("Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showCamera) {
                CameraPickerUIKit { image, _ in
                    showCamera = false
                    if let image { processAndSaveAvatar(image) }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoLibraryPicker { image, _ in
                    showPhotoLibrary = false
                    if let image { processAndSaveAvatar(image) }
                }
            }
            .sheet(item: $activeCategory) { cat in
                ItemPickerSheet(category: cat) { item in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        if let item {
                            store.selectItem(item)
                        } else {
                            store.removeItem(for: cat)
                        }
                    }
                    activeCategory = nil
                }
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: showSaveOutfit) { _, isShowing in
                if isShowing {
                    outfitCountBeforeSave = store.savedOutfits.count
                }
            }
            .sheet(isPresented: $showSaveOutfit, onDismiss: {
                if store.savedOutfits.count > outfitCountBeforeSave {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showSavedBanner = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSavedBanner = false
                        }
                    }
                }
            }) {
                SaveOutfitSheet(snapshot: processedComposite)
                    .presentationDetents([.fraction(0.38)])
            }
            .overlay(alignment: .top) {
                if showSavedBanner {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        Text("Saved successfully in My Collection")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(colors: [.burgundy, .rose],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: Color.burgundy.opacity(0.3), radius: 10, y: 4)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                }
            }
        }
    }

    var heroCanvas: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.blushLight, Color.blush, Color.petal],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                if store.avatarImage == nil {
                    VStack(spacing: 14) {
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(
                                LinearGradient(colors: [.rose.opacity(0.6), .burgundy.opacity(0.5)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        Text("Your mannequin photo\nwill appear here")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.mauve)
                            .multilineTextAlignment(.center)
                        Menu {
                            Button { showCamera = true } label: {
                                Label("Take Photo", systemImage: "camera")
                            }
                            Button { showPhotoLibrary = true } label: {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                Text("Add My Photo")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule().fill(
                                    LinearGradient(colors: [.burgundy, .rose],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                            )
                        }
                    }
                } else if isProcessingComposite, let previous = processedComposite {
                    Image(uiImage: previous)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .blur(radius: 12)
                        .opacity(0.4)
                }

                if store.avatarImage != nil, isProcessingComposite {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.rose.opacity(0.12))
                                .frame(width: 64, height: 64)
                                .scaleEffect(processingProgress > 0.3 ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isProcessingComposite)

                            Image(systemName: "sparkles")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(colors: [.burgundy, .rose], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .symbolEffect(.pulse, isActive: isProcessingComposite)
                        }

                        Text(processingStage)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.rose)
                            .contentTransition(.numericText())

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.blush)
                                .frame(width: 140, height: 4)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(colors: [.burgundy, .rose], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: 140 * processingProgress, height: 4)
                                .animation(.easeInOut(duration: 0.3), value: processingProgress)
                        }
                    }
                    .transition(.opacity)
                } else if store.avatarImage != nil, !store.selectedItems.isEmpty, let processed = processedComposite {
                    Image(uiImage: processed)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .interactive3DEffect()
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else if store.avatarImage != nil, !store.selectedItems.isEmpty {
                    Image(compositeAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .interactive3DEffect()
                } else if let avatar = store.avatarImage {
                    Image(uiImage: avatar)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .interactive3DEffect()
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.35), value: isProcessingComposite)
        }
        .onAppear {
            if store.avatarImage != nil, !store.selectedItems.isEmpty {
                processComposite(compositeAssetName, animated: false)
            }
        }
        .onChange(of: compositeAssetName) { _, newName in
            if store.avatarImage != nil, !store.selectedItems.isEmpty {
                processComposite(newName, animated: true)
            } else {
                processedComposite = nil
                isProcessingComposite = false
            }
        }
        .onChange(of: store.avatarImage) { _, newAvatar in
            if newAvatar != nil, !store.selectedItems.isEmpty {
                processComposite(compositeAssetName, animated: true)
            } else if newAvatar == nil {
                processedComposite = nil
                isProcessingComposite = false
            }
        }
        .onChange(of: store.selectedItems) { _, newItems in
            if store.avatarImage != nil, !newItems.isEmpty {
                processComposite(compositeAssetName, animated: true)
            } else {
                processedComposite = nil
                isProcessingComposite = false
            }
        }
    }

    private func processComposite(_ assetName: String, animated: Bool) {
        guard let sourceImage = UIImage(named: assetName) else { return }

        let stages = ["Analyzing garment...", "Generating try-on...", "Refining fit..."]

        if animated {
            isProcessingComposite = true
            processingProgress = 0
            processingStage = stages[0]

            Task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                await MainActor.run {
                    withAnimation { processingProgress = 0.35; processingStage = stages[1] }
                }

                let result = await ImagePreProcessor.removePersonBackground(sourceImage)

                await MainActor.run {
                    withAnimation { processingProgress = 0.75; processingStage = stages[2] }
                }

                try? await Task.sleep(nanoseconds: 350_000_000)
                await MainActor.run {
                    withAnimation { processingProgress = 1.0 }
                }

                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        processedComposite = result
                        isProcessingComposite = false
                        processingProgress = 0
                    }
                }
            }
        } else {
            isProcessingComposite = true
            processingStage = "Loading..."
            processingProgress = 0.5
            Task {
                let result = await ImagePreProcessor.removePersonBackground(sourceImage)
                await MainActor.run {
                    withAnimation {
                        processedComposite = result
                        isProcessingComposite = false
                        processingProgress = 0
                    }
                }
            }
        }
    }

    private func processAndSaveAvatar(_ image: UIImage) {
        Task {
            let processed = await ImagePreProcessor.removePersonBackground(image)
            await MainActor.run {
                store.saveAvatar(processed)
            }
        }
    }

    var selectedItemsStrip: some View {
        Group {
            if sortedSelections.isEmpty {
                Text("Tap a category below to start building")
                    .font(.system(size: 13))
                    .foregroundColor(.mauve)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(sortedSelections, id: \.1.id) { (cat, item) in
                            Button { withAnimation { store.removeItem(for: cat) } } label: {
                                HStack(spacing: 8) {
                                    if let img = store.loadImage(for: item) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 36, height: 36)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.deepWine)
                                        Text(cat.rawValue)
                                            .font(.system(size: 10))
                                            .foregroundColor(.mauve)
                                    }
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.mauve)
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.blushLight)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.blushBorder, lineWidth: 1)
                                        )
                                )
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal, 16)
                }.frame(height: 56)
            }
        }
    }

    var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ClothingCategory.allCases) { cat in
                    CategoryPill(category: cat, hasSelection: store.selectedItems[cat] != nil) { activeCategory = cat }
                }
            }.padding(.horizontal, 16)
        }
    }

    var confirmButton: some View {
        Button(action: { showSaveOutfit = true }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Outfit").font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        store.selectedItems.isEmpty
                            ? AnyShapeStyle(Color.blush)
                            : AnyShapeStyle(LinearGradient(colors: [.burgundy, .rose], startPoint: .leading, endPoint: .trailing))
                    )
            )
        }.disabled(store.selectedItems.isEmpty)
    }

    @ToolbarContentBuilder
    var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                withAnimation { selectedTab = previousTab }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.burgundy)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 14) {
                if !store.selectedItems.isEmpty {
                    Button("Clear") { withAnimation { store.clearAllSelections() } }
                        .foregroundColor(.mauve)
                }
                Menu {
                    Button { showCamera = true } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    Button { showPhotoLibrary = true } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                    if store.avatarImage != nil {
                        Divider()
                        Button(role: .destructive) {
                            withAnimation { store.deleteAvatar() }
                        } label: {
                            Label("Remove Avatar", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "person.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.burgundy)
                }
            }
        }
    }
}

// MARK: - CategoryPill
struct CategoryPill: View {
    let category: ClothingCategory
    let hasSelection: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(category.emoji)
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(hasSelection ? .burgundy : .deepWine)
                if hasSelection {
                    Circle()
                        .fill(Color.burgundy)
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(hasSelection ? Color.burgundy.opacity(0.1) : Color.blushLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(hasSelection ? Color.burgundy.opacity(0.3) : Color.blushBorder, lineWidth: 1)
                    )
            )
        }.buttonStyle(.plain)
    }
}

// MARK: - ItemPickerSheet
struct ItemPickerSheet: View {
    @EnvironmentObject var store: AppStore
    let category: ClothingCategory
    let onSelect: (ClothingItem?) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if store.items(for: category).isEmpty {
                    VStack(spacing: 18) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.rose.opacity(0.15), Color.burgundy.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                            Text(category.emoji)
                                .font(.system(size: 38))
                        }
                        Text("\(category.rawValue) is empty")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.deepWine)
                        Text("Add items from the Closet tab first")
                            .font(.system(size: 14))
                            .foregroundColor(.mauve)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(store.items(for: category)) { item in
                                Button(action: { onSelect(item) }) {
                                    VStack {
                                        if let img = store.loadImage(for: item) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 100)
                                        }
                                        Text(item.name)
                                            .font(.caption)
                                            .foregroundColor(.deepWine)
                                    }
                                    .padding(8)
                                    .background(Color.blushLight, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blushBorder, lineWidth: 1)
                                    )
                                }
                            }
                        }.padding()
                    }
                }
            }
            .background(Color.petal)
            .navigationTitle(category.rawValue)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onSelect(nil) }
                        .foregroundColor(.burgundy)
                }
            }
        }
    }
}

// MARK: - SaveOutfitSheet
struct SaveOutfitSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    let snapshot: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.blushBorder)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            Text("Save Outfit")
                .font(.headline)
                .foregroundColor(.deepWine)
            TextField("Outfit Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.deepWine)
                .padding(.horizontal)
            Button("Save") {
                store.saveCurrentOutfit(name: name, snapshot: snapshot)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.burgundy)
            .padding(.bottom, 8)
        }
        .background(Color.petal)
        .presentationSizing(.fitted)
    }
}
