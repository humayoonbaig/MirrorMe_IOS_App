# MirrorMe — Technical Report

## 1. App Overview

MirrorMe is a **virtual wardrobe and outfit planning** iOS app built entirely in **Swift** and **SwiftUI**. It allows users to photograph their clothing items, compose outfits on a virtual mannequin (their own photo), and plan what to wear on a calendar. The app uses **on-device machine learning** for background removal and a **free weather API** for contextual recommendations.

---

## 2. Architecture

The app follows a **single source of truth** pattern:

```
FashionApp (@main)
  └── AppStore (@StateObject, injected via .environmentObject)
        ├── Structured data  →  UserDefaults (JSON-encoded)
        ├── Image files      →  Documents directory (PNG files)
        └── Ephemeral state  →  In-memory only
```

- **`AppStore`** is an `ObservableObject` class that acts as ViewModel, Repository, and Persistence layer combined.
- It is created once in `FashionApp.swift` as a `@StateObject` and injected into the entire view hierarchy via `.environmentObject(store)`.
- Every view accesses it through `@EnvironmentObject var store: AppStore`.

---

## 3. Frontend (UI Layer)

### Navigation Structure

| Tab | View | Purpose |
|-----|------|---------|
| 0 | `HomeView` | Dashboard — greeting, weather, today's plan, saved collection |
| 1 | `OutfitView` | Studio — virtual try-on, compose outfits on mannequin |
| 2 | `ClosetView` | Closet — browse, search, add, delete clothing items |
| 3 | `CalendarView` | Planner — assign outfits to calendar dates |

Plus an **Onboarding flow** (3 steps: name, location permission, avatar photo) shown only on first launch.

### Key UI Features

- **Custom calendar** built from scratch with `LazyVGrid` (not `UICalendarView`)
- **Interactive 3D tilt effect** — a custom `ViewModifier` using `rotation3DEffect` on X/Y axes with drag gesture, specular highlight overlay, and dynamic shadow
- **Glassmorphism tab bar** using `UIBlurEffect(style: .systemUltraThinMaterial)`
- **Dusty Rose color palette** — 8 custom colors (`petal`, `blushLight`, `blush`, `burgundy`, `rose`, `deepWine`, `mauve`, `blushBorder`)

---

## 4. Data Models

All models conform to `Codable` for JSON serialization:

### `ClothingItem`
- `id: UUID`, `name: String`, `category: ClothingCategory`, `imageFileName: String`, `brand: String`
- `imageFileName` stores the name of the PNG file in the Documents directory

### `Outfit`
- `id: UUID`, `name: String`, `itemIDs: [UUID]`, `snapshotFileName: String`, `createdAt: Date`
- `itemIDs` references `ClothingItem.id` values (a join-table pattern)
- `snapshotFileName` stores the composite mannequin snapshot filename

### `CalendarEntry`
- `id: UUID`, `date: Date`, `outfitID: UUID?`
- Links a specific date to an optional Outfit

### `ClothingCategory` (enum, 5 cases)
- `.top`, `.bottom`, `.outerwear`, `.shoes`, `.accessories`
- Has computed `emoji`, `layerOrder` (z-ordering for rendering), and `subcategories`

---

## 5. Database / Persistence Strategy

The app uses a **dual-layer persistence** approach with **no external database**:

### Layer 1 — UserDefaults (Structured Data)

| Key | Data | Format |
|-----|------|--------|
| `wardrobe_v3` | All clothing items | JSON via `JSONEncoder` |
| `outfits_v3` | All saved outfits | JSON via `JSONEncoder` |
| `calendar_v3` | All calendar entries | JSON via `JSONEncoder` |
| `userName` | User's name | Plain string (`@AppStorage`) |
| `isFirstLaunchh` | Onboarding completed flag | Bool (`@AppStorage`) |

- Data is **automatically saved on every mutation** using Swift `didSet` property observers on `wardrobeItems`, `savedOutfits`, and `calendarEntries`.
- Data is loaded in `AppStore.init()` via `loadAll()`.

### Layer 2 — File System (Images)

All images are stored in the app's **sandboxed Documents directory** as PNG files.

---

## 6. How Images Are Stored and Fetched

### Saving an Image

```
User takes photo / picks from library
        ↓
Background removal via Vision ML (async)
        ↓
store.saveImage(processedImage) is called
        ↓
Generates filename: UUID().uuidString + ".png"
        ↓
Converts to PNG: image.pngData()
        ↓
Writes to: Documents/{UUID}.png
        ↓
Returns filename string → stored in ClothingItem.imageFileName
```

### Loading an Image

```
store.loadImage(for: item) is called
        ↓
Constructs path: Documents/{item.imageFileName}
        ↓
Reads from disk: UIImage(contentsOfFile: url.path)
        ↓
Returns UIImage? to the view for display
```

### Three Image Types

| Image Type | Filename Pattern | Used For |
|------------|-----------------|----------|
| Clothing items | `{UUID}.png` | Individual garment photos |
| Outfit snapshots | `{UUID}.png` | Composite mannequin screenshots |
| Avatar | `avatar.png` (fixed name, overwritten) | User's full-body mannequin photo |

---

## 7. Image Processing Engine (`ImagePreProcessor`)

Uses **Apple's Vision framework** for on-device ML inference — **no cloud/server processing**.

### Two Processing Pipelines

| Method | Vision Request | Used For |
|--------|---------------|----------|
| `removePersonBackground()` | `VNGeneratePersonSegmentationRequest` (.accurate) | Avatar/mannequin photos |
| `removeForegroundBackground()` | `VNGenerateForegroundInstanceMaskRequest` (iOS 17+) | Clothing item photos |

### Processing Steps

1. **Normalize** EXIF orientation
2. **Scale down** to max 2048px edge (memory management)
3. **Run Vision ML** to generate a segmentation mask (`CVPixelBuffer`)
4. **Apply mask** using Core Image `CIBlendWithMask` filter
5. **Return** transparent-background `UIImage`

All processing is `async` and runs off the main thread.

---

## 8. Virtual Try-On System (`TryOnLookup`)

The outfit studio uses a **combinatorial lookup table** of **27 pre-rendered mannequin images**:

- 3 shirt variants (white, grey, darkBlue)
- 3 bottom variants (khaki, blackJeans, blueJeans)
- 3 shoe variants (barefoot, blackChelsea, puma)
- **3 × 3 × 3 = 27 combinations** stored in the asset catalog

The system uses **fuzzy string matching** against item names, filenames, and brands to determine which variant to use, then loads the matching pre-rendered composite from the asset catalog.

---

## 9. External APIs

### Open-Meteo Weather API (free, no API key)

- **Endpoint:** `https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,weather_code`
- Returns current temperature and WMO weather code
- **Location** obtained via `CLLocationManager` (CoreLocation)
- **City name** resolved via `CLGeocoder.reverseGeocodeLocation`
- WMO codes mapped to SF Symbols and human-readable text

---

## 10. Frameworks and Technologies Used

| Framework | Purpose |
|-----------|---------|
| SwiftUI | Entire UI layer |
| UIKit | Camera picker, tab bar appearance, image processing |
| Vision | On-device ML for person/foreground segmentation |
| CoreImage | Pixel-level image compositing (mask application) |
| CoreLocation | GPS location for weather |
| PhotosUI | PHPicker for photo library access |
| Foundation | JSON encoding/decoding, file management, UserDefaults |

### What Is NOT Used

- No Core Data, SQLite, Realm, or SwiftData
- No CloudKit or server-side backend
- No third-party libraries or CocoaPods/SPM packages
- No Firebase, analytics, or authentication
- No Combine framework (uses async/await throughout)

---

## 11. Complete Data Flow Diagram

```
User Action              →  View Layer        →  AppStore          →  Persistence
─────────────────────────────────────────────────────────────────────────────────
Add clothing item        →  AddItemView       →  addItem()         →  UserDefaults (JSON)
                                                  saveImage()      →  Documents/{UUID}.png

Take avatar photo        →  OnboardingView    →  saveAvatar()      →  Documents/avatar.png

Compose outfit           →  OutfitView        →  selectItem()      →  In-memory only
Save outfit              →  SaveOutfitSheet   →  saveCurrentOutfit()→  UserDefaults + PNG

Plan outfit for date     →  CalendarView      →  assign(outfit:to:)→  UserDefaults (JSON)

Browse closet            →  ClosetView        →  items(for:)       ←  UserDefaults (read)
                                                  loadImage(for:)   ←  Documents/ (read)
```

---

## 12. App Flow Summary

### First Launch
1. Onboarding: Enter name → Grant location → Take avatar photo
2. Avatar processed through Vision ML (person segmentation, background removal)
3. Saved to Documents/avatar.png

### Adding Clothing
1. User photographs or selects a garment
2. Vision ML isolates the foreground (removes background)
3. Processed image saved as `{UUID}.png` in Documents
4. `ClothingItem` metadata saved to UserDefaults as JSON

### Creating an Outfit
1. User selects items from their closet (one per category)
2. System matches selections to pre-rendered mannequin assets (27 combinations)
3. Composite image processed through person segmentation
4. User names and saves the outfit
5. Snapshot PNG + Outfit metadata persisted

### Planning Calendar
1. User selects a date on the custom calendar
2. Chooses from saved outfits
3. `CalendarEntry` created linking date → outfit ID
4. Confirmation popup: "[Outfit Name] is planned for [date]"

---

## 13. Key Answer for Professors

**"How do you store images and how are they fetched?"**

> Structured metadata (item names, IDs, category, filename references) is **JSON-encoded using `JSONEncoder` and stored in `UserDefaults`** under versioned keys (`wardrobe_v3`, `outfits_v3`, `calendar_v3`). The `didSet` property observers on the `@Published` arrays ensure data is automatically persisted on every mutation.
>
> Actual image binary data is stored as **PNG files in the app's sandboxed Documents directory**. Each image gets a unique filename generated from `UUID().uuidString + ".png"`. The filename string is stored inside the model's `imageFileName` property, creating a **reference link** between the JSON metadata and the file system.
>
> To load an image, the app constructs the full path by combining the Documents directory URL with the stored filename, then reads it via `UIImage(contentsOfFile:)`. This approach keeps UserDefaults lightweight (only JSON text) while storing potentially large image data efficiently on the file system.
>
> Before storage, all images are processed through **Apple's Vision framework** on-device — clothing items use `VNGenerateForegroundInstanceMaskRequest` for foreground isolation, and avatar photos use `VNGeneratePersonSegmentationRequest` for person segmentation. The processed (transparent-background) images are what gets saved to disk.
