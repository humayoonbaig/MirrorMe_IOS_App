import SwiftUI
import Combine

class AppStore: ObservableObject {

    // MARK: - Avatar
    @Published var avatarImage: UIImage? = nil

    // MARK: - Wardrobe
    @Published var wardrobeItems: [ClothingItem] = [] {
        didSet { saveWardrobe() }
    }

    // MARK: - Outfit selections (active in Outfit tab)
    @Published var selectedItems: [ClothingCategory: ClothingItem] = [:]

    // MARK: - Saved Outfits
    @Published var savedOutfits: [Outfit] = [] {
        didSet { saveOutfits() }
    }

    // MARK: - Calendar
    @Published var calendarEntries: [CalendarEntry] = [] {
        didSet { saveCalendar() }
    }

    private let cal = Calendar.current

    // MARK: - Init
    init() {
        loadAll()
        avatarImage = loadAvatar()
    }

    // MARK: - Wardrobe helpers
    func items(for category: ClothingCategory) -> [ClothingItem] {
        wardrobeItems.filter { $0.category == category }
    }

    func addItem(_ item: ClothingItem) {
        wardrobeItems.append(item)
    }

    func updateItem(_ item: ClothingItem) {
        if let index = wardrobeItems.firstIndex(where: { $0.id == item.id }) {
            wardrobeItems[index] = item
        }
    }

    func deleteItem(_ item: ClothingItem) {
        wardrobeItems.removeAll { $0.id == item.id }
        if selectedItems[item.category]?.id == item.id {
            selectedItems.removeValue(forKey: item.category)
        }
    }

    // MARK: - Outfit selection helpers
    func selectItem(_ item: ClothingItem) {
        selectedItems[item.category] = item
    }

    func removeItem(for category: ClothingCategory) {
        selectedItems.removeValue(forKey: category)
    }

    func clearAllSelections() {
        selectedItems.removeAll()
    }

    func loadOutfit(_ outfit: Outfit) {
        clearAllSelections()
        for id in outfit.itemIDs {
            if let item = wardrobeItems.first(where: { $0.id == id }) {
                selectedItems[item.category] = item
            }
        }
    }

    var currentOutfitItems: [ClothingItem] {
        selectedItems.values.sorted { $0.category.layerOrder < $1.category.layerOrder }
    }

    // MARK: - Save outfit
    /// Saves the outfit with an optional snapshot image of the composite look.
    func saveCurrentOutfit(name: String, snapshot: UIImage? = nil) {
        var outfit = Outfit(name: name, itemIDs: currentOutfitItems.map { $0.id })
        if let snapshot {
            outfit.snapshotFileName = saveImage(snapshot)
        }
        savedOutfits.append(outfit)
    }

    /// Load the saved snapshot image for an outfit.
    func loadSnapshot(for outfit: Outfit) -> UIImage? {
        guard !outfit.snapshotFileName.isEmpty,
              let url = documentsDir()?.appendingPathComponent(outfit.snapshotFileName)
        else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    func deleteOutfit(_ outfit: Outfit) {
        savedOutfits.removeAll { $0.id == outfit.id }
    }

    func items(in outfit: Outfit) -> [ClothingItem] {
        outfit.itemIDs.compactMap { id in wardrobeItems.first { $0.id == id } }
    }

    // MARK: - Calendar helpers
    func entry(for date: Date) -> CalendarEntry? {
        calendarEntries.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    func outfit(for date: Date) -> Outfit? {
        guard let oid = entry(for: date)?.outfitID else { return nil }
        return savedOutfits.first { $0.id == oid }
    }

    func assign(outfit: Outfit?, to date: Date) {
        if let idx = calendarEntries.firstIndex(where: { cal.isDate($0.date, inSameDayAs: date) }) {
            calendarEntries[idx].outfitID = outfit?.id
        } else if let outfit {
            calendarEntries.append(CalendarEntry(date: date, outfitID: outfit.id))
        }
    }

    // MARK: - Image loading
    func loadImage(for item: ClothingItem) -> UIImage? {
        if !item.builtInImageName.isEmpty {
            return UIImage(named: item.builtInImageName)
        }
        if !item.imageFileName.isEmpty,
           let url = documentsDir()?.appendingPathComponent(item.imageFileName) {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }

    func saveImage(_ image: UIImage) -> String {
        let filename = UUID().uuidString + ".png"
        if let data = image.pngData(),
           let url = documentsDir()?.appendingPathComponent(filename) {
            try? data.write(to: url)
        }
        return filename
    }

    // Inside your AppStore class
    var allItemsCount: Int {
        // This safely iterates through all categories and sums up the items
        return ClothingCategory.allCases.reduce(0) { $0 + items(for: $1).count }
    }
    
    // MARK: - Avatar (The Mannequin)
    func saveAvatar(_ image: UIImage) {
        if let data = image.pngData(),
           let url = documentsDir()?.appendingPathComponent("avatar.png") {
            try? data.write(to: url)
        }
        self.avatarImage = image
    }

    func loadAvatar() -> UIImage? {
        if let url = documentsDir()?.appendingPathComponent("avatar.png"),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return nil
    }

    func deleteAvatar() {
        avatarImage = nil
        if let url = documentsDir()?.appendingPathComponent("avatar.png") {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Persistence
    private func documentsDir() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private func saveWardrobe() {
        if let data = try? JSONEncoder().encode(wardrobeItems) {
            UserDefaults.standard.set(data, forKey: "wardrobe_v3")
        }
    }

    private func saveOutfits() {
        if let data = try? JSONEncoder().encode(savedOutfits) {
            UserDefaults.standard.set(data, forKey: "outfits_v3")
        }
    }

    private func saveCalendar() {
        if let data = try? JSONEncoder().encode(calendarEntries) {
            UserDefaults.standard.set(data, forKey: "calendar_v3")
        }
    }

    private func loadAll() {
        if let d = UserDefaults.standard.data(forKey: "wardrobe_v3"),
           let v = try? JSONDecoder().decode([ClothingItem].self, from: d) { wardrobeItems = v }
        if let d = UserDefaults.standard.data(forKey: "outfits_v3"),
           let v = try? JSONDecoder().decode([Outfit].self, from: d) { savedOutfits = v }
        if let d = UserDefaults.standard.data(forKey: "calendar_v3"),
           let v = try? JSONDecoder().decode([CalendarEntry].self, from: d) { calendarEntries = v }
    }
}
