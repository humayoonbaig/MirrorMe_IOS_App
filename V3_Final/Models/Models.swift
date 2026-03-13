import SwiftUI

// MARK: - Clothing Subcategory
// Fine-grained type shown as filter pills inside the item picker sheet
enum ClothingSubcategory: String, CaseIterable, Codable {
    // Top subcategories
    case tshirt     = "T-shirt"
    case shirt      = "Shirt"
    case sweater    = "Sweater"
    case blouse     = "Blouse"
    case hoodie     = "Hoodie"
    // Bottom subcategories
    case jeans      = "Jeans"
    case trousers   = "Trousers"
    case shorts     = "Shorts"
    case skirt      = "Skirt"
    // Outerwear subcategories
    case jacket     = "Jacket"
    case coat       = "Coat"
    case blazer     = "Blazer"
    // Shoes subcategories
    case sneakers   = "Sneakers"
    case boots      = "Boots"
    case sandals    = "Sandals"
    case heels      = "Heels"
    // Accessories subcategories
    case hat        = "Hat"
    case bag        = "Bag"
    case belt       = "Belt"
    case scarf      = "Scarf"

    // Which main category this belongs to
    var parent: ClothingCategory {
        switch self {
        case .tshirt, .shirt, .sweater, .blouse, .hoodie:   return .top
        case .jeans, .trousers, .shorts, .skirt:             return .bottom
        case .jacket, .coat, .blazer:                        return .outerwear
        case .sneakers, .boots, .sandals, .heels:            return .shoes
        case .hat, .bag, .belt, .scarf:                      return .accessories
        }
    }
}

// MARK: - Clothing Category
enum ClothingCategory: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    case top         = "Top"
    case bottom      = "Bottom"
    case outerwear   = "Outerwear"
    case shoes       = "Shoes"
    case accessories = "Accessories"

    var emoji: String {
        switch self {
        case .top:         return "👕"
        case .bottom:      return "👖"
        case .outerwear:   return "🧥"
        case .shoes:       return "👟"
        case .accessories: return "💍"
        }
    }

    // Layer order: drawn bottom-up
    var layerOrder: Int {
        switch self {
        case .shoes:       return 0
        case .bottom:      return 1
        case .top:         return 2
        case .outerwear:   return 3
        case .accessories: return 4
        }
    }

    // All subcategories that belong to this category
    var subcategories: [ClothingSubcategory] {
        ClothingSubcategory.allCases.filter { $0.parent == self }
    }
}

// MARK: - Clothing Item
struct ClothingItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var category: ClothingCategory
    var subcategory: ClothingSubcategory? = nil   // optional fine-grained type
    var imageFileName: String  = ""               // saved in Documents directory
    var builtInImageName: String = ""             // from Assets.xcassets (empty now)
    var originalFileName: String = ""             // original filename from photo gallery
    var brand: String = ""

    static func == (lhs: ClothingItem, rhs: ClothingItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - Outfit
struct Outfit: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var itemIDs: [UUID] = []
    var snapshotFileName: String = ""   // saved composite image in Documents
    var createdAt: Date = Date()
}

// MARK: - Calendar Entry
struct CalendarEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var outfitID: UUID?
}

// No sample data — wardrobe starts empty.
// User adds items via Closet tab > camera or photo library.
