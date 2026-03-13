import SwiftUI



struct CalendarView: View {
    @EnvironmentObject var store: AppStore
    @Binding var selectedTab: Int
    @Binding var previousTab: Int
    @State private var selectedDate    = Date()
    @State private var displayedMonth  = Date()
    @State private var showOutfitPicker = false

    private let cal = Calendar.current

    private var plannedCount: Int {
        daysInMonth().filter { store.outfit(for: $0) != nil }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.petal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        unifiedCalendarCard
                        dayDetailCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Planner")
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
            }
            .sheet(isPresented: $showOutfitPicker) {
                CalendarOutfitPicker(date: selectedDate)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Unified Calendar Card
    var unifiedCalendarCard: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color.burgundy, Color.rose],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .offset(x: 100, y: -30)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .offset(x: -80, y: 40)

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayedMonth, format: .dateTime.month(.wide))
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                        Text(displayedMonth, format: .dateTime.year())
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        if plannedCount > 0 {
                            HStack(spacing: 5) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11))
                                Text("\(plannedCount) outfit\(plannedCount == 1 ? "" : "s") planned")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.2), in: Capsule())
                            .padding(.top, 4)
                        }
                    }
                    .layoutPriority(1)

                    Spacer(minLength: 8)

                    DatePicker(
                        "",
                        selection: Binding(
                            get: { displayedMonth },
                            set: { newDate in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    displayedMonth = newDate
                                    selectedDate = newDate
                                }
                            }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .scaleEffect(0.9)
                    .background(
                        Color.white.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .padding(20)
            }

            VStack(spacing: 0) {
                weekdayHeaders
                    .padding(.horizontal, 10)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                monthGrid
                    .padding(.horizontal, 6)
                    .padding(.bottom, 14)
            }
            .background(Color.petal)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.burgundy.opacity(0.15), radius: 14, y: 6)
    }

    // MARK: - Weekday Headers
    var weekdayHeaders: some View {
        let symbols = cal.shortWeekdaySymbols
        let weekendIndices = [0, 6]
        return HStack(spacing: 0) {
            ForEach(symbols.indices, id: \.self) { i in
                Text(symbols[i])
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(weekendIndices.contains(i) ? Color.rose : Color.mauve)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Month Grid
    var monthGrid: some View {
        let days = daysInMonth()
        let firstWeekday = cal.component(.weekday, from: days.first ?? Date()) - cal.firstWeekday
        let offset = (firstWeekday + 7) % 7

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 6) {
            ForEach(0..<offset, id: \.self) { _ in
                Color.clear.frame(height: 48)
            }

            ForEach(days, id: \.self) { date in
                CalDayCell(
                    date: date,
                    isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                    hasOutfit: store.outfit(for: date) != nil
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedDate = date
                    }
                }
            }
        }
    }

    // MARK: - Day Detail Card
    var dayDetailCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.burgundy, Color.rose],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    Text(selectedDate, format: .dateTime.day())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(selectedDate, format: .dateTime.weekday(.wide))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.deepWine)
                        if cal.isDateInToday(selectedDate) {
                            Text("TODAY")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(colors: [.burgundy, .rose], startPoint: .leading, endPoint: .trailing),
                                    in: Capsule()
                                )
                        }
                    }
                    Text(selectedDate, format: .dateTime.month(.wide).year())
                        .font(.system(size: 13))
                        .foregroundColor(.mauve)
                }
                .padding(.leading, 4)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()
                .background(Color.blushBorder)
                .padding(.horizontal, 20)

            if let outfit = store.outfit(for: selectedDate) {
                plannedContent(outfit: outfit)
            } else {
                emptyDayContent
            }
        }
        .background(Color.blushLight, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Planned Content
    func plannedContent(outfit: Outfit) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                    Text("Planned")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.1), in: Capsule())

                Spacer()

                Button { showOutfitPicker = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text("Change")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.burgundy)
                }
            }

            Text(outfit.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.deepWine)

            let items = store.items(in: outfit)
            if !items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { item in
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.blush)
                                    if let img = store.loadImage(for: item) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 76, height: 76)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                    } else {
                                        Text(item.category.emoji)
                                            .font(.system(size: 22))
                                    }
                                }
                                .frame(width: 76, height: 76)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.blushBorder, lineWidth: 1)
                                )
                                .interactive3DEffect(maxAngle: 10, enableShadow: false)

                                Text(item.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.deepWine)
                                    .lineLimit(1)
                                    .frame(width: 76)

                                Text(item.category.rawValue)
                                    .font(.system(size: 9))
                                    .foregroundColor(.mauve)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    store.loadOutfit(outfit)
                    selectedTab = 1
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.stand")
                        Text("Load in Studio")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(colors: [.burgundy, .rose], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }

                Button(role: .destructive) {
                    withAnimation { store.assign(outfit: nil, to: selectedDate) }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(.red)
                        .frame(width: 48, height: 46)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(20)
    }

    // MARK: - Empty Day Content
    var emptyDayContent: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.rose.opacity(0.15), Color.burgundy.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "hanger")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color.rose.opacity(0.6))
            }
            .padding(.top, 10)

            VStack(spacing: 5) {
                Text("No outfit planned")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.deepWine)
                Text("Pick something great to wear")
                    .font(.system(size: 13))
                    .foregroundColor(.mauve)
            }

            Button { showOutfitPicker = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Plan This Day")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.burgundy, .rose], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
        }
        .padding(20)
    }

    // MARK: - Helpers
    func daysInMonth() -> [Date] {
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: first) }
    }
}

// MARK: - Calendar Day Cell
struct CalDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasOutfit: Bool
    private let cal = Calendar.current

    var isToday: Bool { cal.isDateInToday(date) }
    var isWeekend: Bool {
        let weekday = cal.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    var body: some View {
        VStack(spacing: 3) {
            Text("\(cal.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected || isToday ? .bold : .medium, design: .rounded))
                .foregroundColor(textColor)

            if hasOutfit {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color.white : Color.rose)
                    .frame(width: 14, height: 3)
            } else {
                Color.clear.frame(width: 14, height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(background)
    }

    var textColor: Color {
        if isSelected { return .white }
        if isToday { return .burgundy }
        if isWeekend { return .rose }
        return .deepWine
    }

    @ViewBuilder
    var background: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.burgundy, .rose],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else if isToday {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.burgundy.opacity(0.1))
        } else {
            Color.clear
        }
    }
}

// MARK: - Calendar Outfit Picker
struct CalendarOutfitPicker: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let date: Date

    @State private var confirmedOutfit: Outfit? = nil
    @State private var showConfirmation = false

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.savedOutfits.isEmpty {
                    emptyState
                } else {
                    outfitList
                }
            }
            .navigationTitle("Choose Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.burgundy)
                }
            }
            .overlay {
                if showConfirmation {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.burgundy.opacity(0.15), Color.rose.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 70, height: 70)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.burgundy, .rose],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            Text("Outfit Planned!")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.deepWine)

                            if let outfit = confirmedOutfit {
                                Text("\(outfit.name) is planned for \(formattedDate)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mauve)
                                    .multilineTextAlignment(.center)
                            }

                            Button {
                                withAnimation { showConfirmation = false }
                                dismiss()
                            } label: {
                                Text("OK")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(
                                        LinearGradient(
                                            colors: [.burgundy, .rose],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 14)
                                    )
                            }
                        }
                        .padding(24)
                        .background(Color.petal, in: RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.blushBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.burgundy.opacity(0.15), radius: 20, y: 8)
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }

    var emptyState: some View {
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
                    .frame(width: 100, height: 100)
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color.rose.opacity(0.4))
            }
            Text("No saved outfits")
                .font(.headline)
                .foregroundColor(.deepWine)
            Text("Create outfits in the Studio tab first")
                .font(.subheadline)
                .foregroundColor(.mauve)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    var outfitList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(store.savedOutfits) { outfit in
                    let isAssigned = store.outfit(for: date)?.id == outfit.id
                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            HStack(spacing: -10) {
                                ForEach(store.items(in: outfit).prefix(3)) { item in
                                    ZStack {
                                        Color.blush
                                        if let img = store.loadImage(for: item) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Text(item.category.emoji)
                                        }
                                    }
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.petal, lineWidth: 2)
                                    )
                                }
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(outfit.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.deepWine)
                                Text("\(store.items(in: outfit).count) items")
                                    .font(.system(size: 12))
                                    .foregroundColor(.mauve)
                            }

                            Spacer()

                            if isAssigned {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.burgundy)
                            }
                        }
                        .padding(14)

                        Divider()
                            .background(Color.blushBorder)
                            .padding(.horizontal, 14)

                        HStack(spacing: 10) {
                            NavigationLink {
                                OutfitPreviewView(outfit: outfit, date: date, dismissSheet: { dismiss() })
                                    .environmentObject(store)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "eye")
                                        .font(.system(size: 12))
                                    Text("Show Outfit")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.burgundy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.burgundy.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            }

                            Button {
                                store.assign(outfit: outfit, to: date)
                                confirmedOutfit = outfit
                                showConfirmation = true
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 12))
                                    Text("Plan This Day")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(colors: [.burgundy, .rose], startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                    .background(
                        isAssigned ? Color.burgundy.opacity(0.06) : Color.petal,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isAssigned ? Color.burgundy.opacity(0.3) : Color.blushBorder,
                                lineWidth: 1
                            )
                    )
                }
            }
            .padding(16)
        }
        .background(Color.blushLight)
    }
}

// MARK: - Outfit Preview View
struct OutfitPreviewView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let outfit: Outfit
    let date: Date
    var dismissSheet: (() -> Void)? = nil

    @State private var showConfirmation = false

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let snapshot = store.loadSnapshot(for: outfit) {
                    Image(uiImage: snapshot)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.burgundy.opacity(0.15), radius: 10, y: 4)
                        .interactive3DEffect(maxAngle: 12, enableShadow: false)
                        .padding(.top, 8)
                }

                Text(outfit.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.deepWine)

                let items = store.items(in: outfit)
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Items")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.mauve)
                            .padding(.horizontal, 4)

                        ForEach(items) { item in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blush)
                                    if let img = store.loadImage(for: item) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 56, height: 56)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        Text(item.category.emoji)
                                            .font(.system(size: 22))
                                    }
                                }
                                .frame(width: 56, height: 56)
                                .interactive3DEffect(maxAngle: 10, enableShadow: false)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.deepWine)
                                    Text(item.category.rawValue)
                                        .font(.system(size: 12))
                                        .foregroundColor(.mauve)
                                }

                                Spacer()
                            }
                            .padding(10)
                            .background(Color.petal, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }

                Button {
                    store.assign(outfit: outfit, to: date)
                    showConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.plus")
                        Text("Plan This Day")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.burgundy, .rose], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(Color.blushLight)
        .navigationTitle("Outfit Preview")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if showConfirmation {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.burgundy.opacity(0.15), Color.rose.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.burgundy, .rose],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text("Outfit Planned!")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.deepWine)

                        Text("\(outfit.name) is planned for \(formattedDate)")
                            .font(.system(size: 14))
                            .foregroundColor(.mauve)
                            .multilineTextAlignment(.center)

                        Button {
                            withAnimation { showConfirmation = false }
                            if let dismissSheet {
                                dismissSheet()
                            } else {
                                dismiss()
                            }
                        } label: {
                            Text("OK")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    LinearGradient(
                                        colors: [.burgundy, .rose],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                        }
                    }
                    .padding(24)
                    .background(Color.petal, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.blushBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.burgundy.opacity(0.15), radius: 20, y: 8)
                    .padding(.horizontal, 40)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
}
