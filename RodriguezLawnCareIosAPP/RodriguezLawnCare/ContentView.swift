import SwiftUI
import UserNotifications
import AVKit
import Combine

// MARK: - THEME & BRANDING
enum Brand {
    static let primary = Color(red: 0.13, green: 0.77, blue: 0.36)       // Emerald Green #22c55e
    static let primaryDark = Color(red: 0.08, green: 0.55, blue: 0.25)   // Deep Forest #15803d
    static let accent = Color(red: 0.96, green: 0.62, blue: 0.04)        // Amber Gold #f59e0b
    static let background = Color(red: 0.06, green: 0.08, blue: 0.12)    // Dark Slate #0f172a
    static let card = Color(red: 0.11, green: 0.15, blue: 0.22)          // Slate Card #1e293b
    static let cardLight = Color(red: 0.15, green: 0.20, blue: 0.30)     // Border / Highlight
}

// MARK: - DATA MODELS
struct Lead: Identifiable, Codable, Equatable {
    var id: Int
    var created_at: Int?
    var date_str: String?
    var name: String
    var phone: String
    var services: [String]?
    var address: String?
    var date: String?
    var time: String?
    var frequency: String?
    var description: String?
    var source: String?
    var status: String?          // pending, contacted, estimated, confirmed, completed, cancelled
    var estimated_amount: Double?
    var notes: String?
}

struct GalleryPhoto: Identifiable, Codable, Equatable {
    var id: Int
    var filename: String
    var url: String
    var title: String
    var category: String
    var location: String?
    var verified: Bool?
    var uploaded_at: Int?
}

struct WebStats: Codable {
    var status: String?
    var bot_online: Bool?
    var bot_user: String?
    var total_leads: Int?
    var pending_leads: Int?
    var confirmed_leads: Int?
    var completed_leads: Int?
    var gallery_count: Int?
    var total_visits: Int?
    var visits_today: Int?
    var conversion_rate: String?
    var uptime_seconds: Int?
}

struct WebAnalytics: Codable {
    var total_visits: Int
    var unique_visitors: Int
    var visits_today: Int
    var quotes_submitted: Int
    var conversion_rate: String
}

struct VideoPreset: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var video_url: String
    var poster_url: String
    var desc: String
}

struct PhotoPreset: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var photo_url: String
}

struct WebSettings: Codable {
    var hero_type: String           // "video" or "image"
    var hero_video_url: String
    var hero_poster_url: String
    var hero_preset_id: String?
    var hero_title: String?
    var hero_subtitle: String?
    var video_presets: [VideoPreset]?
    var photo_presets: [PhotoPreset]?
}

struct LeadListResponse: Codable {
    var success: Bool
    var leads: [Lead]
}

struct GalleryResponse: Codable {
    var success: Bool
    var gallery: [GalleryPhoto]
}

struct StatsResponse: Codable {
    var success: Bool
    var stats: WebStats
}

struct SettingsResponse: Codable {
    var success: Bool
    var settings: WebSettings
}

// MARK: - APP STORE (STATE MANAGEMENT & REAL-TIME API)
class LawnCareStore: ObservableObject {
    @Published var leads: [Lead] = []
    @Published var gallery: [GalleryPhoto] = []
    @Published var stats: WebStats? = nil
    @Published var settings: WebSettings? = nil
    @Published var isLoading: Bool = false
    @Published var isOnline: Bool = false
    @Published var lastSyncTime: String = "Nunca"

    // Real-time notification banner
    @Published var latestAlertMessage: String? = nil
    @Published var showAlertBanner: Bool = false

    @AppStorage("api_server_url") var serverURL: String = "https://rodriguezlawncarenuevaa-production.up.railway.app"

    private var knownLeadIds: Set<Int> = []
    private var isFirstLoad: Bool = true
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadDemoData()
        requestNotificationPermissions()
        startRealtimePolling()
    }

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notification permission: \(granted)")
        }
    }

    func startRealtimePolling() {
        // Real-time auto sync every 10 seconds
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.refreshAll(silent: true)
                }
            }
            .store(in: &cancellables)

        Task { @MainActor in
            await refreshAll(silent: false)
        }
    }

    func triggerNotification(lead: Lead) {
        // 1. In-app heads-up banner
        let bannerText = "🚨 ¡Nueva Cotización! \(lead.name) • \(lead.phone)"
        self.latestAlertMessage = bannerText
        self.showAlertBanner = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Auto hide banner after 6 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            self.showAlertBanner = false
        }

        // 2. iOS System Notification (works in background / lockscreen)
        let content = UNMutableNotificationContent()
        content.title = "🚨 ¡NUEVA COTIZACIÓN EN LA WEB!"
        content.subtitle = "\(lead.name) • \(lead.phone)"
        let svcs = lead.services?.joined(separator: ", ") ?? "Corte de Césped"
        content.body = "Servicios: \(svcs) | Fecha: \(lead.date ?? "Lo antes posible")"
        content.sound = .default

        let request = UNNotificationRequest(identifier: "lead_\(lead.id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func loadDemoData() {
        leads = [
            Lead(
                id: 1730101,
                name: "Marcus Henderson",
                phone: "(254) 555-0192",
                services: ["Corte de Césped & Orillado", "Orillado con Navaja"],
                address: "4201 Trimmier Rd, Killeen, TX",
                date: "Mañana temprano",
                time: "9:00 AM",
                frequency: "Quincenal",
                description: "Pasto crecido, requiere líneas limpias en banqueta y entrada.",
                source: "Web Estimado Rápido",
                status: "pending",
                estimated_amount: 55.0,
                notes: "Código portón: 4421. Avisar por texto 15 min antes."
            ),
            Lead(
                id: 1730102,
                name: "Sarah Jenkins",
                phone: "(254) 555-0144",
                services: ["Instalación de Mulch Oscuro", "Poda de Arbustos"],
                address: "1208 Knights Way, Harker Heights, TX",
                date: "Viernes",
                time: "10:30 AM",
                frequency: "Una vez",
                description: "4 jardineras con mulch color chocolate y recorte de arbustos.",
                source: "Web Formulario Citas",
                status: "confirmed",
                estimated_amount: 185.0,
                notes: "Mulch color chocolate aprobado por WhatsApp."
            )
        ]

        gallery = [
            GalleryPhoto(id: 8, filename: "work_8.jpg", url: "./assets/gallery/work_8.jpg", title: "Builder Duplex", category: "General LawnCare", location: "Killeen & Central TX", verified: true),
            GalleryPhoto(id: 7, filename: "work_7.jpg", url: "./assets/gallery/work_7.jpg", title: "Front Yard Clean & Sharp Mowing", category: "Front Yard", location: "Killeen & Central TX", verified: true),
            GalleryPhoto(id: 6, filename: "work_6.jpg", url: "./assets/gallery/work_6.jpg", title: "7 duplex", category: "General LawnCare", location: "Killeen & Central TX", verified: true),
            GalleryPhoto(id: 5, filename: "work_5.jpg", url: "./assets/gallery/work_5.jpg", title: "Front and back", category: "Front Yard", location: "Killeen & Central TX", verified: true),
            GalleryPhoto(id: 4, filename: "work_4.jpg", url: "./assets/gallery/work_4.jpg", title: "Fresh Dark Mulch Installation", category: "Mulch", location: "Killeen & Central TX", verified: true),
            GalleryPhoto(id: 3, filename: "work_3.jpg", url: "./assets/gallery/work_3.jpg", title: "Hedge Trimming & Shrub Shaping", category: "Shrubs & Bushes", location: "Killeen & Central TX", verified: true),
            GalleryPhoto(id: 2, filename: "work_2.jpg", url: "./assets/gallery/work_2.jpg", title: "Front Yard Renovation & Razor Edging", category: "Front Yard", location: "Killeen & Central TX", verified: true)
        ]

        settings = WebSettings(
            hero_type: "video",
            hero_video_url: "./assets/video/hero.mp4",
            hero_poster_url: "./assets/images/drone_tundra_intro.jpg",
            hero_preset_id: "drone_tundra",
            hero_title: "Your Dream Lawn, Flawlessly Maintained",
            video_presets: [
                VideoPreset(id: "drone_tundra", name: "🚁 Drone Aéreo Tundra & Remolque", video_url: "./assets/video/hero.mp4", poster_url: "./assets/images/drone_tundra_intro.jpg", desc: "Drone 4K, Tundra negra, créditos de Rafael Rodriguez y Antes/Después."),
                VideoPreset(id: "mower_stripes", name: "🚜 Corte Comercial con Líneas y Orillado", video_url: "./assets/video/hero.mp4", poster_url: "./assets/images/mowing.jpg", desc: "Líneas perfectas en césped con podadora comercial y orillado."),
                VideoPreset(id: "luxury_estate", name: "🏡 Residencia de Lujo & Mulch", video_url: "./assets/video/hero.mp4", poster_url: "./assets/images/drone_intro.jpg", desc: "Propiedad residencial en Central Texas con jardineras de mulch oscuro.")
            ],
            photo_presets: [
                PhotoPreset(id: "photo_drone", name: "📸 Foto Dron Tundra & Residencia", photo_url: "./assets/images/drone_tundra_intro.jpg"),
                PhotoPreset(id: "photo_mowing", name: "📸 Foto Líneas de Corte de Césped", photo_url: "./assets/images/mowing.jpg"),
                PhotoPreset(id: "photo_mulch", name: "📸 Foto Mulch e Instalación", photo_url: "./assets/images/mulch.jpg"),
                PhotoPreset(id: "photo_hero", name: "📸 Foto Jardín Principal Clásico", photo_url: "./assets/images/hero.jpg")
            ]
        )
    }

    private var cleanURL: String {
        var base = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.hasSuffix("/") {
            base.removeLast()
        }
        return base
    }

    func fullMediaURL(_ path: String) -> String {
        if path.starts(with: "http://") || path.starts(with: "https://") {
            return path
        }
        var cleanPath = path
        if cleanPath.starts(with: "./") {
            cleanPath.removeFirst(2)
        }
        if !cleanPath.starts(with: "/") {
            cleanPath = "/" + cleanPath
        }
        return "\(cleanURL)\(cleanPath)"
    }

    @MainActor
    func refreshAll(silent: Bool = false) async {
        if !silent { isLoading = true }
        defer { if !silent { isLoading = false } }

        await fetchStats()
        await fetchLeads()
        await fetchGallery()
        await fetchSettings()

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        lastSyncTime = formatter.string(from: Date())
    }

    @MainActor
    func fetchStats() async {
        guard let url = URL(string: "\(cleanURL)/api/stats") else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 6
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(StatsResponse.self, from: data)
                self.stats = decoded.stats
                self.isOnline = true
            } else {
                self.isOnline = false
            }
        } catch {
            self.isOnline = false
        }
    }

    @MainActor
    func fetchLeads() async {
        guard let url = URL(string: "\(cleanURL)/api/leads") else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 8
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(LeadListResponse.self, from: data)

                // Check for new incoming leads
                if !isFirstLoad {
                    for lead in decoded.leads {
                        if !knownLeadIds.contains(lead.id) {
                            triggerNotification(lead: lead)
                        }
                    }
                }
                isFirstLoad = false
                knownLeadIds = Set(decoded.leads.map { $0.id })
                self.leads = decoded.leads
            }
        } catch {
            // Keep existing leads cache
        }
    }

    @MainActor
    func fetchGallery() async {
        guard let url = URL(string: "\(cleanURL)/api/gallery") else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 8
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(GalleryResponse.self, from: data)
                if !decoded.gallery.isEmpty {
                    self.gallery = decoded.gallery
                }
            }
        } catch {
            // Keep existing cache
        }
    }

    @MainActor
    func fetchSettings() async {
        guard let url = URL(string: "\(cleanURL)/api/settings") else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 8
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(SettingsResponse.self, from: data)
                self.settings = decoded.settings
            }
        } catch {
            // Keep existing settings cache
        }
    }

    @MainActor
    func updateLeadStatus(id: Int, status: String, notes: String? = nil, estimatedAmount: Double? = nil) async {
        if let idx = leads.firstIndex(where: { $0.id == id }) {
            leads[idx].status = status
            if let n = notes { leads[idx].notes = n }
            if let e = estimatedAmount { leads[idx].estimated_amount = e }
        }

        guard let url = URL(string: "\(cleanURL)/api/leads/update") else { return }
        var payload: [String: Any] = ["id": id, "status": status]
        if let n = notes { payload["notes"] = n }
        if let e = estimatedAmount { payload["estimated_amount"] = e }

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
        } catch {
            print("Update lead server error: \(error)")
        }
    }

    @MainActor
    func createLead(name: String, phone: String, services: [String], address: String, date: String, time: String, frequency: String, description: String, amount: Double, notes: String) async {
        let newLead = Lead(
            id: Int(Date().timeIntervalSince1970 * 1000),
            name: name,
            phone: phone,
            services: services,
            address: address,
            date: date,
            time: time,
            frequency: frequency,
            description: description,
            source: "App Rodriguez LawnCare",
            status: "pending",
            estimated_amount: amount,
            notes: notes
        )
        leads.insert(newLead, at: 0)

        guard let url = URL(string: "\(cleanURL)/api/leads") else { return }
        let payload: [String: Any] = [
            "name": name,
            "phone": phone,
            "services": services,
            "address": address,
            "date": date,
            "time": time,
            "frequency": frequency,
            "description": description,
            "source": "App Rodriguez LawnCare",
            "estimated_amount": amount,
            "notes": notes
        ]

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
        } catch {
            print("Create lead error: \(error)")
        }
    }

    @MainActor
    func deleteLead(id: Int) async {
        leads.removeAll(where: { $0.id == id })
        guard let url = URL(string: "\(cleanURL)/api/leads/delete") else { return }
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["id": id])
            _ = try await URLSession.shared.data(for: req)
        } catch {
            print("Delete lead error: \(error)")
        }
    }

    // GALLERY CRUD ACTIONS
    @MainActor
    func addGalleryPhoto(title: String, category: String, urlString: String, location: String = "Killeen & Central TX") async {
        let newId = (gallery.map { $0.id }.max() ?? 0) + 1
        let item = GalleryPhoto(id: newId, filename: "work_\(newId).jpg", url: urlString, title: title, category: category, location: location, verified: true)
        gallery.insert(item, at: 0)

        guard let url = URL(string: "\(cleanURL)/api/gallery") else { return }
        let payload: [String: Any] = [
            "title": title,
            "category": category,
            "url": urlString,
            "location": location,
            "verified": true
        ]
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
        } catch {
            print("Add photo error: \(error)")
        }
    }

    @MainActor
    func updateGalleryPhoto(id: Int, title: String, category: String, urlString: String?, location: String?) async {
        if let idx = gallery.firstIndex(where: { $0.id == id }) {
            gallery[idx].title = title
            gallery[idx].category = category
            if let u = urlString, !u.isEmpty { gallery[idx].url = u }
            if let loc = location { gallery[idx].location = loc }
        }

        guard let url = URL(string: "\(cleanURL)/api/gallery/update") else { return }
        var payload: [String: Any] = ["id": id, "title": title, "category": category]
        if let u = urlString, !u.isEmpty { payload["url"] = u }
        if let loc = location { payload["location"] = loc }

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
        } catch {
            print("Update photo error: \(error)")
        }
    }

    @MainActor
    func moveGalleryPhotoToTop(id: Int) async {
        if let idx = gallery.firstIndex(where: { $0.id == id }) {
            let item = gallery.remove(at: idx)
            gallery.insert(item, at: 0)
        }

        guard let url = URL(string: "\(cleanURL)/api/gallery/reorder") else { return }
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["id": id, "action": "move_to_top"])
            _ = try await URLSession.shared.data(for: req)
        } catch {
            print("Move photo error: \(error)")
        }
    }

    @MainActor
    func deleteGalleryPhoto(id: Int) async {
        gallery.removeAll(where: { $0.id == id })
        guard let url = URL(string: "\(cleanURL)/api/gallery/delete") else { return }
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["id": id])
            _ = try await URLSession.shared.data(for: req)
        } catch {
            print("Delete photo error: \(error)")
        }
    }

    // HERO BACKGROUND MANAGEMENT
    @MainActor
    func updateHeroBackground(type: String, videoURL: String, posterURL: String, presetId: String) async {
        if settings == nil {
            settings = WebSettings(hero_type: type, hero_video_url: videoURL, hero_poster_url: posterURL)
        } else {
            settings?.hero_type = type
            settings?.hero_video_url = videoURL
            settings?.hero_poster_url = posterURL
            settings?.hero_preset_id = presetId
        }

        guard let url = URL(string: "\(cleanURL)/api/settings/hero") else { return }
        let payload: [String: Any] = [
            "hero_type": type,
            "hero_video_url": videoURL,
            "hero_poster_url": posterURL,
            "hero_preset_id": presetId
        ]
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
        } catch {
            print("Save hero settings error: \(error)")
        }
    }
}

// MARK: - MAIN ROOT VIEW WITH LIVE NOTIFICATION BANNER
struct ContentView: View {
    @StateObject private var store = LawnCareStore()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                AppointmentsView(store: store)
                    .tabItem {
                        Label("Citas", systemImage: "calendar.badge.clock")
                    }
                    .tag(0)

                EstimatorView(store: store)
                    .tabItem {
                        Label("Estimados", systemImage: "dollarsign.circle.fill")
                    }
                    .tag(1)

                GalleryAdminView(store: store)
                    .tabItem {
                        Label("Trabajos Web", systemImage: "photo.on.rectangle.angled")
                    }
                    .tag(2)

                WebAdminView(store: store)
                    .tabItem {
                        Label("Web & Servidor", systemImage: "globe.americas.fill")
                    }
                    .tag(3)
            }
            .accentColor(Brand.primary)

            // Real-Time Floating Notification Banner
            if store.showAlertBanner, let msg = store.latestAlertMessage {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title3)
                            .foregroundStyle(Brand.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(msg)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text("Toca para ver la cita en Citas")
                                .font(.caption2)
                                .foregroundStyle(Brand.primary)
                        }
                        Spacer()
                        Button {
                            withAnimation { store.showAlertBanner = false }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(14)
                    .background(Brand.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Brand.primary.opacity(0.6), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
                    .padding(.horizontal, 16)
                    .padding(.top, 48)
                    .onTapGesture {
                        selectedTab = 0
                        store.showAlertBanner = false
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: store.showAlertBanner)
            }
        }
    }
}

// MARK: - TAB 1: CITAS & LEADS (REAL TIME)
struct AppointmentsView: View {
    @ObservedObject var store: LawnCareStore
    @State private var selectedFilter = "all"
    @State private var searchText = ""
    @State private var showNewLeadSheet = false
    @State private var activeLeadDetail: Lead? = nil

    var filteredLeads: [Lead] {
        store.leads.filter { lead in
            let matchesFilter: Bool
            if selectedFilter == "all" {
                matchesFilter = true
            } else {
                matchesFilter = (lead.status?.lowercased() == selectedFilter)
            }

            if searchText.isEmpty {
                return matchesFilter
            } else {
                let term = searchText.lowercased()
                let nameMatch = lead.name.lowercased().contains(term)
                let phoneMatch = lead.phone.contains(term)
                let addrMatch = (lead.address ?? "").lowercased().contains(term)
                return matchesFilter && (nameMatch || phoneMatch || addrMatch)
            }
        }
    }

    var pendingCount: Int { store.leads.filter { ($0.status ?? "") == "pending" }.count }
    var confirmedCount: Int { store.leads.filter { ($0.status ?? "") == "confirmed" }.count }
    var completedCount: Int { store.leads.filter { ($0.status ?? "") == "completed" }.count }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Live Visitor & Quote Ribbon
                    HStack(spacing: 10) {
                        // Live Visitors
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Visitas Web")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray)
                                Text("\(store.stats?.total_visits ?? 1420)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Visits Today
                        HStack(spacing: 6) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption2)
                                .foregroundStyle(Brand.primary)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Hoy")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray)
                                Text("+\(store.stats?.visits_today ?? 42)")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        Spacer()

                        // Status counts
                        HStack(spacing: 6) {
                            StatusTag(title: "Pend.", count: pendingCount, color: Brand.accent)
                            StatusTag(title: "Conf.", count: confirmedCount, color: Brand.primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "Todas (\(store.leads.count))", isSelected: selectedFilter == "all") { selectedFilter = "all" }
                            FilterChip(title: "Pendientes (\(pendingCount))", isSelected: selectedFilter == "pending") { selectedFilter = "pending" }
                            FilterChip(title: "Confirmadas (\(confirmedCount))", isSelected: selectedFilter == "confirmed") { selectedFilter = "confirmed" }
                            FilterChip(title: "Cotizadas", isSelected: selectedFilter == "estimated") { selectedFilter = "estimated" }
                            FilterChip(title: "Completadas", isSelected: selectedFilter == "completed") { selectedFilter = "completed" }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 10)

                    // Search Field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)
                        TextField("Buscar cliente, teléfono o dirección...", text: $searchText)
                            .foregroundStyle(.white)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Brand.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                    // Appointments List
                    if filteredLeads.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundStyle(.gray)
                            Text("No hay citas registradas")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Cuando un cliente pida cotización en la web, sonará una notificación en vivo.")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredLeads) { lead in
                                LeadCardView(lead: lead) {
                                    activeLeadDetail = lead
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { indexSet in
                                for idx in indexSet {
                                    let item = filteredLeads[idx]
                                    Task { await store.deleteLead(id: item.id) }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await store.refreshAll()
                        }
                    }
                }
            }
            .navigationTitle("Citas en Tiempo Real 🌿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(store.isOnline ? Brand.primary : .orange)
                            .frame(width: 8, height: 8)
                        Text(store.isOnline ? "En Línea 24/7" : "Offline")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewLeadSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Nueva Cita")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(Brand.primary)
                    }
                }
            }
            .sheet(isPresented: $showNewLeadSheet) {
                NewLeadSheet(store: store)
            }
            .sheet(item: $activeLeadDetail) { lead in
                LeadDetailSheet(lead: lead, store: store)
            }
        }
    }
}

struct StatusTag: View {
    let title: String
    let count: Int
    let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Text(title).font(.system(size: 10)).foregroundStyle(.gray)
            Text("\(count)").font(.caption.bold()).foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - LEAD CARD COMPONENT
struct LeadCardView: View {
    let lead: Lead
    let onDetails: () -> Void

    var statusColor: Color {
        switch (lead.status ?? "").lowercased() {
        case "pending": return Brand.accent
        case "confirmed": return Brand.primary
        case "estimated": return .blue
        case "completed": return .purple
        case "cancelled": return .red
        default: return .gray
        }
    }

    var statusLabel: String {
        switch (lead.status ?? "").lowercased() {
        case "pending": return "Pendiente"
        case "confirmed": return "Confirmado"
        case "estimated": return "Cotizado"
        case "completed": return "Completado"
        case "cancelled": return "Cancelado"
        default: return lead.status ?? "Nuevo"
        }
    }

    var cleanPhoneDigits: String {
        lead.phone.filter { $0.isNumber }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lead.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)

                    if let source = lead.source {
                        Text(source)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()

                if let amt = lead.estimated_amount, amt > 0 {
                    Text("$\(Int(amt))")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Brand.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Brand.primary.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(statusLabel)
                    .font(.caption2.bold())
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.18))
                    .clipShape(Capsule())
            }

            if let svcs = lead.services, !svcs.isEmpty {
                HStack(spacing: 6) {
                    ForEach(svcs.prefix(2), id: \.self) { svc in
                        Text(svc)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    if svcs.count > 2 {
                        Text("+\(svcs.count - 2)")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let d = lead.date, !d.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(Brand.primary)
                        Text("\(d) • \(lead.time ?? "Horario regular")")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                        if let f = lead.frequency, !f.isEmpty {
                            Text("(\(f))")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                    }
                }

                if let addr = lead.address, !addr.isEmpty, addr != "Por coordinar por llamada/mensaje" {
                    Button {
                        if let encoded = addr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.9))
                            Text(addr)
                                .font(.caption)
                                .foregroundStyle(.blue.opacity(0.9))
                                .lineLimit(1)
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 10))
                                .foregroundStyle(.blue.opacity(0.7))
                        }
                    }
                }
            }

            // Quick actions
            HStack(spacing: 10) {
                Button {
                    let greeting = "Hola \(lead.name), te saludamos de Rodriguez LawnCare sobre tu solicitud de cita/servicio."
                    let phoneDial = cleanPhoneDigits.starts(with: "1") ? cleanPhoneDigits : "1\(cleanPhoneDigits)"
                    if let enc = greeting.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let url = URL(string: "https://wa.me/\(phoneDial)?text=\(enc)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "message.fill")
                        Text("WhatsApp")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.15, green: 0.68, blue: 0.38))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    if let url = URL(string: "tel://\(cleanPhoneDigits)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "phone.fill")
                        Text("Llamar")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    onDetails()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Brand.cardLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - FILTER CHIP
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Brand.primary : Brand.card)
                .foregroundStyle(isSelected ? .black : .white.opacity(0.8))
                .clipShape(Capsule())
        }
    }
}

// MARK: - DETAIL & STATUS UPDATE SHEET
struct LeadDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var lead: Lead
    @ObservedObject var store: LawnCareStore
    @State private var notesText: String = ""
    @State private var amountText: String = ""
    @State private var selectedStatus: String = "pending"

    let statuses = [
        ("pending", "🟡 Pendiente"),
        ("contacted", "🔵 Contactado"),
        ("estimated", "💵 Cotizado"),
        ("confirmed", "🟢 Confirmado"),
        ("completed", "🟣 Completado"),
        ("cancelled", "🔴 Cancelado")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lead.name)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text(lead.phone)
                                .font(.headline)
                                .foregroundStyle(Brand.primary)
                            if let addr = lead.address {
                                Text(addr)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("ESTADO DE LA CITA")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)

                            Picker("Estado", selection: $selectedStatus) {
                                ForEach(statuses, id: \.0) { st in
                                    Text(st.1).tag(st.0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("MONTO ESTIMADO / COTIZADO ($)")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)

                            HStack {
                                Text("$").foregroundStyle(Brand.primary).font(.title3.bold())
                                TextField("Ej. 75.00", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .foregroundStyle(.white)
                            }
                            .padding(12)
                            .background(Brand.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTAS INTERNAS (CÓDIGO DE PUERTA, PREFERENCIAS)")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)

                            TextEditor(text: $notesText)
                                .frame(height: 90)
                                .padding(8)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                        }

                        Button {
                            let amt = Double(amountText.replacingOccurrences(of: "$", with: ""))
                            Task {
                                await store.updateLeadStatus(
                                    id: lead.id,
                                    status: selectedStatus,
                                    notes: notesText,
                                    estimatedAmount: amt
                                )
                                dismiss()
                            }
                        } label: {
                            Text("Guardar Cambios")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Brand.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 10)

                        Button(role: .destructive) {
                            Task {
                                await store.deleteLead(id: lead.id)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Eliminar Cita")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Detalles de la Cita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onAppear {
                selectedStatus = lead.status ?? "pending"
                notesText = lead.notes ?? ""
                if let a = lead.estimated_amount, a > 0 {
                    amountText = String(format: "%.2f", a)
                }
            }
        }
    }
}

// MARK: - NEW LEAD SHEET
struct NewLeadSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: LawnCareStore

    @State private var name = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var date = "Mañana"
    @State private var time = "9:00 AM"
    @State private var frequency = "Quincenal"
    @State private var description = ""
    @State private var amount = ""
    @State private var notes = ""
    @State private var selectedServices: Set<String> = ["Corte de Césped & Orillado"]

    let availableServices = [
        "Corte de Césped & Orillado",
        "Poda de Arbustos & Setos",
        "Instalación de Mulch",
        "Poda de Árboles",
        "Limpieza de Escombros / Hojas",
        "Borduras y Deshierbe"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("CLIENTE").font(.caption.bold()).foregroundStyle(.gray)
                            TextField("Nombre y Apellido", text: $name)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                            TextField("Teléfono (ej. 254-555-0192)", text: $phone)
                                .keyboardType(.phonePad)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                            TextField("Dirección completa", text: $address)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }

                        Group {
                            Text("HORARIO Y FRECUENCIA").font(.caption.bold()).foregroundStyle(.gray)
                            HStack {
                                TextField("Fecha (ej. Mañana, Sábado)", text: $date)
                                    .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                                TextField("Hora (ej. 10:00 AM)", text: $time)
                                    .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                            }

                            Picker("Frecuencia", selection: $frequency) {
                                Text("Una sola vez").tag("Una vez")
                                Text("Quincenal (Recomendado)").tag("Quincenal")
                                Text("Semanal").tag("Semanal")
                                Text("Mensual").tag("Mensual")
                            }
                            .pickerStyle(.menu)
                            .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        Group {
                            Text("SERVICIOS A REALIZAR").font(.caption.bold()).foregroundStyle(.gray)
                            ForEach(availableServices, id: \.self) { svc in
                                Button {
                                    if selectedServices.contains(svc) {
                                        selectedServices.remove(svc)
                                    } else {
                                        selectedServices.insert(svc)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: selectedServices.contains(svc) ? "checkmark.square.fill" : "square")
                                            .foregroundStyle(selectedServices.contains(svc) ? Brand.primary : .gray)
                                        Text(svc)
                                            .foregroundStyle(.white)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(Brand.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }

                        Group {
                            Text("PRECIO ESTIMADO ($) & NOTAS").font(.caption.bold()).foregroundStyle(.gray)
                            TextField("Precio acordado (ej. 65)", text: $amount)
                                .keyboardType(.decimalPad)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                            TextField("Notas adicionales o instrucciones del portón", text: $notes)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }

                        Button {
                            guard !name.isEmpty else { return }
                            let amt = Double(amount) ?? 0.0
                            Task {
                                await store.createLead(
                                    name: name,
                                    phone: phone,
                                    services: Array(selectedServices),
                                    address: address,
                                    date: date,
                                    time: time,
                                    frequency: frequency,
                                    description: description,
                                    amount: amt,
                                    notes: notes
                                )
                                dismiss()
                            }
                        } label: {
                            Text("Guardar y Agendar Cita")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Brand.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Nueva Cita / Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - TAB 2: ESTIMATOR CALCULATOR
struct EstimatorView: View {
    @ObservedObject var store: LawnCareStore

    @State private var clientName = ""
    @State private var clientPhone = ""
    @State private var lawnSize = "medium"
    @State private var grassHeight = "normal"
    @State private var frequency = "biweekly"

    @State private var includeBushes = false
    @State private var bushCount = 4
    @State private var includeMulch = false
    @State private var mulchYards = 2
    @State private var includeTrees = false
    @State private var includeCleanup = false
    @State private var includeEdgingDethatch = false
    @State private var showCopiedAlert = false

    var basePrice: Double {
        switch lawnSize {
        case "small": return 45.0
        case "medium": return 65.0
        case "large": return 95.0
        case "acreage": return 160.0
        default: return 60.0
        }
    }

    var heightSurcharge: Double {
        switch grassHeight {
        case "tall": return 25.0
        case "overgrown": return 55.0
        default: return 0.0
        }
    }

    var addonsTotal: Double {
        var total = 0.0
        if includeBushes { total += Double(bushCount) * 10.0 }
        if includeMulch { total += Double(mulchYards) * 85.0 }
        if includeTrees { total += 90.0 }
        if includeCleanup { total += 75.0 }
        if includeEdgingDethatch { total += 35.0 }
        return total
    }

    var frequencyDiscountPercent: Double {
        switch frequency {
        case "weekly": return 0.10
        case "biweekly": return 0.05
        default: return 0.0
        }
    }

    var subtotal: Double {
        basePrice + heightSurcharge + addonsTotal
    }

    var totalEstimate: Double {
        let discount = subtotal * frequencyDiscountPercent
        return max(35.0, subtotal - discount)
    }

    var quoteSummaryText: String {
        var lines: [String] = []
        lines.append("🌿 *RODRIGUEZ LAWNCARE - COTIZACIÓN OFICIAL* 🌿")
        if !clientName.isEmpty {
            lines.append("Cliente: \(clientName)")
        }
        lines.append("Servicios incluidos:")
        lines.append("• Corte de césped & orillado con hilo/sopladora (\(lawnSizeName))")
        if grassHeight != "normal" {
            lines.append("• Ajuste por pasto crecido")
        }
        if includeBushes {
            lines.append("• Poda y moldeado de \(bushCount) arbustos")
        }
        if includeMulch {
            lines.append("• Instalación de \(mulchYards) yardas/bolsas de Mulch")
        }
        if includeTrees {
            lines.append("• Poda y recorte de ramas bajas")
        }
        if includeCleanup {
            lines.append("• Limpieza y retiro de escombros/hojas")
        }
        if includeEdgingDethatch {
            lines.append("• Marcado profundo de acera y desorillado")
        }

        let freqName = frequency == "weekly" ? "Semanal (10% desc. incluido)" : (frequency == "biweekly" ? "Quincenal (5% desc. incluido)" : "Servicio puntual")
        lines.append("• Frecuencia: \(freqName)")
        lines.append("----------------------------------------")
        lines.append("💵 *TOTAL ESTIMADO: $\(String(format: "%.2f", totalEstimate))*")
        lines.append("----------------------------------------")
        lines.append("¡Garantía de satisfacción! Trabajamos en Killeen, Harker Heights, Belton y alrededores.")
        lines.append("Llámanos o contáctanos al (254) 852-8163 / (254) 612-1399")
        return lines.joined(separator: "\n")
    }

    var lawnSizeName: String {
        switch lawnSize {
        case "small": return "Jardín Pequeño (< 5,000 sq ft)"
        case "medium": return "Jardín Mediano (5,000 - 10,000 sq ft)"
        case "large": return "Jardín Grande (10,000 - 15,000 sq ft)"
        case "acreage": return "Propiedad Grande (> 15,000 sq ft / Acre)"
        default: return "Estándar"
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(spacing: 6) {
                            Text("TOTAL ESTIMADO")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.7))
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("$").font(.title.bold()).foregroundStyle(Brand.primary)
                                Text(String(format: "%.0f", totalEstimate))
                                    .font(.system(size: 48, weight: .black))
                                    .foregroundStyle(.white)
                                Text(".00")
                                    .font(.title3.bold())
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            Text(frequency == "weekly" ? "Por visita semanal (-10%)" : (frequency == "biweekly" ? "Por visita quincenal (-5%)" : "Servicio puntual"))
                                .font(.caption)
                                .foregroundStyle(Brand.accent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [Brand.card, Brand.primaryDark.opacity(0.35)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Brand.primary.opacity(0.3), lineWidth: 1)
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Text("CLIENTE (OPCIONAL)").font(.caption.bold()).foregroundStyle(.gray)
                            HStack {
                                TextField("Nombre del cliente", text: $clientName)
                                    .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                                TextField("Teléfono", text: $clientPhone)
                                    .keyboardType(.phonePad)
                                    .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("TAMAÑO DE LA PROPIEDAD").font(.caption.bold()).foregroundStyle(.gray)
                            Picker("Tamaño", selection: $lawnSize) {
                                Text("Pequeño ($45)").tag("small")
                                Text("Mediano ($65)").tag("medium")
                                Text("Grande ($95)").tag("large")
                                Text("Acre+ ($160)").tag("acreage")
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("CONDICIÓN DEL CÉSPED").font(.caption.bold()).foregroundStyle(.gray)
                            Picker("Condición", selection: $grassHeight) {
                                Text("Normal").tag("normal")
                                Text("Alto (+ $25)").tag("tall")
                                Text("Muy Crecido (+ $55)").tag("overgrown")
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("FRECUENCIA").font(.caption.bold()).foregroundStyle(.gray)
                            Picker("Frecuencia", selection: $frequency) {
                                Text("Puntual").tag("onetime")
                                Text("Quincenal (-5%)").tag("biweekly")
                                Text("Semanal (-10%)").tag("weekly")
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("SERVICIOS EXTRA AÑADIDOS").font(.caption.bold()).foregroundStyle(.gray)

                            ToggleRow(icon: "scissors", title: "Poda de Arbustos / Setos", price: "$\(bushCount * 10)", isOn: $includeBushes)
                            if includeBushes {
                                Stepper("Cantidad de arbustos: \(bushCount)", value: $bushCount, in: 1...30)
                                    .font(.caption).foregroundStyle(.white).padding(.horizontal)
                            }

                            ToggleRow(icon: "shippingbox.fill", title: "Instalación de Mulch", price: "$\(mulchYards * 85)", isOn: $includeMulch)
                            if includeMulch {
                                Stepper("Yardas / Áreas: \(mulchYards)", value: $mulchYards, in: 1...10)
                                    .font(.caption).foregroundStyle(.white).padding(.horizontal)
                            }

                            ToggleRow(icon: "leaf.fill", title: "Poda de Ramas de Árboles", price: "$90", isOn: $includeTrees)
                            ToggleRow(icon: "trash.fill", title: "Limpieza General & Escombros", price: "$75", isOn: $includeCleanup)
                            ToggleRow(icon: "square.dashed", title: "Bordeado Profundo de Aceras", price: "$35", isOn: $includeEdgingDethatch)
                        }

                        VStack(spacing: 12) {
                            Button {
                                let phoneDigits = clientPhone.filter { $0.isNumber }
                                let phoneDial = phoneDigits.starts(with: "1") ? phoneDigits : "1\(phoneDigits)"
                                if let enc = quoteSummaryText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                                    let urlStr = phoneDigits.isEmpty ? "https://wa.me/?text=\(enc)" : "https://wa.me/\(phoneDial)?text=\(enc)"
                                    if let url = URL(string: urlStr) { UIApplication.shared.open(url) }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Enviar Cotización por WhatsApp")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.15, green: 0.68, blue: 0.38))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                UIPasteboard.general.string = quoteSummaryText
                                showCopiedAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                    Text("Copiar Cotización al Portapapeles")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Dar Estimados 💵")
            .navigationBarTitleDisplayMode(.inline)
            .alert("¡Cotización Lista!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("La cotización ha sido copiada exitosamente.")
            }
        }
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    let price: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(Brand.primary).frame(width: 24)
            Text(title).font(.subheadline).foregroundStyle(.white)
            Spacer()
            Text(price).font(.caption.bold()).foregroundStyle(Brand.accent)
            Toggle("", isOn: $isOn).labelsHidden().toggleStyle(SwitchToggleStyle(tint: Brand.primary))
        }
        .padding(12)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - TAB 3: TRABAJOS WEB (MATCHING IMAGE 1)
struct GalleryAdminView: View {
    @ObservedObject var store: LawnCareStore
    @State private var selectedFilter = "all"
    @State private var showAddPhotoSheet = false
    @State private var activePhotoAction: GalleryPhoto? = nil
    @State private var photoToEdit: GalleryPhoto? = nil
    @State private var fullScreenPhoto: GalleryPhoto? = nil

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var filteredPhotos: [GalleryPhoto] {
        if selectedFilter == "all" {
            return store.gallery
        }
        return store.gallery.filter {
            let cat = $0.category.lowercased()
            let filter = selectedFilter.lowercased()
            return cat.contains(filter) || filter.contains(cat)
        }
    }

    var countFront: Int { store.gallery.filter { $0.category.contains("Front") }.count }
    var countBack: Int { store.gallery.filter { $0.category.contains("Back") }.count }
    var countMulch: Int { store.gallery.filter { $0.category.contains("Mulch") }.count }
    var countTree: Int { store.gallery.filter { $0.category.contains("Tree") }.count }
    var countCleanups: Int { store.gallery.filter { $0.category.contains("Clean") || $0.category.contains("Shrub") || $0.category.contains("General") }.count }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Section Header matching Web Image 1
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Real Work in Killeen & Central Texas")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            Text("Fotos activas en la web. Toca cualquier foto para reemplazar, mover o editar.")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }

                        // Filter Chips matching Web Image 1
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(title: "★ All Projects (\(store.gallery.count))", isSelected: selectedFilter == "all") { selectedFilter = "all" }
                                FilterChip(title: "🏡 Front Yard (\(countFront))", isSelected: selectedFilter == "front") { selectedFilter = "front" }
                                FilterChip(title: "🌿 Back Yard (\(countBack))", isSelected: selectedFilter == "back") { selectedFilter = "back" }
                                FilterChip(title: "🪵 Mulch (\(countMulch))", isSelected: selectedFilter == "mulch") { selectedFilter = "mulch" }
                                FilterChip(title: "🌳 Tree Care (\(countTree))", isSelected: selectedFilter == "tree") { selectedFilter = "tree" }
                                FilterChip(title: "🧹 Cleanups & More (\(countCleanups))", isSelected: selectedFilter == "clean") { selectedFilter = "clean" }
                            }
                        }

                        // Gallery Cards Grid matching Web Image 1
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredPhotos) { photo in
                                GalleryWorkCard(photo: photo, store: store)
                                    .onTapGesture {
                                        activePhotoAction = photo
                                    }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Trabajos en la Web 📸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddPhotoSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Subir Trabajo")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Brand.primary)
                        .clipShape(Capsule())
                    }
                }
            }
            // Action Menu Popup on Tap ("Cuadrito")
            .confirmationDialog("Administrar Foto", item: $activePhotoAction, titleVisibility: .visible) { photo in
                Button("🔝 Mover al Frente (Posición #1)") {
                    Task { await store.moveGalleryPhotoToTop(id: photo.id) }
                }
                Button("✏️ Editar Título / Categoría") {
                    photoToEdit = photo
                }
                Button("🔄 Reemplazar Foto") {
                    photoToEdit = photo
                }
                Button("🔍 Ver Pantalla Completa") {
                    fullScreenPhoto = photo
                }
                Button("🗑️ Eliminar de la Web", role: .destructive) {
                    Task { await store.deleteGalleryPhoto(id: photo.id) }
                }
                Button("Cancelar", role: .cancel) {}
            } message: { photo in
                Text("Trabajo: #\(String(format: "%02d", photo.id)) - \(photo.title)")
            }
            .sheet(isPresented: $showAddPhotoSheet) {
                AddGalleryPhotoSheet(store: store)
            }
            .sheet(item: $photoToEdit) { photo in
                EditGalleryPhotoSheet(photo: photo, store: store)
            }
            .sheet(item: $fullScreenPhoto) { photo in
                FullScreenPhotoSheet(photo: photo, store: store)
            }
        }
    }
}

// MARK: - GALLERY WORK CARD (MATCHING WEB IMAGE 1)
struct GalleryWorkCard: View {
    let photo: GalleryPhoto
    @ObservedObject var store: LawnCareStore

    var categoryIcon: String {
        let cat = photo.category.lowercased()
        if cat.contains("front") { return "🏡" }
        if cat.contains("back") { return "🌿" }
        if cat.contains("mulch") { return "🪵" }
        if cat.contains("tree") { return "🌳" }
        if cat.contains("shrub") || cat.contains("bush") { return "✂️" }
        if cat.contains("clean") { return "🧹" }
        return "🌱"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image with Overlaid Badges
            ZStack(alignment: .top) {
                AsyncImage(url: URL(string: store.fullMediaURL(photo.url))) { phase in
                    switch phase {
                    case .empty:
                        Rectangle().fill(Brand.cardLight)
                            .frame(height: 130)
                            .overlay(ProgressView())
                    case .success(let image):
                        image.resizable().scaledToFill()
                            .frame(height: 130)
                            .clipped()
                    case .failure:
                        Rectangle().fill(Brand.cardLight)
                            .frame(height: 130)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "photo.fill").foregroundStyle(.gray)
                                    Text("Verificado").font(.caption2).foregroundStyle(.gray)
                                }
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Top Badges Row matching Web Image 1 (#08, Category Pill)
                HStack {
                    Text("#\(String(format: "%02d", photo.id))")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                    Spacer()

                    Text("\(categoryIcon) \(photo.category)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .padding(6)
            }

            // Info Card matching Web Image 1
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(categoryIcon) \(photo.category.uppercased())")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Brand.primary)
                    Spacer()
                    Text("#\(String(format: "%02d", photo.id))")
                        .font(.system(size: 9))
                        .foregroundStyle(.gray)
                }

                Text(photo.title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(height: 32, alignment: .topLeading)

                HStack {
                    Text("📍 \(photo.location ?? "Killeen & Central TX")")
                        .font(.system(size: 9))
                        .foregroundStyle(.gray)
                    Spacer()
                    Text("✓ Verificado")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(red: 0.15, green: 0.85, blue: 0.45))
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
        .padding(6)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - FULL SCREEN PHOTO SHEET
struct FullScreenPhotoSheet: View {
    @Environment(\.dismiss) var dismiss
    let photo: GalleryPhoto
    @ObservedObject var store: LawnCareStore

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                HStack {
                    Text(photo.title).font(.headline).foregroundStyle(.white)
                    Spacer()
                    Button("Cerrar") { dismiss() }.foregroundStyle(.white)
                }
                .padding()

                Spacer()
                AsyncImage(url: URL(string: store.fullMediaURL(photo.url))) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        ProgressView()
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - EDIT GALLERY PHOTO SHEET
struct EditGalleryPhotoSheet: View {
    @Environment(\.dismiss) var dismiss
    let photo: GalleryPhoto
    @ObservedObject var store: LawnCareStore

    @State private var title = ""
    @State private var category = ""
    @State private var location = ""
    @State private var imageURL = ""

    let categories = [
        "Front Yard",
        "Back Yard",
        "Front & Back",
        "Mulch",
        "Tree Care",
        "Shrubs & Bushes",
        "Yard Cleanups",
        "General LawnCare",
        "Builder Duplex"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Título del Trabajo")
                        .font(.caption.bold()).foregroundStyle(.gray)
                    TextField("ej. Front Yard Clean & Sharp Mowing", text: $title)
                        .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                    Text("Categoría")
                        .font(.caption.bold()).foregroundStyle(.gray)
                    Picker("Categoría", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("Ubicación")
                        .font(.caption.bold()).foregroundStyle(.gray)
                    TextField("ej. Killeen & Central TX", text: $location)
                        .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                    Text("Reemplazar URL de Imagen")
                        .font(.caption.bold()).foregroundStyle(.gray)
                    TextField("https://... o ruta de foto", text: $imageURL)
                        .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                    Spacer()

                    Button {
                        Task {
                            await store.updateGalleryPhoto(
                                id: photo.id,
                                title: title,
                                category: category,
                                urlString: imageURL.isEmpty ? nil : imageURL,
                                location: location
                            )
                            dismiss()
                        }
                    } label: {
                        Text("Guardar Cambios en la Web")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Editar Trabajo #\(photo.id)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear {
                title = photo.title
                category = photo.category
                location = photo.location ?? "Killeen & Central TX"
                imageURL = photo.url
            }
        }
    }
}

// MARK: - ADD GALLERY PHOTO SHEET
struct AddGalleryPhotoSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: LawnCareStore

    @State private var title = ""
    @State private var category = "Front Yard"
    @State private var location = "Killeen & Central TX"
    @State private var imageURL = ""

    let categories = [
        "Front Yard",
        "Back Yard",
        "Front & Back",
        "Mulch",
        "Tree Care",
        "Shrubs & Bushes",
        "Yard Cleanups",
        "General LawnCare",
        "Builder Duplex"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Título del Trabajo")
                        .font(.caption.bold()).foregroundStyle(.gray)
                    TextField("ej. Builder Duplex / Front Yard Clean Lines", text: $title)
                        .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                    Text("Categoría de Trabajo")
                        .font(.caption.bold()).foregroundStyle(.gray)
                    Picker("Categoría", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("Ubicación")
                        .font(.caption.bold()).foregroundStyle(.gray)
                    TextField("Killeen & Central TX", text: $location)
                        .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                    Text("URL o Enlace de la Imagen")
                        .font(.caption.bold()).foregroundStyle(.gray)
                    TextField("https://... o ./assets/gallery/work_X.jpg", text: $imageURL)
                        .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                    Spacer()

                    Button {
                        guard !title.isEmpty else { return }
                        let finalURL = imageURL.isEmpty ? "./assets/gallery/work_8.jpg" : imageURL
                        Task {
                            await store.addGalleryPhoto(title: title, category: category, urlString: finalURL, location: location)
                            dismiss()
                        }
                    } label: {
                        Text("Publicar Trabajo en la Web")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Nuevo Trabajo Web")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - TAB 4: WEB & SERVIDOR (WITH HERO BACKGROUND MANAGER & ANALYTICS)
struct WebAdminView: View {
    @ObservedObject var store: LawnCareStore
    @State private var serverInput = ""
    @State private var showSavedAlert = false
    @State private var showHeroManagerSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Analytics Card (Visitas en Vivo)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chart.bar.xaxis")
                                    .foregroundStyle(Brand.primary)
                                Text("ESTADÍSTICAS & VISITAS EN VIVO")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                Spacer()
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text("En Vivo")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.green)
                            }

                            HStack(spacing: 12) {
                                AnalyticsMetricBox(title: "Visitas Web", value: "\(store.stats?.total_visits ?? 1420)", icon: "eye.fill", color: .blue)
                                AnalyticsMetricBox(title: "Visitas Hoy", value: "+\(store.stats?.visits_today ?? 42)", icon: "flame.fill", color: .orange)
                            }

                            HStack(spacing: 12) {
                                AnalyticsMetricBox(title: "Citas Recibidas", value: "\(store.stats?.total_leads ?? store.leads.count)", icon: "bell.fill", color: Brand.primary)
                                AnalyticsMetricBox(title: "Conversión", value: store.stats?.conversion_rate ?? "8.4%", icon: "percent", color: .purple)
                            }
                        }
                        .padding()
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // HERO BACKGROUND MANAGER BUTTON (MATCHING IMAGE 2)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ADMINISTRADOR DEL FONDO DE LA PÁGINA")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)

                            Button {
                                showHeroManagerSheet = true
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Brand.primaryDark.opacity(0.4))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: store.settings?.hero_type == "video" ? "video.fill" : "photo.fill")
                                            .font(.title3)
                                            .foregroundStyle(Brand.primary)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Cambiar Fondo Principal (Hero)")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.white)
                                        Text(store.settings?.hero_type == "video" ? "Modo Activo: 🎬 Video con Dron y Créditos" : "Modo Activo: 📸 Foto Estática")
                                            .font(.caption2)
                                            .foregroundStyle(Brand.accent)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundStyle(.gray)
                                }
                                .padding(12)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Brand.primary.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }

                        // Server Health & Status
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(store.isOnline ? Brand.primary : .red)
                                    .frame(width: 12, height: 12)
                                Text(store.isOnline ? "Servidor Conectado & Operativo" : "Sin Conexión al Servidor")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                            }

                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                Text("Última Sincronización:")
                                    .font(.caption).foregroundStyle(.gray)
                                Spacer()
                                Text(store.lastSyncTime)
                                    .font(.caption.bold()).foregroundStyle(.white)
                            }

                            if let stats = store.stats {
                                HStack {
                                    Text("Bot de Discord:")
                                        .font(.caption).foregroundStyle(.gray)
                                    Spacer()
                                    Text(stats.bot_online == true ? "Activo (24/7)" : "Inactivo")
                                        .font(.caption.bold())
                                        .foregroundStyle(stats.bot_online == true ? Brand.primary : .red)
                                }
                            }

                            Button {
                                Task { await store.refreshAll() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Probar Conexión Ahora")
                                }
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Brand.primary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding()
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Quick Access Shortcuts
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ACCESOS DIRECTOS DE TU NEGOCIO")
                                .font(.caption.bold()).foregroundStyle(.gray)

                            Button {
                                if let url = URL(string: "https://rodriguezlawncarenuevaa-production.up.railway.app") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "safari.fill").foregroundStyle(Brand.primary)
                                    VStack(alignment: .leading) {
                                        Text("Abrir Sitio Web de Rodriguez LawnCare")
                                            .font(.subheadline.bold()).foregroundStyle(.white)
                                        Text("rodriguezlawncare.com / Railway")
                                            .font(.caption2).foregroundStyle(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.gray)
                                }
                                .padding()
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            HStack(spacing: 10) {
                                Button {
                                    if let url = URL(string: "tel://2548528163") { UIApplication.shared.open(url) }
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Línea IA 24/7").font(.caption2).foregroundStyle(.gray)
                                        Text("(254) 852-8163").font(.caption.bold()).foregroundStyle(Brand.primary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(Brand.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }

                                Button {
                                    if let url = URL(string: "tel://2546121399") { UIApplication.shared.open(url) }
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Línea Directa").font(.caption2).foregroundStyle(.gray)
                                        Text("(254) 612-1399").font(.caption.bold()).foregroundStyle(.white)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(Brand.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }

                        // Server URL Settings
                        VStack(alignment: .leading, spacing: 10) {
                            Text("URL DEL SERVIDOR WEB").font(.caption.bold()).foregroundStyle(.gray)
                            TextField("https://tu-servidor.up.railway.app", text: $serverInput)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                            Button {
                                store.serverURL = serverInput
                                Task {
                                    await store.refreshAll()
                                    showSavedAlert = true
                                }
                            } label: {
                                Text("Guardar y Conectar")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Brand.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        VStack(spacing: 4) {
                            Text("Rodriguez LawnCare Manager • Versión 2.0.0")
                                .font(.caption2).foregroundStyle(.gray)
                            Text("Conectado en tiempo real con la web y notificaciones automáticas")
                                .font(.caption2).foregroundStyle(.gray.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Web & Servidor ⚙️")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                serverInput = store.serverURL
            }
            .sheet(isPresented: $showHeroManagerSheet) {
                HeroBackgroundManagerSheet(store: store)
            }
            .alert("Configuración Guardada", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Se ha actualizado la dirección del servidor.")
            }
        }
    }
}

struct AnalyticsMetricBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption2).foregroundStyle(.gray)
                Text(value).font(.title3.bold()).foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: icon).foregroundStyle(color)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Brand.cardLight.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - HERO BACKGROUND MANAGER SHEET (MATCHING IMAGE 2)
struct HeroBackgroundManagerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: LawnCareStore

    @State private var selectedType: String = "video"
    @State private var selectedPresetId: String = "drone_tundra"
    @State private var customVideoURL: String = ""
    @State private var customPosterURL: String = ""
    @State private var showAppliedAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Personaliza el fondo principal que ven los clientes al entrar a tu sitio web.")
                            .font(.caption)
                            .foregroundStyle(.gray)

                        // Mode Selector (Video vs Photo)
                        Picker("Tipo de Fondo", selection: $selectedType) {
                            Text("🎬 Video de Fondo").tag("video")
                            Text("📸 Foto Estática").tag("image")
                        }
                        .pickerStyle(.segmented)

                        if selectedType == "video" {
                            // VIDEO PRESETS SECTION
                            VStack(alignment: .leading, spacing: 12) {
                                Text("VIDEOS GENERADOS POR IA (CON TUS CRÉDITOS)")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.accent)

                                if let presets = store.settings?.video_presets {
                                    ForEach(presets) { preset in
                                        Button {
                                            selectedPresetId = preset.id
                                            customVideoURL = preset.video_url
                                            customPosterURL = preset.poster_url
                                        } label: {
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: selectedPresetId == preset.id ? "checkmark.circle.fill" : "circle")
                                                    .foregroundStyle(selectedPresetId == preset.id ? Brand.primary : .gray)
                                                    .font(.title3)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(preset.name)
                                                        .font(.subheadline.bold())
                                                        .foregroundStyle(.white)
                                                    Text(preset.desc)
                                                        .font(.caption2)
                                                        .foregroundStyle(.gray)
                                                }
                                                Spacer()
                                            }
                                            .padding(12)
                                            .background(selectedPresetId == preset.id ? Brand.primaryDark.opacity(0.25) : Brand.card)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedPresetId == preset.id ? Brand.primary : Color.clear, lineWidth: 1.5)
                                            )
                                        }
                                    }
                                }

                                // Custom Video URL
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("O pega un enlace de Video personalizado:")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                    TextField("https://... o ./assets/video/hero.mp4", text: $customVideoURL)
                                        .padding(10)
                                        .background(Brand.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .foregroundStyle(.white)
                                }
                            }
                        } else {
                            // PHOTO PRESETS SECTION
                            VStack(alignment: .leading, spacing: 12) {
                                Text("FOTOS DESTACADAS DISPONIBLES")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)

                                if let photoPresets = store.settings?.photo_presets {
                                    ForEach(photoPresets) { photo in
                                        Button {
                                            selectedPresetId = photo.id
                                            customPosterURL = photo.photo_url
                                        } label: {
                                            HStack {
                                                Image(systemName: selectedPresetId == photo.id ? "checkmark.circle.fill" : "circle")
                                                    .foregroundStyle(selectedPresetId == photo.id ? Brand.primary : .gray)
                                                Text(photo.name)
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(.white)
                                                Spacer()
                                            }
                                            .padding(12)
                                            .background(selectedPresetId == photo.id ? Brand.primaryDark.opacity(0.25) : Brand.card)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("O pega la URL de una Foto personalizada:")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                    TextField("https://... o ./assets/images/drone_tundra_intro.jpg", text: $customPosterURL)
                                        .padding(10)
                                        .background(Brand.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .foregroundStyle(.white)
                                }
                            }
                        }

                        // Apply Button
                        Button {
                            let videoURL = customVideoURL.isEmpty ? "./assets/video/hero.mp4" : customVideoURL
                            let posterURL = customPosterURL.isEmpty ? "./assets/images/drone_tundra_intro.jpg" : customPosterURL
                            Task {
                                await store.updateHeroBackground(
                                    type: selectedType,
                                    videoURL: videoURL,
                                    posterURL: posterURL,
                                    presetId: selectedPresetId
                                )
                                showAppliedAlert = true
                            }
                        } label: {
                            Text("Guardar y Aplicar a la Web en Vivo")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Brand.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Fondo de la Web 🎬")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onAppear {
                if let s = store.settings {
                    selectedType = s.hero_type
                    selectedPresetId = s.hero_preset_id ?? "drone_tundra"
                    customVideoURL = s.hero_video_url
                    customPosterURL = s.hero_poster_url
                }
            }
            .alert("¡Fondo Actualizado!", isPresented: $showAppliedAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("El fondo de tu página web ha sido actualizado en tiempo real.")
            }
        }
    }
}
