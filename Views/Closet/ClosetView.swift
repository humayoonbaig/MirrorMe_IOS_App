import SwiftUI
import PhotosUI



// MARK: - Main Closet View
struct ClosetView: View {
    @EnvironmentObject var store: AppStore
    @Binding var selectedTab: Int
    @Binding var previousTab: Int
    @State private var selectedCategory: ClothingCategory? = nil
    @State private var showAddItem  = false
    @State private var selectedItem: ClothingItem?
    @State private var searchText = ""
    @Namespace private var animation

    var filtered: [ClothingItem] {
        let items: [ClothingItem]
        if let cat = selectedCategory {
            items = store.items(for: cat)
        } else {
            items = store.wardrobeItems
        }
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var searchPlaceholder: String {
        if let cat = selectedCategory {
            return "Search \(cat.rawValue.lowercased())…"
        }
        return "Search all items…"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.petal.ignoresSafeArea()

                VStack(spacing: 0) {
                    statsBar
                    categoryTabs
                        .padding(.bottom, 4)
                    searchBar

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        itemGrid
                    }
                }
            }
            .navigationTitle("My Closet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                    Button { showAddItem = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.burgundy, .rose],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddItemView(defaultCategory: selectedCategory ?? .top)
            }
            .sheet(item: $selectedItem) { ItemDetailView(item: $0) }
        }
    }

    // MARK: - Stats Bar
    var statsBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(ClothingCategory.allCases.enumerated()), id: \.element) { index, cat in
                if index > 0 {
                    Divider().frame(height: 28)
                }
                VStack(spacing: 2) {
                    Text("\(store.items(for: cat).count)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.burgundy, .rose],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(cat.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.mauve)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blushLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.burgundy.opacity(0.04), Color.rose.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blushBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Category Tabs
    var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryPill(
                    label: "All",
                    emoji: "✨",
                    count: store.wardrobeItems.count,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedCategory = nil
                    }
                }

                ForEach(ClothingCategory.allCases) { cat in
                    categoryPill(
                        label: cat.rawValue,
                        emoji: cat.emoji,
                        count: store.items(for: cat).count,
                        isSelected: selectedCategory == cat
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedCategory = cat
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    func categoryPill(label: String, emoji: String, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji).font(.system(size: 16))
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .mauve)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected
                                ? AnyShapeStyle(Color.white.opacity(0.25))
                                : AnyShapeStyle(Color.blush)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isSelected
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [.burgundy, .rose],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    : AnyShapeStyle(Color.petal)
            )
            .foregroundColor(isSelected ? .white : .deepWine)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.blushBorder, lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.burgundy.opacity(0.2) : .clear, radius: 4, y: 2)
        }
    }

    // MARK: - Search Bar
    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.mauve)
                .font(.system(size: 15, weight: .medium))
            TextField(searchPlaceholder, text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.deepWine)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.mauve)
                }
            }
        }
        .padding(12)
        .background(Color.blushLight, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blushBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Item Grid
    var itemGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ], spacing: 14) {
                ForEach(filtered) { item in
                    ClosetItemCard(item: item)
                        .onTapGesture { selectedItem = item }
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation { store.deleteItem(item) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(16)
            .padding(.bottom, 80)
        }
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 20) {
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
                    .frame(width: 120, height: 120)
                if let cat = selectedCategory {
                    Text(cat.emoji).font(.system(size: 52))
                } else {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.rose.opacity(0.5), .burgundy.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }

            VStack(spacing: 6) {
                if let cat = selectedCategory {
                    Text("No \(cat.rawValue) yet")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundColor(.deepWine)
                } else {
                    Text("Your closet is empty")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundColor(.deepWine)
                }
                Text("Add your first item to get started")
                    .font(.subheadline)
                    .foregroundColor(.mauve)
            }

            Button { showAddItem = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Item")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.burgundy, .rose],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
            }
            .shadow(color: Color.burgundy.opacity(0.2), radius: 6, y: 3)

            Spacer()
        }
    }
}

// MARK: - Closet Item Card
struct ClosetItemCard: View {
    @EnvironmentObject var store: AppStore
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color.blushLight, Color.blush],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                if let img = store.loadImage(for: item) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    VStack(spacing: 6) {
                        Text(item.category.emoji).font(.system(size: 36))
                        Text("No image")
                            .font(.system(size: 10))
                            .foregroundColor(.mauve)
                    }
                }
            }
            .frame(height: 190)
            .clipped()
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))


            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.deepWine)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.category.emoji)
                        .font(.system(size: 10))
                    if !item.brand.isEmpty {
                        Text(item.brand)
                            .font(.system(size: 11))
                            .foregroundColor(.mauve)
                            .lineLimit(1)
                    } else {
                        Text(item.category.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(.mauve)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Color.petal)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blushBorder, lineWidth: 1)
        )
        .shadow(color: Color.burgundy.opacity(0.06), radius: 8, y: 4)
    }
}

// MARK: - Add Item View
struct AddItemView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    var defaultCategory: ClothingCategory

    @State private var name         = ""
    @State private var brand        = ""
    @State private var category: ClothingCategory
    @State private var showCamera   = false
    @State private var showLibrary  = false
    @State private var rawImage: UIImage?
    @State private var isProcessing = false
    @State private var galleryFileName = ""

    init(defaultCategory: ClothingCategory) {
        self.defaultCategory = defaultCategory
        _category = State(initialValue: defaultCategory)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    photoSection
                    detailsSection
                    categorySection
                }
                .padding(20)
            }
            .background(Color.petal)
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.mauve)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundColor(.burgundy)
                        .disabled(name.isEmpty || isProcessing)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerUIKit { img, _ in
                    showCamera = false
                    if let img { processImage(img) }
                }
            }
            .sheet(isPresented: $showLibrary) {
                PhotoLibraryPicker { img, fileName in
                    showLibrary = false
                    if let img {
                        if let fileName, !fileName.isEmpty {
                            galleryFileName = fileName
                        }
                        processImage(img)
                    }
                }
            }
        }
    }

    // MARK: - Photo Section
    var photoSection: some View {
        VStack(spacing: 12) {
            if isProcessing {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blushLight)
                    .frame(height: 260)
                    .overlay { ProgressView("Processing…").tint(.burgundy) }
            } else if let img = rawImage {
                Menu {
                    Button { showCamera = true } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    Button { showLibrary = true } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                    Divider()
                    Button(role: .destructive) { rawImage = nil } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                } label: {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [.burgundy.opacity(0.3), .rose.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                                .padding(12)
                        }
                }
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.blushLight, Color.blush],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.rose.opacity(0.2), .burgundy.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 64, height: 64)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.burgundy, .rose],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            Text("Add a photo of your item")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.mauve)
                        }
                    }

                HStack(spacing: 10) {
                    Button { showCamera = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                            Text("Camera")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.burgundy, .rose],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }

                    Button { showLibrary = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Gallery")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.deepWine)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blush, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    // MARK: - Details Section
    var detailsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.burgundy, .rose],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24)
                TextField("Item name", text: $name)
                    .font(.system(size: 16))
                    .foregroundColor(.deepWine)
            }
            .padding(14)

            Divider()
                .background(Color.blushBorder)
                .padding(.leading, 52)

            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.rose, .burgundy],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24)
                TextField("Brand (optional)", text: $brand)
                    .font(.system(size: 16))
                    .foregroundColor(.deepWine)
            }
            .padding(14)
        }
        .background(Color.blushLight, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blushBorder, lineWidth: 1)
        )
    }

    // MARK: - Category Section
    var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.mauve)
                .padding(.leading, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(ClothingCategory.allCases) { cat in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            category = cat
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(cat.emoji).font(.system(size: 24))
                            Text(cat.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            category == cat
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [.burgundy, .rose],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                : AnyShapeStyle(Color.blushLight)
                        )
                        .foregroundColor(category == cat ? .white : .deepWine)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    category == cat
                                        ? AnyShapeStyle(Color.clear)
                                        : AnyShapeStyle(Color.blushBorder),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
    }

    func processImage(_ image: UIImage) {
        isProcessing = true
        Task {
            let result = await ImagePreProcessor.removeForegroundBackground(image)
            await MainActor.run {
                rawImage = result
                isProcessing = false
            }
        }
    }

    func save() {
        let filename = store.saveImage(rawImage ?? UIImage())
        let item = ClothingItem(name: name, category: category, imageFileName: filename, originalFileName: galleryFileName, brand: brand)
        store.addItem(item)
        dismiss()
    }
}

// MARK: - Item Detail View
struct ItemDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let item: ClothingItem
    @State private var showDelete = false
    @State private var editedName: String = ""
    @State private var editedBrand: String = ""
    @State private var editedCategory: ClothingCategory = .top
    @State private var showCategoryPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        LinearGradient(
                            colors: [Color.blushLight, Color.blush],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        if let img = store.loadImage(for: item) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(editedCategory.emoji).font(.system(size: 64))
                        }
                    }
                    .frame(maxHeight: 400)
                    .interactive3DEffect(maxAngle: 15, enableShadow: true)

                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Item name", text: $editedName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.deepWine)
                                TextField("Brand (optional)", text: $editedBrand)
                                    .font(.body)
                                    .foregroundColor(.mauve)
                            }
                            Spacer()
                            Text(editedCategory.emoji)
                                .font(.largeTitle)
                                .padding(10)
                                .background(
                                    LinearGradient(
                                        colors: [Color.rose.opacity(0.15), Color.burgundy.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    in: Circle()
                                )
                        }

                        // Editable category tag
                        Button { showCategoryPicker.toggle() } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.burgundy, .rose],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                Text(editedCategory.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.mauve)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.mauve)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color.burgundy.opacity(0.06), Color.rose.opacity(0.04)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                        }

                        if showCategoryPicker {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(ClothingCategory.allCases) { cat in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            editedCategory = cat
                                            showCategoryPicker = false
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Text(cat.emoji).font(.system(size: 24))
                                            Text(cat.rawValue)
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            editedCategory == cat
                                                ? AnyShapeStyle(
                                                    LinearGradient(
                                                        colors: [.burgundy, .rose],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                : AnyShapeStyle(Color.blushLight)
                                        )
                                        .foregroundColor(editedCategory == cat ? .white : .deepWine)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    editedCategory == cat
                                                        ? AnyShapeStyle(Color.clear)
                                                        : AnyShapeStyle(Color.blushBorder),
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Divider()
                            .background(Color.blushBorder)

                        Button(role: .destructive) { showDelete = true } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove from Closet")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                }
            }
            .background(Color.petal)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .foregroundColor(.burgundy)
                }
            }
            .alert("Remove Item", isPresented: $showDelete) {
                Button("Remove", role: .destructive) {
                    store.deleteItem(item)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This item will be removed from your closet.")
            }
            .onAppear {
                editedName = item.name
                editedBrand = item.brand
                editedCategory = item.category
            }
        }
    }

    private func saveChanges() {
        var updated = item
        updated.name = editedName
        updated.brand = editedBrand
        updated.category = editedCategory
        store.updateItem(updated)
    }
}
