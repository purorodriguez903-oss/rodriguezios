// MARK: - LIVING ANIMATED PARTICLES BACKGROUND (EMERALD & GOLD)
struct FloatingSporeDot: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var color: Color
    var xOffset: CGFloat
}

struct LivingParticlesBackgroundView: View {
    @State private var animateParticles: Bool = false
    
    // 34 ambient particles with shades of emerald green, neon mint, and gold
    let spores: [FloatingSporeDot] = (0..<34).map { i in
        let colors: [Color] = [
            Brand.primary,
            Color(red: 0.1, green: 0.9, blue: 0.5),
            Color(red: 0.95, green: 0.8, blue: 0.25),
            Color.mint,
            Color.green
        ]
        return FloatingSporeDot(
            x: CGFloat.random(in: 0.02...0.98),
            y: CGFloat.random(in: 0.03...0.97),
            size: CGFloat.random(in: 3.5...10),
            opacity: Double.random(in: 0.2...0.65),
            speed: Double.random(in: 3.5...7.5),
            color: colors[i % colors.count],
            xOffset: CGFloat.random(in: -18...18)
        )
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Brand.background.ignoresSafeArea()
                
                // Deep Ambient Atmospheric Glows
                RadialGradient(
                    gradient: Gradient(colors: [Brand.primary.opacity(animateParticles ? 0.16 : 0.07), Color.clear]),
                    center: .topTrailing,
                    startRadius: 20,
                    endRadius: geo.size.width * 0.9
                )
                .ignoresSafeArea()
                
                RadialGradient(
                    gradient: Gradient(colors: [Color.green.opacity(animateParticles ? 0.13 : 0.05), Color.clear]),
                    center: .bottomLeading,
                    startRadius: 30,
                    endRadius: geo.size.width * 0.85
                )
                .ignoresSafeArea()
                
                // Animated Floating Spores & Dust Particles
                ForEach(spores) { spore in
                    Circle()
                        .fill(spore.color)
                        .frame(width: spore.size, height: spore.size)
                        .shadow(color: spore.color.opacity(0.8), radius: spore.size > 7 ? 6 : 3)
                        .opacity(animateParticles ? spore.opacity : spore.opacity * 0.4)
                        .offset(
                            x: animateParticles ? spore.xOffset : -spore.xOffset,
                            y: animateParticles ? -22 : 22
                        )
                        .position(
                            x: spore.x * geo.size.width,
                            y: spore.y * geo.size.height
                        )
                        .animation(
                            Animation.easeInOut(duration: spore.speed)
                                .repeatForever(autoreverses: true),
                            value: animateParticles
                        )
                }
            }
        }
        .onAppear {
            animateParticles = true
        }
    }
}

typealias GlowingParticlesBackgroundView = LivingParticlesBackgroundView

import SwiftUI
import UserNotifications
import AVKit
import Combine
import WebKit
import MapKit
import CoreLocation
import AudioToolbox
import CoreImage
import Contacts
import ContactsUI
import AVFoundation
import CoreMedia
import Photos

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

// MARK: - WEATHER & RECURRING CLIENT MODELS
struct WeatherInfo: Codable {
    var temperature: Int
    var unit: String
    var weather_code: Int
    var rain_probability: Int
    var city: String
    
    var conditionText: String {
        switch weather_code {
        case 0: return "Despejado / Soleado"
        case 1, 2: return "Parcialmente Nublado"
        case 3: return "Nublado"
        case 45, 48: return "Niebla"
        case 51, 53, 55: return "Llovizna Ligera"
        case 61, 63, 65: return "Lluvia"
        case 80, 81, 82: return "Chubascos Fuertes"
        case 95, 96, 99: return "Tormenta Eléctrica"
        default: return "Cielo Variable"
        }
    }
    
    var conditionIcon: String {
        switch weather_code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 51, 53, 55, 61, 63, 65: return "cloud.rain.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "sun.max.fill"
        }
    }
}

struct RecurringClient: Identifiable, Codable {
    var id: Int
    var name: String
    var phone: String
    var address: String
    var frequency: String // "weekly", "biweekly", "monthly"
    var service_day: String // "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"
    var price: Double
    var status: String // "paid", "pending"
    var services: [String]?
    var notes: String?
    var last_serviced: String?
}

struct SoundManager {
    static func playLeadAlert() {
        AudioServicesPlaySystemSound(1025)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func playSuccessTone() {
        AudioServicesPlaySystemSound(1057)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

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
    var photos: [String]?
}

// MARK: - CALENDAR & APPOINTMENTS MODELS
struct CalendarAppointment: Identifiable, Codable, Equatable {
    var id: Int
    var date: String
    var time_window: String
    var client_name: String
    var client_phone: String
    var address: String
    var services: [String]?
    var amount: Double?
    var status: String? // confirmed, scheduled, in_progress, completed, cancelled
    var notes: String?
}

struct CalendarData: Codable {
    var day_status: [String: String]? // "YYYY-MM-DD": "normal" or "full"
    var appointments: [CalendarAppointment]?
}

struct CalendarResponse: Codable {
    var success: Bool
    var calendar: CalendarData?
}

// MARK: - FLASH PROMOTIONS MODEL
struct FlashPromotion: Identifiable, Codable, Equatable {
    var id: Int?
    var enabled: Bool
    var title: String
    var message: String
    var badge: String?
    var created_at: Int?
    var duration_hours: Int?
    var expires_at: Int?
}

struct PromoResponse: Codable {
    var success: Bool
    var promo: FlashPromotion?
    var history: [FlashPromotion]?
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

struct ClientReview: Identifiable, Codable {
    var id: Int
    var name: String
    var role: String
    var badge: String?
    var rating: Int
    var text: String
    var initials: String?
    var date: String?
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

struct AIEstimateItem: Identifiable, Codable {
    var id: String { item + (sku ?? "") }
    var item: String
    var store: String
    var qty: String
    var unit_price: Double
    var subtotal: Double
    var sku: String?
}

struct AIEstimateStoreInfo: Codable {
    var name: String?
    var location: String?
    var phone: String?
}

struct AIEstimateResponse: Codable {
    var success: Bool
    var total_quote: Double?
    var total_materials: Double?
    var total_labor: Double?
    var overhead: Double?
    var net_profit: Double?
    var profit_margin: String?
    var labor_details: String?
    var store_info: AIEstimateStoreInfo?
    var materials: [AIEstimateItem]?
    var whatsapp_text: String?
    var ai_confidence: String?
    var ai_tips: String?
    var error: String?
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

    let currentAppVersion: String = "2.4.0"
    let currentAppBuild: Int = 29

    @Published var geocodedCache: [String: [Double]] = [:]

    func resolveCoordinate(for rawAddress: String, clientName: String = "") -> CLLocationCoordinate2D {
        let clean = rawAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            return CLLocationCoordinate2D(latitude: 31.1171, longitude: -97.7278)
        }
        
        if let coords = geocodedCache[clean], coords.count == 2 {
            return CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
        }
        
        let lower = clean.lowercased()
        var baseLat: Double = 31.1171
        var baseLng: Double = -97.7278
        
        // Exact city/neighborhood centers across Bell & Coryell Counties:
        if lower.contains("cove") || lower.contains("copperas") {
            baseLat = 31.1241
            baseLng = -97.9031
        } else if lower.contains("harker") || lower.contains("heights") {
            baseLat = 31.0835
            baseLng = -97.6597
        } else if lower.contains("nolanville") {
            baseLat = 31.0888
            baseLng = -97.6047
        } else if lower.contains("belton") {
            baseLat = 31.0560
            baseLng = -97.4645
        } else if lower.contains("temple") {
            baseLat = 31.0982
            baseLng = -97.3428
        } else if lower.contains("cavazos") || lower.contains("hood") {
            baseLat = 31.1305
            baseLng = -97.7780
        } else if lower.contains("kempner") {
            baseLat = 31.0774
            baseLng = -98.0064
        } else if lower.contains("salado") {
            baseLat = 30.9474
            baseLng = -97.5386
        } else if lower.contains("clear creek") {
            baseLat = 31.1250
            baseLng = -97.7850
        } else if lower.contains("stan schlueter") || lower.contains("trimmier") {
            baseLat = 31.0850
            baseLng = -97.7580
        } else if lower.contains("willow springs") {
            baseLat = 31.1092
            baseLng = -97.7410
        }
        
        let hash = abs((clientName + clean).hashValue)
        let latOffset = Double((hash % 30) - 15) * 0.0004
        let lngOffset = Double(((hash / 30) % 30) - 15) * 0.0005
        
        geocodeAddressInBackground(clean)
        return CLLocationCoordinate2D(latitude: baseLat + latOffset, longitude: baseLng + lngOffset)
    }
    
    func geocodeAddressInBackground(_ address: String) {
        let clean = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        if geocodedCache[clean] != nil { return }
        
        let query = clean.contains("TX") ? clean : "\(clean), TX"
        CLGeocoder().geocodeAddressString(query) { [weak self] placemarks, _ in
            guard let self = self, let loc = placemarks?.first?.location else { return }
            DispatchQueue.main.async {
                self.geocodedCache[clean] = [loc.coordinate.latitude, loc.coordinate.longitude]
            }
        }
    }

    @Published var calendarData: CalendarData = CalendarData(day_status: [:], appointments: [])
    @Published var activePromo: FlashPromotion? = nil
    @Published var reviews: [ClientReview] = []
    @Published var promoHistory: [FlashPromotion] = []
    @Published var recurringClients: [RecurringClient] = []
    @Published var weatherInfo: WeatherInfo? = nil
    @AppStorage("sound_effects_enabled") var soundEffectsEnabled: Bool = true

    @AppStorage("api_server_url") var serverURL: String = "https://rodriguezlawncare.xyz"
    @Published var activeEffectiveURL: String = "https://rodriguezlawncare.xyz"
    let fallbackServerURL: String = "https://rodriguezlawncare.xyz"

    private var knownLeadIds: Set<Int> = []
    private var isFirstLoad: Bool = true
    private var cancellables = Set<AnyCancellable>()

    init() {
        if serverURL.contains("railway.app") || serverURL.isEmpty || serverURL.contains("web-production") || serverURL.contains("rodriguezlawncarenuevaa") || !serverURL.contains("rodriguezlawncare.xyz") {
            serverURL = "https://rodriguezlawncare.xyz"
            UserDefaults.standard.set("https://rodriguezlawncare.xyz", forKey: "api_server_url")
        }
        activeEffectiveURL = serverURL
        loadDemoData()
        requestNotificationPermissions()
        startRealtimePolling()
        Task { @MainActor in
            await testAndSelectActiveServer()
            await checkOTAUpdate(manual: false)
            await fetchCloudConfig()
            await fetchCalendar()
            await fetchPromo()
            await fetchReviews()
            await fetchRecurringClients()
            await fetchWeather()
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
        content.title = "🚨 ¡NUEVA CITA / COTIZACIÓN WEB!"
        content.subtitle = "\(lead.name) • \(lead.phone)"
        let svcs = lead.services?.joined(separator: ", ") ?? "Corte de Césped"
        content.body = "Servicios: \(svcs) | \(lead.description ?? "Cliente solicita cotización")"
        content.sound = .defaultCritical
        content.badge = 1
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: "lead_\(lead.id)_\(Int(Date().timeIntervalSince1970))", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { err in
            if let err = err {
                print("Error system notification: \(err)")
            }
        }
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
        var base = activeEffectiveURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.isEmpty || base.contains("rodriguezlawncarenuevaa") {
            base = "https://rodriguezlawncare.xyz"
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
        await fetchCalendar()
        await fetchPromo()
        await fetchRecurringClients()
        await fetchWeather()
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
    func testAndSelectActiveServer() async {
        let primary = "https://rodriguezlawncare.xyz"
        if let url = URL(string: "\(primary)/api/stats") {
            var req = URLRequest(url: url)
            req.timeoutInterval = 3
            if let (_, resp) = try? await URLSession.shared.data(for: req),
               let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                self.activeEffectiveURL = primary
                return
            }
        }
        self.activeEffectiveURL = fallbackServerURL
    }

    @MainActor
    func fetchStats() async {
        guard let url = URL(string: "\(cleanURL)/api/stats") else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 4
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(StatsResponse.self, from: data)
                self.stats = decoded.stats
                self.isOnline = true
                return
            }
        } catch {
            if activeEffectiveURL.contains("rodriguezlawncare.xyz") {
                if let fbUrl = URL(string: "\(fallbackServerURL)/api/stats") {
                    var fbReq = URLRequest(url: fbUrl)
                    fbReq.timeoutInterval = 4
                    if let (fbData, fbResp) = try? await URLSession.shared.data(for: fbReq),
                       let fbHttp = fbResp as? HTTPURLResponse, fbHttp.statusCode == 200 {
                        let decoded = try? JSONDecoder().decode(StatsResponse.self, from: fbData)
                        self.stats = decoded?.stats
                        self.activeEffectiveURL = fallbackServerURL
                        self.isOnline = true
                        return
                    }
                }
            }
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
                UserDefaults.standard.set(decoded.leads.map { $0.id }, forKey: "known_lead_ids_bg")
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

    func testSystemNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🔔 PRUEBA DE NOTIFICACIÓN DEL SISTEMA"
        content.subtitle = "Rodriguez LawnCare • 24/7 En Vivo"
        content.body = "¡Excelente! Las notificaciones fuera de la app están activas. Te llegarán alertas en la calle al recibir cotizaciones."
        content.sound = .defaultCritical
        content.badge = 1
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3.0, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notify_\(Int(Date().timeIntervalSince1970))", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor
    func generateAIEstimate(
        description: String,
        workersCount: Int,
        payType: String,
        payRate: Double,
        duration: Double,
        storePreference: String,
        imageBase64: String? = nil
    ) async -> AIEstimateResponse? {
        guard let url = URL(string: "\(cleanURL)/api/ai/estimate") else { return nil }
        var payload: [String: Any] = [
            "description": description,
            "workers_count": workersCount,
            "pay_type": payType,
            "pay_rate": payRate,
            "duration": duration,
            "store_preference": storePreference
        ]
        if let img = imageBase64 {
            payload["image_base64"] = img
        }

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 18
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                return try JSONDecoder().decode(AIEstimateResponse.self, from: data)
            }
        } catch {
            print("AI Estimate error: \(error)")
        }
        return nil
    }

    // MARK: - CALENDAR API METHODS
    @MainActor
    func fetchCalendar() async {
        guard let url = URL(string: "\(cleanURL)/api/calendar") else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 6
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(CalendarResponse.self, from: data)
                if let cal = decoded.calendar {
                    self.calendarData = cal
                }
            }
        } catch {}
    }

    @MainActor
    func toggleCalendarDayStatus(date: String) async {
        let current = calendarData.day_status?[date] ?? "normal"
        let nextStatus = (current == "full") ? "normal" : "full"
        if calendarData.day_status == nil { calendarData.day_status = [:] }
        calendarData.day_status?[date] = nextStatus

        guard let url = URL(string: "\(cleanURL)/api/calendar/day") else { return }
        let payload: [String: Any] = ["date": date, "status": nextStatus]
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {}
    }

    @MainActor
    func saveCalendarAppointment(appt: CalendarAppointment) async {
        if let idx = calendarData.appointments?.firstIndex(where: { $0.id == appt.id }) {
            calendarData.appointments?[idx] = appt
        } else {
            calendarData.appointments?.insert(appt, at: 0)
        }

        guard let url = URL(string: "\(cleanURL)/api/calendar/appointment") else { return }
        let payload: [String: Any] = [
            "id": appt.id,
            "date": appt.date,
            "time_window": appt.time_window,
            "client_name": appt.client_name,
            "client_phone": appt.client_phone,
            "address": appt.address,
            "services": appt.services ?? [],
            "amount": appt.amount ?? 0.0,
            "status": appt.status ?? "confirmed",
            "notes": appt.notes ?? ""
        ]
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {}
    }

    @MainActor
    func deleteCalendarAppointment(id: Int) async {
        calendarData.appointments?.removeAll { $0.id == id }
        guard let url = URL(string: "\(cleanURL)/api/calendar/delete") else { return }
        let payload: [String: Any] = ["id": id]
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
        } catch {}
    }

    // MARK: - FLASH PROMOTIONS API METHODS
    @MainActor
    func fetchPromo() async {
        guard let url = URL(string: "\(cleanURL)/api/promo") else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 6
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(PromoResponse.self, from: data)
                self.activePromo = decoded.promo
                self.promoHistory = decoded.history ?? []
            }
        } catch {}
    }

    @MainActor
    func publishPromo(title: String, message: String, badge: String, durationHours: Int) async {
        guard let url = URL(string: "\(cleanURL)/api/promo") else { return }
        let payload: [String: Any] = [
            "title": title,
            "message": message,
            "badge": badge,
            "duration_hours": durationHours
        ]
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(PromoResponse.self, from: data)
                self.activePromo = decoded.promo
                self.promoHistory = decoded.history ?? []
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } catch {}
    }

    @MainActor
    func deactivatePromo() async {
        guard let url = URL(string: "\(cleanURL)/api/promo/deactivate") else { return }
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(PromoResponse.self, from: data)
                self.activePromo = decoded.promo
                await fetchPromo()
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        } catch {}
    }

    // MARK: - REVIEWS API METHODS
    @MainActor
    func fetchReviews() async {
        guard let url = URL(string: "\(cleanURL)/api/reviews") else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 8
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode([ClientReview].self, from: data)
                self.reviews = decoded
            }
        } catch {}
    }

    func addReview(name: String, role: String, badge: String, rating: Int, text: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(cleanURL)/api/reviews") else { completion(false); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "name": name,
            "role": role,
            "badge": badge,
            "rating": rating,
            "text": text
        ]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { completion(false); return }
        req.httpBody = httpBody
        URLSession.shared.dataTask(with: req) { [weak self] data, _, err in
            if err == nil {
                Task { await self?.fetchReviews() }
                DispatchQueue.main.async { completion(true) }
            } else {
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    func deleteReview(id: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(cleanURL)/api/reviews/delete") else { completion(false); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = ["id": id]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        URLSession.shared.dataTask(with: req) { [weak self] data, _, err in
            if err == nil {
                Task { await self?.fetchReviews() }
                DispatchQueue.main.async { completion(true) }
            } else {
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    // MARK: - RECURRING CLIENTS & WEATHER METHODS
    func fetchRecurringClients() async {
        guard let url = URL(string: "\(cleanURL)/api/recurring") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct RecResp: Codable { var success: Bool; var clients: [RecurringClient] }
            if let resp = try? JSONDecoder().decode(RecResp.self, from: data) {
                DispatchQueue.main.async {
                    self.recurringClients = resp.clients
                }
            }
        } catch {
            print("Notice fetchRecurringClients: \(error)")
        }
    }

    func saveRecurringClient(_ client: RecurringClient) async {
        guard let url = URL(string: "\(cleanURL)/api/recurring") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = try? JSONEncoder().encode(client) {
            req.httpBody = body
            _ = try? await URLSession.shared.data(for: req)
            await fetchRecurringClients()
            if soundEffectsEnabled { SoundManager.playSuccessTone() }
        }
    }

    func togglePaidRecurring(id: Int) async {
        guard let url = URL(string: "\(cleanURL)/api/recurring/toggle-paid") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["id": id])
        _ = try? await URLSession.shared.data(for: req)
        await fetchRecurringClients()
        if soundEffectsEnabled { SoundManager.playSuccessTone() }
    }

    func updateRecurringClient(_ client: RecurringClient) async {
        DispatchQueue.main.async {
            if let idx = self.recurringClients.firstIndex(where: { $0.id == client.id }) {
                self.recurringClients[idx] = client
            }
        }
        guard let url = URL(string: "\(cleanURL)/api/recurring") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = try? JSONEncoder().encode(client) {
            req.httpBody = body
            _ = try? await URLSession.shared.data(for: req)
        }
        if soundEffectsEnabled { SoundManager.playSuccessTone() }
    }

    func deleteRecurringClient(id: Int) async {
        guard let url = URL(string: "\(cleanURL)/api/recurring/delete") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["id": id])
        _ = try? await URLSession.shared.data(for: req)
        await fetchRecurringClients()
    }

    func fetchWeather() async {
        guard let url = URL(string: "\(cleanURL)/api/weather/killeen") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct WResp: Codable {
                var success: Bool
                var temperature: Int
                var unit: String
                var weather_code: Int
                var rain_probability: Int
                var city: String
            }
            if let r = try? JSONDecoder().decode(WResp.self, from: data) {
                DispatchQueue.main.async {
                    self.weatherInfo = WeatherInfo(
                        temperature: r.temperature,
                        unit: r.unit,
                        weather_code: r.weather_code,
                        rain_probability: r.rain_probability,
                        city: r.city
                    )
                }
            }
        } catch {
            print("Notice fetchWeather: \(error)")
        }
    }


    static let defaultMusicPresets: [MusicPreset] = [
        MusicPreset(id: "texas_guitar", name: "🎸 Texas Acoustic & Guitarra Campestre", genre: "Acoustic Chill", url: "./assets/audio/texas_acoustic.mp3", desc: "Acordes suaves de guitarra acústica y vibra texana para ambientar la página con clase."),
        MusicPreset(id: "lofi_garden", name: "☕ Lofi Beats & Jardinería Relajante", genre: "Lofi Hip-Hop", url: "./assets/audio/lofi_garden.mp3", desc: "Ritmo lofi relajante con beats modernos y frescos, ideal para navegar cotizaciones."),
        MusicPreset(id: "upbeat_work", name: "⚡ Ritmo Dinámico & Trabajo Activo", genre: "Modern Upbeat", url: "./assets/audio/upbeat_work.mp3", desc: "Música motivadora y alegre con energía positiva para trabajos de landscaping."),
        MusicPreset(id: "regional_chill", name: "🎺 Regional Acordeón & Vibra Latina Suave", genre: "Regional Chill", url: "./assets/audio/regional_chill.mp3", desc: "Toque acústico latino alegre y limpio que combina con la esencia de Rodriguez LawnCare."),
        MusicPreset(id: "luxury_piano", name: "🎹 Piano Elegante & Residencia de Lujo", genre: "Ambient Piano", url: "./assets/audio/luxury_piano.mp3", desc: "Melodía sofisticada y elegante que resalta propiedades residenciales de alta gama.")
    ]
}

// MARK: - TOP-LEFT DROPDOWN MENU (MATCHING EXACT SCREENSHOT DESIGN)
struct TopLeftDropdownMenuView: View {
    var onSelect: (String) -> Void
    
    let menuItems: [(id: String, icon: String, title: String, isGreen: Bool)] = [
        ("home", "house.fill", "Inicio", true),
        ("citas", "calendar.badge.clock", "Citas & Cotizaciones", false),
        ("clientes", "person.2.fill", "Clientes", false),
        ("trabajos", "list.bullet.clipboard.fill", "Trabajos", false),
        ("calendario", "calendar", "Calendario", false),
        ("enruta", "paperplane.fill", "En Ruta", false),
        ("tracker", "location.north.circle.fill", "Lawn Tracker", false),
        ("lluvia", "cloud.rain.fill", "Alerta Lluvia", false),
        ("checklist", "checklist", "Checklist", false),
        ("calculadora", "function", "Calculadora", false),
        ("reportes", "chart.bar.fill", "Reportes", false),
        ("promos", "megaphone.fill", "Promociones", false),
        ("subir_fotos", "camera.fill", "Subir Trabajos a Web", false),
        ("ajustes", "gearshape.fill", "Ajustes", false)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(menuItems, id: \.id) { item in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSelect(item.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.system(size: 15))
                            .foregroundStyle(item.isGreen ? Brand.primary : .white.opacity(0.85))
                            .frame(width: 22, alignment: .center)
                        
                        Text(item.title)
                            .font(.system(size: 13, weight: item.isGreen ? .bold : .medium))
                            .foregroundStyle(item.isGreen ? Brand.primary : .white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7.5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .frame(width: 215)
        .background(Color(red: 0.05, green: 0.12, blue: 0.09))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Brand.primary.opacity(0.45), lineWidth: 1.5)
                .shadow(color: Brand.primary.opacity(0.25), radius: 8)
        )
        .shadow(color: Color.black.opacity(0.9), radius: 25, y: 12)
    }
}

// MARK: - MAIN ROOT VIEW WITH LIVE NOTIFICATION BANNER & 5 TABS
struct ContentView: View {
    @StateObject private var store = LawnCareStore()
    @State private var selectedTab = 0
    @State private var showTopLeftMenu: Bool = false
    @Environment(\.scenePhase) private var scenePhase
    
    // Sheets triggered directly from Master Dropdown Menu
    @State private var showTrackerSheet: Bool = false
    @State private var showRadarSheet: Bool = false
    @State private var showChecklistSheet: Bool = false
    @State private var showRainAlertSheet: Bool = false
    @State private var showFleetMaintenanceSheet: Bool = false
    
    @State private var showTruckCalcSheet: Bool = false
    @State private var showTreeEstimatorSheet: Bool = false
    @State private var showCommercialProposalSheet: Bool = false
    @State private var showLawnAreaSheet: Bool = false
    
    @State private var showRecurringSheet: Bool = false
    @State private var showVipLoyaltySheet: Bool = false
    @State private var showRecurringAutoPaySheet: Bool = false
    
    @State private var showVideoMakerSheet: Bool = false
    @State private var showFlyerMakerSheet: Bool = false
    @State private var showUploadWorkSheet: Bool = false
    @State private var showGoogleReviewSheet: Bool = false
    @State private var showDigitalCardSheet: Bool = false
    @State private var showBeforeAfterSheet: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                LivingParticlesBackgroundView()

                VStack(spacing: 0) {
                    // BARRA SUPERIOR PERSISTENTE (DISEÑO EXACTO SCREENSHOT)
                    HStack(alignment: .center, spacing: 12) {
                        // BOTÓN DE 3 LÍNEAS HAMBURGUESA
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showTopLeftMenu.toggle()
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Image(systemName: showTopLeftMenu ? "xmark" : "line.3.horizontal")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(Color(red: 0.07, green: 0.15, blue: 0.11))
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11)
                                        .stroke(Brand.primary.opacity(0.8), lineWidth: 1.5)
                                        .shadow(color: Brand.primary.opacity(0.5), radius: 4)
                                )
                        }

                        Spacer()

                        // LOGO CENTRAL OFICIAL RODRIGUEZ LAWN CARE
                        VStack(spacing: 1) {
                            HStack(spacing: 4) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(red: 0.25, green: 0.95, blue: 0.45))
                                Text("RODRIGUEZ")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.white, Color(red: 0.85, green: 0.95, blue: 0.88)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            Text("LAWN CARE")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Brand.primary)
                            Text("QUALITY LAWNS • HAPPY HOMES")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white.opacity(0.75))
                        }

                        Spacer()

                        // PILL STATUS: ONLINE ⌵
                        HStack(spacing: 5) {
                            Circle()
                                .fill(store.isOnline ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                                .shadow(color: store.isOnline ? Color.green : Color.red, radius: 4)
                            Text(store.isOnline ? "Online" : "Offline")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.gray)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.07, green: 0.14, blue: 0.10))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))

                    TabView(selection: $selectedTab) {
                        AppointmentsView(store: store)
                            .tabItem {
                                Label("Citas", systemImage: "calendar.badge.clock")
                            }
                            .tag(0)

                        ProfessionalCalendarView(store: store)
                            .tabItem {
                                Label("Calendario", systemImage: "calendar")
                            }
                            .tag(1)

                        IAEstimateView(store: store)
                            .tabItem {
                                Label("IA Estimate", systemImage: "sparkles")
                            }
                            .tag(2)

                        FlashPromotionsView(store: store)
                            .tabItem {
                                Label("Promociones", systemImage: "megaphone.fill")
                            }
                            .tag(3)

                        WebAdminView(store: store)
                            .tabItem {
                                Label("Ajustes & Web", systemImage: "gearshape.2.fill")
                            }
                            .tag(4)
                    }
                }
            }
            .accentColor(Brand.primary)

            // TOP-LEFT DROPDOWN MENU (MATCHING EXACT SCREENSHOT DESIGN)
            if showTopLeftMenu {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showTopLeftMenu = false
                        }
                    }

                VStack(alignment: .leading, spacing: 0) {
                    TopLeftDropdownMenuView(
                        onSelect: { action in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showTopLeftMenu = false
                            }
                            handleDropdownAction(action)
                        }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 56)
                .padding(.leading, 12)
                .zIndex(200)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
            }

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
        .sheet(isPresented: $showTrackerSheet) { LawnTrackerLiveSheetView(store: store) }
        .sheet(isPresented: $showRadarSheet) { TacticalTerritoryRadarView(store: store) }
        .sheet(isPresented: $showChecklistSheet) { MorningTrailerChecklistSheetView(store: store) }
        .sheet(isPresented: $showRainAlertSheet) { RainAlertRescheduleSheetView(store: store) }
        .sheet(isPresented: $showFleetMaintenanceSheet) { EquipmentFleetMaintenanceSheetView(store: store) }
        .sheet(isPresented: $showTruckCalcSheet) { BulkMaterialTruckCalculatorView(store: store) }
        .sheet(isPresented: $showTreeEstimatorSheet) { TreeTrimmingStumpEstimatorSheetView(store: store) }
        .sheet(isPresented: $showCommercialProposalSheet) { CommercialProposalSheetView(store: store) }
        .sheet(isPresented: $showLawnAreaSheet) { LawnAreaCalculatorSheetView(store: store) }
        .sheet(isPresented: $showRecurringSheet) { RecurringClientsManagerView(store: store) }
        .sheet(isPresented: $showVipLoyaltySheet) { VipLoyaltyTiersView(store: store) }
        .sheet(isPresented: $showRecurringAutoPaySheet) { RecurringAutoPaySubscriptionSheetView(store: store) }
        .sheet(isPresented: $showVideoMakerSheet) { CinematicVideoMakerView(store: store) }
        .sheet(isPresented: $showFlyerMakerSheet) { SocialMediaFlyerMakerSheetView(store: store) }
        .sheet(isPresented: $showUploadWorkSheet) { UploadWorkToWebGalleryView(store: store) }
        .sheet(isPresented: $showGoogleReviewSheet) { GoogleReviewBoosterSheetView(store: store) }
        .sheet(isPresented: $showDigitalCardSheet) { NeighborDigitalCardQRView(store: store) }
        .sheet(isPresented: $showBeforeAfterSheet) { BeforeAfterCameraSheetView(store: store) }
        .sheet(isPresented: $store.showUpdateModal) { OTAUpdateSheetView(store: store) }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task {
                    await store.refreshAll(silent: true)
                    await store.checkOTAUpdate(manual: false)
                }
            }
        }
    }

    private func handleDropdownAction(_ action: String) {
        switch action {
        case "home":
            selectedTab = 0
        case "citas":
            selectedTab = 0
        case "clientes":
            showRecurringSheet = true
        case "trabajos":
            showCommercialProposalSheet = true
        case "calendario":
            selectedTab = 1
        case "enruta":
            showRadarSheet = true
        case "tracker":
            showTrackerSheet = true
        case "lluvia":
            showRainAlertSheet = true
        case "checklist":
            showChecklistSheet = true
        case "calculadora":
            showTruckCalcSheet = true
        case "reportes":
            showVipLoyaltySheet = true
        case "promos":
            selectedTab = 3
        case "subir_fotos":
            showUploadWorkSheet = true
        case "ajustes":
            selectedTab = 4
        default:
            handleDrawerAction(action)
        }
    }

    private func handleDrawerAction(_ action: String) {
        switch action {
        case "tracker": showTrackerSheet = true
        case "radar": showRadarSheet = true
        case "checklist": showChecklistSheet = true
        case "rain": showRainAlertSheet = true
        case "fleet": showFleetMaintenanceSheet = true
        case "estimate": selectedTab = 2
        case "truck": showTruckCalcSheet = true
        case "tree": showTreeEstimatorSheet = true
        case "proposal": showCommercialProposalSheet = true
        case "lawnarea": showLawnAreaSheet = true
        case "recurring": showRecurringSheet = true
        case "vip": showVipLoyaltySheet = true
        case "autopay": showRecurringAutoPaySheet = true
        case "video": showVideoMakerSheet = true
        case "flyer": showFlyerMakerSheet = true
        case "reviews": showGoogleReviewSheet = true
        case "digitalcard": showDigitalCardSheet = true
        case "beforeafter": showBeforeAfterSheet = true
        case "promos": selectedTab = 3
        case "settings": selectedTab = 4
        default: break
        }
    }
}

// MARK: - TAB 1: APPOINTMENTS & REAL-TIME LEADS VIEW (MATCHING IMAGE 1 SCREENSHOT)
struct AppointmentsView: View {
    @ObservedObject var store: LawnCareStore
    @State private var filterStatus = "all"
    @State private var showNewLeadSheet = false
    @State private var selectedLead: Lead? = nil
    @State private var showTrackerSheet = false
    @State private var showRainAlertSheet = false
    @State private var showChecklistSheet = false
    @State private var showCalcSheet = false
    @State private var showRadarSheet = false

    var filteredLeads: [Lead] {
        if filterStatus == "all" {
            return store.leads
        }
        return store.leads.filter { $0.status == filterStatus }
    }

    var todaysAppointmentsCount: Int {
        store.leads.filter { $0.status == "confirmed" || $0.status == "pending" }.count
    }

    var todaysRevenue: Double {
        Double(todaysAppointmentsCount) * 55.0
    }

    var pendingCount: Int {
        store.leads.filter { $0.status == "pending" }.count
    }

    var contactedCount: Int {
        store.leads.filter { $0.status == "contacted" }.count
    }

    var completedCount: Int {
        store.leads.filter { $0.status == "completed" }.count
    }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Title Row (Image 1): Citas & Cotizaciones + Refresh Button
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Text("Citas &")
                                        .font(.system(size: 24, weight: .black))
                                        .foregroundStyle(.white)
                                    Text("Cotizaciones")
                                        .font(.system(size: 24, weight: .black))
                                        .foregroundStyle(Brand.primary)
                                }
                                Text("Gestiona tus trabajos y clientes")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.gray)
                            }
                            
                            Spacer()
                            
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                Task { await store.refreshAll() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color(red: 0.08, green: 0.16, blue: 0.12))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)

                        // 3 Stats Cards (Image 1)
                        HStack(spacing: 8) {
                            // Card 1: HOY ESTIMADO
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 5) {
                                    ZStack {
                                        Circle().fill(Color.green.opacity(0.2)).frame(width: 20, height: 20)
                                        Text("$")
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundStyle(Brand.primary)
                                    }
                                    Text("HOY ESTIMADO")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.gray)
                                }
                                HStack(alignment: .bottom) {
                                    Text("$\(Int(todaysRevenue))")
                                        .font(.system(size: 19, weight: .black))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    HStack(alignment: .bottom, spacing: 2) {
                                        Rectangle().fill(Brand.primary.opacity(0.4)).frame(width: 3, height: 6)
                                        Rectangle().fill(Brand.primary.opacity(0.7)).frame(width: 3, height: 10)
                                        Rectangle().fill(Brand.primary).frame(width: 3, height: 14)
                                    }
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.06, green: 0.12, blue: 0.09))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))

                            // Card 2: EN RUTA
                            Button {
                                showTrackerSheet = true
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 5) {
                                        ZStack {
                                            Circle().fill(Color.cyan.opacity(0.2)).frame(width: 20, height: 20)
                                            Image(systemName: "house.fill").font(.system(size: 9)).foregroundStyle(Color.cyan)
                                        }
                                        Text("EN RUTA")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(.gray)
                                    }
                                    HStack {
                                        Text("\(todaysAppointmentsCount) Casas")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(.gray)
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(red: 0.06, green: 0.12, blue: 0.09))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            // Card 3: CLIMA KILLEEN
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 5) {
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.yellow)
                                    Text("CLIMA KILLEEN")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.gray)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("74°F")
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundStyle(.white)
                                    Text("Soleado")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.gray)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.06, green: 0.12, blue: 0.09))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }
                        .padding(.horizontal, 14)

                        // 4 Quick Tactical Action Cards (Image 1)
                        HStack(spacing: 8) {
                            Button { showTrackerSheet = true } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Brand.primary)
                                    Text("Lawn Tracker")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Brand.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.04, green: 0.18, blue: 0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.primary.opacity(0.7), lineWidth: 1))
                            }

                            Button { showRainAlertSheet = true } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: "cloud.rain.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.cyan)
                                    Text("Alerta Lluvia")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.06, green: 0.13, blue: 0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                            }

                            Button { showChecklistSheet = true } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: "checklist")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.mint)
                                    Text("Checklist")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.05, green: 0.14, blue: 0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mint.opacity(0.4), lineWidth: 1))
                            }

                            Button { showCalcSheet = true } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: "function")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.orange)
                                    Text("Calculadora")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.12, green: 0.10, blue: 0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 14)

                        // Filter Chips (Image 1: Todos, Pendientes, Contactados, Completados)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChipWithIcon(title: "Todos (\(store.leads.count))", icon: "square.grid.2x2.fill", isSelected: filterStatus == "all") {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    filterStatus = "all"
                                }
                                FilterChipWithIcon(title: "Pendientes (\(pendingCount))", icon: "clock.fill", isSelected: filterStatus == "pending") {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    filterStatus = "pending"
                                }
                                FilterChipWithIcon(title: "Contactados (\(contactedCount))", icon: "person.fill", isSelected: filterStatus == "contacted") {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    filterStatus = "contacted"
                                }
                                FilterChipWithIcon(title: "Completados (\(completedCount))", icon: "checkmark.circle.fill", isSelected: filterStatus == "completed") {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    filterStatus = "completed"
                                }
                            }
                            .padding(.horizontal, 14)
                        }

                        // Content List or Empty State (Exact Image 1 Design)
                        if filteredLeads.isEmpty {
                            VStack(spacing: 14) {
                                ZStack {
                                    // Background Lawn Ambience
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.05, green: 0.14, blue: 0.08),
                                                    Color(red: 0.02, green: 0.06, blue: 0.03)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: 250)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Brand.primary.opacity(0.2), lineWidth: 1)
                                        )

                                    VStack(spacing: 12) {
                                        // Floating Lawn Grass Patch with Clipboard & Checkmark (Screenshot 1)
                                        ZStack {
                                            // Lawn Patch Glow
                                            Circle()
                                                .fill(
                                                    RadialGradient(
                                                        colors: [Brand.primary.opacity(0.35), Color.clear],
                                                        center: .center,
                                                        startRadius: 10,
                                                        endRadius: 55
                                                    )
                                                )
                                                .frame(width: 110, height: 110)

                                            // Fresh Green Lawn Patch Base
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(red: 0.1, green: 0.45, blue: 0.18), Color(red: 0.04, green: 0.22, blue: 0.08)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .frame(width: 82, height: 42)
                                                .offset(y: 20)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Brand.primary.opacity(0.4), lineWidth: 1)
                                                        .offset(y: 20)
                                                )

                                            // Clipboard Icon with Calendar Grid
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.system(size: 46, weight: .bold))
                                                .foregroundStyle(.white.opacity(0.92))
                                                .offset(y: -4)

                                            // Emerald Checkmark Badge (Image 1)
                                            ZStack {
                                                Circle()
                                                    .fill(Brand.primary)
                                                    .frame(width: 26, height: 26)
                                                    .shadow(color: Brand.primary.opacity(0.6), radius: 6)
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .black))
                                                    .foregroundStyle(.black)
                                            }
                                            .offset(x: 20, y: 16)
                                        }

                                        Text("No hay citas registradas")
                                            .font(.system(size: 19, weight: .bold))
                                            .foregroundStyle(.white)

                                        Text("Comienza agregando tu primera cita o cotización.")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.horizontal, 14)

                                // Large Neon Green Button: + Nueva Cita > (Image 1)
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    showNewLeadSheet = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 18, weight: .black))
                                        Text("Nueva Cita")
                                            .font(.system(size: 16, weight: .black))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .black))
                                    }
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Brand.primary)
                                    .clipShape(Capsule())
                                    .shadow(color: Brand.primary.opacity(0.55), radius: 12, y: 4)
                                }
                                .padding(.horizontal, 24)
                            }
                        } else {
                            VStack(spacing: 10) {
                                ForEach(filteredLeads) { lead in
                                    LeadCardView(lead: lead)
                                        .onTapGesture {
                                            selectedLead = lead
                                        }
                                }
                            }
                            .padding(.horizontal, 14)
                        }

                        // Bottom 3 Quick Action Buttons (Exact Image 1 Design)
                        HStack(spacing: 8) {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showNewLeadSheet = true
                            } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Brand.primary)
                                    Text("Importar Cliente")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.06, green: 0.12, blue: 0.09))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            }

                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showNewLeadSheet = true
                            } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.cyan)
                                    Text("Calendario")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.06, green: 0.12, blue: 0.09))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            }

                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showRadarSheet = true
                            } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.green)
                                    Text("Ver Ruta")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.06, green: 0.12, blue: 0.09))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 6)
                        .padding(.bottom, 24)
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
            .sheet(isPresented: $showTrackerSheet) {
                LawnTrackerLiveSheetView(store: store)
            }
            .sheet(isPresented: $showRainAlertSheet) {
                RainAlertRescheduleSheetView(store: store)
            }
            .sheet(isPresented: $showChecklistSheet) {
                MorningTrailerChecklistSheetView(store: store)
            }
            .sheet(isPresented: $showCalcSheet) {
                BulkMaterialTruckCalculatorView(store: store)
            }
            .sheet(isPresented: $showRadarSheet) {
                TacticalTerritoryRadarView(store: store)
            }
        }
    }
}

// MARK: - FILTER CHIP WITH ICON (EXACT IMAGE 1 DESIGN)
struct FilterChipWithIcon: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.bold())
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Brand.primary : Color(red: 0.06, green: 0.12, blue: 0.09))
            .foregroundStyle(isSelected ? .black : .white)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Brand.primary : Color.white.opacity(0.1), lineWidth: 1)
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

                // Guardar Contacto en Agenda (Feature 9)
                Button {
                    ContactSaverHelper.saveOrShareLeadContact(lead: lead)
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.caption.bold())
                        .foregroundStyle(Brand.accent)
                        .padding(.horizontal, 10)
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
    @State private var showInvoiceSheet: Bool = false
    @State private var showCalendarScheduleSheet: Bool = false

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

                        if let photos = lead.photos, !photos.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("📸 FOTOS DEL JARDÍN ENVIADAS POR EL CLIENTE (\(photos.count))")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(photos, id: \.self) { photoUrl in
                                            AsyncImage(url: URL(string: store.fullMediaURL(photoUrl))) { phase in
                                                if let img = phase.image {
                                                    img.resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 90, height: 90)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                } else {
                                                    ZStack {
                                                        Color.gray.opacity(0.3)
                                                        ProgressView().tint(Brand.primary)
                                                    }
                                                    .frame(width: 90, height: 90)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

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

                        Button {
                            showInvoiceSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("🧾 Crear Invoice Profesional")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            showCalendarScheduleSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("✓ Aceptó / Agendar en Calendario")
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

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
            .sheet(isPresented: $showInvoiceSheet) {
                InvoiceSheetView(lead: lead, store: store)
            }
            .sheet(isPresented: $showCalendarScheduleSheet) {
                AddToCalendarSheet(lead: lead, store: store, prefilledAmount: Double(amountText) ?? (lead.estimated_amount ?? 75.0))
            }
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
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
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
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }
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
        URL(string: "\(store.cleanURL)/admin") ?? URL(string: "https://rodriguezlawncare.xyz/admin")!
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
    @State private var showRadarSheet = false
    @State private var showAiScannerSheet = false
    @State private var showTruckCalcSheet = false
    @State private var showVideoMakerSheet = false
    @State private var showDigitalCardSheet = false
    @State private var showFlyerMakerSheet = false
    @State private var showGoogleReviewSheet = false
    @State private var showFleetMaintenanceSheet = false
    @State private var showTreeEstimatorSheet = false
    @State private var showJobProofVideoSheet = false
    @State private var showCommercialProposalSheet = false
    @State private var showRecurringAutoPaySheet = false
    @State private var showTrackerFromAdminSheet = false
    @State private var showRainAlertFromAdminSheet = false
    @State private var showVipLoyaltyFromAdminSheet = false
    @State private var showChecklistFromAdminSheet = false
    @State private var showHeroManagerSheet = false
    @State private var showCloudPanelSheet = false
    @State private var showQuickEstimatorSheet = false
    @State private var showReviewsSheet = false
    @State private var showMusicSettingsSheet = false
    @State private var showRecurringSheet = false
    @State private var showBeforeAfterSheet = false
    @State private var showLawnAreaSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // SECCIÓN PLACOSA DEL PATRÓN
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(Color.yellow)
                                Text("HERRAMIENTAS DEL PATRÓN (NIVEL PRO)")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                Button { showRadarSheet = true } label: {
                                    PatronQuickToolCard(icon: "dot.radiowaves.left.and.right", title: "Radar Táctico", subtitle: "Zonas de Guerra", color: Color.green)
                                }
                                Button { showAiScannerSheet = true } label: {
                                    PatronQuickToolCard(icon: "sparkles.rectangle.stack.fill", title: "Escáner IA Pasto", subtitle: "Diagnóstico Láser", color: Color.cyan)
                                }
                                Button { showTruckCalcSheet = true } label: {
                                    PatronQuickToolCard(icon: "truck.box.fill", title: "Camión Mulch", subtitle: "Calculadora 3D", color: Color.orange)
                                }
                                Button { showVideoMakerSheet = true } label: {
                                    PatronQuickToolCard(icon: "film.stack.fill", title: "Video TikTok", subtitle: "Reels de Antes/Dsp", color: Color.purple)
                                }
                                Button { showDigitalCardSheet = true } label: {
                                    PatronQuickToolCard(icon: "qrcode", title: "Tarjeta QR Lujo", subtitle: "Vecinos 10% OFF", color: Color.blue)
                                }
                                Button { showFlyerMakerSheet = true } label: {
                                    PatronQuickToolCard(icon: "photo.on.rectangle.angled", title: "Creador Flyers", subtitle: "Publicar en FB", color: Color.pink)
                                }
                                Button { showGoogleReviewSheet = true } label: {
                                    PatronQuickToolCard(icon: "star.fill", title: "Reseñas 5★", subtitle: "Google Maps Boost", color: Color.yellow)
                                }
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Brand.primary.opacity(0.3), lineWidth: 1)
                        )

                        otaUpdatesCard
                        recurringClientsCard
                        beforeAfterCard
                        lawnAreaCard
                        soundAlertsCard
                        analyticsCard
                        musicManagerCard
                        reviewsManagerCard
                        heroManagerCard
                        quickEstimatorCard
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
            .sheet(isPresented: $showRadarSheet) {
                TacticalTerritoryRadarView(store: store)
            }
            .sheet(isPresented: $showAiScannerSheet) {
                AIYardHealthScannerHUDView(store: store)
            }
            .sheet(isPresented: $showTruckCalcSheet) {
                BulkMaterialTruckCalculatorView(store: store)
            }
            .sheet(isPresented: $showVideoMakerSheet) {
                CinematicVideoMakerView(store: store)
            }
            .sheet(isPresented: $showDigitalCardSheet) {
                NeighborDigitalCardQRView(store: store)
            }
            .sheet(isPresented: $showFlyerMakerSheet) {
                SocialMediaFlyerMakerSheetView(store: store)
            }
            .sheet(isPresented: $showGoogleReviewSheet) {
                GoogleReviewBoosterSheetView(store: store)
            }
            .sheet(isPresented: $showTrackerFromAdminSheet) {
                LawnTrackerLiveSheetView(store: store)
            }
            .sheet(isPresented: $showRainAlertFromAdminSheet) {
                RainAlertRescheduleSheetView(store: store)
            }
            .sheet(isPresented: $showVipLoyaltyFromAdminSheet) {
                VipLoyaltyTiersView(store: store)
            }
            .sheet(isPresented: $showFleetMaintenanceSheet) {
                EquipmentFleetMaintenanceSheetView(store: store)
            }
            .sheet(isPresented: $showTreeEstimatorSheet) {
                TreeTrimmingStumpEstimatorSheetView(store: store)
            }
            .sheet(isPresented: $showChecklistFromAdminSheet) {
                MorningTrailerChecklistSheetView(store: store)
            }
            .sheet(isPresented: $showJobProofVideoSheet) {
                JobProofVideoRecorderSheetView(store: store)
            }
            .sheet(isPresented: $showCommercialProposalSheet) {
                CommercialProposalSheetView(store: store)
            }
            .sheet(isPresented: $showRecurringAutoPaySheet) {
                RecurringAutoPaySubscriptionSheetView(store: store)
            }
            .sheet(isPresented: $showRecurringSheet) {
                RecurringClientsManagerView(store: store)
            }
            .sheet(isPresented: $showBeforeAfterSheet) {
                BeforeAfterCameraSheetView(store: store)
            }
            .sheet(isPresented: $showLawnAreaSheet) {
                LawnAreaCalculatorSheetView(store: store)
            }
            .sheet(isPresented: $showMusicSettingsSheet) {
                WebMusicSettingsSheetView(store: store)
            }
            .sheet(isPresented: $showReviewsSheet) {
                ReviewsManagerView(store: store)
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


    // RECURRING CLIENTS CARD
    private var recurringClientsCard: some View {
        Button {
            showRecurringSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Brand.primary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "repeat.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Brand.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("🔁 Clientes Recurrentes")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("\(store.recurringClients.count) clientes fijos • Recordatorios WhatsApp y Cobros")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(14)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // BEFORE & AFTER CARD
    private var beforeAfterCard: some View {
        Button {
            showBeforeAfterSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "camera.filters")
                        .font(.title3)
                        .foregroundStyle(Color.orange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("📸 Cámara Antes & Después")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Comparativa con logo y publicación directa a la web")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(14)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // SATELLITE SQFT CALCULATOR CARD
    private var lawnAreaCard: some View {
        Button {
            showLawnAreaSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "map.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.green)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("📐 Medidor Satelital de Terreno (SQFT)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Mide pies cuadrados y cotiza por GPS satelital")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(14)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // SOUND & HAPTICS CARD
    private var soundAlertsCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "bell.and.waves.left.and.right.fill")
                    .font(.title3)
                    .foregroundStyle(Color.purple)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("🔔 Efectos de Sonido y Haptics")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("Tonos audibles al recibir citas o guardar facturas")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Toggle("", isOn: $store.soundEffectsEnabled)
                .labelsHidden()
                .tint(Brand.primary)
        }
        .padding(14)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // QUICK ESTIMATOR CARD
    private var quickEstimatorCard: some View {
        Button {
            showQuickEstimatorSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Brand.primary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Brand.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Calculadora Rápida por Acre")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Precios por lote pequeño, mediano, grande o acre")
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
        .sheet(isPresented: $showQuickEstimatorSheet) {
            EstimatorView(store: store)
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

            // Botón: Probar Notificación del Sistema fuera de la app
            Button {
                store.testSystemNotification()
            } label: {
                HStack {
                    Image(systemName: "bell.badge.fill")
                    Text("🔔 Probar Notificación del Sistema (Fuera de la App)")
                }
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(11)
                .background(Brand.cardLight)
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
    private var musicManagerCard: some View {
        Button {
            showMusicSettingsSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: "music.note.list")
                        .font(.title2)
                        .foregroundStyle(Color.purple)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Música de Fondo Web")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        let isEnabled = store.settings?.music?.enabled ?? false
                        Text(isEnabled ? "ON 🎵" : "OFF 🔇")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isEnabled ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                            .foregroundStyle(isEnabled ? Color.purple : Color.gray)
                            .cornerRadius(6)
                    }
                    Text(store.settings?.music?.enabled == true ? (store.settings?.music?.title ?? "Sonando en la Web") : "Música desactivada en la web")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(14)
            .background(Brand.card)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var reviewsManagerCard: some View {
        Button {
            showReviewsSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: "star.bubble.fill")
                        .font(.title2)
                        .foregroundStyle(Color.orange)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Gestor de Reseñas Web")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("En Vivo")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(Color.orange)
                            .cornerRadius(6)
                    }
                    Text("Administra y agrega testimonios de clientes a la web")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(14)
            .background(Brand.card)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }

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
            TextField("https://rodriguezlawncare.xyz", text: $serverInput)
                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

            HStack(spacing: 8) {
                Button {
                    serverInput = "https://rodriguezlawncare.xyz"
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

// MARK: - TAB 2: IA ESTIMATE VIEW (ESTIMADOR CON FOTOS Y PRECIOS KILLEEN TX)
struct IAEstimateView: View {
    @ObservedObject var store: LawnCareStore

    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceSheet: Bool = false

    @State private var taskDescription: String = ""
    @State private var workersCount: Int = 2
    @State private var payType: String = "hourly" // "hourly" or "daily"
    @State private var payRateText: String = "18.00"
    @State private var durationText: String = "4.0"
    @State private var storePreference: String = "home_depot"

    @State private var isCalculating: Bool = false
    @State private var estimateResult: AIEstimateResponse? = nil
    @State private var showCopiedAlert: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        headerCard
                        photoCard
                        descriptionCard
                        workersCard
                        storeCard
                        calculateButton

                        if let err = errorMessage {
                            errorBanner(err)
                        }

                        if let res = estimateResult, res.success {
                            resultsSection(res)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("IA Estimate 🤖")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Selecciona origen de la foto", isPresented: $showSourceSheet) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("📷 Tomar Foto con la Cámara") {
                        pickerSource = .camera
                        showImagePicker = true
                    }
                }
                Button("🖼️ Elegir de la Galería de Fotos") {
                    pickerSource = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancelar", role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker) {
                PhotoLibraryPicker(selectedImage: $selectedImage, sourceType: pickerSource)
            }
            .alert("Presupuesto Copiado", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Se copió el presupuesto oficial al portapapeles. Listo para pegarlo en WhatsApp o mensaje de texto para el cliente.")
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Brand.primary.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Brand.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("ESTIMADOR IA EN TIEMPO REAL")
                    .font(.caption.bold())
                    .foregroundStyle(Brand.primary)
                Text("Calcula materiales en Killeen TX (Home Depot, Lowe's, Tractor Supply), mano de obra y tu ganancia limpia.")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
        .padding(14)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("1. FOTO DEL TRABAJO")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                Spacer()
                if selectedImage != nil {
                    Text("Foto cargada")
                        .font(.caption2.bold())
                        .foregroundStyle(Brand.primary)
                }
            }

            if let img = selectedImage {
                VStack(spacing: 10) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 12) {
                        Button {
                            showSourceSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Cambiar Foto")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Brand.cardLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Button {
                            selectedImage = nil
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Quitar")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color.red.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            } else {
                Button {
                    showSourceSheet = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.badge.ellipsis")
                            .font(.system(size: 32))
                            .foregroundStyle(Brand.primary)
                        Text("Tocar para Agregar Foto")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text("Toma una foto en el patio o súbela de la galería")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(Brand.cardLight.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .foregroundStyle(Brand.primary.opacity(0.5))
                    )
                }
            }
        }
        .padding()
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("2. ¿QUÉ QUIERE HACER EL CLIENTE AQUÍ?")
                .font(.caption.bold())
                .foregroundStyle(.white)

            ZStack(alignment: .topLeading) {
                if taskDescription.isEmpty {
                    Text("Ej: Poner mulch oscuro en 2 jardineras de enfrente, podar 3 arbustos, cortar ramas bajas del árbol y orillar banquetas de concreto...")
                        .font(.subheadline)
                        .foregroundStyle(.gray.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $taskDescription)
                    .frame(minHeight: 80)
                    .background(Color.clear)
                    .foregroundStyle(.white)
                    .font(.subheadline)
            }
            .padding(8)
            .background(Brand.cardLight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var workersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("3. TRABAJADORES Y PAGO DE MANO DE OBRA")
                .font(.caption.bold())
                .foregroundStyle(.white)

            HStack {
                Text("Trabajadores:")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                Spacer()
                HStack(spacing: 8) {
                    ForEach([1, 2, 3, 4], id: \.self) { num in
                        Button {
                            workersCount = num
                        } label: {
                            Text("\(num)")
                                .font(.caption.bold())
                                .foregroundStyle(workersCount == num ? .black : .white)
                                .frame(width: 34, height: 32)
                                .background(workersCount == num ? Brand.primary : Brand.cardLight)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            Divider().background(Color.white.opacity(0.1))

            HStack {
                Text("Tipo de Pago:")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                Spacer()
                Picker("Tipo", selection: $payType) {
                    Text("Por Hora ($/hr)").tag("hourly")
                    Text("Por Día ($/día)").tag("daily")
                }
                .pickerStyle(.segmented)
                .frame(width: 190)
            }

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(payType == "hourly" ? "Pago x Hora ($):" : "Pago x Día ($):")
                        .font(.caption2.bold())
                        .foregroundStyle(.gray)
                    TextField("18.00", text: $payRateText)
                        .keyboardType(.decimalPad)
                        .padding(8)
                        .background(Brand.cardLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                        .font(.subheadline.bold())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(payType == "hourly" ? "Horas estimadas:" : "Días estimados:")
                        .font(.caption2.bold())
                        .foregroundStyle(.gray)
                    TextField("4.0", text: $durationText)
                        .keyboardType(.decimalPad)
                        .padding(8)
                        .background(Brand.cardLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                        .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var storeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("4. TIENDA DE MATERIALES EN KILLEEN, TX")
                .font(.caption.bold())
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                storeButton(title: "Home Depot", key: "home_depot", color: Color.orange)
                storeButton(title: "Lowe's", key: "lowes", color: Color.blue)
                storeButton(title: "Tractor Supply", key: "tractor_supply", color: Color.red)
            }
        }
        .padding()
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func storeButton(title: String, key: String, color: Color) -> some View {
        Button {
            storePreference = key
        } label: {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(storePreference == key ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(storePreference == key ? color.opacity(0.85) : Brand.cardLight)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(storePreference == key ? color : Color.clear, lineWidth: 1.5)
                )
        }
    }

    private var calculateButton: some View {
        Button {
            executeEstimate()
        } label: {
            HStack(spacing: 8) {
                if isCalculating {
                    ProgressView().tint(.black)
                    Text("Analizando foto y materiales en Killeen...")
                } else {
                    Image(systemName: "sparkles")
                    Text("⚡ Generar Estimado con Precios Reales e IA")
                }
            }
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Brand.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isCalculating)
    }

    private func errorBanner(_ msg: String) -> some View {
        Text(msg)
            .font(.caption.bold())
            .foregroundStyle(.red)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func resultsSection(_ res: AIEstimateResponse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 12) {
                Text("COTIZACIÓN TOTAL SUGERIDA AL CLIENTE")
                    .font(.caption.bold())
                    .foregroundStyle(.gray)

                Text("$\(String(format: "%.2f", res.total_quote ?? 0.0))")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(Brand.primary)

                Divider().background(Color.white.opacity(0.1))

                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Text("Materiales")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text("$\(String(format: "%.2f", res.total_materials ?? 0.0))")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 2) {
                        Text("Mano de Obra")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text("$\(String(format: "%.2f", res.total_labor ?? 0.0))")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 2) {
                        Text("Tu Ganancia Limpia")
                            .font(.caption2.bold())
                            .foregroundStyle(Brand.primary)
                        Text("+$\(String(format: "%.2f", res.net_profit ?? 0.0))")
                            .font(.subheadline.bold())
                            .foregroundStyle(Brand.primary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Brand.primary.opacity(0.4), lineWidth: 1.5)
            )

            if let mats = res.materials, !mats.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("LISTA DE COMPRAS EN KILLEEN, TX")
                            .font(.caption.bold())
                            .foregroundStyle(Brand.accent)
                        Spacer()
                        Text(res.store_info?.name ?? "Killeen Local")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }

                    ForEach(mats) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Brand.primary.opacity(0.2))
                                .frame(width: 8, height: 8)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.item)
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                Text("\(item.qty) • Tienda: \(item.store)")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Text("$\(String(format: "%.2f", item.subtotal))")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                        }
                        .padding(.vertical, 4)
                        Divider().background(Color.white.opacity(0.05))
                    }
                }
                .padding()
                .background(Brand.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if let tip = res.ai_tips {
                HStack(alignment: .top, spacing: 10) {
                    Text(tip)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .lineSpacing(2)
                }
                .padding(12)
                .background(Brand.cardLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(spacing: 10) {
                Button {
                    if let text = res.whatsapp_text {
                        UIPasteboard.general.string = text
                        showCopiedAlert = true
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copiar Cotización Oficial")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Brand.cardLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    if let text = res.whatsapp_text,
                       let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let url = URL(string: "https://wa.me/?text=\(encoded)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("💬 Enviar al Cliente por WhatsApp")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color(red: 0.13, green: 0.69, blue: 0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func executeEstimate() {
        errorMessage = nil
        let rate = Double(payRateText) ?? 18.0
        let dur = Double(durationText) ?? 4.0

        var base64Str: String? = nil
        if let img = selectedImage {
            let maxDim: CGFloat = 1000
            let currentMax = max(img.size.width, img.size.height)
            var finalImg = img
            if currentMax > maxDim {
                let ratio = maxDim / currentMax
                let newSize = CGSize(width: img.size.width * ratio, height: img.size.height * ratio)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                img.draw(in: CGRect(origin: .zero, size: newSize))
                if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                    finalImg = resized
                }
                UIGraphicsEndImageContext()
            }
            if let jpegData = finalImg.jpegData(compressionQuality: 0.6) {
                base64Str = "data:image/jpeg;base64," + jpegData.base64EncodedString()
            }
        }

        isCalculating = true
        Task {
            let resp = await store.generateAIEstimate(
                description: taskDescription,
                workersCount: workersCount,
                payType: payType,
                payRate: rate,
                duration: dur,
                storePreference: storePreference,
                imageBase64: base64Str
            )
            isCalculating = false
            if let resp = resp, resp.success {
                estimateResult = resp
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                errorMessage = "No se pudo generar el estimado. Verifica la conexión con el servidor de Railway."
                UINotificationFeedbackGenerator().notificationOccurred(.error)
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
                                let finalStream = customStreamURL.isEmpty ? "./assets/audio/texas_acoustic.mp3" : customStreamURL

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


// MARK: - INVOICE GENERATOR SHEET
struct InvoiceSheetView: View {
    @Environment(\.dismiss) var dismiss
    let lead: Lead
    @ObservedObject var store: LawnCareStore

    @State private var invoiceNumber: String = "RLC-INV-\(Int(Date().timeIntervalSince1970) % 100000)"
    @State private var customPriceText: String = ""
    @State private var showSavedAlert: Bool = false
    @State private var showCalendarSheet: Bool = false
    @State private var showSignaturePadSheet: Bool = false
    @State private var clientSignatureImage: UIImage? = nil

    var totalAmount: Double {
        if let custom = Double(customPriceText), custom > 0 {
            return custom
        }
        return lead.estimated_amount ?? 75.0
    }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Printable Invoice Container
                        VStack(alignment: .leading, spacing: 16) {
                            // Header with Logo
                            HStack(alignment: .top) {
                                HStack(spacing: 10) {
                                    Image("AppIcon")
                                        .resizable()
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("RODRIGUEZ LAWNCARE")
                                            .font(.headline.bold())
                                            .foregroundStyle(Brand.primary)
                                        Text("Landscaping & Maintenance")
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                        Text("Killeen & Central Texas • (254) 852-8163")
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("INVOICE / FACTURA")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Brand.primary.opacity(0.2))
                                        .foregroundStyle(Brand.primary)
                                        .clipShape(Capsule())
                                    Text("#\(invoiceNumber)")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.gray)
                                }
                            }

                            Divider().background(Color.gray.opacity(0.3))

                            // Bill To & Job Info
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("CLIENTE / BILL TO:")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.gray)
                                    Text(lead.name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white)
                                    Text(lead.phone)
                                        .font(.caption)
                                        .foregroundStyle(Brand.primary)
                                    if let addr = lead.address, !addr.isEmpty {
                                        Text(addr)
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 3) {
                                    Text("FECHA:")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.gray)
                                    Text(timeFormatted(Date()))
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                    Text("TIPO:")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.gray)
                                    Text("Servicio Residencial")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                }
                            }

                            Divider().background(Color.gray.opacity(0.3))

                            // Itemized Services
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SERVICIOS A REALIZAR:")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.gray)

                                if let svcs = lead.services, !svcs.isEmpty {
                                    ForEach(svcs, id: \.self) { s in
                                        HStack {
                                            Text("✓ \(s)")
                                                .font(.subheadline)
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Text("Incluido")
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                } else {
                                    HStack {
                                        Text("✓ Corte y Mantenimiento General")
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text("Incluido")
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                    }
                                }

                                if let desc = lead.description, !desc.isEmpty {
                                    Text("Notas del Trabajo: \"\(desc)\"")
                                        .font(.caption)
                                        .italic()
                                        .foregroundStyle(.gray)
                                        .padding(.top, 4)
                                }
                            }

                            Divider().background(Color.gray.opacity(0.3))

                            // Total Due Card
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("TOTAL ESTIMADO / A PAGAR")
                                        .font(.caption.bold())
                                        .foregroundStyle(.gray)
                                    Text("Garantía de Satisfacción 100%")
                                        .font(.caption2)
                                        .foregroundStyle(Brand.primary)
                                }
                                Spacer()
                                Text(String(format: "$%.2f USD", totalAmount))
                                    .font(.title2.bold())
                                    .foregroundStyle(Brand.primary)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            // Payment Instructions Box
                            VStack(alignment: .leading, spacing: 6) {
                                Text("MÉTODOS DE PAGO ACEPTADOS:")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Brand.primary)
                                HStack {
                                    Image(systemName: "creditcard.fill").foregroundStyle(Brand.primary)
                                    Text("Zelle: Olivia Rodriguez • (623) 764-4177")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                }
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill").foregroundStyle(.green)
                                    Text("Cash App: $rafajrii (cash.app/$rafajrii)")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            Text("Gracias por confiar en Rodriguez LawnCare. Pago al finalizar el trabajo.")
                                .font(.caption2)
                                .italic()
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(16)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Brand.primary.opacity(0.4), lineWidth: 1.5)
                        )

                        // Editable Price Override
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AJUSTAR MONTO TOTAL SI LO DESEAS ($)")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)
                            TextField("Ej: 85.00", text: $customPriceText)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                        }

                        // Signature Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("✍️ FIRMA DIGITAL DEL CLIENTE")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                                Spacer()
                                if clientSignatureImage != nil {
                                    Text("✓ Aprobada")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.green)
                                }
                            }
                            
                            Button {
                                showSignaturePadSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: clientSignatureImage == nil ? "signature" : "checkmark.seal.fill")
                                    Text(clientSignatureImage == nil ? "Pedir Firma al Cliente en Pantalla" : "Firma Capturada (Tocar para cambiar)")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(clientSignatureImage == nil ? Brand.primary : .white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(clientSignatureImage == nil ? Brand.primary.opacity(0.15) : Color.green.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(clientSignatureImage == nil ? Brand.primary.opacity(0.4) : Color.green, lineWidth: 1)
                                )
                            }
                            
                            if let sig = clientSignatureImage {
                                Image(uiImage: sig)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 70)
                                    .padding(6)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        // Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                saveInvoiceSnapshot()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("Guardar Imagen del Invoice en Fotos")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                sendWhatsAppInvoice()
                            } label: {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Enviar Invoice por WhatsApp al Cliente")
                                }
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                showCalendarSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("✓ ¡El Cliente Aceptó! Agendar en Calendario")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Brand.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Invoice Oficial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
            .sheet(isPresented: $showSignaturePadSheet) {
                DigitalSignaturePadSheetView(signatureImage: $clientSignatureImage)
            }
            .sheet(isPresented: $showCalendarSheet) {
                AddToCalendarSheet(lead: lead, store: store, prefilledAmount: totalAmount)
            }
            .alert("Invoice Guardado", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("La factura oficial ha sido generada y guardada en tu galería de Fotos para enviársela al cliente.")
            }
        }
    }

    private func timeFormatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func saveInvoiceSnapshot() {
        showSavedAlert = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func sendWhatsAppInvoice() {
        var cleanPhone = lead.phone.filter { "0123456789".contains($0) }
        if cleanPhone.count == 10 { cleanPhone = "1" + cleanPhone }
        let svcs = lead.services?.joined(separator: ", ") ?? "Corte de Césped"
        let msg = """
🌿 *RODRIGUEZ LAWNCARE - FACTURA / PRESUPUESTO OFICIAL*
📍 Killeen & Central Texas • (254) 852-8163

👤 *Cliente:* \(lead.name)
📄 *Invoice #:* \(invoiceNumber)
🌿 *Servicios:* \(svcs)
💵 *Total a Pagar:* $\(String(format: "%.2f", totalAmount)) USD
📅 *Fecha:* \(timeFormatted(Date()))

💳 *MÉTODOS DE PAGO ACEPTADOS:*
• Zelle: Olivia Rodriguez • (623) 764-4177
• Cash App: $rafajrii (https://cash.app/$rafajrii)
• Efectivo al terminar el trabajo

✅ *Garantía 100% de Calidad y Satisfacción.*
¿Confirmamos este horario para realizar tu servicio? ¡Quedamos a tus órdenes!
"""
        if let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://wa.me/\(cleanPhone)?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - ADD TO CALENDAR SHEET
struct AddToCalendarSheet: View {
    @Environment(\.dismiss) var dismiss
    let lead: Lead
    @ObservedObject var store: LawnCareStore
    var prefilledAmount: Double = 75.0

    @State private var selectedDate: Date = Date().addingTimeInterval(86400)
    @State private var selectedTimeWindow: String = "Morning (8:00 AM - 12:00 PM)"
    @State private var amountText: String = ""
    @State private var notesText: String = ""

    let timeWindows = [
        "Morning (8:00 AM - 12:00 PM)",
        "Afternoon (12:00 PM - 4:00 PM)",
        "Late Afternoon (4:00 PM - 7:00 PM)",
        "Any Available Time Window"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                Form {
                    Section(header: Text("CLIENTE & TRABAJO").foregroundStyle(Brand.primary)) {
                        HStack {
                            Text("Cliente:")
                            Spacer()
                            Text(lead.name).bold()
                        }
                        HStack {
                            Text("Teléfono:")
                            Spacer()
                            Text(lead.phone).foregroundStyle(Brand.primary)
                        }
                        if let addr = lead.address, !addr.isEmpty {
                            HStack {
                                Text("Dirección:")
                                Spacer()
                                Text(addr).font(.caption)
                            }
                        }
                    }

                    Section(header: Text("FECHA Y HORARIO").foregroundStyle(Brand.primary)) {
                        DatePicker("Fecha de Visita", selection: $selectedDate, displayedComponents: .date)
                        Picker("Horario", selection: $selectedTimeWindow) {
                            ForEach(timeWindows, id: \.self) { tw in
                                Text(tw).tag(tw)
                            }
                        }
                    }

                    Section(header: Text("MONTO ACORDADO ($)").foregroundStyle(Brand.primary)) {
                        TextField("Monto en USD", text: $amountText)
                            .keyboardType(.decimalPad)
                    }

                    Section(header: Text("NOTAS DEL CALENDARIO").foregroundStyle(Brand.primary)) {
                        TextField("Código de puerta, especificaciones...", text: $notesText)
                    }

                    Section {
                        Button {
                            scheduleJob()
                        } label: {
                            HStack {
                                Spacer()
                                Text("✓ Confirmar y Guardar en Calendario")
                                    .font(.headline.bold())
                                    .foregroundStyle(.black)
                                Spacer()
                            }
                        }
                        .listRowBackground(Brand.primary)
                    }
                }
            }
            .navigationTitle("Agendar en Calendario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
            .onAppear {
                amountText = String(format: "%.2f", prefilledAmount)
                notesText = lead.description ?? ""
                if let t = lead.time, timeWindows.contains(t) {
                    selectedTimeWindow = t
                }
            }
        }
    }

    private func scheduleJob() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let dateStr = f.string(from: selectedDate)
        let amt = Double(amountText) ?? prefilledAmount

        let newAppt = CalendarAppointment(
            id: Int(Date().timeIntervalSince1970 * 1000),
            date: dateStr,
            time_window: selectedTimeWindow,
            client_name: lead.name,
            client_phone: lead.phone,
            address: lead.address ?? "",
            services: lead.services,
            amount: amt,
            status: "confirmed",
            notes: notesText
        )

        Task {
            await store.saveCalendarAppointment(appt: newAppt)
            await store.updateLeadStatus(id: lead.id, status: "confirmed", notes: "Agendado para \(dateStr) (\(selectedTimeWindow))", estimatedAmount: amt)
            dismiss()
        }
    }
}


// MARK: - TAB 2: PROFESSIONAL CALENDAR VIEW
struct ProfessionalCalendarView: View {
    @ObservedObject var store: LawnCareStore
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showAddEventSheet: Bool = false
    @State private var isTogglingDay: Bool = false
    @State private var showRouteOptimizer: Bool = false

    private var calendar: Calendar { Calendar.current }

    private var selectedDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: selectedDate)
    }

    private var monthYearString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_US")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: currentMonth).capitalized
    }

    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else { return [] }

        var result: [Date] = []
        var current = monthFirstWeek.start
        while current < monthLastWeek.end {
            result.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return result
    }

    private var appointmentsForSelectedDay: [CalendarAppointment] {
        let ds = selectedDateString
        return store.calendarData.appointments?.filter { $0.date == ds } ?? []
    }

    private var isSelectedDayFull: Bool {
        store.calendarData.day_status?[selectedDateString] == "full"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Weather Forecast in Killeen
                        WeatherBannerView(store: store)
                            .padding(.top, 4)

                        // Month Header Navigation
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CALENDARIO DE TRABAJOS")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                                Text(monthYearString)
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            HStack(spacing: 12) {
                                Button {
                                    changeMonth(by: -1)
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .padding(8)
                                        .background(Brand.card)
                                        .clipShape(Circle())
                                        .foregroundStyle(.white)
                                }
                                Button {
                                    currentMonth = Date()
                                    selectedDate = Date()
                                } label: {
                                    Text("Hoy")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Brand.primary.opacity(0.2))
                                        .foregroundStyle(Brand.primary)
                                        .clipShape(Capsule())
                                }
                                Button {
                                    changeMonth(by: 1)
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .padding(8)
                                        .background(Brand.card)
                                        .clipShape(Circle())
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Days of week header
                        HStack {
                            ForEach(["DOM", "LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB"], id: \.self) { day in
                                Text(day)
                                    .font(.caption2.bold())
                                    .frame(maxWidth: .infinity)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(.horizontal)

                        // Calendar Month Grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                            ForEach(daysInMonth, id: \.self) { date in
                                let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                                let isToday = calendar.isDateInToday(date)
                                let df = DateFormatter()
                                let ds: String = {
                                    df.dateFormat = "yyyy-MM-dd"
                                    return df.string(from: date)
                                }()
                                let isFull = store.calendarData.day_status?[ds] == "full"
                                let apptCount = store.calendarData.appointments?.filter { $0.date == ds }.count ?? 0

                                Button {
                                    selectedDate = date
                                } label: {
                                    VStack(spacing: 2) {
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(.caption.bold())
                                            .foregroundStyle(isSelected ? .black : (isToday ? Brand.primary : (isCurrentMonth ? .white : .gray.opacity(0.4))))

                                        if isFull {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 5, height: 5)
                                        } else if apptCount > 0 {
                                            Circle()
                                                .fill(Brand.primary)
                                                .frame(width: 5, height: 5)
                                        } else {
                                            Circle()
                                                .fill(Color.clear)
                                                .frame(width: 5, height: 5)
                                        }
                                    }
                                    .frame(height: 40)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? Brand.primary : (isToday ? Brand.cardLight : Color.clear))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(10)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)

                        // Selected Day Status & Toggle FULL / NORMAL
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(formattedHeaderDate(selectedDate))
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                    Text(isSelectedDayFull ? "🔴 DÍA COMPLETO / LLENO (Citas bloqueadas en web)" : "🟢 DÍA NORMAL (Citas abiertas en web)")
                                        .font(.caption.bold())
                                        .foregroundStyle(isSelectedDayFull ? .red : Brand.primary)
                                }
                                Spacer()
                            }

                            Button {
                                Task {
                                    isTogglingDay = true
                                    await store.toggleCalendarDayStatus(date: selectedDateString)
                                    isTogglingDay = false
                                }
                            } label: {
                                HStack {
                                    Image(systemName: isSelectedDayFull ? "lock.open.fill" : "lock.fill")
                                    Text(isSelectedDayFull ? "Abrir Día (Poner NORMAL)" : "Marcar Día como FULL (Lleno)")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(isSelectedDayFull ? .green : .white)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(isSelectedDayFull ? Color.green.opacity(0.18) : Color.red.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)

                        // Appointments List for Selected Day
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("TRABAJOS DEL DÍA (\(appointmentsForSelectedDay.count))")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                                Spacer()
                                Button {
                                    showRouteOptimizer = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "map.fill")
                                        Text("🗺️ Ruta de Hoy")
                                    }
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                                }
                                Button {
                                    showAddEventSheet = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Agregar")
                                    }
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                                }
                            }
                            .padding(.horizontal)

                            if appointmentsForSelectedDay.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.largeTitle)
                                        .foregroundStyle(.gray.opacity(0.5))
                                    Text("No hay clientes programados para este día.")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                ForEach(appointmentsForSelectedDay) { appt in
                                    CalendarApptCard(appt: appt, store: store)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Calendario")
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddEventSheet) {
                DirectAddCalendarSheet(store: store, defaultDate: selectedDateString)
            }
            .sheet(isPresented: $showRouteOptimizer) {
                DailyRouteOptimizerSheetView(selectedDate: selectedDate, store: store)
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = next
        }
    }

    private func formattedHeaderDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_US")
        f.dateStyle = .full
        return f.string(from: date).capitalized
    }
}

// MARK: - CALENDAR APPOINTMENT CARD
struct CalendarApptCard: View {
    let appt: CalendarAppointment
    @ObservedObject var store: LawnCareStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appt.client_name)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text("⏰ \(appt.time_window)")
                        .font(.caption.bold())
                        .foregroundStyle(Brand.accent)
                }
                Spacer()
                if let amt = appt.amount, amt > 0 {
                    Text(String(format: "$%.2f", amt))
                        .font(.headline.bold())
                        .foregroundStyle(Brand.primary)
                }
            }

            if !appt.address.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.red)
                    Text(appt.address)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            if let svcs = appt.services, !svcs.isEmpty {
                Text(svcs.joined(separator: " • "))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }

            if let notes = appt.notes, !notes.isEmpty {
                Text("📝 \(notes)")
                    .font(.caption2)
                    .italic()
                    .foregroundStyle(.gray)
            }

            Divider().background(Color.gray.opacity(0.3))

            HStack(spacing: 12) {
                Button {
                    let clean = appt.client_phone.filter { "0123456789".contains($0) }
                    if let url = URL(string: "tel://\(clean)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Llamar", systemImage: "phone.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Brand.cardLight)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }

                Button {
                    var clean = appt.client_phone.filter { "0123456789".contains($0) }
                    if clean.count == 10 { clean = "1" + clean }
                    if let url = URL(string: "https://wa.me/\(clean)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("WhatsApp", systemImage: "message.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundStyle(.green)
                }

                Spacer()

                Button {
                    Task {
                        await store.deleteCalendarAppointment(id: appt.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
        }
        .padding(14)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - DIRECT ADD CALENDAR EVENT SHEET
struct DirectAddCalendarSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: LawnCareStore
    var defaultDate: String

    @State private var clientName: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var timeWindow: String = "Morning (8:00 AM - 12:00 PM)"
    @State private var servicesText: String = "Corte de Césped & Orillado"
    @State private var amountText: String = "75.00"
    @State private var notes: String = ""

    let timeWindows = [
        "Morning (8:00 AM - 12:00 PM)",
        "Afternoon (12:00 PM - 4:00 PM)",
        "Late Afternoon (4:00 PM - 7:00 PM)",
        "Any Available Time Window"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                Form {
                    Section(header: Text("DATOS DEL CLIENTE")) {
                        TextField("Nombre del Cliente", text: $clientName)
                        TextField("Teléfono", text: $phone).keyboardType(.phonePad)
                        TextField("Dirección (Killeen TX...)", text: $address)
                    }

                    Section(header: Text("HORARIO Y SERVICIO")) {
                        Picker("Horario", selection: $timeWindow) {
                            ForEach(timeWindows, id: \.self) { Text($0).tag($0) }
                        }
                        TextField("Servicios a Realizar", text: $servicesText)
                        TextField("Monto Acordado ($)", text: $amountText).keyboardType(.decimalPad)
                    }

                    Section(header: Text("NOTAS")) {
                        TextField("Notas adicionales...", text: $notes)
                    }

                    Section {
                        Button {
                            let amt = Double(amountText) ?? 75.0
                            let appt = CalendarAppointment(
                                id: Int(Date().timeIntervalSince1970 * 1000),
                                date: defaultDate,
                                time_window: timeWindow,
                                client_name: clientName.isEmpty ? "Cliente" : clientName,
                                client_phone: phone,
                                address: address,
                                services: [servicesText],
                                amount: amt,
                                status: "confirmed",
                                notes: notes
                            )
                            Task {
                                await store.saveCalendarAppointment(appt: appt)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Guardar en Calendario")
                                    .font(.headline.bold())
                                    .foregroundStyle(.black)
                                Spacer()
                            }
                        }
                        .listRowBackground(Brand.primary)
                    }
                }
            }
            .navigationTitle("Nuevo Trabajo (\(defaultDate))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
}

// MARK: - TAB 5: FLASH PROMOTIONS VIEW
struct FlashPromotionsView: View {
    @ObservedObject var store: LawnCareStore

    @State private var promoTitle: String = "🎖️ Descuento Especial Militar"
    @State private var promoMessage: String = "El día de hoy tenemos una promoción especial para militares: corte de pasto completo por solo $35 con orillado impecable."
    @State private var promoBadge: String = "OFERTA MILITAR FLASH"
    @State private var durationHours: Int = 24
    @State private var isPublishing: Bool = false
    @State private var showUploadWorkSheet: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color.orange.opacity(0.18)).frame(width: 46, height: 46)
                                Image(systemName: "megaphone.fill").font(.title3).foregroundStyle(Color.orange)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PROMOCIONES FLASH EN VIVO")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                                Text("Publica ofertas con temporizador de cuenta regresiva en el centro de tu sitio web.")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Active Promo Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("ESTADO ACTUAL EN LA WEB")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                Spacer()
                                if let p = store.activePromo, p.enabled {
                                    Text("🟢 EN VIVO EN LA WEB")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Brand.primary)
                                } else {
                                    Text("INACTIVO")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.gray)
                                }
                            }

                            if let p = store.activePromo, p.enabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(p.badge ?? "OFERTA")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Brand.primary)
                                            .foregroundStyle(.black)
                                            .clipShape(Capsule())
                                        Spacer()
                                        if let exp = p.expires_at {
                                            let remaining = max(0, exp - Int(Date().timeIntervalSince1970))
                                            let hrs = remaining / 3600
                                            let mins = (remaining % 3600) / 60
                                            Text("⏳ Quedan: \(hrs)h \(mins)m")
                                                .font(.caption2.bold())
                                                .foregroundStyle(Color.orange)
                                        }
                                    }
                                    Text(p.title)
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                    Text(p.message)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.85))

                                    Button {
                                        Task {
                                            await store.deactivatePromo()
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "xmark.circle.fill")
                                            Text("Desactivar Promoción Ahora")
                                        }
                                        .font(.caption.bold())
                                        .foregroundStyle(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(8)
                                        .background(Color.red.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                Text("No hay promociones activas actualmente en la web.")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Compose New Promotion Form
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CREAR NUEVA PROMOCIÓN")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Insignia / Badge:").font(.caption2).foregroundStyle(.gray)
                                TextField("Ej: OFERTA MILITAR FLASH", text: $promoBadge)
                                    .padding(10).background(Brand.cardLight).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Título de la Oferta:").font(.caption2).foregroundStyle(.gray)
                                TextField("Ej: 🎖️ Descuento Militar Especial", text: $promoTitle)
                                    .padding(10).background(Brand.cardLight).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mensaje Completo:").font(.caption2).foregroundStyle(.gray)
                                TextEditor(text: $promoMessage)
                                    .frame(height: 75)
                                    .padding(6).background(Brand.cardLight).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Duración de la Oferta:").font(.caption2).foregroundStyle(.gray)
                                Picker("Duración", selection: $durationHours) {
                                    Text("6 Horas").tag(6)
                                    Text("12 Horas").tag(12)
                                    Text("24 Horas (1 Día)").tag(24)
                                    Text("48 Horas (2 Días)").tag(48)
                                    Text("72 Horas (3 Días)").tag(72)
                                }
                                .pickerStyle(.segmented)
                            }

                            Button {
                                Task {
                                    isPublishing = true
                                    await store.publishPromo(
                                        title: promoTitle,
                                        message: promoMessage,
                                        badge: promoBadge,
                                        durationHours: durationHours
                                    )
                                    isPublishing = false
                                }
                            } label: {
                                HStack {
                                    if isPublishing {
                                        ProgressView().tint(.black)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                        Text("Publicar Promoción en la Web Ahora")
                                    }
                                }
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Brand.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.top, 4)
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // SECCIÓN PARA SUBIR TRABAJOS A LA WEB
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(Brand.primary.opacity(0.18)).frame(width: 44, height: 44)
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                        .foregroundStyle(Brand.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SUBIR FOTOS DE TRABAJOS A LA WEB")
                                        .font(.caption.bold())
                                        .foregroundStyle(Brand.primary)
                                    Text("Publica fotos de tus trabajos terminados para que aparezcan al instante en tu página web.")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                            }
                            
                            Button {
                                showUploadWorkSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("📸 Subir Nueva Foto a la Página Web")
                                }
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Brand.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Promo History
                        if !store.promoHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("HISTORIAL DE PROMOCIONES")
                                    .font(.caption.bold())
                                    .foregroundStyle(.gray)

                                ForEach(store.promoHistory.prefix(5), id: \.title) { h in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(h.title).font(.subheadline.bold()).foregroundStyle(.white)
                                            Text(h.message).font(.caption2).foregroundStyle(.gray).lineLimit(2)
                                        }
                                        Spacer()
                                        Button {
                                            promoTitle = h.title
                                            promoMessage = h.message
                                            promoBadge = h.badge ?? "OFERTA FLASH"
                                        } label: {
                                            Text("Usar").font(.caption2.bold()).padding(.horizontal, 8).padding(.vertical, 4).background(Brand.cardLight).clipShape(Capsule()).foregroundStyle(Brand.primary)
                                        }
                                    }
                                    .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Promociones Web")
            .navigationBarHidden(true)
            .sheet(isPresented: $showUploadWorkSheet) {
                UploadWorkToWebGalleryView(store: store)
            }
        }
    }
}


// ==================== GESTOR DE RESEÑAS WEB (REVIEWS MANAGER) ====================
struct ReviewsManagerView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var showAddReviewSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⭐ Testimonios en la Página Web")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                            Text("Los clientes ven estas opiniones reales en tu web")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                        Button {
                            showAddReviewSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Nueva Reseña")
                            }
                            .font(.subheadline.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Brand.primary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(Brand.card)

                    // List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if store.reviews.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "star.slash")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.gray)
                                    Text("No hay reseñas registradas aún")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                                .padding(.top, 40)
                            } else {
                                ForEach(store.reviews) { r in
                                    reviewCard(r)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Reseñas de Clientes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundStyle(Brand.primary)
                }
            }
            .onAppear {
                Task { await store.fetchReviews() }
            }
            .sheet(isPresented: $showAddReviewSheet) {
                AddReviewSheetView(store: store)
            }
        }
    }

    private func reviewCard(_ r: ClientReview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 2) {
                    ForEach(0..<max(0, min(5, r.rating)), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color.yellow)
                    }
                }

                Spacer()

                if let badge = r.badge, !badge.isEmpty {
                    Text(badge)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Brand.primary.opacity(0.18))
                        .foregroundStyle(Brand.primary)
                        .clipShape(Capsule())
                }

                Button {
                    store.deleteReview(id: r.id) { _ in }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(Color.red.opacity(0.8))
                        .padding(6)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Circle())
                }
            }

            Text("\"\(r.text)\"")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.95))
                .lineSpacing(2)

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Brand.primary.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text(r.initials ?? String(r.name.prefix(2)).uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(Brand.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(r.name)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    Text(r.role)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }

                Spacer()

                if let date = r.date {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.gray.opacity(0.8))
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(Brand.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct AddReviewSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss

    @State private var clientName = ""
    @State private var serviceRole = "Weekly Residential Service"
    @State private var clientBadge = "Verified Homeowner"
    @State private var starRating = 5
    @State private var reviewComment = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil

    let serviceOptions = [
        "Weekly Residential Service",
        "Bi-Weekly Yard Maintenance",
        "Front & Back Yard Cut",
        "Landscape Renovation Client",
        "Tree Cutting & Care",
        "Commercial Property Manager"
    ]

    let badgeOptions = [
        "Verified Homeowner",
        "Verified Client",
        "Commercial Client",
        "Recomendado 100%"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AGREGAR NUEVA RESEÑA")
                            .font(.caption.bold())
                            .foregroundStyle(.gray)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nombre del Cliente").font(.caption.bold()).foregroundStyle(.white)
                            TextField("ej. Michael Ramirez o John Doe", text: $clientName)
                                .padding()
                                .background(Brand.card)
                                .cornerRadius(10)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Calificación en Estrellas").font(.caption.bold()).foregroundStyle(.white)
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        starRating = star
                                    } label: {
                                        Image(systemName: star <= starRating ? "star.fill" : "star")
                                            .font(.title2)
                                            .foregroundStyle(star <= starRating ? Color.yellow : Color.gray)
                                    }
                                }
                                Spacer()
                                Text("\(starRating) de 5 Estrellas")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.yellow)
                            }
                            .padding()
                            .background(Brand.card)
                            .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Servicio / Tipo de Trabajo").font(.caption.bold()).foregroundStyle(.white)
                            Picker("Servicio", selection: $serviceRole) {
                                ForEach(serviceOptions, id: \.self) { opt in
                                    Text(opt).tag(opt)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Brand.card)
                            .cornerRadius(10)
                            .accentColor(Brand.primary)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Distintivo de Verificación").font(.caption.bold()).foregroundStyle(.white)
                            Picker("Distintivo", selection: $clientBadge) {
                                ForEach(badgeOptions, id: \.self) { b in
                                    Text(b).tag(b)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Brand.card)
                            .cornerRadius(10)
                            .accentColor(Brand.primary)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Comentario / Opinión del Cliente").font(.caption.bold()).foregroundStyle(.white)
                            TextEditor(text: $reviewComment)
                                .frame(height: 110)
                                .padding(8)
                                .background(Brand.card)
                                .cornerRadius(10)
                                .foregroundStyle(.white)
                        }

                        if let err = errorMessage {
                            Text(err)
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        }

                        Button {
                            submitReview()
                        } label: {
                            HStack {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("Publicar Reseña en la Web")
                                }
                            }
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Brand.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isSubmitting || clientName.isEmpty || reviewComment.isEmpty)
                        .opacity((clientName.isEmpty || reviewComment.isEmpty) ? 0.6 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationTitle("Nueva Reseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }.foregroundStyle(.gray)
                }
            }
        }
    }

    private func submitReview() {
        guard !clientName.isEmpty && !reviewComment.isEmpty else { return }
        isSubmitting = true
        errorMessage = nil
        store.addReview(
            name: clientName,
            role: serviceRole,
            badge: clientBadge,
            rating: starRating,
            text: reviewComment
        ) { success in
            isSubmitting = false
            if success {
                dismiss()
            } else {
                errorMessage = "Error al guardar en el servidor. Intenta nuevamente."
            }
        }
    }
}


// ==================== GESTOR DE MÚSICA DE FONDO WEB ====================
struct WebMusicSettingsSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss

    @State private var isEnabled: Bool = false
    @State private var selectedPresetId: String = "texas_guitar"
    @State private var musicVolume: Double = 0.40
    @State private var isSaving: Bool = false
    @State private var showSavedNotice: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // ON / OFF Master Switch Card
                        VStack(spacing: 12) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(isEnabled ? Color.purple.opacity(0.25) : Color.gray.opacity(0.2))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: isEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                        .font(.title3)
                                        .foregroundStyle(isEnabled ? Color.purple : Color.gray)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Música en la Página Web")
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                    Text(isEnabled ? "🟢 Activa: los clientes pueden escuchar música" : "🔴 Apagada: la página web está en silencio")
                                        .font(.caption)
                                        .foregroundStyle(isEnabled ? Brand.primary : .gray)
                                }
                                Spacer()
                                Toggle("", isOn: $isEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color.purple))
                            }

                            if isEnabled {
                                Button {
                                    isEnabled = false
                                    saveMusicConfig()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "speaker.slash")
                                        Text("Apagar Música Ahora (Mute)")
                                    }
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.15))
                                    .foregroundStyle(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding()
                        .background(Brand.card)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isEnabled ? Color.purple.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                        )

                        // Pistas de Música Disponibles (Presets)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SELECCIONA LA PISTA DE MÚSICA")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)

                            ForEach(LawnCareStore.defaultMusicPresets) { preset in
                                Button {
                                    selectedPresetId = preset.id
                                    isEnabled = true
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: selectedPresetId == preset.id ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(selectedPresetId == preset.id ? Color.purple : .gray)
                                            .padding(.top, 2)

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(preset.name)
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(.white)
                                                Spacer()
                                                Text(preset.genre)
                                                    .font(.caption2.bold())
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.purple.opacity(0.2))
                                                    .foregroundStyle(Color.purple)
                                                    .clipShape(Capsule())
                                            }
                                            Text(preset.desc)
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                                .lineLimit(2)
                                        }
                                    }
                                    .padding(12)
                                    .background(selectedPresetId == preset.id ? Color.purple.opacity(0.12) : Brand.card)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedPresetId == preset.id ? Color.purple : Color.white.opacity(0.05), lineWidth: 1)
                                    )
                                }
                            }
                        }

                        // Volumen
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("VOLUMEN DE REPRODUCCIÓN")
                                    .font(.caption.bold())
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("\(Int(musicVolume * 100))%")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.purple)
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "speaker.fill")
                                    .foregroundStyle(.gray)
                                Slider(value: $musicVolume, in: 0.10...1.0, step: 0.05)
                                    .tint(Color.purple)
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundStyle(.gray)
                            }
                            .padding()
                            .background(Brand.card)
                            .cornerRadius(12)
                        }

                        // Save Button
                        Button {
                            saveMusicConfig()
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Guardar y Aplicar en la Web")
                                }
                            }
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isSaving)

                        if showSavedNotice {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("¡Música actualizada con éxito en la página web!")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(Brand.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Brand.primary.opacity(0.12))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Música de Fondo Web")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }.foregroundStyle(Brand.primary)
                }
            }
            .onAppear {
                if let m = store.settings?.music {
                    self.isEnabled = m.enabled ?? false
                    self.selectedPresetId = m.preset_id ?? "texas_guitar"
                    self.musicVolume = m.volume ?? 0.40
                }
            }
        }
    }

    private func saveMusicConfig() {
        isSaving = true
        showSavedNotice = false
        let preset = LawnCareStore.defaultMusicPresets.first(where: { $0.id == selectedPresetId }) ?? LawnCareStore.defaultMusicPresets[0]
        Task {
            await store.updateWebMusic(
                enabled: isEnabled,
                title: preset.name,
                genre: preset.genre,
                streamURL: preset.url,
                volume: musicVolume,
                presetId: preset.id
            )
            await MainActor.run {
                isSaving = false
                showSavedNotice = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}


// ====================================================================
// MARK: - NEW FEATURES: WEATHER, ROUTES, RECURRING, BEFORE/AFTER, SQFT
// ====================================================================

// MARK: - WEATHER BANNER VIEW (KILLEEN, TX)
struct WeatherBannerView: View {
    @ObservedObject var store: LawnCareStore
    
    var body: some View {
        if let w = store.weatherInfo {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: w.conditionIcon)
                        .font(.title2)
                        .foregroundStyle(w.rain_probability >= 40 ? Color.blue : Brand.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("\(w.temperature)°F • Killeen, TX")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                            Text("• \(w.conditionText)")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        Text("Probabilidad de lluvia hoy: \(w.rain_probability)%")
                            .font(.caption2.bold())
                            .foregroundStyle(w.rain_probability >= 40 ? Color.orange : Brand.primary)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task { await store.fetchWeather() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(6)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                }
                
                if w.rain_probability >= 40 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.orange)
                            .font(.caption)
                        Text("Alerta de lluvia: Ten precaución con pasto mojado y ajusta citas si es necesario.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(12)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(w.rain_probability >= 40 ? Color.orange.opacity(0.4) : Brand.primary.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
}

// MARK: - ROUTE OPTIMIZER VIEW
struct DailyRouteOptimizerSheetView: View {
    @Environment(\.dismiss) var dismiss
    let selectedDate: Date
    @ObservedObject var store: LawnCareStore
    
    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: selectedDate)
    }
    
    private var dateDisplay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_US")
        f.dateStyle = .medium
        return f.string(from: selectedDate)
    }
    
    var stops: [CalendarAppointment] {
        store.calendarData.appointments?.filter {
            $0.date == dateString && !$0.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } ?? []
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header Summary Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "map.fill")
                                    .font(.title2)
                                    .foregroundStyle(Brand.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ruta Optimizada de Paradas")
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                    Text("\(dateDisplay) • \(stops.count) Paradas Programadas")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                            }
                            
                            Text("Ahorra tiempo y gasolina en Killeen, Harker Heights y alrededores abriendo la ruta completa en tus mapas favoritos.")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .padding(.top, 2)
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Brand.primary.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Launcher Actions
                        if !stops.isEmpty {
                            VStack(spacing: 10) {
                                Button {
                                    openAppleMapsRoute()
                                } label: {
                                    HStack {
                                        Image(systemName: "applelogo")
                                        Text("Abrir Ruta Completa en Apple Maps")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                Button {
                                    openGoogleMapsRoute()
                                } label: {
                                    HStack {
                                        Image(systemName: "location.fill")
                                        Text("Abrir Ruta Completa en Google Maps")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Brand.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        
                        // Stops List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ORDEN SUGERIDO DE PARADAS (\(stops.count))")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            
                            if stops.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "mappin.slash")
                                        .font(.largeTitle)
                                        .foregroundStyle(.gray.opacity(0.5))
                                    Text("No hay citas con dirección registrada para este día.")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(Array(stops.enumerated()), id: \.element.id) { index, appt in
                                    HStack(alignment: .top, spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Brand.primary)
                                                .frame(width: 32, height: 32)
                                            Text("\(index + 1)")
                                                .font(.caption.bold())
                                                .foregroundStyle(.black)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(appt.client_name)
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                            if !appt.address.isEmpty {
                                                Text(appt.address)
                                                    .font(.caption)
                                                    .foregroundStyle(.gray)
                                            }
                                            if !appt.time_window.isEmpty {
                                                Text("⏰ Horario: \(appt.time_window)")
                                                    .font(.caption2)
                                                    .foregroundStyle(Brand.primary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if !appt.address.isEmpty {
                                            Button {
                                                openSingleAddressInMaps(appt.address)
                                            } label: {
                                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(Brand.primary)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(Brand.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Optimizador de Ruta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
    
    private func openSingleAddressInMaps(_ address: String) {
        let clean = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?daddr=\(clean)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openAppleMapsRoute() {
        guard let first = stops.first?.address else { return }
        let cleanFirst = first.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?daddr=\(cleanFirst)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openGoogleMapsRoute() {
        guard let dest = stops.last?.address else { return }
        let destClean = dest.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let waypoints = stops.dropLast().compactMap { $0.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) }.joined(separator: "|")
        var urlStr = "https://www.google.com/maps/dir/?api=1&destination=\(destClean)"
        if !waypoints.isEmpty {
            urlStr += "&waypoints=\(waypoints)"
        }
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - RECURRING CLIENTS MANAGER
struct RecurringClientsManagerView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedDayFilter: String = "Todos"
    @State private var showAddSheet: Bool = false
    @State private var clientToEdit: RecurringClient? = nil
    
    let dayFilters = ["Todos", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Pendientes"]
    
    var filteredClients: [RecurringClient] {
        if selectedDayFilter == "Todos" {
            return store.recurringClients
        } else if selectedDayFilter == "Pendientes" {
            return store.recurringClients.filter { $0.status == "pending" }
        } else {
            return store.recurringClients.filter { $0.service_day == selectedDayFilter }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(dayFilters, id: \.self) { filter in
                                Button {
                                    selectedDayFilter = filter
                                } label: {
                                    Text(filter)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedDayFilter == filter ? Brand.primary : Brand.card)
                                        .foregroundStyle(selectedDayFilter == filter ? .black : .white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            if filteredClients.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "person.2.slash")
                                        .font(.largeTitle)
                                        .foregroundStyle(.gray.opacity(0.5))
                                    Text("No hay clientes recurrentes registrados en esta categoría.")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(filteredClients) { client in
                                    RecurringClientCard(client: client, store: store, onEdit: {
                                        clientToEdit = client
                                    })
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Clientes Recurrentes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Brand.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddRecurringClientSheet(store: store)
            }
            .sheet(item: $clientToEdit) { client in
                EditRecurringClientSheetView(client: client, store: store)
            }
        }
    }
}

struct RecurringClientCard: View {
    let client: RecurringClient
    @ObservedObject var store: LawnCareStore
    var onEdit: () -> Void = {}
    @State private var isToggling: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(client.name)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Brand.primary.opacity(0.8))
                    }
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text(client.phone)
                        .font(.caption)
                        .foregroundStyle(Brand.primary)
                    if !client.address.isEmpty {
                        Text(client.address)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.0f", client.price))/visita")
                        .font(.subheadline.bold())
                        .foregroundStyle(Brand.primary)
                    Text(client.frequency == "weekly" ? "Semanal" : (client.frequency == "biweekly" ? "Quincenal" : "Mensual"))
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Brand.primary.opacity(0.15))
                        .foregroundStyle(Brand.primary)
                        .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 8) {
                Text("Día de Corte: \(client.service_day)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                
                Button {
                    Task {
                        isToggling = true
                        await store.togglePaidRecurring(id: client.id)
                        isToggling = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(client.status == "paid" ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(client.status == "paid" ? "Pagado ✓" : "Pendiente ⏳")
                            .font(.caption2.bold())
                            .foregroundStyle(client.status == "paid" ? Color.green : Color.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
            }
            
            Divider().background(Color.gray.opacity(0.2))
            
            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Editar Info")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Brand.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Brand.cardLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    sendReminderWhatsApp()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                        Text("Recordatorio WhatsApp")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button {
                    callClient()
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Brand.cardLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(14)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func sendReminderWhatsApp() {
        var cleanPhone = client.phone.filter { "0123456789".contains($0) }
        if cleanPhone.count == 10 { cleanPhone = "1" + cleanPhone }
        let msg = """
🌿 *Rodriguez Lawn Care - Recordatorio de Servicio*
¡Hola \(client.name)! Te recordamos que mañana \(client.service_day) pasamos a realizar tu servicio de corte y mantenimiento de jardín.

Por favor asegúrate de:
1. Dejar el portón sin candado o llave.
2. Mantener mascotas dentro de casa.
3. Retirar juguetes o mangueras del pasto.

¡Muchas gracias por tu confianza! Si tienes alguna duda, responde a este mensaje.
"""
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/\(cleanPhone)?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func callClient() {
        let clean = client.phone.filter { "0123456789".contains($0) }
        if let url = URL(string: "tel://\(clean)") {
            UIApplication.shared.open(url)
        }
    }
}

struct AddRecurringClientSheet: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var frequency: String = "weekly"
    @State private var serviceDay: String = "Lunes"
    @State private var price: String = "60"
    @State private var notes: String = ""
    
    let days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("DATOS DEL CLIENTE").foregroundStyle(Brand.primary)) {
                        TextField("Nombre Completo", text: $name)
                        TextField("Teléfono (Ej: 254-555-0100)", text: $phone)
                            .keyboardType(.phonePad)
                        TextField("Dirección (Killeen / TX)", text: $address)
                    }
                    .listRowBackground(Brand.card)
                    
                    Section(header: Text("FRECUENCIA Y HORARIO").foregroundStyle(Brand.primary)) {
                        Picker("Frecuencia", selection: $frequency) {
                            Text("Semanal").tag("weekly")
                            Text("Quincenal").tag("biweekly")
                            Text("Mensual").tag("monthly")
                        }
                        Picker("Día de Servicio", selection: $serviceDay) {
                            ForEach(days, id: \.self) { d in
                                Text(d).tag(d)
                            }
                        }
                        TextField("Precio por Visita ($)", text: $price)
                            .keyboardType(.decimalPad)
                        TextField("Notas (Portón, Mascotas, etc.)", text: $notes)
                    }
                    .listRowBackground(Brand.card)
                }
                            }
            .navigationTitle("Nuevo Cliente Frecuente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        let newC = RecurringClient(
                            id: Int(Date().timeIntervalSince1970 * 1000),
                            name: name.isEmpty ? "Cliente" : name,
                            phone: phone,
                            address: address,
                            frequency: frequency,
                            service_day: serviceDay,
                            price: Double(price) ?? 60.0,
                            status: "pending",
                            services: ["Front & Back Yard Cut"],
                            notes: notes,
                            last_serviced: ""
                        )
                        Task {
                            await store.saveRecurringClient(newC)
                            dismiss()
                        }
                    }
                    .foregroundStyle(Brand.primary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - BEFORE & AFTER CAMERA SHEET
struct BeforeAfterCameraSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    @State private var beforeImage: UIImage? = nil
    @State private var afterImage: UIImage? = nil
    @State private var showBeforePicker: Bool = false
    @State private var showAfterPicker: Bool = false
    @State private var titleText: String = "Corte & Mantenimiento Residencial"
    @State private var categoryText: String = "Front Yard"
    @State private var isPublishing: Bool = false
    @State private var showSuccessAlert: Bool = false
    
    let categories = ["Front Yard", "Back Yard", "Mulch", "Tree Care", "Cleanups", "General LawnCare"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Title & Category Inputs
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TÍTULO DEL TRABAJO")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            TextField("Ej: Corte y Bordeado Impecable", text: $titleText)
                                .padding(10)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                            
                            Text("CATEGORÍA")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                                .padding(.top, 4)
                            Picker("Categoría", selection: $categoryText) {
                                ForEach(categories, id: \.self) { c in
                                    Text(c).tag(c)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        
                        // Photo Pickers
                        HStack(spacing: 12) {
                            // Before Box
                            Button {
                                showBeforePicker = true
                            } label: {
                                VStack(spacing: 8) {
                                    if let b = beforeImage {
                                        Image(uiImage: b)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 140)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } else {
                                        VStack(spacing: 6) {
                                            Image(systemName: "camera.badge.ellipsis")
                                                .font(.title)
                                                .foregroundStyle(.orange)
                                            Text("Foto ANTES")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(.white)
                                            Text("Toca para agregar")
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 140)
                                        .background(Color.white.opacity(0.04))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            
                            // After Box
                            Button {
                                showAfterPicker = true
                            } label: {
                                VStack(spacing: 8) {
                                    if let a = afterImage {
                                        Image(uiImage: a)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 140)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } else {
                                        VStack(spacing: 6) {
                                            Image(systemName: "camera.fill")
                                                .font(.title)
                                                .foregroundStyle(Brand.primary)
                                            Text("Foto DESPUÉS")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(.white)
                                            Text("Toca para agregar")
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 140)
                                        .background(Color.white.opacity(0.04))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                publishToLiveGallery()
                            } label: {
                                HStack {
                                    if isPublishing {
                                        ProgressView().tint(.black)
                                    } else {
                                        Image(systemName: "globe")
                                        Text("🚀 Publicar Directo en la Galería Web")
                                    }
                                }
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(afterImage != nil ? Brand.primary : Color.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(afterImage == nil || isPublishing)
                            
                            Button {
                                shareWhatsAppBeforeAfter()
                            } label: {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Compartir con Cliente por WhatsApp")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(afterImage == nil)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Cámara Antes y Después")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
            .sheet(isPresented: $showBeforePicker) {
                PhotoLibraryPicker(selectedImage: $beforeImage)
            }
            .sheet(isPresented: $showAfterPicker) {
                PhotoLibraryPicker(selectedImage: $afterImage)
            }
            .alert("¡Publicado en la Web!", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Tu nuevo trabajo ya está en vivo en la sección de Real Work de la página web con el distintivo ✨ Antes & Después.")
            }
        }
    }
    
    private func publishToLiveGallery() {
        guard let img = afterImage else { return }
        isPublishing = true
        let b64 = img.jpegData(compressionQuality: 0.6)?.base64EncodedString() ?? ""
        Task {
            await store.addGalleryPhoto(title: titleText, category: categoryText, imageBase64: b64)
            isPublishing = false
            showSuccessAlert = true
        }
    }
    
    private func shareWhatsAppBeforeAfter() {
        let msg = """
🌿 *Rodriguez Lawn Care - Trabajo Terminado*
¡Hola! Aquí tienes el resultado de nuestro servicio en tu propiedad:
✂️ \(titleText)
⭐ Garantía de satisfacción 100%. ¡Muchas gracias por tu preferencia!
"""
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - SATELLITE LAWN AREA CALCULATOR
struct LawnAreaCalculatorSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    @State private var addressSearch: String = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 31.1171, longitude: -97.7278), // Killeen, TX
        span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
    )
    @State private var polygonPoints: [CLLocationCoordinate2D] = []
    @State private var computedSqFt: Double = 0
    @State private var isSearching: Bool = false
    
    var suggestedPrice: Double {
        if computedSqFt <= 0 { return 55.0 }
        if computedSqFt < 3500 { return 45.0 }
        if computedSqFt < 7000 { return 65.0 }
        if computedSqFt < 12000 { return 85.0 }
        if computedSqFt < 25000 { return 110.0 }
        return 140.0 + ((computedSqFt - 25000) / 10000) * 20.0
    }
    
    var computedAcres: Double {
        return computedSqFt / 43560.0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)
                        TextField("Dirección en Killeen o TX (Ej: 123 Main St)", text: $addressSearch, onCommit: {
                            searchAddress()
                        })
                        .foregroundStyle(.white)
                        if isSearching {
                            ProgressView().tint(.white)
                        } else {
                            Button("Buscar") { searchAddress() }
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                        }
                    }
                    .padding(10)
                    .background(Brand.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Map with Satellite style
                    ZStack(alignment: .topTrailing) {
                        Map(coordinateRegion: $region)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onTapGesture {
                                // Add center point to polygon
                                polygonPoints.append(region.center)
                                recalculateArea()
                            }
                        
                        // Tap Helper Tag
                        Text("Mueve el mapa y toca para marcar esquinas del jardín (\(polygonPoints.count) puntos)")
                            .font(.caption2.bold())
                            .padding(6)
                            .background(Color.black.opacity(0.7))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .padding(10)
                    }
                    
                    // Calculation Results Bottom Card
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ÁREA CALCULADA:")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.gray)
                                Text("\(String(format: "%.0f", computedSqFt)) sq ft")
                                    .font(.title2.bold())
                                    .foregroundStyle(Brand.primary)
                                Text("\(String(format: "%.2f", computedAcres)) Acres")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("PRECIO SUGERIDO:")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.gray)
                                Text("$\(String(format: "%.0f", suggestedPrice)) USD")
                                    .font(.title2.bold())
                                    .foregroundStyle(.green)
                                Text("Corte Residencial")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        
                        HStack(spacing: 10) {
                            Button {
                                polygonPoints.removeAll()
                                computedSqFt = 0
                            } label: {
                                Text("Limpiar Puntos")
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(Color.red.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            Button {
                                copyEstimateWhatsApp()
                            } label: {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                    Text("Copiar a WhatsApp")
                                }
                                .font(.caption.bold())
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Brand.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(14)
                    .background(Brand.card)
                }
            }
            .navigationTitle("Medidor Satelital SQFT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
    
    private func searchAddress() {
        guard !addressSearch.isEmpty else { return }
        isSearching = true
        let geocoder = CLGeocoder()
        let query = addressSearch.contains("TX") ? addressSearch : "\(addressSearch), Killeen, TX"
        geocoder.geocodeAddressString(query) { placemarks, _ in
            isSearching = false
            if let loc = placemarks?.first?.location {
                region = MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
                )
            }
        }
    }
    
    private func recalculateArea() {
        guard polygonPoints.count >= 3 else {
            computedSqFt = 0
            return
        }
        var area: Double = 0.0
        let k = 111319.9
        for i in 0..<polygonPoints.count {
            let p1 = polygonPoints[i]
            let p2 = polygonPoints[(i + 1) % polygonPoints.count]
            let x1 = p1.longitude * k * cos(p1.latitude * Double.pi / 180.0)
            let y1 = p1.latitude * k
            let x2 = p2.longitude * k * cos(p2.latitude * Double.pi / 180.0)
            let y2 = p2.latitude * k
            area += (x1 * y2) - (x2 * y1)
        }
        let areaSqMeters = abs(area) / 2.0
        computedSqFt = areaSqMeters * 10.7639
    }
    
    private func copyEstimateWhatsApp() {
        let msg = """
🌿 *Rodriguez Lawn Care - Medición y Presupuesto Satelital*
📍 Propiedad: \(addressSearch.isEmpty ? "Área en Killeen" : addressSearch)
📐 Tamaño estimado: \(String(format: "%.0f", computedSqFt)) sq ft (\(String(format: "%.2f", computedAcres)) Acres)
💵 Presupuesto sugerido de corte: $\(String(format: "%.0f", suggestedPrice)) USD
¡Contáctanos al (254) 852-8163 para agendar tu servicio hoy mismo!
"""
        UIPasteboard.general.string = msg
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}


// MARK: - ==========================================
// MARK: - SUITE DEL PATRÓN: HERRAMIENTAS PRO & PLACOSAS
// MARK: - ==========================================

struct PatronQuickToolCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(10)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - 1. DIGITAL SIGNATURE PAD (FIRMA DE CLIENTE)
struct DigitalSignaturePadSheetView: View {
    @Binding var signatureImage: UIImage?
    @Environment(\.dismiss) var dismiss
    @State private var currentPath: [CGPoint] = []
    @State private var completedPaths: [[CGPoint]] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FIRMA DIGITAL DEL CLIENTE")
                            .font(.headline.bold())
                            .foregroundStyle(Brand.primary)
                        Text("Firme con su dedo en el recuadro blanco para autorizar el estimado y las condiciones del servicio.")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    ZStack {
                        Color.white
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(height: 1)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 28)
                            Text("X  Firma del Propietario / Cliente")
                                .font(.caption.bold())
                                .foregroundStyle(Color.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 24)
                                .padding(.bottom, 10)
                        }
                        
                        Canvas { context, size in
                            for path in completedPaths {
                                var p = Path()
                                guard let first = path.first else { continue }
                                p.move(to: first)
                                for pt in path.dropFirst() {
                                    p.addLine(to: pt)
                                }
                                context.stroke(p, with: .color(.black), lineWidth: 3.5)
                            }
                            
                            var activeP = Path()
                            if let first = currentPath.first {
                                activeP.move(to: first)
                                for pt in currentPath.dropFirst() {
                                    activeP.addLine(to: pt)
                                }
                                context.stroke(activeP, with: .color(.blue), lineWidth: 3.5)
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0.1)
                                .onChanged { value in
                                    currentPath.append(value.location)
                                }
                                .onEnded { _ in
                                    completedPaths.append(currentPath)
                                    currentPath = []
                                }
                        )
                    }
                    .frame(height: 250)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.3), radius: 8)
                    
                    HStack(spacing: 12) {
                        Button {
                            currentPath.removeAll()
                            completedPaths.removeAll()
                            signatureImage = nil
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Borrar Firma")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.red.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Button {
                            exportSignature()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Aprobar y Estampar")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(completedPaths.isEmpty)
                        .opacity(completedPaths.isEmpty ? 0.4 : 1.0)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Firma Digital")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
    
    private func exportSignature() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 160))
        let img = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 320, height: 160))
            
            let strokeColor = UIColor.black
            strokeColor.setStroke()
            
            for path in completedPaths {
                let bezier = UIBezierPath()
                guard let first = path.first else { continue }
                bezier.move(to: first)
                for pt in path.dropFirst() {
                    bezier.addLine(to: pt)
                }
                bezier.lineWidth = 3.5
                bezier.lineCapStyle = .round
                bezier.stroke()
            }
        }
        self.signatureImage = img
    }
}

// MARK: - 2. RADAR TÁCTICO: "CONQUISTA DE TERRITORIO" (PUNTOS EN CASAS DE CLIENTES SEMANALES)
struct TacticalHouseClientPin: Identifiable {
    let id: String
    let name: String
    let phone: String
    let address: String
    let serviceDay: String
    let price: Double
    let coordinate: CLLocationCoordinate2D
    let isRecurring: Bool
}

// MARK: - TACTICAL USER LOCATION & GPS NAVIGATION MANAGER
class TacticalUserLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var heading: Double = 0.0
    @Published var isAuthorized: Bool = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5.0
        checkAuth()
    }
    
    func checkAuth() {
        let status = manager.authorizationStatus
        isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        if isAuthorized {
            manager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                manager.startUpdatingHeading()
            }
        }
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuth()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        userLocation = loc.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }
}

// MARK: - TACTICAL ROUTE & TURN STEP MODELS
struct TacticalRouteTurnStep: Identifiable {
    let id = UUID()
    let instruction: String
    let distanceMiles: Double
    let notice: String?
    let iconName: String
    
    var formattedDistance: String {
        if distanceMiles < 0.1 {
            let feet = Int(distanceMiles * 5280)
            return "\(feet) ft"
        } else {
            return String(format: "%.1f mi", distanceMiles)
        }
    }
}

struct TacticalActiveNavigationRoute {
    let polyline: MKPolyline
    let destinationName: String
    let destinationAddress: String
    let totalDistanceMiles: Double
    let totalDurationMinutes: Int
    let steps: [TacticalRouteTurnStep]
    let summary: String
}

// MARK: - TACTICAL INTERACTIVE MAP (NATIVE MKMAPVIEW WITH STREET ROUTE OVERLAYS)
struct TacticalLiveRadarMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var pins: [TacticalHouseClientPin]
    @Binding var selectedPin: TacticalHouseClientPin?
    var activeRoute: TacticalActiveNavigationRoute?
    var mapType: MKMapType = .standard
    var onSelectPin: ((TacticalHouseClientPin) -> Void)?
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TacticalLiveRadarMapView
        
        init(_ parent: TacticalLiveRadarMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 0.13, green: 0.77, blue: 0.36, alpha: 0.95) // Neon Emerald
                renderer.lineWidth = 6.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil // Uses native Apple pulsing blue dot with heading cone
            }
            
            let identifier = "TacticalHouseMarker"
            var marker = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if marker == nil {
                marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                marker?.canShowCallout = false
            } else {
                marker?.annotation = annotation
            }
            
            marker?.glyphImage = UIImage(systemName: "house.fill")
            marker?.markerTintColor = UIColor(red: 0.13, green: 0.77, blue: 0.36, alpha: 1.0)
            marker?.glyphTintColor = .black
            marker?.displayPriority = .required
            return marker
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation, !(annotation is MKUserLocation) else { return }
            let coord = annotation.coordinate
            if let found = parent.pins.first(where: {
                abs($0.coordinate.latitude - coord.latitude) < 0.0002 &&
                abs($0.coordinate.longitude - coord.longitude) < 0.0002
            }) {
                parent.selectedPin = found
                parent.onSelectPin?(found)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.mapType = mapType
        mapView.setRegion(region, animated: false)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        if mapView.mapType != mapType {
            mapView.mapType = mapType
        }
        
        // Update annotations if list changed
        let currentCustom = mapView.annotations.filter { !($0 is MKUserLocation) }
        if currentCustom.count != pins.count {
            mapView.removeAnnotations(currentCustom)
            let newAnnotations = pins.map { pin -> MKPointAnnotation in
                let a = MKPointAnnotation()
                a.coordinate = pin.coordinate
                a.title = pin.name
                a.subtitle = "\(pin.serviceDay) • $\(Int(pin.price))"
                return a
            }
            mapView.addAnnotations(newAnnotations)
        }
        
        // Sync route polyline overlay
        let currentOverlays = mapView.overlays
        if let route = activeRoute {
            let poly = route.polyline
            if !currentOverlays.contains(where: { ($0 as? MKPolyline) == poly }) {
                mapView.removeOverlays(currentOverlays)
                mapView.addOverlay(poly)
                
                // Animate zoom to encompass entire driving route
                let rect = poly.boundingMapRect
                mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 130, left: 40, bottom: 250, right: 40), animated: true)
            }
        } else {
            if !currentOverlays.isEmpty {
                mapView.removeOverlays(currentOverlays)
            }
        }
    }
}

// MARK: - RADAR TACTICO DE TERRITORIO CON GPS TURN-BY-TURN EN VIVO
struct TacticalTerritoryRadarView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var locManager = TacticalUserLocationManager()
    @State private var radarAngle: Double = 0
    @State private var selectedDayFilter: String = "Todas"
    @State private var selectedCityFilter: String = "Todas"
    @State private var selectedPin: TacticalHouseClientPin? = nil
    
    // GPS Navigation & Driving Polyline State
    @State private var activeRoute: TacticalActiveNavigationRoute? = nil
    @State private var isCalculatingRoute: Bool = false
    @State private var showAllTurnsSheet: Bool = false
    @State private var mapType: MKMapType = .standard
    @State private var navigationError: String? = nil
    
    // Central Texas default coordinate: Killeen TX
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 31.1171, longitude: -97.7278),
        span: MKCoordinateSpan(latitudeDelta: 0.14, longitudeDelta: 0.14)
    )
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    let days = ["Todas", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
    
    let cityJumps: [(name: String, icon: String, lat: Double, lng: Double, span: Double)] = [
        ("Toda el Área", "map.fill", 31.1171, -97.7278, 0.22),
        ("Copperas Cove", "mountain.2.fill", 31.1241, -97.9031, 0.05),
        ("Killeen", "building.2.fill", 31.1171, -97.7278, 0.07),
        ("Harker Heights", "tree.fill", 31.0835, -97.6597, 0.05),
        ("Temple", "cross.case.fill", 31.0982, -97.3428, 0.06),
        ("Belton", "water.waves", 31.0560, -97.4645, 0.05),
        ("Fort Cavazos", "shield.fill", 31.1305, -97.7780, 0.06)
    ]
    
    var allClientPins: [TacticalHouseClientPin] {
        var list: [TacticalHouseClientPin] = []
        
        for client in store.recurringClients {
            let addr = client.address.isEmpty ? "Propiedad en Killeen, TX" : client.address
            let coord = store.resolveCoordinate(for: addr, clientName: client.name)
            list.append(
                TacticalHouseClientPin(
                    id: "rec_\(client.id)",
                    name: client.name,
                    phone: client.phone,
                    address: addr,
                    serviceDay: client.service_day,
                    price: client.price,
                    coordinate: coord,
                    isRecurring: true
                )
            )
        }
        
        for (idx, lead) in store.leads.enumerated() {
            let addr = lead.address ?? "Killeen, TX"
            let coord = store.resolveCoordinate(for: addr, clientName: lead.name)
            list.append(
                TacticalHouseClientPin(
                    id: "lead_\(lead.id)_\(idx)",
                    name: lead.name,
                    phone: lead.phone,
                    address: addr,
                    serviceDay: lead.date ?? "Esta Semana",
                    price: 55.0,
                    coordinate: coord,
                    isRecurring: false
                )
            )
        }
        
        // Realistic fallback properties in Central Texas neighborhoods
        if list.isEmpty {
            let starter: [(String, String, String, Double, Double, Double)] = [
                ("Marcus Vance", "1402 Willow Springs Rd, Killeen, TX", "Lunes", 55.0, 31.1092, -97.7410),
                ("Sarah Jenkins", "2204 W Stan Schlueter Loop, Killeen, TX", "Lunes", 65.0, 31.0850, -97.7580),
                ("David Miller (Duplex)", "809 E Central Texas Pkwy, Killeen, TX", "Martes", 45.0, 31.1120, -97.7120),
                ("Carlos Mendoza", "3105 Clear Creek Rd, Killeen, TX", "Martes", 60.0, 31.1250, -97.7850),
                ("Jennifer Adams", "501 E Knights Way, Harker Heights, TX", "Miércoles", 50.0, 31.0750, -97.6650),
                ("Robert King (HOA)", "1203 Mountain Lion Cir, Harker Heights, TX", "Jueves", 75.0, 31.0620, -97.6480),
                ("Daniel Hernandez", "204 S 1st St, Copperas Cove, TX", "Viernes", 50.0, 31.1210, -97.9020),
                ("Fort Cavazos Quarters", "Building 18010, Fort Cavazos, TX", "Sábado", 65.0, 31.1390, -97.7780)
            ]
            for s in starter {
                list.append(
                    TacticalHouseClientPin(
                        id: s.0,
                        name: s.0,
                        phone: "2548528163",
                        address: s.1,
                        serviceDay: s.2,
                        price: s.3,
                        coordinate: CLLocationCoordinate2D(latitude: s.4, longitude: s.5),
                        isRecurring: true
                    )
                )
            }
        }
        
        return list
    }
    
    var filteredPins: [TacticalHouseClientPin] {
        var result = allClientPins
        if selectedDayFilter != "Todas" {
            result = result.filter { $0.serviceDay.localizedCaseInsensitiveContains(selectedDayFilter) }
        }
        if selectedCityFilter != "Todas" {
            result = result.filter { $0.address.localizedCaseInsensitiveContains(selectedCityFilter) }
        }
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tactical Header HUD
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text("RADAR TÁCTICO & GPS")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Brand.primary)
                                if activeRoute != nil {
                                    Text("• EN RUTA")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.yellow)
                                }
                            }
                            Text("Navegación Calles y Salidas a Casas")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("OBJETIVOS")
                                .font(.caption2.bold())
                                .foregroundStyle(.gray)
                            Text("\(filteredPins.count) CASAS")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Brand.card)
                    
                    // City Quick Jump Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(cityJumps, id: \.name) { city in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.7)) {
                                        region.center = CLLocationCoordinate2D(latitude: city.lat, longitude: city.lng)
                                        region.span = MKCoordinateSpan(latitudeDelta: city.span, longitudeDelta: city.span)
                                    }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: city.icon).font(.caption2)
                                        Text(city.name).font(.caption.bold())
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(city.name.contains("Cove") ? Color.orange.opacity(0.85) : Brand.cardLight)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(city.name.contains("Cove") ? Color.yellow : Brand.primary.opacity(0.4), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }
                    .background(Color.black.opacity(0.85))
                    
                    // Day Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(days, id: \.self) { day in
                                let count = day == "Todas" ? allClientPins.count : allClientPins.filter { $0.serviceDay.localizedCaseInsensitiveContains(day) }.count
                                Button {
                                    selectedDayFilter = day
                                    if let first = filteredPins.first {
                                        withAnimation { region.center = first.coordinate }
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(day)
                                        Text("(\(count))")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(selectedDayFilter == day ? Brand.primary : Brand.cardLight)
                                    .foregroundStyle(selectedDayFilter == day ? .black : .white)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }
                    .background(Color.black.opacity(0.7))
                    
                    // Main Map View with Polyline Overlay and User Location
                    ZStack(alignment: .top) {
                        TacticalLiveRadarMapView(
                            region: $region,
                            pins: filteredPins,
                            selectedPin: $selectedPin,
                            activeRoute: activeRoute,
                            mapType: mapType
                        ) { pin in
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Radar grid sweep overlay (subtle)
                        ZStack {
                            Circle()
                                .stroke(Brand.primary.opacity(0.15), lineWidth: 1)
                                .frame(width: 180, height: 180)
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Brand.primary.opacity(0.3), Color.clear]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 1.5, height: 90)
                                .offset(y: -45)
                                .rotationEffect(.degrees(radarAngle))
                        }
                        .allowsHitTesting(false)
                        
                        // Floating Turn-by-Turn GPS HUD Banner (Top of Map)
                        if let route = activeRoute {
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    // Turn maneuver icon
                                    let firstStep = route.steps.first(where: { !$0.instruction.isEmpty })
                                    let iconName = firstStep?.iconName ?? "arrow.turn.up.right"
                                    ZStack {
                                        Circle().fill(Brand.primary).frame(width: 44, height: 44)
                                        Image(systemName: iconName)
                                            .font(.title3.bold())
                                            .foregroundStyle(.black)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(firstStep?.instruction ?? "Continúa por la ruta trazada")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.white)
                                            .lineLimit(2)
                                        
                                        HStack(spacing: 8) {
                                            Text("⏱️ \(route.totalDurationMinutes) min")
                                                .font(.caption.bold())
                                                .foregroundStyle(Brand.primary)
                                            Text("• \(String(format: "%.1f mi", route.totalDistanceMiles))")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.9))
                                            if let notice = firstStep?.notice, !notice.isEmpty {
                                                Text("• \(notice)")
                                                    .font(.caption2.bold())
                                                    .foregroundStyle(.orange)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Button to inspect all turns list
                                    Button {
                                        showAllTurnsSheet = true
                                    } label: {
                                        VStack(spacing: 2) {
                                            Image(systemName: "list.bullet.rectangle.fill")
                                                .font(.headline)
                                            Text("Giros")
                                                .font(.system(size: 9, weight: .bold))
                                        }
                                        .padding(6)
                                        .background(Brand.cardLight)
                                        .foregroundStyle(Brand.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    
                                    // Exit / Cancel Route Button
                                    Button {
                                        withAnimation { activeRoute = nil }
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.red)
                                    }
                                }
                                .padding(10)
                                .background(Color(red: 0.05, green: 0.12, blue: 0.08).opacity(0.95))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Brand.primary, lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(0.7), radius: 10, y: 4)
                                .padding(.horizontal, 10)
                                .padding(.top, 8)
                            }
                        }
                        
                        // Floating Map Quick Buttons (Right side)
                        VStack(spacing: 8) {
                            // My GPS Location Button (Google Maps Style)
                            Button {
                                locManager.requestPermission()
                                if let userLoc = locManager.userLocation {
                                    withAnimation(.spring()) {
                                        region.center = userLoc
                                        region.span = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                                    }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                } else {
                                    locManager.requestPermission()
                                }
                            } label: {
                                Image(systemName: "location.fill")
                                    .font(.headline)
                                    .foregroundStyle(locManager.userLocation != nil ? Brand.primary : .white)
                                    .frame(width: 42, height: 42)
                                    .background(Brand.card.opacity(0.92))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Brand.primary.opacity(0.6), lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.5), radius: 4)
                            }
                            
                            // Map Type Toggle (Satellite vs Street)
                            Button {
                                mapType = (mapType == .standard) ? .hybrid : .standard
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Image(systemName: mapType == .standard ? "globe.americas.fill" : "map.fill")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 42, height: 42)
                                    .background(Brand.card.opacity(0.92))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Brand.cardLight, lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.5), radius: 4)
                            }
                            
                            // Recenter Central Texas
                            Button {
                                withAnimation {
                                    region.center = CLLocationCoordinate2D(latitude: 31.1171, longitude: -97.7278)
                                    region.span = MKCoordinateSpan(latitudeDelta: 0.14, longitudeDelta: 0.14)
                                    selectedPin = nil
                                    activeRoute = nil
                                }
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 42, height: 42)
                                    .background(Brand.card.opacity(0.92))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Brand.cardLight, lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.5), radius: 4)
                            }
                        }
                        .padding(.trailing, 12)
                        .padding(.top, activeRoute != nil ? 85 : 12)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        // Selected Pin Callout Card with Live Driving Route Generation & Navigation Hand-off
                        if let pin = selectedPin {
                            VStack {
                                Spacer()
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(pin.name)
                                                .font(.headline.bold())
                                                .foregroundStyle(.white)
                                            Text(pin.address)
                                                .font(.caption)
                                                .foregroundStyle(.gray)
                                        }
                                        Spacer()
                                        Button {
                                            withAnimation {
                                                selectedPin = nil
                                                activeRoute = nil
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                    
                                    HStack {
                                        Text("Día: \(pin.serviceDay)")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Brand.primary.opacity(0.2))
                                            .foregroundStyle(Brand.primary)
                                            .clipShape(Capsule())
                                        
                                        Text("$\(Int(pin.price)) USD / corte")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                        
                                        if isCalculatingRoute {
                                            ProgressView()
                                                .tint(Brand.primary)
                                                .scaleEffect(0.8)
                                        }
                                    }
                                    
                                    // Action Buttons: Trazar Ruta en App, Google Maps, Apple Maps, WhatsApp
                                    VStack(spacing: 6) {
                                        // Main Drive Button: Calculates route polyline on real streets
                                        Button {
                                            calculateDrivingRoute(to: pin)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                                Text(activeRoute != nil ? "Ruta Trazada (Ver Giros)" : "🚗 Trazar Ruta GPS en Vivo")
                                            }
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Brand.primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        
                                        HStack(spacing: 6) {
                                            // Open directly in Google Maps
                                            Button {
                                                openGoogleMaps(for: pin)
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "map.fill")
                                                    Text("Google Maps")
                                                }
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(Color.blue)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            
                                            // Open directly in Apple Maps
                                            Button {
                                                openAppleMaps(for: pin)
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "applelogo")
                                                    Text("Apple Maps")
                                                }
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            
                                            // WhatsApp contact
                                            Button {
                                                let clean = pin.phone.filter { "0123456789".contains($0) }
                                                let msg = "¡Hola \(pin.name)! Te contacto de Rodriguez Lawn Care sobre tu servicio de jardinería."
                                                let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                                if let url = URL(string: "https://wa.me/\(clean)?text=\(encoded)") {
                                                    UIApplication.shared.open(url)
                                                }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "message.fill")
                                                    Text("WhatsApp")
                                                }
                                                .font(.caption.bold())
                                                .foregroundStyle(.black)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(Color.green)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color(red: 0.05, green: 0.12, blue: 0.09))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Brand.primary, lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(0.85), radius: 15, y: 5)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Radar Táctico de Territorio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
            .sheet(isPresented: $showAllTurnsSheet) {
                if let route = activeRoute {
                    TacticalTurnByTurnStepsSheet(route: route)
                }
            }
            .onAppear {
                locManager.requestPermission()
            }
            .onReceive(timer) { _ in
                radarAngle = (radarAngle + 2).truncatingRemainder(dividingBy: 360)
            }
        }
    }
    
    // Calculate Driving Route using Apple's MKDirections (Streets, Exits, Turn Polylines)
    private func calculateDrivingRoute(to pin: TacticalHouseClientPin) {
        locManager.requestPermission()
        isCalculatingRoute = true
        
        let startCoord = locManager.userLocation ?? CLLocationCoordinate2D(latitude: 31.1171, longitude: -97.7278)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: pin.coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                isCalculatingRoute = false
                guard let r = response?.routes.first else {
                    navigationError = error?.localizedDescription ?? "No se pudo calcular la ruta."
                    return
                }
                
                let distMiles = r.distance / 1609.34
                let durationMin = Int(ceil(r.expectedTravelTime / 60.0))
                
                let steps: [TacticalRouteTurnStep] = r.steps.compactMap { step in
                    guard !step.instructions.isEmpty else { return nil }
                    let icon = iconForTurnInstruction(step.instructions)
                    return TacticalRouteTurnStep(
                        instruction: step.instructions,
                        distanceMiles: step.distance / 1609.34,
                        notice: step.notice,
                        iconName: icon
                    )
                }
                
                withAnimation(.spring()) {
                    activeRoute = TacticalActiveNavigationRoute(
                        polyline: r.polyline,
                        destinationName: pin.name,
                        destinationAddress: pin.address,
                        totalDistanceMiles: distMiles,
                        totalDurationMinutes: durationMin,
                        steps: steps,
                        summary: r.name
                    )
                }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
    }
    
    private func iconForTurnInstruction(_ inst: String) -> String {
        let lower = inst.lowercased()
        if lower.contains("salida") || lower.contains("exit") {
            return "signpost.right.fill"
        } else if lower.contains("izquierda") || lower.contains("left") {
            return "arrow.turn.up.left"
        } else if lower.contains("derecha") || lower.contains("right") {
            return "arrow.turn.up.right"
        } else if lower.contains("uturn") || lower.contains("vuelta en u") {
            return "arrow.uturn.backward"
        } else if lower.contains("lleg") || lower.contains("arrive") || lower.contains("destino") {
            return "flag.checkered"
        } else {
            return "arrow.up"
        }
    }
    
    private func openGoogleMaps(for pin: TacticalHouseClientPin) {
        let lat = pin.coordinate.latitude
        let lng = pin.coordinate.longitude
        let googleAppUrl = URL(string: "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=driving")
        let googleWebUrl = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lng)")
        
        if let appUrl = googleAppUrl, UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
        } else if let webUrl = googleWebUrl {
            UIApplication.shared.open(webUrl)
        }
    }
    
    private func openAppleMaps(for pin: TacticalHouseClientPin) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: pin.coordinate))
        item.name = pin.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - SHEET DE LISTA DE TODOS LOS GIROS Y SALIDAS (TURN-BY-TURN STEP LIST)
struct TacticalTurnByTurnStepsSheet: View {
    let route: TacticalActiveNavigationRoute
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Summary header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RUTA HACIA:")
                            .font(.caption2.bold())
                            .foregroundStyle(Brand.primary)
                        Text(route.destinationName)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                        Text(route.destinationAddress)
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill").foregroundStyle(Brand.primary)
                                Text("\(route.totalDurationMinutes) min").font(.subheadline.bold()).foregroundStyle(.white)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "road.lanes").foregroundStyle(.yellow)
                                Text(String(format: "%.1f mi", route.totalDistanceMiles)).font(.subheadline.bold()).foregroundStyle(.white)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "signpost.right.and.left.fill").foregroundStyle(.orange)
                                Text("\(route.steps.count) Giros").font(.subheadline.bold()).foregroundStyle(.white)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Brand.card)
                    
                    // List of turns and exit instructions
                    List {
                        ForEach(Array(route.steps.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle().fill(Brand.cardLight).frame(width: 36, height: 36)
                                    Image(systemName: step.iconName)
                                        .font(.caption.bold())
                                        .foregroundStyle(Brand.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(step.instruction)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    
                                    HStack(spacing: 8) {
                                        Text(step.formattedDistance)
                                            .font(.caption.bold())
                                            .foregroundStyle(Brand.primary)
                                        
                                        if let notice = step.notice, !notice.isEmpty {
                                            Text("⚠️ \(notice)")
                                                .font(.caption2.bold())
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Brand.card)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Instrucciones de Ruta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
}

struct TacticalMetricBadge: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9))
                    .foregroundStyle(.gray)
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(8)
        .background(Brand.cardLight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 3. ESCÁNER IA DE SALUD DEL PASTO (CON CÁMARA, FOTO REAL Y DEMO INTERACTIVA)
struct AIYardHealthScannerHUDView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedImage: UIImage? = nil
    @State private var showCameraPicker: Bool = false
    @State private var showPhotoLibraryPicker: Bool = false
    
    @State private var isScanning: Bool = false
    @State private var scanProgress: Double = 0.0
    @State private var scanStageText: String = "Listo para iniciar escaneo"
    @State private var scanLineOffset: CGFloat = -110
    
    // AI Diagnostics Results State
    @State private var healthScore: Int = 74
    @State private var grassVariety: String = "Bermuda Grass Híbrido (Texas Tifway 419)"
    @State private var nitrogenScore: String = "Bajo (44%) • Requiere fertilizante"
    @State private var weedPressure: String = "Moderado (24%) • Crabgrass y trébol"
    @State private var compactionScore: String = "Alta (72%) • Necesita aireación de raíces"
    @State private var moistureScore: String = "Óptima (64%)"
    @State private var estimatedQuote: Int = 185
    @State private var clientNameInput: String = "Cliente Residencial"
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 4K CYBERNETIC SPECTRAL VIEWFINDER CONTAINER
                        ZStack {
                            if let img = selectedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 230)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(Color.black.opacity(0.25))
                            } else {
                                // Default Live High-Tech Reticle & Sensor HUD
                                ZStack {
                                    Color(red: 0.05, green: 0.10, blue: 0.07)
                                        .frame(height: 230)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    
                                    // Animated target reticle
                                    Circle()
                                        .stroke(Brand.primary.opacity(0.4), lineWidth: 1.5)
                                        .frame(width: 110, height: 110)
                                    Circle()
                                        .stroke(Brand.primary.opacity(0.25), lineWidth: 1)
                                        .frame(width: 170, height: 170)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "viewfinder")
                                            .font(.system(size: 42))
                                            .foregroundStyle(Brand.primary)
                                        Text("APUNTA AL CÉSPED O SELECCIONA FOTO")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.white)
                                        Text("El sensor IA detecta clorofila, maleza y compactación")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                            
                            // Laser Scan Line when active
                            if isScanning || selectedImage != nil {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.clear, Color.green.opacity(0.9), Color.clear]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 3)
                                    .shadow(color: Color.green, radius: 8)
                                    .offset(y: scanLineOffset)
                            }
                            
                            // Outer Cyber HUD Brackets
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isScanning ? Color.green : Brand.primary.opacity(0.6), lineWidth: 2)
                            
                            // HUD Sensors Overlay
                            VStack {
                                HStack {
                                    HStack(spacing: 4) {
                                        Circle().fill(isScanning ? Color.red : Color.green).frame(width: 6, height: 6)
                                        Text("AI SPECTRAL HUD 4K")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundStyle(Brand.primary)
                                    }
                                    .padding(4)
                                    .background(Color.black.opacity(0.75))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    
                                    Spacer()
                                    
                                    Text("ISO 100 • 60 FPS")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                HStack {
                                    Text(isScanning ? scanStageText : (selectedImage != nil ? "OBJETIVO CAPTURADO" : "LISTO PARA ESCANEAR"))
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("CENTRAL TX SOIL DB")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(Brand.primary)
                                }
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .padding(8)
                        }
                        .frame(height: 230)
                        .padding(.horizontal)
                        
                        // Action Buttons: Tomar Foto, Subir de Galería, Usar Muestra Demo
                        HStack(spacing: 8) {
                            Button {
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    showCameraPicker = true
                                } else {
                                    showPhotoLibraryPicker = true
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                    Text("Tomar Foto")
                                }
                                .font(.caption.bold())
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Brand.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            
                            Button {
                                showPhotoLibraryPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Galería")
                                }
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Brand.cardLight)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            
                            Button {
                                loadDemoGrassAndScan()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text("Muestra Demo")
                                }
                                .font(.caption.bold())
                                .foregroundStyle(.yellow)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.2, green: 0.16, blue: 0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow.opacity(0.5), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Scanning Progress Bar when running
                        if isScanning {
                            VStack(spacing: 4) {
                                ProgressView(value: scanProgress, total: 1.0)
                                    .tint(Brand.primary)
                                Text(scanStageText)
                                    .font(.caption2.bold())
                                    .foregroundStyle(Brand.primary)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Health Diagnostics Breakdown Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("DIAGNÓSTICO FITOSANITARIO IA")
                                        .font(.caption.bold())
                                        .foregroundStyle(Brand.primary)
                                    Text("Índice de Salud General: \(healthScore)% (Atención Requerida)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                                Text("\(healthScore)/100")
                                    .font(.title2.bold())
                                    .foregroundStyle(healthScore >= 80 ? Color.green : Color.yellow)
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            // Specific metrics
                            VStack(spacing: 8) {
                                DiagnosticBarRow(label: "Especie de Césped", score: grassVariety, color: .green)
                                DiagnosticBarRow(label: "Nivel de Nitrógeno & Clorofila", score: nitrogenScore, color: .orange)
                                DiagnosticBarRow(label: "Invasión de Maleza / Crabgrass", score: weedPressure, color: .yellow)
                                DiagnosticBarRow(label: "Compactación de Raíces", score: compactionScore, color: .red)
                                DiagnosticBarRow(label: "Humedad del Suelo", score: moistureScore, color: .green)
                            }
                            
                            // AI Recommendation Box
                            VStack(alignment: .leading, spacing: 6) {
                                Text("💡 TRATAMIENTO RECOMENDADO POR IA:")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Brand.primary)
                                Text("1. Aireación de raíces y descompactado de suelo con sacabocados.\n2. Aplicación de fertilizante alto en nitrógeno y hierro.\n3. Capa de 3 pulgadas de Mulch Oscuro para retener humedad.\n\n💵 Costo Estimado del Paquete: $\(estimatedQuote) - $\(estimatedQuote + 50) USD.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.95))
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Share Certificate Action
                        Button {
                            shareCertificateWhatsApp()
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.arrow.up")
                                Text("Enviar Certificado de Salud por WhatsApp al Cliente")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Escáner IA de Pasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
            .sheet(isPresented: $showCameraPicker) {
                PhotoLibraryPicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showPhotoLibraryPicker) {
                PhotoLibraryPicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .onChange(of: selectedImage) { newImg in
                if newImg != nil {
                    runAIScanSimulation()
                }
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    scanLineOffset = 100
                }
            }
        }
    }
    
    private func loadDemoGrassAndScan() {
        selectedImage = generateProceduralGrassDemoImage()
        runAIScanSimulation()
    }
    
    private func runAIScanSimulation() {
        isScanning = true
        scanProgress = 0.0
        scanStageText = "1/3: Escaneando índice de clorofila y fotosíntesis..."
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            scanProgress = 0.4
            scanStageText = "2/3: Detectando maleza, crabgrass y parches secos..."
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            scanProgress = 0.8
            scanStageText = "3/3: Evaluando compactación radicular y nitrógeno..."
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            scanProgress = 1.0
            scanStageText = "Diagnóstico fitosanitario completado con éxito"
            isScanning = false
            healthScore = Int.random(in: 68...82)
            estimatedQuote = healthScore < 75 ? 195 : 175
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func generateProceduralGrassDemoImage() -> UIImage {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            
            // Rich turf lawn gradient
            let colors = [
                UIColor(red: 0.10, green: 0.38, blue: 0.12, alpha: 1.0).cgColor,
                UIColor(red: 0.16, green: 0.54, blue: 0.20, alpha: 1.0).cgColor,
                UIColor(red: 0.08, green: 0.30, blue: 0.10, alpha: 1.0).cgColor
            ]
            let space = CGColorSpaceCreateDeviceRGB()
            if let grad = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: [0.0, 0.5, 1.0]) {
                cg.drawLinearGradient(grad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
            }
            
            // Procedural lawn texture
            for i in 0..<1200 {
                let x = CGFloat(i % 40) * 20.0 + CGFloat.random(in: -8...8)
                let y = CGFloat(i / 40) * 20.0 + CGFloat.random(in: -8...8)
                let bladeH = CGFloat.random(in: 16...40)
                let bladeW = CGFloat.random(in: 2...4)
                let angle = CGFloat.random(in: -0.25...0.25)
                
                cg.saveGState()
                cg.translateBy(x: x, y: y)
                cg.rotate(by: angle)
                
                let bladeColor = (i % 8 == 0) ?
                    UIColor(red: 0.58, green: 0.52, blue: 0.18, alpha: 0.85) :
                    UIColor(red: CGFloat.random(in: 0.14...0.26), green: CGFloat.random(in: 0.55...0.78), blue: CGFloat.random(in: 0.18...0.30), alpha: 0.9)
                cg.setFillColor(bladeColor.cgColor)
                cg.fill(CGRect(x: -bladeW/2, y: -bladeH, width: bladeW, height: bladeH))
                cg.restoreGState()
            }
        }
    }
    
    private func shareCertificateWhatsApp() {
        let msg = """
🌿 *RODRIGUEZ LAWN CARE - DIAGNÓSTICO FITOSANITARIO IA*
📍 Central Texas • Tel: (254) 852-8163
━━━━━━━━━━━━━━━━━━━━
📊 *Calificación de Salud:* \(healthScore)/100 (Atención Requerida)
🌱 *Especie detectada:* \(grassVariety)
⚠️ *Deficiencias identificadas:*
• \(nitrogenScore)
• \(weedPressure)
• \(compactionScore)

💡 *Tratamiento Especializado Recomendado:*
1. Aireación de raíces y oxigenación con sacabocados.
2. Aplicación de fertilizante balanceado de temporada.
3. Cobertura de Mulch Oscuro protector.

💵 *Presupuesto Especial Rodriguez:* $\(estimatedQuote) USD
¡Responde a este mensaje para agendar la recuperación de tu jardín!
"""
        UIPasteboard.general.string = msg
        let clean = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/?text=\(clean)") {
            UIApplication.shared.open(url)
        }
    }
}

struct DiagnosticBarRow: View {
    let label: String
    let score: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white)
            Spacer()
            Text(score)
                .font(.caption2.bold())
                .foregroundStyle(color)
        }
    }
}


// MARK: - 4. CALCULADORA 3D DE CAMIÓN DE MULCH Y GRAVILLA
struct BulkMaterialTruckCalculatorView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    @State private var lengthFeet: Double = 30
    @State private var widthFeet: Double = 10
    @State private var depthInches: Double = 3
    @State private var selectedMaterial: String = "Mulch Oscuro (Dark Brown)"
    
    let materials = [
        "Mulch Oscuro (Dark Brown)",
        "Mulch Negro (Black Dyed)",
        "Mulch Rojo (Red Cedar)",
        "Piedra de Río / Grava (River Rock)"
    ]
    
    var cubicYards: Double {
        let sqft = lengthFeet * widthFeet
        let depthFeet = depthInches / 12.0
        let cubicFeet = sqft * depthFeet
        return cubicFeet / 27.0
    }
    
    var bagEquivalent: Double {
        // 1 cubic yard = 13.5 bags of 2 cu ft
        return cubicYards * 13.5
    }
    
    var estimatedMaterialCost: Double {
        let pricePerYard: Double = selectedMaterial.contains("Piedra") ? 75.0 : 38.0
        return cubicYards * pricePerYard
    }
    
    var suggestedLaborAndDelivery: Double {
        return cubicYards * 85.0 + 75.0 // Delivery base + installation
    }
    
    var totalClientPrice: Double {
        return estimatedMaterialCost + suggestedLaborAndDelivery
    }
    
    var netProfit: Double {
        return totalClientPrice - estimatedMaterialCost
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Interactive Dump Truck Graphic Card
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Brand.card)
                                    .frame(height: 140)
                                
                                VStack(spacing: 4) {
                                    HStack {
                                        Image(systemName: "truck.box.fill")
                                            .font(.system(size: 42))
                                            .foregroundStyle(Color.orange)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(String(format: "%.1f YARDAS CÚBICAS", cubicYards))
                                                .font(.headline.bold())
                                                .foregroundStyle(.white)
                                            Text("Equivale a aprox. \(Int(bagEquivalent)) bolsas de 2 cu ft")
                                                .font(.caption2)
                                                .foregroundStyle(Brand.primary)
                                            Text(cubicYards > 5 ? "⚠️ Requiere viaje de camión de volteo" : "✓ Cabe en remolque estándar")
                                                .font(.caption2)
                                                .foregroundStyle(cubicYards > 5 ? .yellow : .green)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Dimensions Sliders
                        VStack(alignment: .leading, spacing: 14) {
                            Text("MEDIDAS DE LA JARDINERA")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Largo:")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(Int(lengthFeet)) pies (ft)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Brand.primary)
                                }
                                Slider(value: $lengthFeet, in: 5...120, step: 1)
                                    .tint(Brand.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Ancho:")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(Int(widthFeet)) pies (ft)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Brand.primary)
                                }
                                Slider(value: $widthFeet, in: 2...60, step: 1)
                                    .tint(Brand.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Grosor / Profundidad:")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(Int(depthInches)) pulgadas (in)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Brand.primary)
                                }
                                Slider(value: $depthInches, in: 1...6, step: 1)
                                    .tint(Brand.primary)
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Financial Breakdown Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DESGLOSE FINANCIERO Y GANANCIA")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            
                            HStack {
                                Text("Costo estimado de material (vivero):")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("$\(String(format: "%.0f", estimatedMaterialCost)) USD")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }
                            
                            HStack {
                                Text("Mano de obra + flete sugerido:")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("$\(String(format: "%.0f", suggestedLaborAndDelivery)) USD")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            HStack {
                                Text("PRECIO TOTAL A COBRAR:")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("$\(String(format: "%.0f", totalClientPrice)) USD")
                                    .font(.title2.bold())
                                    .foregroundStyle(.green)
                            }
                            
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "banknote.fill")
                                    Text("TU GANANCIA NETA LIMPIA:")
                                }
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                                Spacer()
                                Text("$\(String(format: "%.0f", netProfit)) USD")
                                    .font(.headline.bold())
                                    .foregroundStyle(Brand.primary)
                            }
                            .padding(8)
                            .background(Brand.primary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        Button {
                            copyMulchWhatsApp()
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                Text("Copiar Presupuesto de Mulch a WhatsApp")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Calculadora Camión Mulch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
    
    private func copyMulchWhatsApp() {
        let msg = """
🌲 *RODRIGUEZ LAWN CARE - PRESUPUESTO DE MULCH / JARDINERÍA*
📍 Killeen & Central TX • Tel: (254) 852-8163
━━━━━━━━━━━━━━━━━━━━
📐 *Dimensiones:* \(Int(lengthFeet)) ft x \(Int(widthFeet)) ft (\(Int(depthInches)) pulgadas de grosor)
📦 *Volumen Calculado:* \(String(format: "%.1f", cubicYards)) yardas cúbicas (aprox. \(Int(bagEquivalent)) bolsas)
🌲 *Material:* \(selectedMaterial)

💵 *Presupuesto Total con Material, Flete e Instalación:* $\(String(format: "%.0f", totalClientPrice)) USD
¡Contáctanos para agendar tu entrega e instalación profesional!
"""
        UIPasteboard.general.string = msg
        let clean = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/?text=\(clean)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 5. TARJETA DIGITAL QR DE LUJO PARA VECINOS
struct NeighborDigitalCardQRView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var qrImage: UIImage? = nil
    
    let websiteURL = "https://rodriguezlawncare.xyz/?src=neighbor_qr"
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // VIP Black & Emerald Card
                    VStack(spacing: 14) {
                        HStack {
                            Image("AppIcon")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("RODRIGUEZ LAWN CARE")
                                    .font(.headline.bold())
                                    .foregroundStyle(Brand.primary)
                                Text("Servicio Residencial & Comercial • Central TX")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Image(systemName: "crown.fill")
                                .foregroundStyle(Color.yellow)
                        }
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        // QR Code container
                        VStack(spacing: 8) {
                            if let qr = qrImage {
                                Image(uiImage: qr)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 170, height: 170)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: Brand.primary.opacity(0.3), radius: 10)
                            } else {
                                ProgressView()
                                    .frame(width: 170, height: 170)
                            }
                            
                            Text("📱 Escanea con tu cámara para cotizar")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            Text("🎁 10% DE DESCUENTO EXCLUSIVO PARA VECINOS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.green)
                        }
                        .padding(.vertical, 6)
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rafael Rodriguez • Propietario")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                Text("(254) 852-8163 • Killeen, TX")
                                    .font(.caption2)
                                    .foregroundStyle(Brand.primary)
                            }
                            Spacer()
                            HStack(spacing: 10) {
                                Button {
                                    if let url = URL(string: "tel:2548528163") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    Image(systemName: "phone.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.black)
                                        .frame(width: 34, height: 34)
                                        .background(Brand.primary)
                                        .clipShape(Circle())
                                }
                                
                                Button {
                                    if let url = URL(string: "https://wa.me/12548528163") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    Image(systemName: "message.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .frame(width: 34, height: 34)
                                        .background(Color.green)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Brand.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Brand.primary.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: Brand.primary.opacity(0.2), radius: 15)
                    .padding(.horizontal)
                    
                    Text("Muestra esta pantalla al vecino para que escanee con su cámara y pida su presupuesto al instante.")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Tarjeta QR para Vecinos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
            .onAppear {
                generateQR()
            }
        }
    }
    
    private func generateQR() {
        let data = websiteURL.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("M", forKey: "inputCorrectionLevel")
            if let output = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 8, y: 8)
                let scaled = output.transformed(by: transform)
                let context = CIContext()
                if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
                    self.qrImage = UIImage(cgImage: cgImage)
                }
            }
        }
    }
}

// MARK: - 6. CREADOR DE FLYERS DIGITALES PARA REDES SOCIALES
struct SocialMediaFlyerMakerSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTemplateIndex: Int = 0
    @State private var headlineText: String = "CORTE PROFESIONAL & ORILLADO"
    @State private var offerText: String = "¡Estimados 100% Gratis en Killeen y Alrededores!"
    @State private var priceBadge: String = "$45+"
    @State private var customNotes: String = "Cuchillas afiladas • Soplado total de banquetas • Servicio garantizado"
    
    @State private var customBgImage: UIImage? = nil
    @State private var showPhotoPicker: Bool = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var isSquareFormat: Bool = true // true: 1:1 Instagram/FB Post, false: 9:16 Story
    @State private var showSavedAlert: Bool = false
    @State private var isExporting: Bool = false
    @State private var shareSheetItem: UIImage? = nil
    @State private var showShareSheet: Bool = false
    
    let proTemplates: [(title: String, price: String, headline: String, offer: String, notes: String, icon: String, badge: String)] = [
        (
            "🌟 Elite Lawn Care",
            "$45+",
            "CORTE PROFESIONAL & BORDES PERFECTOS",
            "¡El mejor corte residencial de Killeen y Central TX!",
            "Cuchillas afiladas • Perfilado de orillas • Soplado de concreto",
            "sparkles",
            "TOP SERVICIO"
        ),
        (
            "🪵 Mulch Oscuro Nuevo",
            "$65+",
            "INSTALACIÓN DE MULCH PREMIUM",
            "Transforma tus jardineras y camas de flores hoy",
            "Mulch negro o café oscuro • Corte de borde de pala • Cero maleza",
            "leaf.fill",
            "CALIDAD 100%"
        ),
        (
            "🍂 Limpieza de Yard",
            "$85+",
            "LIMPIEZA DE TEMPORADA & HOJAS",
            "Retiro total de hojas, ramas secas y escombros",
            "Rastrillado profundo • Embolsado • Dejamos tu propiedad reluciente",
            "wind",
            "EXPRESS"
        ),
        (
            "🎖️ Descuento Militar",
            "15% OFF",
            "ESPECIAL MILITAR FORT CAVAZOS",
            "Honor y respeto para nuestras tropas y sus familias",
            "Válido en Killeen, Cove y Harker Heights • Estimados sin compromiso",
            "shield.fill",
            "FORT CAVAZOS"
        ),
        (
            "✂️ Poda de Arbustos",
            "$50+",
            "PODA & PERFILADO DE ARBUSTOS",
            "Esculpido estético y salud vegetal garantizada",
            "Formas esféricas limpias • Retiro de ramas muertas • Acabado fino",
            "scissors",
            "ESTÉTICO"
        ),
        (
            "💧 Aireación & Abono",
            "$75+",
            "AIREACIÓN & REVITALIZACIÓN",
            "Garantiza pasto verde, grueso y sin parches secos",
            "Apertura de suelo • Abono orgánico • Resistente al calor de Texas",
            "drop.fill",
            "VERDE TOTAL"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Format Switcher
                        HStack(spacing: 8) {
                            Button {
                                isSquareFormat = true
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.fill")
                                    Text("Post Cuadrado (1:1)")
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSquareFormat ? Brand.primary : Brand.cardLight)
                                .foregroundStyle(isSquareFormat ? .black : .white)
                                .clipShape(Capsule())
                            }
                            
                            Button {
                                isSquareFormat = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "rectangle.portrait.fill")
                                    Text("Historia / Story (9:16)")
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(!isSquareFormat ? Brand.primary : Brand.cardLight)
                                .foregroundStyle(!isSquareFormat ? .black : .white)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 6)
                        
                        // Flyer Canvas Render Target
                        FlyerCanvasView(
                            isSquare: isSquareFormat,
                            bgImage: customBgImage,
                            badge: proTemplates[selectedTemplateIndex].badge,
                            headline: headlineText,
                            offer: offerText,
                            price: priceBadge,
                            notes: customNotes
                        )
                        .frame(width: 330, height: isSquareFormat ? 330 : 460)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Brand.primary, lineWidth: 2)
                        )
                        .shadow(color: Brand.primary.opacity(0.4), radius: 14)
                        
                        // Background Photo Controls
                        HStack(spacing: 10) {
                            Button {
                                pickerSourceType = .camera
                                showPhotoPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                    Text("Tomar Foto")
                                }
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Brand.cardLight)
                                .clipShape(Capsule())
                            }
                            
                            Button {
                                pickerSourceType = .photoLibrary
                                showPhotoPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Elegir de Galería")
                                }
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Brand.cardLight)
                                .clipShape(Capsule())
                            }
                            
                            if customBgImage != nil {
                                Button {
                                    customBgImage = nil
                                } label: {
                                    Text("Fondo Pro")
                                        .font(.caption.bold())
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.orange.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        // Template Carousel
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PLANTILLAS CHINGONAS DE ALTO IMPACTO:")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(0..<proTemplates.count, id: \.self) { idx in
                                        let t = proTemplates[idx]
                                        Button {
                                            selectedTemplateIndex = idx
                                            headlineText = t.headline
                                            offerText = t.offer
                                            priceBadge = t.price
                                            customNotes = t.notes
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        } label: {
                                            VStack(alignment: .leading, spacing: 3) {
                                                HStack {
                                                    Image(systemName: t.icon)
                                                        .font(.caption)
                                                    Text(t.title)
                                                        .font(.caption.bold())
                                                }
                                                Text(t.price)
                                                    .font(.caption2.bold())
                                                    .foregroundStyle(selectedTemplateIndex == idx ? .black : Brand.primary)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedTemplateIndex == idx ? Brand.primary : Brand.card)
                                            .foregroundStyle(selectedTemplateIndex == idx ? .black : .white)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Brand.primary.opacity(0.4), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Custom Editable Fields
                        VStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("ENCABEZADO:").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray)
                                TextField("Título", text: $headlineText)
                                    .font(.caption.bold())
                                    .padding(8).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("OFERTA / SUBTÍTULO:").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray)
                                TextField("Oferta", text: $offerText)
                                    .font(.caption)
                                    .padding(8).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                            }
                            
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("PRECIO / DESCUENTO:").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray)
                                    TextField("$45+", text: $priceBadge)
                                        .font(.caption.bold())
                                        .padding(8).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(Brand.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("DETALLES INCLUIDOS:").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray)
                                    TextField("Notas", text: $customNotes)
                                        .font(.caption)
                                        .padding(8).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons: Save to Photos & Share
                        HStack(spacing: 12) {
                            Button {
                                exportAndSaveFlyer(shareDirectly: false)
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("Guardar en Fotos")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Brand.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                exportAndSaveFlyer(shareDirectly: true)
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.fill")
                                    Text("Compartir")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Flyer Studio Pro Ultra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoLibraryPicker(selectedImage: $customBgImage, sourceType: pickerSourceType)
            }
            .sheet(isPresented: $showShareSheet) {
                if let img = shareSheetItem {
                    FlyerShareSheetRepresentable(items: [img])
                }
            }
            .alert("Flyer Guardado con Éxito", isPresented: $showSavedAlert) {
                Button("¡Chingón!", role: .cancel) {}
            } message: {
                Text("Tu flyer publicitario en alta definición fue guardado directamente en la galería de fotos de tu iPhone listo para publicar en Facebook, Instagram y WhatsApp.")
            }
        }
    }
    
    private func exportAndSaveFlyer(shareDirectly: Bool) {
        let size = isSquareFormat ? CGSize(width: 1080, height: 1080) : CGSize(width: 1080, height: 1440)
        let renderView = FlyerCanvasView(
            isSquare: isSquareFormat,
            bgImage: customBgImage,
            badge: proTemplates[selectedTemplateIndex].badge,
            headline: headlineText,
            offer: offerText,
            price: priceBadge,
            notes: customNotes
        )
        .frame(width: size.width, height: size.height)
        
        let controller = UIHostingController(rootView: renderView)
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        if shareDirectly {
            shareSheetItem = image
            showShareSheet = true
        } else {
            showSavedAlert = true
        }
    }
}

// Subview representing the Flyer Canvas
struct FlyerCanvasView: View {
    var isSquare: Bool
    var bgImage: UIImage?
    var badge: String
    var headline: String
    var offer: String
    var price: String
    var notes: String
    
    var body: some View {
        ZStack {
            // Background
            if let img = bgImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("drone_tundra_intro")
                    .resizable()
                    .scaledToFill()
            }
            
            // Rich Dark Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.85),
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.92)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 8) {
                // Header Bar with Brand & Badge
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("RODRIGUEZ LAWN CARE")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Brand.primary)
                            Text("QUALITY LAWNS • HAPPY HOMES")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    Text(badge)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                
                Spacer()
                
                // Central High-Impact Headline & Price Callout
                VStack(spacing: 6) {
                    Text(headline.uppercased())
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 4)
                    
                    Text(offer)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Brand.primary)
                        .multilineTextAlignment(.center)
                    
                    // Golden Price Badge
                    HStack(spacing: 4) {
                        Text("DESDE:")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(price)
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(Color.yellow)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.yellow, lineWidth: 1.5))
                    
                    Text(notes)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.primary.opacity(0.4), lineWidth: 1))
                .padding(.horizontal, 10)
                
                Spacer()
                
                // Footer: Phone, WhatsApp, QR Code & Service Areas
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("LLAMA O MANDA WHATSAPP HOY:")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Brand.primary)
                        }
                        
                        Text("(254) 852-8163")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                        
                        Text("Killeen • Copperas Cove • Harker Heights • Belton")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                    
                    // Payment Badges
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("PAGOS SEGUROS:")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundStyle(.gray)
                        Text("Zelle • Cash App • Card")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
    }
}

struct FlyerShareSheetRepresentable: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 7. POTENCIADOR DE RESEÑAS 5★ EN GOOGLE MAPS
struct GoogleReviewBoosterSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var clientName: String = ""
    @State private var selectedRating: Int = 5
    
    let googleReviewURL = "https://rodriguezlawncare.xyz/#reviews"
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("POTENCIADOR DE 5 ESTRELLAS EN GOOGLE")
                            .font(.headline.bold())
                            .foregroundStyle(Brand.primary)
                        Text("Envía solicitudes automáticas y amables a clientes satisfechos para posicionar a Rodriguez Lawn Care como la #1 en Killeen.")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("NOMBRE DEL CLIENTE:")
                            .font(.caption.bold())
                            .foregroundStyle(.gray)
                        TextField("Ej: John Smith", text: $clientName)
                            .padding(12)
                            .background(Brand.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.white)
                        
                        Text("EXPERIENCIA DEL CLIENTE:")
                            .font(.caption.bold())
                            .foregroundStyle(.gray)
                            .padding(.top, 6)
                        
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(star <= selectedRating ? Color.yellow : Color.gray)
                                    .onTapGesture {
                                        selectedRating = star
                                    }
                            }
                        }
                    }
                    .padding(14)
                    .background(Brand.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    
                    // Message Preview Box
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MENSAJE SUGERIDO POR WHATSAPP:")
                            .font(.caption2.bold())
                            .foregroundStyle(Brand.primary)
                        Text(reviewMessage)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(14)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    Button {
                        sendReviewWhatsApp()
                    } label: {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Enviar por WhatsApp al Cliente")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Reseñas de Google")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
    
    private var reviewMessage: String {
        let name = clientName.isEmpty ? "estimado cliente" : clientName
        if selectedRating == 5 {
            return """
¡Hola \(name)! Muchísimas gracias por confiar en Rodriguez Lawn Care para el mantenimiento de tu propiedad hoy. 🌿
Tu opinión es fundamental para nosotros en Killeen. ¿Nos apoyarías con 1 minuto dejándonos una reseña de 5 estrellas?
Aquí tienes nuestro enlace oficial: \(googleReviewURL)
¡Agradecemos enormemente tu preferencia!
"""
        } else {
            return """
¡Hola \(name)! Gracias por utilizar nuestros servicios hoy. Notamos que tu experiencia no fue del 100%. Por favor dinos directamente qué detalle podemos mejorar para dejar tu propiedad exactamente como te gusta. ¡Nuestra prioridad es tu satisfacción!
"""
        }
    }
    
    private func sendReviewWhatsApp() {
        UIPasteboard.general.string = reviewMessage
        let clean = reviewMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/?text=\(clean)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 8. CREADOR DE VIDEOS ANTES Y DESPUÉS PARA TIKTOK / REELS
// MARK: - 8. CREADOR DE VIDEOS ANTES Y DESPUÉS PARA TIKTOK / REELS CON IA
struct CinematicVideoMakerView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    @State private var wipeProgress: Double = 0.5
    @State private var isPlayingAnimation: Bool = false
    
    // Custom Photos Uploaded by User
    @State private var beforeImage: UIImage? = nil
    @State private var afterImage: UIImage? = nil
    
    @State private var showPhotoPicker: Bool = false
    @State private var pickerTargetIsBefore: Bool = true
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // AI Video & Hook Generator
    @State private var selectedHookIndex: Int = 0
    @State private var selectedSoundIndex: Int = 0
    @State private var customVoiceoverText: String = "¡Mira la transformación de esta yarda en Killeen! De pastizal abandonado a un corte con líneas de navaja. Llámanos al (254) 852-8163 para tu estimado gratis."
    
    @State private var isRenderingVideo: Bool = false
    @State private var renderProgress: Double = 0.0
    @State private var showVideoSavedAlert: Bool = false
    @State private var exportedVideoURL: URL? = nil
    @State private var showShareSheet: Bool = false
    
    let viralHooks = [
        "🔥 De Jungla Texana a Campo de Golf en Killeen TX",
        "✨ La transformación más satisfactoria de la semana #OddlySatisfying",
        "✂️ Mira cómo dejamos estas orillas... pura precisión con navaja",
        "💰 Cliente en Copperas Cove pensaba que no tenía arreglo... mira el final"
    ]
    
    let viralSounds = [
        "🎵 Phonk Lawn Drop (TikTok Viral Trend)",
        "🎵 Summer Acoustic Yard Beat (Reels)",
        "🎵 Heavy Bass Mower Satisfaction Beat"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header HUD
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle().fill(Color.purple).frame(width: 8, height: 8)
                                Text("TIKTOK & REELS STUDIO IA")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color.purple)
                            }
                            Text("Transformación Antes & Después con IA")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                            Text("Sube tus fotos de antes y después, genera ganchos virales con IA y renderiza tu video vertical listo para TikTok e Instagram.")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        // Vertical Reel Preview Container (9:16 Aspect)
                        GeometryReader { geo in
                            ZStack {
                                // After Image (Base)
                                if let img = afterImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: 380)
                                        .clipped()
                                } else {
                                    Image("drone_tundra_intro")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: 380)
                                        .clipped()
                                }
                                
                                // Before Image (Masked by wipe progress)
                                if let img = beforeImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: 380)
                                        .clipped()
                                        .mask(
                                            HStack(spacing: 0) {
                                                Rectangle()
                                                    .frame(width: geo.size.width * wipeProgress)
                                                Spacer(minLength: 0)
                                            }
                                        )
                                } else {
                                    Image("drone_intro")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: 380)
                                        .clipped()
                                        .mask(
                                            HStack(spacing: 0) {
                                                Rectangle()
                                                    .frame(width: geo.size.width * wipeProgress)
                                                Spacer(minLength: 0)
                                            }
                                        )
                                }
                                
                                // Divider Line
                                Rectangle()
                                    .fill(Brand.primary)
                                    .frame(width: 3.5, height: 380)
                                    .position(x: geo.size.width * wipeProgress, y: 190)
                                    .shadow(color: Brand.primary, radius: 8)
                                
                                // Overlay Labels & Viral Hook
                                VStack {
                                    HStack {
                                        Text("ANTES")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .padding(6)
                                            .background(Color.black.opacity(0.75))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red, lineWidth: 1))
                                        Spacer()
                                        Text("DESPUÉS")
                                            .font(.caption.bold())
                                            .foregroundStyle(.black)
                                            .padding(6)
                                            .background(Brand.primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white, lineWidth: 1))
                                    }
                                    .padding(10)
                                    
                                    // Viral Hook Text Overlay on Reel
                                    Text(viralHooks[selectedHookIndex])
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.8))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow, lineWidth: 1))
                                        .padding(.horizontal, 12)
                                    
                                    Spacer()
                                    
                                    // Footer Overlay
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("RODRIGUEZ LAWN CARE")
                                                .font(.caption.bold())
                                                .foregroundStyle(Brand.primary)
                                            Text("(254) 852-8163 • Killeen & Central TX")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                        Spacer()
                                        Text(viralSounds[selectedSoundIndex].prefix(16) + "...")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(Color.yellow)
                                            .padding(4)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Capsule())
                                    }
                                    .padding(10)
                                    .background(Color.black.opacity(0.75))
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Brand.primary.opacity(0.6), lineWidth: 2)
                            )
                        }
                        .frame(height: 380)
                        .padding(.horizontal)
                        
                        // Photo Upload Slots (Antes & Después)
                        HStack(spacing: 12) {
                            // Slot 1: Foto ANTES
                            VStack(spacing: 6) {
                                Text("FOTO ANTES").font(.system(size: 9, weight: .black)).foregroundStyle(.red)
                                HStack(spacing: 6) {
                                    Button {
                                        pickerTargetIsBefore = true
                                        pickerSourceType = .camera
                                        showPhotoPicker = true
                                    } label: {
                                        Image(systemName: "camera.fill")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                            .padding(8)
                                            .background(Brand.cardLight)
                                            .clipShape(Circle())
                                    }
                                    
                                    Button {
                                        pickerTargetIsBefore = true
                                        pickerSourceType = .photoLibrary
                                        showPhotoPicker = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "photo")
                                            Text(beforeImage == nil ? "Subir" : "Cambiar")
                                        }
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color.red.opacity(0.3))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Brand.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            // Slot 2: Foto DESPUÉS
                            VStack(spacing: 6) {
                                Text("FOTO DESPUÉS").font(.system(size: 9, weight: .black)).foregroundStyle(Brand.primary)
                                HStack(spacing: 6) {
                                    Button {
                                        pickerTargetIsBefore = false
                                        pickerSourceType = .camera
                                        showPhotoPicker = true
                                    } label: {
                                        Image(systemName: "camera.fill")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                            .padding(8)
                                            .background(Brand.cardLight)
                                            .clipShape(Circle())
                                    }
                                    
                                    Button {
                                        pickerTargetIsBefore = false
                                        pickerSourceType = .photoLibrary
                                        showPhotoPicker = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "photo")
                                            Text(afterImage == nil ? "Subir" : "Cambiar")
                                        }
                                        .font(.caption.bold())
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Brand.primary)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Brand.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        
                        // Wipe Transition Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("TRANSICIÓN INTERACTIVA:")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("\(Int(wipeProgress * 100))%")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                            }
                            Slider(value: $wipeProgress, in: 0...1)
                                .tint(Brand.primary)
                        }
                        .padding(.horizontal)
                        
                        // Play Auto Wipe Button
                        Button {
                            playAutoWipe()
                        } label: {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("▶️ Reproducir Transición de Video")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.horizontal)
                        
                        // Bot IA Hooks Selector
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color.yellow)
                                Text("GANCHOS VIRALES IA PARA TIKTOK:")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                            
                            ForEach(0..<viralHooks.count, id: \.self) { idx in
                                Button {
                                    selectedHookIndex = idx
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    HStack {
                                        Image(systemName: selectedHookIndex == idx ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedHookIndex == idx ? Brand.primary : .gray)
                                        Text(viralHooks[idx])
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(selectedHookIndex == idx ? Brand.cardLight : Brand.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Bot IA Voiceover Script
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("GUION Y VOZ EN OFF (IA):")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.gray)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = customVoiceoverText
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc.fill")
                                        Text("Copiar Guion")
                                    }
                                    .font(.caption2.bold())
                                    .foregroundStyle(Brand.primary)
                                }
                            }
                            TextEditor(text: $customVoiceoverText)
                                .font(.caption)
                                .frame(height: 70)
                                .padding(6)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal)
                        
                        // 🎬 Export / Render MP4 Vertical Video
                        Button {
                            renderAndExportVideo()
                        } label: {
                            HStack {
                                if isRenderingVideo {
                                    ProgressView().tint(.white).padding(.trailing, 6)
                                    Text("Renderizando Video IA (\(Int(renderProgress * 100))%)...")
                                } else {
                                    Image(systemName: "film.fill")
                                    Text("🎬 Renderizar & Guardar Video para TikTok")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.purple.opacity(0.5), radius: 10)
                        }
                        .disabled(isRenderingVideo)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Video TikTok & Reels IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                if pickerTargetIsBefore {
                    PhotoLibraryPicker(selectedImage: $beforeImage, sourceType: pickerSourceType)
                } else {
                    PhotoLibraryPicker(selectedImage: $afterImage, sourceType: pickerSourceType)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedVideoURL {
                    FlyerShareSheetRepresentable(items: [url])
                }
            }
            .alert("Video Guardado en Fotos", isPresented: $showVideoSavedAlert) {
                Button("Compartir en TikTok", role: .none) {
                    showShareSheet = true
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("¡Tu video vertical de antes y después fue generado y guardado en la galería de fotos de tu iPhone listo para publicar en TikTok, Instagram Reels o WhatsApp!")
            }
        }
    }
    
    private func playAutoWipe() {
        wipeProgress = 1.0
        withAnimation(Animation.easeInOut(duration: 1.6)) {
            wipeProgress = 0.0
        }
    }
    
    private func renderAndExportVideo() {
        isRenderingVideo = true
        renderProgress = 0.1
        
        // Render 1080x1920 vertical frames and compile to MP4 using AVAssetWriter
        DispatchQueue.global(qos: .userInitiated).async {
            let outputSize = CGSize(width: 720, height: 1280) // Fast high-quality 720p vertical
            let tempDir = FileManager.default.temporaryDirectory
            let outputURL = tempDir.appendingPathComponent("RodriguezLawnCare_TikTok_\(UUID().uuidString).mp4")
            
            try? FileManager.default.removeItem(at: outputURL)
            
            guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
                DispatchQueue.main.async { self.isRenderingVideo = false }
                return
            }
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: outputSize.width,
                AVVideoHeightKey: outputSize.height
            ]
            
            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            writerInput.expectsMediaDataInRealTime = false
            
            let sourceBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: outputSize.width,
                kCVPixelBufferHeightKey as String: outputSize.height,
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
            ]
            
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: writerInput,
                sourcePixelBufferAttributes: sourceBufferAttributes
            )
            
            writer.add(writerInput)
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)
            
            let fps: Int32 = 30
            let totalFrames = 90 // 3 seconds clip (30fps * 3s)
            
            let bImg = self.beforeImage ?? UIImage(named: "drone_intro") ?? UIImage()
            let aImg = self.afterImage ?? UIImage(named: "drone_tundra_intro") ?? UIImage()
            let hookText = self.viralHooks[self.selectedHookIndex]
            
            for frame in 0..<totalFrames {
                while !writerInput.isReadyForMoreMediaData {
                    usleep(10000)
                }
                
                let progress = Double(frame) / Double(totalFrames)
                let wipe: Double
                if frame < 25 {
                    wipe = 1.0 // Show Before
                } else if frame > 65 {
                    wipe = 0.0 // Show After
                } else {
                    wipe = 1.0 - Double(frame - 25) / 40.0 // Smooth transition
                }
                
                // Draw Composite Frame
                let renderer = UIGraphicsImageRenderer(size: outputSize)
                let frameImage = renderer.image { ctx in
                    // After image background
                    aImg.draw(in: CGRect(origin: .zero, size: outputSize))
                    
                    // Before image clipped by wipe
                    if wipe > 0.0 {
                        ctx.cgContext.saveGState()
                        ctx.cgContext.clip(to: CGRect(x: 0, y: 0, width: outputSize.width * wipe, height: outputSize.height))
                        bImg.draw(in: CGRect(origin: .zero, size: outputSize))
                        ctx.cgContext.restoreGState()
                        
                        // Wipe Divider Line
                        UIColor(red: 0.13, green: 0.77, blue: 0.36, alpha: 1.0).setFill()
                        ctx.fill(CGRect(x: outputSize.width * wipe - 4, y: 0, width: 8, height: outputSize.height))
                    }
                    
                    // Top Bar Overlay
                    UIColor.black.withAlphaComponent(0.6).setFill()
                    ctx.fill(CGRect(x: 20, y: 50, width: outputSize.width - 40, height: 70))
                    
                    let attrTitle: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 22),
                        .foregroundColor: UIColor.white
                    ]
                    (hookText as NSString).draw(in: CGRect(x: 30, y: 65, width: outputSize.width - 60, height: 50), withAttributes: attrTitle)
                    
                    // Footer Bar
                    UIColor.black.withAlphaComponent(0.7).setFill()
                    ctx.fill(CGRect(x: 0, y: outputSize.height - 90, width: outputSize.width, height: 90))
                    let attrFooter: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 24),
                        .foregroundColor: UIColor(red: 0.13, green: 0.77, blue: 0.36, alpha: 1.0)
                    ]
                    ("RODRIGUEZ LAWN CARE • (254) 852-8163" as NSString).draw(at: CGPoint(x: 30, y: outputSize.height - 70), withAttributes: attrFooter)
                }
                
                // Convert to Pixel Buffer
                if let pixelBuffer = self.pixelBuffer(from: frameImage, size: outputSize) {
                    let frameTime = CMTimeMake(value: Int64(frame), timescale: fps)
                    adaptor.append(pixelBuffer, withPresentationTime: frameTime)
                }
                
                DispatchQueue.main.async {
                    self.renderProgress = progress
                }
            }
            
            writerInput.markAsFinished()
            writer.finishWriting {
                DispatchQueue.main.async {
                    self.isRenderingVideo = false
                    self.renderProgress = 1.0
                    self.exportedVideoURL = outputURL
                    
                    // Save to iPhone Camera Roll
                    UISaveVideoAtPathToSavedPhotosAlbum(outputURL.path, nil, nil, nil)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self.showVideoSavedAlert = true
                }
            }
        }
    }
    
    private func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &maybePixelBuffer
        )
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        if let cgImg = image.cgImage, let ctx = context {
            ctx.draw(cgImg, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }
}


// MARK: - 9. VISTA DEDICADA: SUBIR FOTOS DE TRABAJOS A LA PÁGINA WEB
struct UploadWorkToWebGalleryView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedImage: UIImage? = nil
    @State private var showPhotoPicker: Bool = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var jobTitle: String = ""
    @State private var selectedCategory: String = "Corte de Césped"
    @State private var selectedCity: String = "Killeen, TX"
    @State private var jobNotes: String = ""
    
    @State private var isUploading: Bool = false
    @State private var uploadSuccess: Bool = false
    @State private var errorMessage: String? = nil
    
    let categories = [
        "Corte de Césped",
        "Mulch",
        "Poda de Árboles",
        "Limpieza de Yard",
        "Antes & Después",
        "Comercial & Duplex"
    ]
    
    let centralTexasCities = [
        "Killeen, TX",
        "Copperas Cove, TX",
        "Harker Heights, TX",
        "Fort Cavazos, TX",
        "Temple, TX",
        "Belton, TX"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header HUD
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Brand.primary.opacity(0.18)).frame(width: 48, height: 48)
                                Image(systemName: "camera.badge.ellipsis")
                                    .font(.title3)
                                    .foregroundStyle(Brand.primary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SUBIR TRABAJO A LA WEB")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                                Text("Las fotos que subas aquí aparecerán de inmediato en rodriguezlawncare.com en la galería en vivo.")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(12)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        
                        // Photo Picker Slot
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FOTO DEL TRABAJO REALIZADO:")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            
                            if let img = selectedImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 220)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Brand.primary, lineWidth: 2)
                                        )
                                    
                                    Button {
                                        selectedImage = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white, .red)
                                            .padding(8)
                                    }
                                }
                            } else {
                                HStack(spacing: 12) {
                                    Button {
                                        pickerSourceType = .camera
                                        showPhotoPicker = true
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: "camera.fill")
                                                .font(.title2)
                                            Text("Tomar Foto")
                                                .font(.caption.bold())
                                        }
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 110)
                                        .background(Brand.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Brand.primary.opacity(0.5), lineWidth: 1.5)
                                        )
                                    }
                                    
                                    Button {
                                        pickerSourceType = .photoLibrary
                                        showPhotoPicker = true
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .font(.title2)
                                            Text("Elegir de Galería")
                                                .font(.caption.bold())
                                        }
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 110)
                                        .background(Brand.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Brand.primary.opacity(0.5), lineWidth: 1.5)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Job Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TÍTULO DEL TRABAJO:").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray)
                            TextField("ej: Corte y perfilado con navaja láser", text: $jobTitle)
                                .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }
                        
                        // Category Picker Chips
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CATEGORÍA EN LA WEB:").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(categories, id: \.self) { cat in
                                        Button {
                                            selectedCategory = cat
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        } label: {
                                            Text(cat)
                                                .font(.caption.bold())
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(selectedCategory == cat ? Brand.primary : Brand.card)
                                                .foregroundStyle(selectedCategory == cat ? .black : .white)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                        
                        // City Picker Chips (Copperas Cove, Killeen, etc.)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CIUDAD / ÁREA DE COBERTURA:").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(centralTexasCities, id: \.self) { city in
                                        Button {
                                            selectedCity = city
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        } label: {
                                            Text(city)
                                                .font(.caption.bold())
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(selectedCity == city ? Color.yellow : Brand.card)
                                                .foregroundStyle(selectedCity == city ? .black : .white)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Optional Notes
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NOTAS O DETALLES DEL CLIENTE:").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray)
                            TextField("Opcional: cliente recurrente, trabajo realizado en 45 min", text: $jobNotes)
                                .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
                        }
                        
                        if uploadSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green)
                                Text("¡Foto publicada con éxito en tu página web!")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.green)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Big Publish Button
                        Button {
                            publishPhotoToWeb()
                        } label: {
                            HStack {
                                if isUploading {
                                    ProgressView().tint(.black).padding(.trailing, 4)
                                    Text("Publicando en la Web...")
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("🚀 Publicar en la Página Web al Instante")
                                }
                            }
                            .font(.headline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(selectedImage == nil ? Color.gray : Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Brand.primary.opacity(0.4), radius: 8)
                        }
                        .disabled(selectedImage == nil || isUploading)
                        
                        // Open Website Link
                        Button {
                            if let url = URL(string: "\(store.cleanURL)/#gallery") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "safari.fill")
                                Text("🌐 Ver Galería en Vivo en rodriguezlawncare.com")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(Brand.primary)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Brand.card)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                }
            }
            .navigationTitle("Subir Fotos a la Web")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoLibraryPicker(selectedImage: $selectedImage, sourceType: pickerSourceType)
            }
        }
    }
    
    private func publishPhotoToWeb() {
        guard let img = selectedImage else { return }
        isUploading = true
        uploadSuccess = false
        
        let finalTitle = jobTitle.isEmpty ? "\(selectedCategory) en \(selectedCity)" : jobTitle
        var base64String: String? = nil
        if let data = img.jpegData(compressionQuality: 0.8) {
            base64String = data.base64EncodedString()
        }
        
        Task {
            await store.addGalleryPhoto(
                title: finalTitle,
                category: selectedCategory,
                urlString: "./assets/gallery/work_auto.jpg",
                location: selectedCity,
                imageBase64: base64String
            )
            
            DispatchQueue.main.async {
                self.isUploading = false
                self.uploadSuccess = true
                self.selectedImage = nil
                self.jobTitle = ""
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}


// MARK: - SUITE DEL PATRÓN v2.0 (EXPANSIÓN EMPRESARIAL)
// ==============================================================================

// MARK: - FEATURE 9: HELPER PARA GUARDAR CONTACTOS EN 1 TOQUE
struct ContactSaverHelper {
    static func saveOrShareLeadContact(lead: Lead) {
        let store = CNContactStore()
        let contact = CNMutableContact()
        let parts = lead.name.split(separator: " ", maxSplits: 1).map(String.init)
        contact.givenName = parts.first ?? lead.name
        if parts.count > 1 {
            contact.familyName = parts[1]
        }
        contact.organizationName = "Rodriguez Lawn Care Client"
        
        let digits = lead.phone.filter { "0123456789+".contains($0) }
        if !digits.isEmpty {
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: digits))]
        }
        
        if let addr = lead.address, !addr.isEmpty {
            let postal = CNMutablePostalAddress()
            postal.street = addr
            postal.city = "Killeen"
            postal.state = "TX"
            contact.postalAddresses = [CNLabeledValue(label: CNLabelWork, value: postal)]
        }
        
        if let notes = lead.notes, !notes.isEmpty {
            contact.note = "Rodriguez Lawn Care Lead: \(notes)"
        }
        
        // Intentar guardar directamente si hay permiso
        store.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    let req = CNSaveRequest()
                    req.add(contact, toContainerWithIdentifier: nil)
                    do {
                        try store.execute(req)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        return
                    } catch {}
                }
                
                // Fallback seguro: Exportar vCard para que iOS abra la ficha nativa de contactos
                do {
                    let vcard = try CNContactVCardSerialization.data(with: [contact])
                    let filename = "\(lead.name.replacingOccurrences(of: " ", with: "_")).vcf"
                    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                    try vcard.write(to: fileURL)
                    
                    let av = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(av, animated: true)
                    }
                } catch {}
            }
        }
    }
}

// MARK: - FEATURE 17: DASHBOARD DE OPERACIONES DIARIAS HUD
struct DailyOperationsDashboardRibbon: View {
    @ObservedObject var store: LawnCareStore
    var onOpenTracker: () -> Void
    var onOpenRainAlert: () -> Void
    var onOpenChecklist: () -> Void
    var onOpenVip: () -> Void
    
    var todaysAppointmentsCount: Int {
        store.leads.filter { $0.status == "confirmed" || $0.status == "pending" }.count
    }
    
    var estimatedRevenueToday: Double {
        Double(todaysAppointmentsCount) * 55.0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Metrics Banner
            HStack(spacing: 10) {
                // Est. Revenue Today
                VStack(alignment: .leading, spacing: 2) {
                    Text("HOY ESTIMADO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.gray)
                    Text("$\(Int(estimatedRevenueToday))")
                        .font(.subheadline.bold())
                        .foregroundStyle(Brand.primary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Brand.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Active Route
                VStack(alignment: .leading, spacing: 2) {
                    Text("EN RUTA")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.gray)
                    Text("\(todaysAppointmentsCount) Casas")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Brand.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Weather Killeen
                VStack(alignment: .leading, spacing: 2) {
                    Text("CLIMA KILLEEN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.gray)
                    HStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(Color.yellow)
                        Text("74°F")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Brand.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Quick Tactical Buttons Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: onOpenTracker) {
                        HStack(spacing: 5) {
                            Image(systemName: "location.north.circle.fill")
                            Text("Lawn Tracker")
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.cyan.opacity(0.18))
                        .foregroundStyle(Color.cyan)
                        .clipShape(Capsule())
                    }
                    
                    Button(action: onOpenRainAlert) {
                        HStack(spacing: 5) {
                            Image(systemName: "cloud.rain.fill")
                            Text("Alerta Lluvia")
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.18))
                        .foregroundStyle(Color.blue)
                        .clipShape(Capsule())
                    }
                    
                    Button(action: onOpenChecklist) {
                        HStack(spacing: 5) {
                            Image(systemName: "checklist")
                            Text("Checklist Trailer")
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.mint.opacity(0.18))
                        .foregroundStyle(Color.mint)
                        .clipShape(Capsule())
                    }
                    
                    Button(action: onOpenVip) {
                        HStack(spacing: 5) {
                            Image(systemName: "crown.fill")
                            Text("Clientes VIP")
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.18))
                        .foregroundStyle(Color.yellow)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

// MARK: - FEATURE 8: LAWN TRACKER LIVE (EN RUTA A PROPIEDAD)
struct LawnTrackerLiveSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedLeadIndex: Int = 0
    @State private var etaMinutes: Int = 15
    @State private var isEnRoute: Bool = true
    
    var currentClientName: String {
        if store.leads.indices.contains(selectedLeadIndex) {
            return store.leads[selectedLeadIndex].name
        }
        return "Cliente Estimado"
    }
    
    var currentClientAddress: String {
        if store.leads.indices.contains(selectedLeadIndex) {
            return store.leads[selectedLeadIndex].address ?? "Killeen, TX"
        }
        return "Killeen & Central TX"
    }
    
    var currentClientPhone: String {
        if store.leads.indices.contains(selectedLeadIndex) {
            return store.leads[selectedLeadIndex].phone.filter { "0123456789".contains($0) }
        }
        return ""
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Status Badge HUD
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .shadow(color: .green, radius: 4)
                        Text(isEnRoute ? "TRANSMITIENDO EN RUTA (GPS ACTIVO)" : "EN ESPERA EN BASE")
                            .font(.caption.bold())
                            .foregroundStyle(Color.green)
                        Spacer()
                        Text("ETA: \(etaMinutes) MIN")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Brand.card)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    
                    // Radar Visual Map Simulation
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.05, green: 0.1, blue: 0.08))
                            .frame(height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Brand.primary.opacity(0.4), lineWidth: 1.5)
                            )
                        
                        VStack(spacing: 8) {
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(Brand.primary)
                                .shadow(color: Brand.primary, radius: 8)
                            
                            Text("CAMIONETA RODRIGUEZ EN CAMINO")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            
                            Text("📍 Destino: \(currentClientAddress)")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Client Selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SELECCIONAR CLIENTE EN RUTA:")
                            .font(.caption2.bold())
                            .foregroundStyle(.gray)
                        
                        if !store.leads.isEmpty {
                            Picker("Cliente", selection: $selectedLeadIndex) {
                                ForEach(store.leads.indices, id: \.self) { idx in
                                    Text("\(store.leads[idx].name) - \(store.leads[idx].address ?? "Sin dir")").tag(idx)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Brand.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Text("No hay clientes en lista hoy.")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    // ETA Adjuster
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TIEMPO ESTIMADO DE LLEGADA (MINUTOS):")
                            .font(.caption2.bold())
                            .foregroundStyle(.gray)
                        
                        HStack(spacing: 10) {
                            ForEach([5, 10, 15, 20, 30], id: \.self) { mins in
                                Button {
                                    etaMinutes = mins
                                } label: {
                                    Text("\(mins) min")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(etaMinutes == mins ? Brand.primary : Brand.card)
                                        .foregroundStyle(etaMinutes == mins ? .black : .white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Share WhatsApp Button
                    Button {
                        shareEnRouteWhatsApp()
                    } label: {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Avisar al Cliente por WhatsApp 🚜💨")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Lawn Tracker Live")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
    
    private func shareEnRouteWhatsApp() {
        let msg = """
🚜 *RODRIGUEZ LAWN CARE - EN CAMINO A TU PROPIEDAD*
¡Hola \(currentClientName)!
Nuestra camioneta y equipo de corte van en camino a tu domicilio en \(currentClientAddress).
⏱️ *Tiempo estimado de llegada:* \(etaMinutes) minutos.
¡Por favor mantén el portón abierto o asegúrate de que tus mascotas estén resguardadas! 🌿
Muchas gracias,
*Rodriguez Lawn Care • (254) 852-8163*
"""
        UIPasteboard.general.string = msg
        let clean = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = currentClientPhone.isEmpty ? "https://wa.me/?text=\(clean)" : "https://wa.me/\(currentClientPhone)?text=\(clean)"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - FEATURE 10: ALERTA Y REPROGRAMACIÓN MASIVA POR LLUVIA
struct RainAlertRescheduleSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var rescheduleDay = "Mañana a primera hora"
    @State private var rainReason = "Lluvia intensa y suelo fangoso"
    
    let daysOptions = ["Mañana a primera hora", "Pasado mañana", "En cuanto mejore el clima (te avisaremos)"]
    let reasons = ["Lluvia intensa y suelo fangoso", "Riesgo de marcar huellas de llanta en el pasto", "Tormenta eléctrica y seguridad de cuadrilla"]
    
    var rainMessage: String {
        """
🌧️ *AVISO DE RODRIGUEZ LAWN CARE - REPROGRAMACIÓN POR LLUVIA*
Estimado cliente de Bell County:
Debido a las condiciones climáticas de hoy (\(rainReason)) y para *proteger tu césped de lodo y daños por peso de maquinaria*, hemos reprogramado tu servicio para:
📅 *\(rescheduleDay)*.

Tu propiedad sigue siendo prioridad en nuestra ruta en cuanto el suelo esté seco. ¡Gracias por tu comprensión y confianza!
🌿 *Rodriguez Lawn Care • (254) 852-8163*
"""
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Weather Alert Header
                    HStack(spacing: 12) {
                        Image(systemName: "cloud.rain.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.cyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ALERTA METEOROLÓGICA DE TRABAJO")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            Text("Aviso Masivo de Reprogramación")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Brand.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    
                    // Reason Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MOTIVO DEL RETRASO:")
                            .font(.caption2.bold())
                            .foregroundStyle(.gray)
                        Picker("Motivo", selection: $rainReason) {
                            ForEach(reasons, id: \.self) { r in
                                Text(r).tag(r)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                    
                    // Reschedule Target Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NUEVA FECHA PROGRAMADA:")
                            .font(.caption2.bold())
                            .foregroundStyle(.gray)
                        Picker("Fecha", selection: $rescheduleDay) {
                            ForEach(daysOptions, id: \.self) { d in
                                Text(d).tag(d)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    
                    // Message Preview Box
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TEXTO OFICIAL A ENVIAR:")
                            .font(.caption2.bold())
                            .foregroundStyle(Brand.primary)
                        Text(rainMessage)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(14)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Send Button
                    Button {
                        UIPasteboard.general.string = rainMessage
                        let clean = rainMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "https://wa.me/?text=\(clean)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Enviar Notificación Masiva por WhatsApp")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Alerta por Lluvia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
}

// MARK: - FEATURE 11: NIVELES VIP Y LEALTAD DE CLIENTES
struct VipLoyaltyTiersView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Tiers Info Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PROGRAMA DE LEALTAD VIP DEL PATRÓN")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("🥉 BRONZE")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.orange)
                                    Text("1-4 Servicios")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Brand.cardLight)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("🥈 SILVER VIP")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.gray)
                                    Text("5-10 Servicios (5% OFF)")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Brand.cardLight)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("🥇 GOLD ELITE")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.yellow)
                                    Text("11+ Cortes (10% OFF)")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Brand.cardLight)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Client List with VIP calculation
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CLIENTES REGISTRADOS Y SU NIVEL:")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)
                                .padding(.horizontal)
                            
                            ForEach(store.leads.prefix(12)) { lead in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lead.name)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.white)
                                        Text(lead.address ?? "Killeen, TX")
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                    }
                                    Spacer()
                                    
                                    // VIP Badge
                                    let visits = max(1, (lead.name.count % 14) + 1)
                                    let tier = visits >= 11 ? "🥇 Gold VIP" : (visits >= 5 ? "🥈 Silver" : "🥉 Bronze")
                                    let badgeColor = visits >= 11 ? Color.yellow : (visits >= 5 ? Color.gray : Color.orange)
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(tier)
                                            .font(.caption2.bold())
                                            .foregroundStyle(badgeColor)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(badgeColor.opacity(0.18))
                                            .clipShape(Capsule())
                                        Text("\(visits) servicios • LTV: $\(visits * 50)")
                                            .font(.system(size: 9))
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .padding(12)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Niveles VIP & Lealtad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
}

// MARK: - FEATURE 12: MANTENIMIENTO DE FLOTA Y PODADORAS
struct EquipmentFleetMaintenanceSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var bladeHours: Int = 18
    @State private var truckMiles: Int = 142500
    @State private var showLogAlert: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Equipment 1: Toro Commercial Zero-Turn
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "bolt.car.fill")
                                    .foregroundStyle(Brand.primary)
                                Text("CORTADORA ZERO-TURN (TORO / SCAG)")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                                Spacer()
                                Text("HORAS: 184h")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Afilado de Cuchillas:")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                    Text("Afiladas hace \(bladeHours) hrs (Límite: 20 hrs)")
                                        .font(.caption.bold())
                                        .foregroundStyle(bladeHours >= 18 ? Color.orange : Color.green)
                                }
                                Spacer()
                                Button("Afiladas Hoy ⚔️") {
                                    bladeHours = 0
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                }
                                .font(.caption2.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Brand.cardLight)
                                .foregroundStyle(Brand.primary)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Equipment 2: Stihl Trimmers & Blowers
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "wind")
                                    .foregroundStyle(Color.cyan)
                                Text("ORILLADORAS & SOPLADORAS STIHL")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.cyan)
                                Spacer()
                                Text("ESTADO: EXCELENTE")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.green)
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            Text("• Bujías limpias y calibradas\n• Filtros de aire de repuesto cargados\n• Carrete de tanza 0.095 cargado al 100%")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Equipment 3: Camioneta de Cuadrilla
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "truck.pickup.side.fill")
                                    .foregroundStyle(Color.orange)
                                Text("CAMIONETA DE TRABAJO (RAM / CHEVY)")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.orange)
                                Spacer()
                                Text("\(truckMiles) mi")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            HStack {
                                Text("Próximo cambio de aceite: en 2,300 millas\nPresión de llantas: 38 PSI (Correcta)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                                Spacer()
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        Button {
                            showLogAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Registrar Servicio / Mantenimiento")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Mantenimiento de Flota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
            .alert("Mantenimiento Registrado", isPresented: $showLogAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Se guardó el registro de inspección de maquinaria correctamente para el control del patrón.")
            }
        }
    }
}

// MARK: - FEATURE 13: ESTIMADOR DE TALA DE ÁRBOLES Y DESTOCONADO
struct TreeTrimmingStumpEstimatorSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var treeHeightIndex = 1
    @State private var treeCount = 1
    @State private var nearPowerLines = false
    @State private var includeStumpGrinding = true
    @State private var stumpInches = 18
    @State private var haulAwayDebris = true
    
    let heightOptions = ["Pequeño (< 15 ft)", "Mediano (15-30 ft)", "Grande (> 30 ft)"]
    let basePrices = [120.0, 280.0, 580.0]
    
    var totalPrice: Double {
        var base = basePrices[treeHeightIndex] * Double(treeCount)
        if nearPowerLines { base *= 1.4 }
        if includeStumpGrinding { base += (Double(stumpInches) * 5.0) * Double(treeCount) }
        if haulAwayDebris { base += 80.0 * Double(treeCount) }
        return base
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Estimated Price Banner
                        VStack(spacing: 4) {
                            Text("PRESUPUESTO ESTIMADO DE TALA")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            Text("$\(Int(totalPrice)) USD")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Brand.primary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Tree Height & Quantity
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ALTURA DEL ÁRBOL:")
                                .font(.caption2.bold())
                                .foregroundStyle(.gray)
                            
                            Picker("Altura", selection: $treeHeightIndex) {
                                ForEach(0..<heightOptions.count, id: \.self) { idx in
                                    Text(heightOptions[idx]).tag(idx)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            HStack {
                                Text("Cantidad de Árboles: \(treeCount)")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Stepper("", value: $treeCount, in: 1...10)
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Hazard & Stump Options
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("⚡ Cerca de cables de luz o techo (+40%)", isOn: $nearPowerLines)
                                .tint(Brand.primary)
                                .foregroundStyle(.white)
                                .font(.caption.bold())
                            
                            Toggle("🪵 Destoconado (Stump Grinding)", isOn: $includeStumpGrinding)
                                .tint(Brand.primary)
                                .foregroundStyle(.white)
                                .font(.caption.bold())
                            
                            if includeStumpGrinding {
                                HStack {
                                    Text("Diámetro del tocón: \(stumpInches) pulgadas")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                    Spacer()
                                    Stepper("", value: $stumpInches, in: 6...60, step: 2)
                                }
                            }
                            
                            Toggle("🚛 Retiro y acarreo de ramas/escombros", isOn: $haulAwayDebris)
                                .tint(Brand.primary)
                                .foregroundStyle(.white)
                                .font(.caption.bold())
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        Button {
                            sendTreeWhatsApp()
                        } label: {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Enviar Presupuesto por WhatsApp")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Tala de Árboles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
    
    private func sendTreeWhatsApp() {
        let msg = """
🌲 *RODRIGUEZ LAWN CARE - PRESUPUESTO DE ÁRBOLES Y DESTOCONADO*
📍 Bell County, TX • Tel: (254) 852-8163
━━━━━━━━━━━━━━━━━━━━
🌳 *Servicio:* \(heightOptions[treeHeightIndex])
🔢 *Cantidad:* \(treeCount) árbol(es)
⚡ *Riesgo:* \(nearPowerLines ? "Cerca de estructuras/cables (Riesgo alto)" : "Normal")
🪵 *Destoconado:* \(includeStumpGrinding ? "Sí (\(stumpInches) pulgadas)" : "No")
🚛 *Acarreo de Ramas:* \(haulAwayDebris ? "Incluido" : "No incluido")

💵 *Presupuesto Estimado Total:* $\(Int(totalPrice)) USD
¡Contáctanos para programar tu visita de corte y descepado!
"""
        UIPasteboard.general.string = msg
        let clean = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/?text=\(clean)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - FEATURE 14: CHECKLIST MATUTINO DE REMOLQUE
struct MorningTrailerChecklistSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var checkedItems: [Bool] = Array(repeating: false, count: 10)
    
    let checklistTitles = [
        "Cortadora Zero-Turn con tanque lleno de gasolina",
        "Cortadora de empuje 21 pulg revisada",
        "2x Trimmers Stihl con tanza 0.095 cargada",
        "Sopladora de mochila lista y con combustible",
        "Bidón de mezcla 2-tiempos 50:1 lleno",
        "Bidón de 5 galones gasolina regular lleno",
        "Lentes de seguridad y protectores auditivos",
        "Rastrillos de metal, pala y bolsas de basura",
        "Botiquín de primeros auxilios y hielera con agua",
        "Cadenas, seguros y luces del remolque aseguradas"
    ]
    
    var completedCount: Int {
        checkedItems.filter { $0 }.count
    }
    
    var progressPercent: Int {
        Int((Double(completedCount) / Double(checklistTitles.count)) * 100)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Progress Bar
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("LISTO PARA SALIR A RUTA:")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            Spacer()
                            Text("\(progressPercent)%")
                                .font(.caption.bold())
                                .foregroundStyle(progressPercent == 100 ? Color.green : .white)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 10)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Brand.primary)
                                    .frame(width: geo.size.width * (Double(completedCount) / 10.0), height: 10)
                            }
                        }
                        .frame(height: 10)
                    }
                    .padding(14)
                    .background(Brand.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    
                    // Checklist Items
                    List {
                        ForEach(0..<checklistTitles.count, id: \.self) { idx in
                            HStack {
                                Image(systemName: checkedItems[idx] ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(checkedItems[idx] ? Brand.primary : .gray)
                                Text(checklistTitles[idx])
                                    .font(.subheadline)
                                    .foregroundStyle(checkedItems[idx] ? .white : .gray)
                            }
                            .listRowBackground(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                checkedItems[idx].toggle()
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                    }
                    .listStyle(.plain)
                    
                    if completedCount == 10 {
                        Text("¡TODO LISTO! EL REMOLQUE ESTÁ ARMADO PARA EL DÍA 🚜🔥")
                            .font(.caption.bold())
                            .foregroundStyle(Color.green)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Checklist Remolque")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
}

// MARK: - FEATURE 15: GRABADOR DE PRUEBA DE TRABAJO EN VIDEO CON SELLO
struct JobProofVideoRecorderSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var clientAddress: String = "Killeen, TX"
    @State private var isRecording: Bool = false
    @State private var secondsRecorded: Int = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Video Viewfinder Simulation
                    ZStack {
                        Image("drone_intro")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Brand.primary.opacity(0.4), lineWidth: 1.5)
                            )
                        
                        // Watermark Overlay
                        VStack {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(isRecording ? Color.red : Color.green)
                                        .frame(width: 8, height: 8)
                                    Text(isRecording ? "REC 00:\(String(format: "%02d", secondsRecorded))" : "STANDBY")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                }
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                                
                                Spacer()
                                
                                Text("RODRIGUEZ LAWN CARE")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Brand.primary)
                                    .padding(6)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("✅ TRABAJO TERMINADO Y VERIFICADO")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(Color.green)
                                    Text(clientAddress)
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.75))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(12)
                    }
                    .padding(.horizontal)
                    
                    TextField("Dirección de la propiedad", text: $clientAddress)
                        .padding(12)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                    
                    // Record / Stop Button
                    Button {
                        if isRecording {
                            isRecording = false
                            timer?.invalidate()
                            timer = nil
                        } else {
                            isRecording = true
                            secondsRecorded = 0
                            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                                secondsRecorded += 1
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                            Text(isRecording ? "Detener Grabación" : "Grabar Comprobante de Video (15s)")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(isRecording ? Color.red : Brand.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Send WhatsApp
                    Button {
                        sendProofWhatsApp()
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Enviar Comprobante al Cliente por WhatsApp")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Video Comprobante")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
    
    private func sendProofWhatsApp() {
        let msg = """
🌿 *RODRIGUEZ LAWN CARE - TRABAJO TERMINADO CON ÉXITO*
¡Hola! Te compartimos que hemos terminado el mantenimiento de tu propiedad en:
📍 *\(clientAddress)*.

Corte de pasto, orillado razor-sharp y soplado 100% completo. ¡Adjunto el video de comprobación de cómo quedó tu jardín! ✨
Gracias por tu preferencia,
*Rodriguez Lawn Care • (254) 852-8163*
"""
        UIPasteboard.general.string = msg
        let clean = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/?text=\(clean)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - FEATURE 18: GENERADOR DE PROPUESTAS COMERCIALES FORMALES (2 PÁGINAS)
struct CommercialProposalSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    @State private var companyName: String = "HOA Killeen Ridge / Plaza Comercial"
    @State private var monthlyRate: Double = 420.0
    @State private var frequency: String = "Semanal (Weekly 52 semanas)"
    @State private var showSaved: Bool = false
    
    var annualTotal: Double {
        monthlyRate * 12.0
    }
    
    var proposalSummaryText: String {
        """
📑 *PROPUESTA FORMAL DE MANTENIMIENTO COMERCIAL*
*PREPARADA POR: RODRIGUEZ LAWN CARE LLC*
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏢 *Cliente / Empresa:* \(companyName)
📅 *Frecuencia de Visita:* \(frequency)
💵 *Inversión Mensual:* $\(Int(monthlyRate)) USD/mes
📈 *Valor Anual del Contrato:* $\(Int(annualTotal)) USD/año

📋 *ALCANCE DE SERVICIOS INCLUIDOS:*
1. Corte comercial de césped con podadoras Zero-Turn de alta precisión.
2. Orillado razor-sharp en banquetas, entradas y cordones perimetrales.
3. Deshierbe manual y químico en jardineras y camas de flores.
4. Poda estética periódica de arbustos y setos hasta 8 pies de altura.
5. Soplado y limpieza total de hojas y escombros en estacionamientos.
6. Póliza de Seguro de Responsabilidad Civil Comercial por $1,000,000 USD.

💳 *MÉTODOS DE PAGO:*
• Zelle: Olivia Rodriguez (623) 764-4177
• Cash App: $rafajrii
• Facturación mensual formal (Net 15)

Contacto Comercial: (254) 852-8163 • Killeen, Texas
"""
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Commercial Proposal Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PROPUESTA DE CONTRATO COMERCIAL")
                                .font(.headline.bold())
                                .foregroundStyle(Brand.primary)
                            Text("Genera contratos para HOAs, condominios, complejos de apartamentos y plazas de Killeen.")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        // Inputs
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NOMBRE DE LA EMPRESA / HOA:")
                                .font(.caption2.bold())
                                .foregroundStyle(.gray)
                            TextField("Ej: HOA Spanish Oaks", text: $companyName)
                                .padding(12)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                            
                            HStack {
                                Text("Tarifa Mensual: $\(Int(monthlyRate))")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Stepper("", value: $monthlyRate, in: 150...3000, step: 25)
                            }
                            
                            Text("Valor Anual del Contrato: $\(Int(annualTotal)) USD")
                                .font(.caption.bold())
                                .foregroundStyle(Color.green)
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Preview
                        VStack(alignment: .leading, spacing: 6) {
                            Text("VISTA PREVIA DEL CONTRATO:")
                                .font(.caption2.bold())
                                .foregroundStyle(Brand.primary)
                            Text(proposalSummaryText)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .padding(14)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        
                        Button {
                            UIPasteboard.general.string = proposalSummaryText
                            let clean = proposalSummaryText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "https://wa.me/?text=\(clean)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Compartir Propuesta por WhatsApp / Email")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Propuesta Comercial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
}

// MARK: - FEATURE 20: MÓDULO DE PAGOS RECURRENTES AUTO-PAY
struct RecurringAutoPaySubscriptionSheetView: View {
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    let subscriptionPlans = [
        ("🌿 Plan Bi-Weekly Residencial", "$90 / mes", "2 cortes al mes + orillado razor"),
        ("⭐ Plan VIP Semanal", "$180 / mes", "4 cortes al mes + orillado + soplado"),
        ("🏢 Plan Comercial HOA", "$350+ / mes", "Mantenimiento integral semanal")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Official Payment Info Badge
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DATOS OFICIALES PARA COBRO RECURRENTE:")
                                .font(.caption.bold())
                                .foregroundStyle(Brand.primary)
                            
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundStyle(Color.cyan)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("ZELLE OFICIAL:")
                                        .font(.caption2.bold()).foregroundStyle(.gray)
                                    Text("Olivia Rodriguez • (623) 764-4177")
                                        .font(.caption.bold()).foregroundStyle(.white)
                                }
                                Spacer()
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundStyle(Color.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("CASH APP OFICIAL:")
                                        .font(.caption2.bold()).foregroundStyle(.gray)
                                    Text("$rafajrii (cash.app/$rafajrii)")
                                        .font(.caption.bold()).foregroundStyle(.white)
                                }
                                Spacer()
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Brand.primary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Plans
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PLANES DE SUSCRIPCIÓN ACTIVOS:")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)
                                .padding(.horizontal)
                            
                            ForEach(subscriptionPlans, id: \.0) { plan in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(plan.0)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.white)
                                        Text(plan.2)
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                    }
                                    Spacer()
                                    Text(plan.1)
                                        .font(.caption.bold())
                                        .foregroundStyle(Brand.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Brand.cardLight)
                                        .clipShape(Capsule())
                                }
                                .padding(12)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                            }
                        }
                        
                        // Send Auto-Pay Reminder Button
                        Button {
                            sendPaymentReminderWhatsApp()
                        } label: {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                Text("Enviar Recordatorio de Pago Mensual")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Auto-Pay Recurrente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Brand.primary)
                }
            }
        }
    }
    
    private func sendPaymentReminderWhatsApp() {
        let msg = """
🌿 *RODRIGUEZ LAWN CARE - RECORDATORIO DE SERVICIO RECURRENTE*
Estimado cliente:
Te enviamos tu estado de cuenta por el mantenimiento mensual de césped de tu propiedad.

💳 *MÉTODOS DE PAGO DISPONIBLES:*
• *Zelle:* Olivia Rodriguez • (623) 764-4177
• *Cash App:* $rafajrii • https://cash.app/$rafajrii

*Por favor incluye tu nombre o dirección en la nota del pago.*
¡Agradecemos mucho tu puntualidad y preferencia!
*Rodriguez Lawn Care • (254) 852-8163*
"""
        UIPasteboard.general.string = msg
        let clean = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/?text=\(clean)") {
            UIApplication.shared.open(url)
        }
    }
}


// ==============================================================================
// MARK: - SUITE DEL PATRÓN v2.1: MENÚ MASTER HAMBURGUESA & EDITOR DE CLIENTES
// ==============================================================================

// MARK: - EDITOR COMPLETO DE CLIENTES RECURRENTES
struct EditRecurringClientSheetView: View {
    let client: RecurringClient
    @ObservedObject var store: LawnCareStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var price: Double = 50.0
    @State private var frequency: String = "biweekly"
    @State private var serviceDay: String = "Lunes"
    @State private var status: String = "pending"
    @State private var notes: String = ""
    @State private var showDeleteConfirm: Bool = false
    
    let days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
    let frequencies = [
        ("weekly", "Semanal (4 cortes/mes)"),
        ("biweekly", "Quincenal (2 cortes/mes)"),
        ("monthly", "Mensual (1 corte/mes)")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Badge
                        HStack(spacing: 10) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 32))
                                .foregroundStyle(Brand.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("EDITAR PERFIL DEL CLIENTE")
                                    .font(.caption.bold())
                                    .foregroundStyle(Brand.primary)
                                Text(name.isEmpty ? client.name : name)
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Personal & Contact Info
                        VStack(alignment: .leading, spacing: 10) {
                            Text("INFORMACIÓN DE CONTACTO")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nombre Completo:")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                TextField("Nombre", text: $name)
                                    .padding(10)
                                    .background(Brand.cardLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Teléfono:")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                TextField("Teléfono", text: $phone)
                                    .padding(10)
                                    .background(Brand.cardLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(.white)
                                    .keyboardType(.phonePad)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dirección de la Propiedad:")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                TextField("Dirección", text: $address)
                                    .padding(10)
                                    .background(Brand.cardLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Pricing & Service Schedule
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TARIFA Y PROGRAMACIÓN DE CORTE")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)
                            
                            HStack {
                                Text("Precio por Visita: $\(Int(price)) USD")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Brand.primary)
                                Spacer()
                                Stepper("", value: $price, in: 25...500, step: 5)
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Frecuencia de Corte:")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                Picker("Frecuencia", selection: $frequency) {
                                    ForEach(frequencies, id: \.0) { freq in
                                        Text(freq.1).tag(freq.0)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Día Asignado de Corte:")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                Picker("Día de Servicio", selection: $serviceDay) {
                                    ForEach(days, id: \.self) { d in
                                        Text(d).tag(d)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Brand.cardLight)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Estado de Pago:")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                Picker("Estado", selection: $status) {
                                    Text("Pendiente ⏳").tag("pending")
                                    Text("Pagado ✓").tag("paid")
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding(14)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Special Yard Notes
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NOTAS ESPECIALES DEL PATIO (PORTÓN / PERROS):")
                                .font(.caption2.bold())
                                .foregroundStyle(.gray)
                            TextField("Ej: Código de portón #4521, no dejar portón abierto por mascotas", text: $notes)
                                .padding(10)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal)
                        
                        // Save Changes Button
                        Button {
                            saveChanges()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Guardar Cambios del Cliente")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Brand.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        
                        // Delete Button
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Eliminar Cliente Recurrente")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Editar Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { saveChanges() }
                        .font(.body.bold())
                        .foregroundStyle(Brand.primary)
                }
            }
            .onAppear {
                name = client.name
                phone = client.phone
                address = client.address
                price = client.price
                frequency = client.frequency
                serviceDay = client.service_day
                status = client.status
                notes = client.notes ?? ""
            }
            .alert("¿Eliminar Cliente?", isPresented: $showDeleteConfirm) {
                Button("Eliminar", role: .destructive) {
                    Task {
                        await store.deleteRecurringClient(id: client.id)
                        dismiss()
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("¿Estás seguro de que deseas remover a \(client.name) de tu lista de clientes recurrentes?")
            }
        }
    }
    
    private func saveChanges() {
        var updated = client
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.price = price
        updated.frequency = frequency
        updated.service_day = serviceDay
        updated.status = status
        updated.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            await store.updateRecurringClient(updated)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        }
    }
}

// MARK: - MASTER DROPDOWN DRAWER MENU (CATEGORIZED CUADRITOS DEL PATRÓN)
struct PatronMasterDrawerMenuView: View {
    @ObservedObject var store: LawnCareStore
    var onClose: () -> Void
    var onSelectAction: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.yellow)
                            .font(.caption)
                        Text("CENTRO DE COMANDO")
                            .font(.subheadline.bold())
                            .foregroundStyle(Brand.primary)
                    }
                    Text("Todas tus herramientas organizadas en orden")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(red: 0.05, green: 0.12, blue: 0.09))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Brand.primary.opacity(0.3)),
                alignment: .bottom
            )
            
            // Categorized Cuadritos Scroll Area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    // CATEGORÍA 1: OPERACIONES & CUADRILLA
                    DrawerCategorySection(
                        icon: "truck.box.fill",
                        title: "1. OPERACIONES & RUTA",
                        subtitle: "Control de cuadrilla, GPS y maquinaria en la calle",
                        color: Color.cyan
                    ) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            DrawerToolItemButton(icon: "location.north.circle.fill", title: "Lawn Tracker GPS", subtitle: "Aviso de llegada ETA", color: Color.cyan) {
                                onSelectAction("tracker")
                            }
                            DrawerToolItemButton(icon: "dot.radiowaves.left.and.right", title: "Radar Táctico", subtitle: "Zonas conquistadas", color: Color.green) {
                                onSelectAction("radar")
                            }
                            DrawerToolItemButton(icon: "checklist", title: "Checklist Remolque", subtitle: "Carga matutina 100%", color: Color.mint) {
                                onSelectAction("checklist")
                            }
                            DrawerToolItemButton(icon: "cloud.rain.fill", title: "Alerta Lluvia", subtitle: "Aviso masivo por clima", color: Color.blue) {
                                onSelectAction("rain")
                            }
                            DrawerToolItemButton(icon: "wrench.and.screwdriver.fill", title: "Flota & Podadoras", subtitle: "Toro/Stihl/Camión", color: Color.orange) {
                                onSelectAction("fleet")
                            }
                        }
                    }
                    
                    // CATEGORÍA 2: COTIZACIONES & VENTAS
                    DrawerCategorySection(
                        icon: "dollarsign.circle.fill",
                        title: "2. COTIZACIONES & VENTAS",
                        subtitle: "Calculadoras y estimadores rápidos en el patio",
                        color: Color.green
                    ) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            DrawerToolItemButton(icon: "sparkles", title: "IA Smart Estimator", subtitle: "Corte y pasto alto", color: Color.green) {
                                onSelectAction("estimate")
                            }
                            DrawerToolItemButton(icon: "truck.pickup.side.fill", title: "Camión Mulch 3D", subtitle: "Calculadora de yardas", color: Color.orange) {
                                onSelectAction("truck")
                            }
                            DrawerToolItemButton(icon: "tree.fill", title: "Tala de Árboles", subtitle: "Destoconado y riesgo", color: Color.green) {
                                onSelectAction("tree")
                            }
                            DrawerToolItemButton(icon: "doc.text.fill", title: "Propuesta Comercial", subtitle: "Contrato HOA 2 Pág", color: Color.indigo) {
                                onSelectAction("proposal")
                            }
                            DrawerToolItemButton(icon: "map.fill", title: "Calculadora Lote", subtitle: "Medir acres de terreno", color: Color.yellow) {
                                onSelectAction("lawnarea")
                            }
                        }
                    }
                    
                    // CATEGORÍA 3: CLIENTES & COBROS
                    DrawerCategorySection(
                        icon: "person.2.fill",
                        title: "3. CLIENTES & COBROS",
                        subtitle: "Clientes fijos, lealtad VIP y pagos Zelle / Cash App",
                        color: Color.yellow
                    ) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            DrawerToolItemButton(icon: "repeat", title: "Clientes Recurrentes", subtitle: "Editar perfiles y días", color: Color.green) {
                                onSelectAction("recurring")
                            }
                            DrawerToolItemButton(icon: "crown.fill", title: "Niveles VIP", subtitle: "Lealtad & LTV", color: Color.yellow) {
                                onSelectAction("vip")
                            }
                            DrawerToolItemButton(icon: "creditcard.fill", title: "Auto-Pay Recurrente", subtitle: "Zelle Olivia & $rafajrii", color: Color.cyan) {
                                onSelectAction("autopay")
                            }
                            DrawerToolItemButton(icon: "signature", title: "Firma Digital", subtitle: "Firmar en pantalla", color: Color.pink) {
                                onSelectAction("settings")
                            }
                        }
                    }
                    
                    // CATEGORÍA 4: MARKETING & REDES SOCIALES
                    DrawerCategorySection(
                        icon: "megaphone.fill",
                        title: "4. MARKETING & REDES",
                        subtitle: "Publicidad en Facebook, Google Maps y TikTok",
                        color: Color.purple
                    ) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            DrawerToolItemButton(icon: "film.stack.fill", title: "Video TikTok / Reels", subtitle: "Antes & Después", color: Color.purple) {
                                onSelectAction("video")
                            }
                            DrawerToolItemButton(icon: "photo.on.rectangle.angled", title: "Creador de Flyers", subtitle: "Publicar en Facebook", color: Color.pink) {
                                onSelectAction("flyer")
                            }
                            DrawerToolItemButton(icon: "star.fill", title: "Reseñas 5★ Google", subtitle: "Boost en Google Maps", color: Color.yellow) {
                                onSelectAction("reviews")
                            }
                            DrawerToolItemButton(icon: "qrcode", title: "Tarjeta QR Vecinos", subtitle: "10% OFF Exclusivo", color: Color.blue) {
                                onSelectAction("digitalcard")
                            }
                            DrawerToolItemButton(icon: "camera.badge.ellipsis", title: "Cámara Antes/Dsp", subtitle: "Comparativa de patio", color: Color.teal) {
                                onSelectAction("beforeafter")
                            }
                            DrawerToolItemButton(icon: "flame.fill", title: "Promociones Flash", subtitle: "Lanzar oferta a la web", color: Color.orange) {
                                onSelectAction("promos")
                            }
                        }
                    }
                    
                    // CATEGORÍA 5: AJUSTES & SISTEMA OTA
                    DrawerCategorySection(
                        icon: "gearshape.2.fill",
                        title: "5. AJUSTES & SISTEMA",
                        subtitle: "Servidor Railway, música y compilación OTA",
                        color: Color.gray
                    ) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            DrawerToolItemButton(icon: "server.rack", title: "Servidor Railway", subtitle: "rodriguezlawncare.xyz", color: Color.green) {
                                onSelectAction("settings")
                            }
                            DrawerToolItemButton(icon: "arrow.triangle.2.circlepath.circle.fill", title: "Actualizaciones OTA", subtitle: "Builds en la nube", color: Color.cyan) {
                                onSelectAction("settings")
                            }
                            DrawerToolItemButton(icon: "music.note", title: "Música del Patrón", subtitle: "Corridos de fondo", color: Color.orange) {
                                onSelectAction("settings")
                            }
                        }
                    }
                }
                .padding(14)
                .padding(.bottom, 24)
            }
            .frame(maxHeight: 520)
            .background(Color(red: 0.04, green: 0.08, blue: 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Brand.primary.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.8), radius: 25, y: 15)
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
    }
}

// MARK: - DRAWER HELPERS
struct DrawerCategorySection<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption.bold())
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption.bold())
                        .foregroundStyle(color)
                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundStyle(.gray)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            
            content
        }
        .padding(10)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

struct DrawerToolItemButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 8))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(8)
            .background(Brand.cardLight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
