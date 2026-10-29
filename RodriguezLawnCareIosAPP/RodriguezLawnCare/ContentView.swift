import SwiftUI
import UserNotifications
import AVKit
import Combine
import WebKit

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

struct WebMusicConfig: Codable, Equatable {
    var enabled: Bool?
    var title: String?
    var genre: String?
    var stream_url: String?
    var volume: Double?
    var preset_id: String?
}

struct MusicPreset: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var genre: String
    var url: String
    var desc: String
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
    var music: WebMusicConfig?
    var music_presets: [MusicPreset]?
}

struct AppVersionInfo: Codable {
    var success: Bool?
    var app_name: String?
    var version: String?
    var build: Int?
    var min_version: String?
    var release_notes: String?
    var ipa_url: String?
    var ota_install_url: String?
    var trollstore_url: String?
    var esign_url: String?
    var gbox_url: String?
    var web_install_url: String?
    var has_update: Bool?
}

struct CloudRates: Codable {
    var small: Double?
    var medium: Double?
    var large: Double?
    var acre: Double?
    var overgrown_mult: Double?
    var weekly_discount: Double?
    var biweekly_discount: Double?
}

struct CloudAddons: Codable {
    var bushes: Double?
    var mulch: Double?
    var trees: Double?
    var cleanups: Double?
    var edging: Double?
}

struct CloudConfig: Codable {
    var app_name: String?
    var app_version: String?
    var app_build: Int?
    var rates: CloudRates?
    var addons: CloudAddons?
}

struct CloudConfigResponse: Codable {
    var success: Bool
    var config: CloudConfig
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

// MARK: - APP STORE (STATE MANAGEMENT & REAL-TIME CLOUD SYNC)
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

    // OTA In-App Updater & Cloud Config
    @Published var availableUpdate: AppVersionInfo? = nil
    @Published var showUpdateModal: Bool = false
    @Published var isCheckingUpdate: Bool = false
    @Published var updateCheckStatus: String = "Al día"
    @Published var cloudConfig: CloudConfig? = nil

    let currentAppVersion: String = "1.4.0"
    let currentAppBuild: Int = 14

    @AppStorage("api_server_url") var serverURL: String = "https://web-production-b6891b.up.railway.app"

    private var knownLeadIds: Set<Int> = []
    private var isFirstLoad: Bool = true
    private var cancellables = Set<AnyCancellable>()

    init() {
        if serverURL.contains("rodriguezlawncarenuevaa") || serverURL.isEmpty || !serverURL.contains("web-production-b6891b.up.railway.app") {
            serverURL = "https://web-production-b6891b.up.railway.app"
            UserDefaults.standard.set("https://web-production-b6891b.up.railway.app", forKey: "api_server_url")
        }
        loadDemoData()
        requestNotificationPermissions()
        startRealtimePolling()
        Task { @MainActor in
            await checkOTAUpdate(manual: false)
            await fetchCloudConfig()
        }
    }

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notification permission: \(granted)")
        }
    }

    func startRealtimePolling() {
        // Real-time auto sync every 6 seconds with Railway
        Timer.publish(every: 6, on: .main, in: .common)
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
        let bannerText = "🚨 ¡Nueva Cotización! \(lead.name) • \(lead.phone)"
        self.latestAlertMessage = bannerText
        self.showAlertBanner = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            self.showAlertBanner = false
        }

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
        // Clean initial leads state: 100% Real data loaded from Railway
        leads = []

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

    var cleanURL: String {
        var base = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.isEmpty || base.contains("rodriguezlawncarenuevaa") {
            base = "https://web-production-b6891b.up.railway.app"
        }
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
        await fetchCloudConfig()
        await checkOTAUpdate(manual: false)

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        lastSyncTime = formatter.string(from: Date())
    }

    @MainActor
    func checkOTAUpdate(manual: Bool = false) async {
        if manual { isCheckingUpdate = true }
        defer { if manual { isCheckingUpdate = false } }

        guard let url = URL(string: "\(cleanURL)/api/app/version") else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 6
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let info = try JSONDecoder().decode(AppVersionInfo.self, from: data)
                self.availableUpdate = info
                let serverBuild = info.build ?? 0
                if serverBuild > self.currentAppBuild {
                    self.showUpdateModal = true
                    self.updateCheckStatus = "¡Nueva versión \(info.version ?? "") disponible!"
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                } else {
                    self.updateCheckStatus = "Estás en la última versión (\(currentAppVersion))"
                    if manual {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            }
        } catch {
            if manual {
                self.updateCheckStatus = "No se pudo conectar con el servidor OTA"
            }
        }
    }

    @MainActor
    func fetchCloudConfig() async {
        guard let url = URL(string: "\(cleanURL)/api/cloud/config") else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 6
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(CloudConfigResponse.self, from: data)
                self.cloudConfig = decoded.config
            }
        } catch {
            // Keep existing
        }
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
            // Keep cache
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
            // Keep cache
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
            // Keep cache
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
            source: "App rodriguezlawncareios",
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
            "source": "App rodriguezlawncareios",
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
            print("Create lead server error: \(error)")
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
            print("Delete lead server error: \(error)")
        }
    }

    @MainActor
    func addGalleryPhoto(title: String, category: String, urlString: String? = nil, location: String = "Killeen & Central TX", imageBase64: String? = nil) async {
        let newId = (gallery.map { $0.id }.max() ?? 0) + 1
        let finalUrl = (urlString != nil && !urlString!.isEmpty) ? urlString! : "./assets/gallery/work_\(newId).jpg"
        let newPhoto = GalleryPhoto(
            id: newId,
            filename: "work_\(newId).jpg",
            url: finalUrl,
            title: title,
            category: category,
            location: location,
            verified: true,
            uploaded_at: Int(Date().timeIntervalSince1970 * 1000)
        )
        gallery.insert(newPhoto, at: 0)

        guard let url = URL(string: "\(cleanURL)/api/gallery") else { return }
        var payload: [String: Any] = [
            "title": title,
            "category": category,
            "url": finalUrl,
            "location": location
        ]
        if let b64 = imageBase64, !b64.isEmpty {
            payload["image_base64"] = b64
        }
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
            await fetchGallery()
        } catch {
            print("Add photo server error: \(error)")
        }
    }

    @MainActor
    func updateGalleryPhoto(id: Int, title: String, category: String, urlString: String? = nil, location: String? = nil, imageBase64: String? = nil) async {
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
        if let b64 = imageBase64, !b64.isEmpty { payload["image_base64"] = b64 }

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
            await fetchGallery()
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

    @MainActor
    func updateWebMusic(enabled: Bool, title: String, genre: String, streamURL: String, volume: Double, presetId: String) async {
        if settings == nil {
            settings = WebSettings(
                hero_type: "video",
                hero_video_url: "./assets/video/hero.mp4",
                hero_poster_url: "./assets/images/drone_tundra_intro.jpg",
                music: WebMusicConfig(enabled: enabled, title: title, genre: genre, stream_url: streamURL, volume: volume, preset_id: presetId)
            )
        } else {
            if settings?.music == nil {
                settings?.music = WebMusicConfig()
            }
            settings?.music?.enabled = enabled
            settings?.music?.title = title
            settings?.music?.genre = genre
            settings?.music?.stream_url = streamURL
            settings?.music?.volume = volume
            settings?.music?.preset_id = presetId
        }

        guard let url = URL(string: "\(cleanURL)/api/settings/music") else { return }
        let payload: [String: Any] = [
            "enabled": enabled,
            "title": title,
            "genre": genre,
            "stream_url": streamURL,
            "volume": volume,
            "preset_id": presetId
        ]
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
        } catch {
            print("Save music settings error: \(error)")
        }
    }

    static let defaultVideoPresets: [VideoPreset] = [
        VideoPreset(id: "drone_tundra", name: "🚁 Drone Aéreo Tundra & Remolque (Con Créditos)", video_url: "./assets/video/hero.mp4", poster_url: "./assets/images/drone_tundra_intro.jpg", desc: "Vista de dron 4K, camioneta Toyota Tundra negra, remolque rotulado, créditos de Rafael Rodriguez y transición Antes/Después."),
        VideoPreset(id: "mower_stripes", name: "🚜 Corte Comercial con Líneas y Orillado", video_url: "./assets/video/hero.mp4", poster_url: "./assets/images/mowing.jpg", desc: "Corte de césped con podadora zero-turn comercial y orillado profundo en concreto."),
        VideoPreset(id: "luxury_estate", name: "🏡 Residencia de Lujo & Mulch Premium", video_url: "./assets/video/hero.mp4", poster_url: "./assets/images/drone_intro.jpg", desc: "Panorámica de propiedad residencial en Central Texas con jardineras de mulch oscuro."),
        VideoPreset(id: "tree_cutting", name: "🌲 Poda & Corte de Árboles con Motosierra", video_url: "./assets/video/hero.mp4", poster_url: "./assets/images/trimming.jpg", desc: "Poda profesional de árboles altos, motosierras en acción, corte de ramas peligrosas y remoción de troncos."),
        VideoPreset(id: "razor_edging", name: "📐 Orillado con Navaja en Concreto", video_url: "./assets/video/hero.mp4", poster_url: "./assets/gallery/work_7.jpg", desc: "Líneas de orillado perfectas y definidas al milímetro en banquetas, orillas y entradas de vehículos."),
        VideoPreset(id: "dark_mulch", name: "🪵 Instalación de Mulch Chocolate & Jardineras", video_url: "./assets/video/hero.mp4", poster_url: "./assets/images/mulch.jpg", desc: "Transformación estética de jardines residenciales con acolchado oscuro de corteza de pino y recorte de arbustos."),
        VideoPreset(id: "yard_cleanup", name: "🧹 Limpieza Profunda & Soplado Comercial de Hojas", video_url: "./assets/video/hero.mp4", poster_url: "./assets/images/after.jpg", desc: "Retiro intensivo de hojas secas, ramas y escombros con sopladoras comerciales a gasolina y acabado impecable."),
        VideoPreset(id: "duplex_commercial", name: "🏢 Mantenimiento a Complejos Duplex & Contratistas", video_url: "./assets/video/hero.mp4", poster_url: "./assets/gallery/work_8.jpg", desc: "Servicio de mantenimiento integral para constructoras, duplex y propiedades multifamiliares en Killeen.")
    ]

    static let defaultMusicPresets: [MusicPreset] = [
        MusicPreset(id: "texas_guitar", name: "🎸 Texas Acoustic & Guitarra Campestre", genre: "Acoustic Chill", url: "https://cdn.pixabay.com/download/audio/2022/01/18/audio_d0a13f69d2.mp3?filename=acoustic-guitars-ambient-10874.mp3", desc: "Acordes suaves de guitarra acústica y vibra texana para ambientar la página con clase."),
        MusicPreset(id: "lofi_garden", name: "☕ Lofi Beats & Jardinería Relajante", genre: "Lofi Hip-Hop", url: "https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=lofi-study-112191.mp3", desc: "Ritmo lofi relajante con beats modernos y frescos, ideal para navegar cotizaciones."),
        MusicPreset(id: "upbeat_work", name: "⚡ Ritmo Dinámico & Trabajo Activo", genre: "Modern Upbeat", url: "https://cdn.pixabay.com/download/audio/2022/03/15/audio_c8c8a73467.mp3?filename=energetic-indie-rock-110077.mp3", desc: "Música motivadora y alegre con energía positiva para trabajos de landscaping."),
        MusicPreset(id: "regional_chill", name: "🎺 Regional Acordeón & Vibra Latina Suave", genre: "Regional Chill", url: "https://cdn.pixabay.com/download/audio/2022/10/14/audio_9939f77cb5.mp3?filename=latin-acoustic-122971.mp3", desc: "Toque acústico latino alegre y limpio que combina con la esencia de Rodriguez LawnCare."),
        MusicPreset(id: "luxury_piano", name: "🎹 Piano Elegante & Residencia de Lujo", genre: "Ambient Piano", url: "https://cdn.pixabay.com/download/audio/2021/08/04/audio_12b0c7443c.mp3?filename=inspiring-cinematic-ambient-116199.mp3", desc: "Melodía sofisticada y elegante que resalta propiedades residenciales de alta gama.")
    ]
}

// MARK: - MAIN ROOT VIEW WITH LIVE NOTIFICATION BANNER & 5 TABS
struct ContentView: View {
    @StateObject private var store = LawnCareStore()
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase

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

                WebMusicControlView(store: store)
                    .tabItem {
                        Label("Música Web", systemImage: "music.note.list")
                    }
                    .tag(3)

                WebAdminView(store: store)
                    .tabItem {
                        Label("OTA & Ajustes", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .accentColor(Brand.primary)

            // HEADS-UP NOTIFICATION BANNER
            if store.showAlertBanner, let msg = store.latestAlertMessage {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title3)
                            .foregroundStyle(Brand.accent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("¡NUEVA COTIZACIÓN EN VIVO!")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            Text(msg)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button {
                            store.showAlertBanner = false
                            selectedTab = 0
                        } label: {
                            Text("Ver")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Brand.primary)
                                .foregroundStyle(.black)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Brand.cardLight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Brand.primary, lineWidth: 1.5)
                    )
                    .shadow(color: Brand.primary.opacity(0.3), radius: 10, y: 4)
                    .padding(.horizontal, 12)
                    .padding(.top, 48)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                .zIndex(100)
            }
        }
        .sheet(isPresented: $store.showUpdateModal) {
            OTAUpdateSheetView(store: store)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task {
                    await store.refreshAll(silent: true)
                    await store.checkOTAUpdate(manual: false)
                }
            }
        }
    }
}

// MARK: - TAB 1: APPOINTMENTS & REAL-TIME LEADS VIEW
struct AppointmentsView: View {
    @ObservedObject var store: LawnCareStore
    @State private var filterStatus = "all"
    @State private var showNewLeadSheet = false
    @State private var selectedLead: Lead? = nil

    var filteredLeads: [Lead] {
        if filterStatus == "all" {
            return store.leads
        }
        return store.leads.filter { $0.status == filterStatus }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Ribbon with Live Stats
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RODRIGUEZ LAWNCARE")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            Text("Citas & Cotizaciones")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(store.isOnline ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(store.isOnline ? "Online" : "Offline")
                                    .font(.caption2.bold())
                                    .foregroundStyle(store.isOnline ? .green : .red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Brand.card)
                            .clipShape(Capsule())

                            Button {
                                Task { await store.refreshAll() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Brand.card)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    // Filter Segmented Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "Todos (\(store.leads.count))", isSelected: filterStatus == "all") { filterStatus = "all" }
                            FilterChip(title: "Pendientes (\(store.leads.filter { $0.status == "pending" }.count))", isSelected: filterStatus == "pending", highlight: true) { filterStatus = "pending" }
                            FilterChip(title: "Contactados", isSelected: filterStatus == "contacted") { filterStatus = "contacted" }
                            FilterChip(title: "Confirmados", isSelected: filterStatus == "confirmed") { filterStatus = "confirmed" }
                            FilterChip(title: "Completados", isSelected: filterStatus == "completed") { filterStatus = "completed" }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }

                    // Leads List
                    if filteredLeads.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "tray.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.gray.opacity(0.5))
                            Text("No hay citas registradas en este estado.")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(filteredLeads) { lead in
                                LeadCardView(lead: lead)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .onTapGesture {
                                        selectedLead = lead
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
            .navigationBarHidden(true)
            .sheet(item: $selectedLead) { lead in
                LeadDetailSheet(lead: lead, store: store)
            }
            .sheet(isPresented: $showNewLeadSheet) {
                NewLeadSheet(store: store)
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showNewLeadSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Nueva Cita")
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Brand.primary)
                            .clipShape(Capsule())
                            .shadow(color: Brand.primary.opacity(0.4), radius: 8, y: 4)
                        }
                        .padding()
                    }
                }
            )
        }
    }
}

// MARK: - FILTER CHIP
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var highlight: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? (highlight ? Brand.accent : Brand.primary) : Brand.card)
                .foregroundStyle(isSelected ? .black : .white)
                .clipShape(Capsule())
        }
    }
}

// MARK: - LEAD CARD VIEW (WITH WHATSAPP PRE-FILL & STATUS)
struct LeadCardView: View {
    let lead: Lead

    var statusColor: Color {
        switch lead.status {
        case "pending": return Brand.accent
        case "contacted": return .blue
        case "confirmed": return Brand.primary
        case "completed": return .gray
        case "cancelled": return .red
        default: return Brand.accent
        }
    }

    var statusLabel: String {
        switch lead.status {
        case "pending": return "PENDIENTE"
        case "contacted": return "CONTACTADO"
        case "confirmed": return "CONFIRMADO"
        case "completed": return "COMPLETADO"
        case "cancelled": return "CANCELADO"
        default: return "PENDIENTE"
        }
    }

    var cleanPhoneForWhatsApp: String {
        let digits = lead.phone.filter { "0123456789".contains($0) }
        if digits.count == 10 {
            return "1" + digits
        }
        return digits
    }

    var prefilledWhatsAppMessage: String {
        let name = lead.name.components(separatedBy: " ").first ?? lead.name
        let svcs = lead.services?.joined(separator: ", ") ?? "Corte de Césped"
        let text = "¡Hola \(name)! Te saludo de Rodriguez LawnCare sobre tu solicitud para \(svcs). ¿Sigues disponible para confirmar la visita?"
        return text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row: Name & Status Pill
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lead.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let src = lead.source {
                        Text(src)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()

                Text(statusLabel)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.18))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(statusColor.opacity(0.4), lineWidth: 1)
                    )
            }

            // Address & Date
            VStack(alignment: .leading, spacing: 4) {
                if let addr = lead.address, !addr.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(Brand.primary)
                        Text(addr)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

                HStack(spacing: 12) {
                    if let d = lead.date {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            Text("\(d) \(lead.time ?? "")")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }

                    if let freq = lead.frequency {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.caption2)
                                .foregroundStyle(Brand.accent)
                            Text(freq)
                                .font(.caption)
                                .foregroundStyle(Brand.accent)
                        }
                    }
                }
            }

            // Services chips
            if let services = lead.services, !services.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(services, id: \.self) { svc in
                            Text(svc)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Brand.cardLight)
                                .foregroundStyle(.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }

            // Action Buttons: WhatsApp & Phone Call
            HStack(spacing: 10) {
                // WhatsApp Button
                Button {
                    let waURLString = "https://wa.me/\(cleanPhoneForWhatsApp)?text=\(prefilledWhatsAppMessage)"
                    if let url = URL(string: waURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 6) {
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

                // Call Phone Button
                Button {
                    let clean = lead.phone.filter { "0123456789".contains($0) }
                    if let url = URL(string: "tel://\(clean)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text("Llamar")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Brand.cardLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Apple Maps Button
                if let addr = lead.address, !addr.isEmpty {
                    Button {
                        let query = addr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "map.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Brand.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Brand.cardLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(lead.status == "pending" ? Brand.accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - LEAD DETAIL SHEET
struct LeadDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let lead: Lead
    @ObservedObject var store: LawnCareStore

    @State private var selectedStatus: String = "pending"
    @State private var amountText: String = ""
    @State private var notesText: String = ""

    let statuses = [
        ("pending", "Pendiente"),
        ("contacted", "Contactado"),
        ("confirmed", "Confirmado"),
        ("completed", "Completado"),
        ("cancelled", "Cancelado")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 4) {
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

                            TextField("Dirección (ej. 4201 Trimmier Rd)", text: $address)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }

                        Group {
                            Text("SERVICIOS SOLICITADOS").font(.caption.bold()).foregroundStyle(.gray)
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
                                        Text(svc).foregroundStyle(.white)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(Brand.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }

                        Group {
                            Text("FECHA Y HORA").font(.caption.bold()).foregroundStyle(.gray)
                            HStack(spacing: 10) {
                                TextField("Fecha (ej. Mañana)", text: $date)
                                    .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                                TextField("Hora (ej. 9:00 AM)", text: $time)
                                    .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                            }
                        }

                        Button {
                            guard !name.isEmpty, !phone.isEmpty else { return }
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
                            Text("Crear y Guardar Cita")
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
            .navigationTitle("Nueva Cita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - TAB 2: ESTIMATOR CALCULATOR (POWERED BY REAL-TIME CLOUD RATES)
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
        if let rates = store.cloudConfig?.rates {
            switch lawnSize {
            case "small": return rates.small ?? 45.0
            case "medium": return rates.medium ?? 65.0
            case "large": return rates.large ?? 95.0
            case "acreage": return rates.acre ?? 160.0
            default: return rates.medium ?? 65.0
            }
        }
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
        let bushUnit = store.cloudConfig?.addons?.bushes ?? 10.0
        let mulchUnit = store.cloudConfig?.addons?.mulch ?? 85.0
        let treeUnit = store.cloudConfig?.addons?.trees ?? 90.0
        let cleanUnit = store.cloudConfig?.addons?.cleanups ?? 75.0
        let edgeUnit = store.cloudConfig?.addons?.edging ?? 35.0

        if includeBushes { total += Double(bushCount) * bushUnit }
        if includeMulch { total += Double(mulchYards) * mulchUnit }
        if includeTrees { total += treeUnit }
        if includeCleanup { total += cleanUnit }
        if includeEdgingDethatch { total += edgeUnit }
        return total
    }

    var frequencyDiscountPercent: Double {
        switch frequency {
        case "weekly": return store.cloudConfig?.rates?.weekly_discount ?? 0.10
        case "biweekly": return store.cloudConfig?.rates?.biweekly_discount ?? 0.05
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
                        // Total Estimate Card
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

                        // Client quick info
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CLIENTE").font(.caption.bold()).foregroundStyle(.gray)
                            HStack(spacing: 10) {
                                TextField("Nombre del cliente", text: $clientName)
                                    .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                                TextField("Teléfono", text: $clientPhone)
                                    .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                            }
                        }

                        // Lawn Size
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TAMAÑO DEL JARDÍN").font(.caption.bold()).foregroundStyle(.gray)
                            Picker("Tamaño", selection: $lawnSize) {
                                Text("< 5,000 sq ft").tag("small")
                                Text("5k - 10k sq ft").tag("medium")
                                Text("10k - 15k sq ft").tag("large")
                                Text("Acre+").tag("acreage")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Grass Height
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ALTURA DEL CÉSPED").font(.caption.bold()).foregroundStyle(.gray)
                            Picker("Altura", selection: $grassHeight) {
                                Text("Normal (0)").tag("normal")
                                Text("Alto (+ $25)").tag("tall")
                                Text("Muy Crecido (+ $55)").tag("overgrown")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Frequency
                        VStack(alignment: .leading, spacing: 10) {
                            Text("FRECUENCIA DE SERVICIO").font(.caption.bold()).foregroundStyle(.gray)
                            Picker("Frecuencia", selection: $frequency) {
                                Text("Puntual").tag("onetime")
                                Text("Quincenal (-5%)").tag("biweekly")
                                Text("Semanal (-10%)").tag("weekly")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Add-ons
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SERVICIOS ADICIONALES").font(.caption.bold()).foregroundStyle(.gray)

                            Toggle("Poda de Arbustos & Setos (+$10 c/u)", isOn: $includeBushes)
                                .tint(Brand.primary)
                                .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8))

                            if includeBushes {
                                Stepper("Cantidad de arbustos: \(bushCount)", value: $bushCount, in: 1...30)
                                    .padding(10).background(Brand.cardLight).clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            Toggle("Instalación de Mulch (+$85 por yarda)", isOn: $includeMulch)
                                .tint(Brand.primary)
                                .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8))

                            Toggle("Poda y Descope de Árboles (+$90)", isOn: $includeTrees)
                                .tint(Brand.primary)
                                .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8))

                            Toggle("Limpieza y Retiro de Hojas/Escombros (+$75)", isOn: $includeCleanup)
                                .tint(Brand.primary)
                                .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8))

                            Toggle("Desorillado con Navaja / Banquetas (+$35)", isOn: $includeEdgingDethatch)
                                .tint(Brand.primary)
                                .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        // Share Buttons
                        VStack(spacing: 10) {
                            Button {
                                let clean = clientPhone.filter { "0123456789".contains($0) }
                                let waPhone = clean.count == 10 ? "1" + clean : clean
                                let encoded = quoteSummaryText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                let waURL = waPhone.isEmpty ? "https://wa.me/?text=\(encoded)" : "https://wa.me/\(waPhone)?text=\(encoded)"
                                if let url = URL(string: waURL) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Enviar Estimado por WhatsApp")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.15, green: 0.68, blue: 0.38))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            HStack(spacing: 10) {
                                Button {
                                    UIPasteboard.general.string = quoteSummaryText
                                    showCopiedAlert = true
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copiar Cotización")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Brand.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                Button {
                                    Task {
                                        let leadName = clientName.isEmpty ? "Cliente Cotización" : clientName
                                        await store.createLead(
                                            name: leadName,
                                            phone: clientPhone,
                                            services: ["Corte de Césped (\(lawnSizeName))"],
                                            address: "",
                                            date: "Estimado",
                                            time: "",
                                            frequency: frequency,
                                            description: quoteSummaryText,
                                            amount: totalEstimate,
                                            notes: "Generado desde Calculadora"
                                        )
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Guardar Cita")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Brand.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Dar Estimados 💵")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Cotización Copiada", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("El resumen formal ha sido copiado al portapapeles listo para pegar.")
            }
        }
    }
}

// MARK: - TAB 3: GALLERY ADMIN VIEW (MATCHING IMAGE 1 PORTFOLIO & POPUP)
struct GalleryAdminView: View {
    @ObservedObject var store: LawnCareStore
    @State private var selectedFilter = "all"
    @State private var showAddPhotoSheet = false

    // Action dialog state
    @State private var selectedPhotoForAction: GalleryPhoto? = nil
    @State private var showPhotoActionDialog = false
    @State private var showEditPhotoSheet = false
    @State private var showFullscreenImage = false

    var filteredPhotos: [GalleryPhoto] {
        if selectedFilter == "all" {
            return store.gallery
        }
        return store.gallery.filter {
            $0.category.lowercased().contains(selectedFilter.lowercased())
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Title & Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PORTAFOLIO OFICIAL")
                            .font(.caption.bold())
                            .foregroundStyle(Brand.primary)
                        Text("Real Work in Killeen & Central Texas")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("Toca cualquier foto para reemplazarla, editar detalles, moverla o eliminarla.")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // Categories Filter Bar (Matching Image 1)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            GalleryFilterPill(title: "★ All Projects \(store.gallery.count)", isSelected: selectedFilter == "all") { selectedFilter = "all" }
                            GalleryFilterPill(title: "🏡 Front Yard \(store.gallery.filter { $0.category.lowercased().contains("front") }.count)", isSelected: selectedFilter == "front") { selectedFilter = "front" }
                            GalleryFilterPill(title: "🌿 Back Yard \(store.gallery.filter { $0.category.lowercased().contains("back") }.count)", isSelected: selectedFilter == "back") { selectedFilter = "back" }
                            GalleryFilterPill(title: "🪵 Mulch \(store.gallery.filter { $0.category.lowercased().contains("mulch") }.count)", isSelected: selectedFilter == "mulch") { selectedFilter = "mulch" }
                            GalleryFilterPill(title: "🌳 Tree Care", isSelected: selectedFilter == "tree") { selectedFilter = "tree" }
                            GalleryFilterPill(title: "✂️ Cleanups & More", isSelected: selectedFilter == "clean") { selectedFilter = "clean" }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }

                    // 2-Column Grid matching website layout
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
                            ForEach(filteredPhotos) { photo in
                                GalleryWorkCard(photo: photo, store: store)
                                    .onTapGesture {
                                        selectedPhotoForAction = photo
                                        showPhotoActionDialog = true
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                    }
                    .refreshable {
                        await store.refreshAll()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddPhotoSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Subir")
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
            .confirmationDialog(
                "Opciones del Trabajo",
                isPresented: $showPhotoActionDialog,
                titleVisibility: .visible
            ) {
                if let photo = selectedPhotoForAction {
                    Button("🔄 Reemplazar Foto de la Web") {
                        showEditPhotoSheet = true
                    }
                    Button("✏️ Editar Título, Categoría o Ubicación") {
                        showEditPhotoSheet = true
                    }
                    Button("🔝 Mover al Inicio (#1 Destacado)") {
                        Task { await store.moveGalleryPhotoToTop(id: photo.id) }
                    }
                    Button("🔍 Ver en Pantalla Completa") {
                        showFullscreenImage = true
                    }
                    Button("🗑️ Eliminar Trabajo de la Web", role: .destructive) {
                        Task { await store.deleteGalleryPhoto(id: photo.id) }
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                if let photo = selectedPhotoForAction {
                    Text("#\(String(format: "%02d", photo.id)) • \(photo.title) (\(photo.category))")
                }
            }
            .sheet(isPresented: $showAddPhotoSheet) {
                AddGalleryPhotoSheet(store: store)
            }
            .sheet(isPresented: $showEditPhotoSheet) {
                if let photo = selectedPhotoForAction {
                    EditGalleryPhotoSheet(photo: photo, store: store)
                }
            }
            .fullScreenCover(isPresented: $showFullscreenImage) {
                if let photo = selectedPhotoForAction {
                    FullscreenPhotoView(photo: photo, store: store)
                }
            }
        }
    }
}

// MARK: - GALLERY WORK CARD (MATCHING IMAGE 1 DESIGN)
struct GalleryWorkCard: View {
    let photo: GalleryPhoto
    @ObservedObject var store: LawnCareStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo Container with Overlays
            ZStack(alignment: .top) {
                // Async / Cached Image
                AsyncImage(url: URL(string: store.fullMediaURL(photo.url))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 125)
                            .clipped()
                    case .failure:
                        ZStack {
                            Color(red: 0.15, green: 0.20, blue: 0.28)
                            VStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundStyle(.gray)
                                Text("Foto #\(photo.id)")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .frame(height: 125)
                    default:
                        ZStack {
                            Brand.cardLight
                            ProgressView().tint(Brand.primary)
                        }
                        .frame(height: 125)
                    }
                }

                // Top Ribbon: #08 Badge & Category Pill
                HStack {
                    Text("#\(String(format: "%02d", photo.id))")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Spacer()

                    HStack(spacing: 3) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 8))
                        Text(photo.category)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Capsule())
                }
                .padding(6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Info Card Bottom
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(photo.category.uppercased())
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Brand.primary)
                    Spacer()
                    Text("#\(String(format: "%02d", photo.id))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.gray)
                }

                Text(photo.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "mappin")
                            .font(.system(size: 8))
                            .foregroundStyle(.red)
                        Text(photo.location ?? "Killeen & Central TX")
                            .font(.system(size: 9))
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Brand.primary)
                        Text("Verificado")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Brand.primary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Brand.primary.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            .padding(8)
        }
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - GALLERY FILTER PILL
struct GalleryFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Brand.primaryDark : Brand.card)
                .foregroundStyle(isSelected ? Brand.primary : .gray)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Brand.primary : Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

// MARK: - FULLSCREEN PHOTO VIEW
struct FullscreenPhotoView: View {
    @Environment(\.dismiss) var dismiss
    let photo: GalleryPhoto
    @ObservedObject var store: LawnCareStore

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()
                }

                Spacer()

                AsyncImage(url: URL(string: store.fullMediaURL(photo.url))) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        ProgressView().tint(.white)
                    }
                }

                Spacer()

                VStack(spacing: 6) {
                    Text(photo.title)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text("\(photo.category) • #\(photo.id) • \(photo.location ?? "Killeen & Central TX")")
                        .font(.caption)
                        .foregroundStyle(Brand.primary)
                }
                .padding(.bottom, 24)
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
    @State private var category = "Front Yard"
    @State private var location = ""
    @State private var imageURL = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showPhotoPicker = false
    @State private var isSaving = false

    let categories = [
        "Front Yard",
        "Back Yard",
        "Front & Back",
        "Mulch",
        "Tree Care",
        "Shrubs & Bushes",
        "Cleanups & More",
        "Mowing & Edging",
        "General LawnCare",
        "Builder Duplex",
        "Commercial Grounds"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Image Replacement / Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FOTO DEL TRABAJO")
                                .font(.caption.bold()).foregroundStyle(.gray)

                            if let img = selectedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                AsyncImage(url: URL(string: store.fullMediaURL(photo.url))) { phase in
                                    if let img = phase.image {
                                        img.resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 180)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        ZStack {
                                            Brand.cardLight
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundStyle(.gray)
                                        }
                                        .frame(height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }

                            Button {
                                showPhotoPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                                    Text(selectedImage == nil ? "📷 Reemplazar Foto desde iPhone" : "Cambiar Foto Seleccionada")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Brand.cardLight)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Brand.primary.opacity(0.6), lineWidth: 1)
                                )
                            }
                        }

                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Título del Trabajo")
                                .font(.caption.bold()).foregroundStyle(.gray)
                            TextField("Título", text: $title)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Categoría")
                                .font(.caption.bold()).foregroundStyle(.gray)
                            Picker("Categoría", selection: $category) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Location
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ubicación")
                                .font(.caption.bold()).foregroundStyle(.gray)
                            TextField("Ubicación", text: $location)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }

                        // URL (Optional)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("URL de la Imagen (Opcional)")
                                .font(.caption.bold()).foregroundStyle(.gray)
                            TextField("URL de la Imagen", text: $imageURL)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }

                        Spacer().frame(height: 10)

                        Button {
                            isSaving = true
                            var base64String: String? = nil
                            if let img = selectedImage, let data = img.jpegData(compressionQuality: 0.8) {
                                base64String = data.base64EncodedString()
                            }
                            Task {
                                await store.updateGalleryPhoto(
                                    id: photo.id,
                                    title: title,
                                    category: category,
                                    urlString: imageURL,
                                    location: location,
                                    imageBase64: base64String
                                )
                                isSaving = false
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.black).padding(.trailing, 4)
                                }
                                Text(isSaving ? "Guardando en la Web..." : "Guardar Cambios en la Web")
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isSaving)
                    }
                    .padding()
                }
            }
            .navigationTitle("Editar Trabajo #\(photo.id)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoLibraryPicker(selectedImage: $selectedImage)
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

// MARK: - PHOTO LIBRARY PICKER (UIKIT BRIDGE)
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - ADD GALLERY PHOTO SHEET
struct AddGalleryPhotoSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: LawnCareStore

    @State private var title = ""
    @State private var category = "Front Yard"
    @State private var location = "Killeen & Central TX"
    @State private var imageURL = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showPhotoPicker = false
    @State private var isUploading = false

    let categories = [
        "Front Yard",
        "Back Yard",
        "Front & Back",
        "Mulch",
        "Tree Care",
        "Shrubs & Bushes",
        "Cleanups & More",
        "Mowing & Edging",
        "General LawnCare",
        "Builder Duplex",
        "Commercial Grounds"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Photo Picker Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FOTO DEL TRABAJO")
                                .font(.caption.bold()).foregroundStyle(.gray)

                            if let img = selectedImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    Button {
                                        selectedImage = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white, .red)
                                            .padding(8)
                                    }
                                }
                            }

                            Button {
                                showPhotoPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text(selectedImage == nil ? "📷 Elegir Foto de la Galería del iPhone" : "Cambiar Foto Seleccionada")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Brand.cardLight)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Brand.primary.opacity(0.6), lineWidth: 1)
                                )
                            }
                        }

                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TÍTULO DEL TRABAJO")
                                .font(.caption.bold()).foregroundStyle(.gray)
                            TextField("ej. Builder Duplex / Front Yard Clean Lines", text: $title)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CATEGORÍA DE TRABAJO")
                                .font(.caption.bold()).foregroundStyle(.gray)
                            Picker("Categoría", selection: $category) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Location
                        VStack(alignment: .leading, spacing: 6) {
                            Text("UBICACIÓN")
                                .font(.caption.bold()).foregroundStyle(.gray)
                            TextField("Killeen & Central TX", text: $location)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }

                        // URL (Optional)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("URL O ENLACE (OPCIONAL SI ELIGES FOTO DE LA GALERÍA)")
                                .font(.caption.bold()).foregroundStyle(.gray)
                            TextField("./assets/gallery/work_X.jpg o enlace web", text: $imageURL)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }

                        Spacer().frame(height: 10)

                        Button {
                            guard !title.isEmpty else { return }
                            isUploading = true
                            var base64String: String? = nil
                            if let img = selectedImage, let data = img.jpegData(compressionQuality: 0.8) {
                                base64String = data.base64EncodedString()
                            }
                            let finalURL = imageURL.isEmpty ? "./assets/gallery/work_8.jpg" : imageURL
                            Task {
                                await store.addGalleryPhoto(
                                    title: title,
                                    category: category,
                                    urlString: finalURL,
                                    location: location,
                                    imageBase64: base64String
                                )
                                isUploading = false
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                if isUploading {
                                    ProgressView().tint(.black).padding(.trailing, 4)
                                }
                                Text(isUploading ? "Publicando en la Web..." : "Publicar Trabajo en la Web")
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(title.isEmpty ? Color.gray : Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(title.isEmpty || isUploading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Nuevo Trabajo Web")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoLibraryPicker(selectedImage: $selectedImage)
            }
        }
    }
}

// MARK: - TAB 4: CLOUD LIVE ADMIN VIEW (EMBEDDED LIVE DASHBOARD)
struct CloudLiveAdminView: View {
    @ObservedObject var store: LawnCareStore
    @State private var reloadTrigger = false

    var adminURL: URL {
        URL(string: "\(store.cleanURL)/admin") ?? URL(string: "https://web-production-b6891b.up.railway.app/admin")!
    }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    CloudAdminWebView(url: adminURL, reloadTrigger: $reloadTrigger)
                        .background(Brand.background)
                }
            }
            .navigationTitle("Panel Cloud 24/7 🌐")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Circle().fill(store.isOnline ? Color.green : Color.red).frame(width: 8, height: 8)
                        Text(store.isOnline ? "Online" : "Offline")
                            .font(.caption2.bold())
                            .foregroundStyle(store.isOnline ? .green : .red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            reloadTrigger = true
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(Brand.primary)
                        }

                        Button {
                            UIApplication.shared.open(adminURL)
                        } label: {
                            Image(systemName: "safari")
                                .foregroundStyle(Brand.primary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - WKWEBVIEW REPRESENTABLE FOR LIVE EMBEDDED CONTROL PANEL
struct CloudAdminWebView: UIViewRepresentable {
    let url: URL
    @Binding var reloadTrigger: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 1.0)
        webView.scrollView.backgroundColor = UIColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 1.0)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(red: 0.13, green: 0.77, blue: 0.36, alpha: 1.0)
        webView.scrollView.addSubview(refreshControl)
        context.coordinator.refreshControl = refreshControl
        context.coordinator.webView = webView

        let req = URLRequest(url: url)
        webView.load(req)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if reloadTrigger {
            uiView.reload()
            DispatchQueue.main.async {
                reloadTrigger = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: CloudAdminWebView
        weak var webView: WKWebView?
        weak var refreshControl: UIRefreshControl?

        init(_ parent: CloudAdminWebView) {
            self.parent = parent
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            webView?.reload()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            refreshControl?.endRefreshing()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            refreshControl?.endRefreshing()
        }
    }
}

// MARK: - TAB 5: WEB, SERVIDOR & CENTRO DE ACTUALIZACIONES OTA
struct WebAdminView: View {
    @ObservedObject var store: LawnCareStore
    @State private var serverInput = ""
    @State private var showSavedAlert = false
    @State private var showHeroManagerSheet = false
    @State private var showCloudPanelSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        otaUpdatesCard
                        analyticsCard
                        heroManagerCard
                        panelCloudCard
                        serverHealthCard
                        serverUrlSettingsCard

                        VStack(spacing: 4) {
                            Text("rodriguezlawncareios • Versión \(store.currentAppVersion) (Build \(store.currentAppBuild))")
                                .font(.caption2.bold()).foregroundStyle(.gray)
                            Text("Conexión 100% online con Railway y compilación inalámbrica OTA")
                                .font(.caption2).foregroundStyle(.gray.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Ajustes & Sistema OTA ⚙️")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                serverInput = store.serverURL
            }
            .sheet(isPresented: $showHeroManagerSheet) {
                HeroBackgroundManagerSheet(store: store)
            }
            .sheet(isPresented: $showCloudPanelSheet) {
                CloudLiveAdminView(store: store)
            }
            .alert("Configuración Guardada", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Se ha actualizado la dirección del servidor.")
            }
        }
    }

    // PANEL CLOUD CARD
    private var panelCloudCard: some View {
        Button {
            showCloudPanelSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.1, green: 0.45, blue: 0.9).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "cloud.fill")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 1.0))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Panel Cloud 24/7 (Navegador en Vivo)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Supervisa Railway, servidor y métricas en vivo")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.gray)
            }
            .padding(14)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // 1. OTA & ONLINE UPDATES CENTER
    private var otaUpdatesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.horizontal.fill")
                    .foregroundStyle(Brand.accent)
                Text("CENTRO DE ACTUALIZACIONES ONLINE (OTA)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("v\(store.currentAppVersion)")
                    .font(.caption2.bold())
                    .foregroundStyle(Brand.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Brand.primaryDark.opacity(0.3))
                    .clipShape(Capsule())
            }

            Text("Actualiza la app inalámbricamente por el aire sin necesidad de conectarla por cable a la PC ni reenviar archivos.")
                .font(.caption)
                .foregroundStyle(.gray)

            HStack {
                Text("Estado:")
                    .font(.caption).foregroundStyle(.gray)
                Spacer()
                Text(store.updateCheckStatus)
                    .font(.caption.bold())
                    .foregroundStyle(Brand.primary)
            }

            HStack(spacing: 10) {
                Button {
                    Task { await store.checkOTAUpdate(manual: true) }
                } label: {
                    HStack {
                        if store.isCheckingUpdate {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text("Buscar Actualizaciones")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Brand.cardLight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    if let url = URL(string: "\(store.cleanURL)/instalar") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Instalar OTA")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Brand.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Button {
                let gboxTarget = "gbox://import?url=\(store.cleanURL)/download/ipa"
                if let url = URL(string: gboxTarget) {
                    UIApplication.shared.open(url) { opened in
                        if !opened {
                            if let fallback = URL(string: "\(store.cleanURL)/download/ipa") {
                                UIApplication.shared.open(fallback)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "shippingbox.fill")
                    Text("📦 Actualizar en 1 Toque con GBox")
                }
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(11)
                .background(Color(red: 0.05, green: 0.55, blue: 0.85))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Brand.accent.opacity(0.4), lineWidth: 1)
        )
    }

    // 2. Analytics Card (Visitas en Vivo)
    private var analyticsCard: some View {
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
                AnalyticsMetricBox(title: "Visitas Web", value: "\(store.stats?.total_visits ?? 0)", icon: "eye.fill", color: .blue)
                AnalyticsMetricBox(title: "Visitas Hoy", value: "\(store.stats?.visits_today ?? 0)", icon: "flame.fill", color: .orange)
            }

            HStack(spacing: 12) {
                AnalyticsMetricBox(title: "Citas Recibidas", value: "\(store.stats?.total_leads ?? store.leads.count)", icon: "bell.fill", color: Brand.primary)
                AnalyticsMetricBox(title: "Conversión", value: store.stats?.conversion_rate ?? "0.0%", icon: "percent", color: .purple)
            }
        }
        .padding()
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // 3. HERO BACKGROUND MANAGER
    private var heroManagerCard: some View {
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
    }

    // 4. Server Health & Status
    private var serverHealthCard: some View {
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
    }

    // 5. Server URL Settings
    private var serverUrlSettingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("URL DEL SERVIDOR WEB").font(.caption.bold()).foregroundStyle(.gray)
            TextField("https://web-production-b6891b.up.railway.app", text: $serverInput)
                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

            HStack(spacing: 8) {
                Button {
                    serverInput = "https://web-production-b6891b.up.railway.app"
                    store.serverURL = serverInput
                    Task {
                        await store.refreshAll()
                        showSavedAlert = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Oficial")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Brand.cardLight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

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
        }
    }
}

// MARK: - OTA UPDATE MODAL SHEET (1-TAP WIRELESS INSTALLATION)
struct OTAUpdateSheetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: LawnCareStore

    var info: AppVersionInfo? {
        store.availableUpdate
    }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Brand.primary.opacity(0.15))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Brand.primary, lineWidth: 2)
                                    )
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 46))
                                    .foregroundStyle(Brand.primary)
                            }
                            .padding(.top, 10)

                            Text("¡Nueva Actualización Online!")
                                .font(.title2.bold())
                                .foregroundStyle(.white)

                            Text("rodriguezlawncareios \(info?.version ?? "v1.2.0")")
                                .font(.subheadline.bold())
                                .foregroundStyle(Brand.accent)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOVEDADES DE ESTA VERSIÓN")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)

                            Text(info?.release_notes ?? "Conexión 100% online con Railway, ícono oficial y actualización inalámbrica OTA sin cables.")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .lineSpacing(4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Button 0: GBox 1-Tap
                        Button {
                            let gboxTarget = info?.gbox_url ?? "gbox://import?url=\(store.cleanURL)/download/ipa"
                            if let url = URL(string: gboxTarget) {
                                UIApplication.shared.open(url) { opened in
                                    if !opened {
                                        if let fallback = URL(string: "\(store.cleanURL)/download/ipa") {
                                            UIApplication.shared.open(fallback)
                                        }
                                    }
                                }
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "shippingbox.fill")
                                    .font(.title3)
                                Text("📦 Instalar / Firmar con GBox (1 Toque)")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.05, green: 0.55, blue: 0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Button 1: Safari OTA
                        Button {
                            if let s = info?.ota_install_url, let url = URL(string: s) {
                                UIApplication.shared.open(url)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "wifi")
                                    .font(.title3)
                                Text("Instalar por Aire (Safari OTA)")
                                    .font(.headline)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Button 2: TrollStore
                        Button {
                            if let s = info?.trollstore_url, let url = URL(string: s) {
                                UIApplication.shared.open(url)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Instalar con TrollStore (1 Toque)")
                                    .font(.subheadline.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Button 3: ESign
                        Button {
                            if let s = info?.esign_url, let url = URL(string: s) {
                                UIApplication.shared.open(url)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "signature")
                                Text("Abrir en ESign / Scarlet")
                                    .font(.subheadline.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Brand.cardLight)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Button 4: Web Install
                        Button {
                            if let s = info?.web_install_url, let url = URL(string: s) {
                                UIApplication.shared.open(url)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text("Abrir Portal Web de Instalación")
                                    .font(.footnote)
                            }
                            .foregroundStyle(.gray)
                        }
                        .padding(.top, 4)

                        Button("Recordar más tarde") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.top, 6)
                    }
                    .padding()
                }
            }
            .navigationTitle("Actualizador OTA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - TAB 4: WEB MUSIC CONTROL VIEW (MÚSICA WEB)
struct WebMusicControlView: View {
    @ObservedObject var store: LawnCareStore

    @State private var musicEnabled: Bool = true
    @State private var volume: Double = 0.35
    @State private var selectedPresetId: String = "texas_guitar"
    @State private var customTitle: String = ""
    @State private var customGenre: String = ""
    @State private var customStreamURL: String = ""
    @State private var isCustomMode: Bool = false
    @State private var showSuccessBanner: Bool = false
    @State private var isSaving: Bool = false

    private var currentMusicPresets: [MusicPreset] {
        if let presets = store.settings?.music_presets, !presets.isEmpty {
            return presets
        }
        return LawnCareStore.defaultMusicPresets
    }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Success Banner
                        if showSuccessBanner {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.black)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("¡MÚSICA WEB ACTUALIZADA!")
                                        .font(.caption.bold())
                                        .foregroundStyle(.black)
                                    Text("Los cambios ya están sonando en la página web oficial.")
                                        .font(.caption2)
                                        .foregroundStyle(.black.opacity(0.85))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Status banner
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(musicEnabled ? Brand.primary.opacity(0.15) : Color.gray.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: musicEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                    .font(.title3)
                                    .foregroundStyle(musicEnabled ? Brand.primary : .gray)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(musicEnabled ? "MÚSICA EN VIVO ACTIVA" : "MÚSICA EN LA WEB SILENCIADA")
                                    .font(.caption.bold())
                                    .foregroundStyle(musicEnabled ? Brand.primary : .gray)
                                Text(musicEnabled ? "Pistas relajantes de fondo para ambientar a los clientes" : "Activa el interruptor para reproducir audio en la web")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Master Toggle
                        VStack(spacing: 0) {
                            Toggle(isOn: $musicEnabled) {
                                HStack(spacing: 10) {
                                    Image(systemName: "music.note")
                                        .font(.title3)
                                        .foregroundStyle(Brand.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Activar Música de Fondo")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text("Reproduce música sutil cuando los clientes navegan")
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                            .tint(Brand.primary)
                            .padding()

                            if musicEnabled {
                                Divider().background(Color.white.opacity(0.1))

                                // Volume Slider
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Volumen de Reproducción:")
                                            .font(.caption.bold())
                                            .foregroundStyle(.gray)
                                        Spacer()
                                        Text("\(Int(volume * 100))%")
                                            .font(.caption.bold())
                                            .foregroundStyle(Brand.primary)
                                    }

                                    HStack(spacing: 12) {
                                        Image(systemName: "speaker.fill")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                        Slider(value: $volume, in: 0.05...1.0, step: 0.05)
                                            .tint(Brand.primary)
                                        Image(systemName: "speaker.wave.3.fill")
                                            .font(.caption)
                                            .foregroundStyle(Brand.primary)
                                    }
                                }
                                .padding()
                            }
                        }
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Curated Presets
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ESTILOS MUSICALES RECOMENDADOS")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)

                            ForEach(currentMusicPresets) { preset in
                                Button {
                                    selectedPresetId = preset.id
                                    customTitle = preset.name
                                    customGenre = preset.genre
                                    customStreamURL = preset.url
                                    isCustomMode = false
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill((!isCustomMode && selectedPresetId == preset.id) ? Brand.primary.opacity(0.2) : Brand.cardLight)
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "music.quarternote.3")
                                                .foregroundStyle((!isCustomMode && selectedPresetId == preset.id) ? Brand.primary : .gray)
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack {
                                                Text(preset.name)
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(.white)
                                                Spacer()
                                                Text(preset.genre)
                                                    .font(.caption2)
                                                    .foregroundStyle(Brand.primary)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Brand.primaryDark.opacity(0.3))
                                                    .clipShape(Capsule())
                                            }

                                            Text(preset.desc)
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                                .lineLimit(2)
                                        }

                                        Image(systemName: (!isCustomMode && selectedPresetId == preset.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle((!isCustomMode && selectedPresetId == preset.id) ? Brand.primary : .gray)
                                    }
                                    .padding(12)
                                    .background(Brand.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke((!isCustomMode && selectedPresetId == preset.id) ? Brand.primary : Color.clear, lineWidth: 1.5)
                                    )
                                }
                            }
                        }

                        // Custom Music Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("PERSONALIZAR CON MÚSICA DIFERENTE")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.accent)
                                Spacer()
                                if isCustomMode {
                                    Text("Activo")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Brand.accent)
                                }
                            }

                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Título o Canción")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.gray)
                                    TextField("Ej: Regional Mexicano / Balada", text: $customTitle)
                                        .padding(10)
                                        .background(Brand.cardLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .foregroundStyle(.white)
                                        .font(.subheadline)
                                        .onChange(of: customTitle) { _ in isCustomMode = true }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Género")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.gray)
                                    TextField("Ej: Ranchera / Acústico / Corridos", text: $customGenre)
                                        .padding(10)
                                        .background(Brand.cardLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .foregroundStyle(.white)
                                        .font(.subheadline)
                                        .onChange(of: customGenre) { _ in isCustomMode = true }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enlace Directo de Audio (MP3 / Stream)")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.gray)
                                    TextField("https://.../cancion.mp3", text: $customStreamURL)
                                        .padding(10)
                                        .background(Brand.cardLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .foregroundStyle(.white)
                                        .font(.subheadline)
                                        .keyboardType(.URL)
                                        .autocapitalization(.none)
                                        .onChange(of: customStreamURL) { _ in isCustomMode = true }
                                }
                            }
                            .padding()
                            .background(Brand.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Apply Button
                        Button {
                            Task {
                                isSaving = true
                                let finalPreset = isCustomMode ? "custom" : selectedPresetId
                                let finalTitle = customTitle.isEmpty ? "Texas Acoustic" : customTitle
                                let finalGenre = customGenre.isEmpty ? "Acoustic Chill" : customGenre
                                let finalStream = customStreamURL.isEmpty ? "https://cdn.pixabay.com/download/audio/2022/01/18/audio_d0a13f69d2.mp3?filename=acoustic-guitars-ambient-10874.mp3" : customStreamURL

                                await store.updateWebMusic(
                                    enabled: musicEnabled,
                                    title: finalTitle,
                                    genre: finalGenre,
                                    streamURL: finalStream,
                                    volume: volume,
                                    presetId: finalPreset
                                )
                                isSaving = false
                                showSuccessBanner = true
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    showSuccessBanner = false
                                }
                            }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("🚀 Guardar y Aplicar Música a la Página Web")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isSaving)
                        .padding(.top, 6)
                    }
                    .padding()
                }
            }
            .navigationTitle("Música Web 🎵")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let m = store.settings?.music {
                    musicEnabled = m.enabled ?? true
                    volume = m.volume ?? 0.35
                    selectedPresetId = m.preset_id ?? "texas_guitar"
                    customTitle = m.title ?? ""
                    customGenre = m.genre ?? ""
                    customStreamURL = m.stream_url ?? ""
                    if m.preset_id == "custom" {
                        isCustomMode = true
                    }
                } else if let firstPreset = currentMusicPresets.first {
                    selectedPresetId = firstPreset.id
                    customTitle = firstPreset.name
                    customGenre = firstPreset.genre
                    customStreamURL = firstPreset.url
                }
            }
        }
    }
}

// MARK: - HERO BACKGROUND MANAGER SHEET (MATCHING IMAGE 2)
struct HeroBackgroundManagerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: LawnCareStore

    @State private var selectedHeroType: String = "video"
    @State private var selectedPresetId: String = "drone_tundra"
    @State private var customVideoURL: String = ""
    @State private var customPosterURL: String = ""
    @State private var showSuccessBanner: Bool = false

    private var currentVideoPresets: [VideoPreset] {
        if let presets = store.settings?.video_presets, !presets.isEmpty {
            return presets
        }
        return LawnCareStore.defaultVideoPresets
    }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Success Banner
                        if showSuccessBanner {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.black)
                                Text("¡Fondo de la web actualizado con éxito!")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Explanation card
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PERSONALIZACIÓN DEL FONDO WEB")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            Text("Controla qué se ve al entrar a tu sitio web oficial. Puedes activar los videos aéreos con dron generados por IA o fotos estáticas en alta definición.")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .lineSpacing(3)
                        }
                        .padding()
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Type selector: Video vs Image
                        VStack(alignment: .leading, spacing: 10) {
                            Text("1. TIPO DE FONDO PRINCIPAL")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)

                            Picker("Tipo", selection: $selectedHeroType) {
                                Text("🎬 Video (Dron IA)").tag("video")
                                Text("📸 Foto Estática").tag("image")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Presets List
                        if selectedHeroType == "video" {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("2. SELECCIONA EL VIDEO CON DRON IA")
                                    .font(.caption.bold())
                                    .foregroundStyle(.gray)

                                ForEach(currentVideoPresets) { preset in
                                    PresetVideoCard(
                                        preset: preset,
                                        isSelected: selectedPresetId == preset.id,
                                        store: store
                                    ) {
                                        selectedPresetId = preset.id
                                        customVideoURL = preset.video_url
                                        customPosterURL = preset.poster_url
                                    }
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("2. SELECCIONA LA FOTO ESTÁTICA")
                                    .font(.caption.bold())
                                    .foregroundStyle(.gray)

                                if let presets = store.settings?.photo_presets {
                                    ForEach(presets) { preset in
                                        PresetPhotoCard(
                                            preset: preset,
                                            isSelected: selectedPresetId == preset.id,
                                            store: store
                                        ) {
                                            selectedPresetId = preset.id
                                            customPosterURL = preset.photo_url
                                        }
                                    }
                                }
                            }
                        }

                        // Apply Button
                        Button {
                            Task {
                                let vUrl = customVideoURL.isEmpty ? "./assets/video/hero.mp4" : customVideoURL
                                let pUrl = customPosterURL.isEmpty ? "./assets/images/drone_tundra_intro.jpg" : customPosterURL
                                await store.updateHeroBackground(
                                    type: selectedHeroType,
                                    videoURL: vUrl,
                                    posterURL: pUrl,
                                    presetId: selectedPresetId
                                )
                                showSuccessBanner = true
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Aplicar Fondo a la Web Ahora")
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Fondo Hero & Videos IA 🎬")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onAppear {
                if let s = store.settings {
                    selectedHeroType = s.hero_type
                    selectedPresetId = s.hero_preset_id ?? "drone_tundra"
                    customVideoURL = s.hero_video_url
                    customPosterURL = s.hero_poster_url
                }
            }
        }
    }
}

// MARK: - PRESET VIDEO CARD
struct PresetVideoCard: View {
    let preset: VideoPreset
    let isSelected: Bool
    @ObservedObject var store: LawnCareStore
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: store.fullMediaURL(preset.poster_url))) { phase in
                    if let img = phase.image {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Brand.cardLight
                    }
                }
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(preset.desc)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Brand.primary : .gray)
            }
            .padding(10)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Brand.primary : Color.white.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - PRESET PHOTO CARD
struct PresetPhotoCard: View {
    let preset: PhotoPreset
    let isSelected: Bool
    @ObservedObject var store: LawnCareStore
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: store.fullMediaURL(preset.photo_url))) { phase in
                    if let img = phase.image {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Brand.cardLight
                    }
                }
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(preset.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Brand.primary : .gray)
            }
            .padding(10)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Brand.primary : Color.white.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - ANALYTICS METRIC BOX
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
        .background(Brand.cardLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
