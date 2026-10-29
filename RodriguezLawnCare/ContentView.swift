import SwiftUI

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
    var uptime_seconds: Int?
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

// MARK: - APP STORE (STATE MANAGEMENT & API)
class LawnCareStore: ObservableObject {
    @Published var leads: [Lead] = []
    @Published var gallery: [GalleryPhoto] = []
    @Published var stats: WebStats? = nil
    @Published var isLoading: Bool = false
    @Published var isOnline: Bool = false
    @Published var lastSyncTime: String = "Nunca"
    @Published var errorMessage: String? = nil

    @AppStorage("api_server_url") var serverURL: String = "https://rodriguezlawncarenuevaa-production.up.railway.app"

    init() {
        loadDemoData()
        Task { @MainActor in
            await refreshAll()
        }
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
            ),
            Lead(
                id: 1730103,
                name: "David Miller",
                phone: "(254) 555-0187",
                services: ["Limpieza de Escombros & Jardín"],
                address: "802 Main St, Belton, TX",
                date: "Lunes",
                time: "2:00 PM",
                frequency: "Una vez",
                description: "Ramas caídas en el patio trasero tras la tormenta.",
                source: "Llamada Telefónica IA 24/7",
                status: "estimated",
                estimated_amount: 120.0,
                notes: "Esperando confirmación final del cliente."
            )
        ]

        gallery = [
            GalleryPhoto(id: 2, filename: "work_2.jpg", url: "https://images.unsplash.com/photo-1558904541-efa8c4a08931?w=800", title: "Corte y Orillado Preciso", category: "Front Yard"),
            GalleryPhoto(id: 3, filename: "work_3.jpg", url: "https://images.unsplash.com/photo-1592417817098-8f3d6910985c?w=800", title: "Poda y Moldeado de Arbustos", category: "Shrubs & Bushes"),
            GalleryPhoto(id: 4, filename: "work_4.jpg", url: "https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=800", title: "Instalación de Mulch Premium", category: "Mulch")
        ]
    }

    private var cleanURL: String {
        var base = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.hasSuffix("/") {
            base.removeLast()
        }
        return base
    }

    @MainActor
    func refreshAll() async {
        isLoading = true
        defer { isLoading = false }

        await fetchStats()
        await fetchLeads()
        await fetchGallery()

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
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
                self.errorMessage = nil
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
                if !decoded.leads.isEmpty {
                    self.leads = decoded.leads
                }
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

    @MainActor
    func addGalleryPhoto(title: String, category: String, urlString: String) async {
        let newId = (gallery.map { $0.id }.max() ?? 0) + 1
        let item = GalleryPhoto(id: newId, filename: "work_\(newId).jpg", url: urlString, title: title, category: category)
        gallery.insert(item, at: 0)

        guard let url = URL(string: "\(cleanURL)/api/gallery") else { return }
        let payload: [String: Any] = [
            "title": title,
            "category": category,
            "url": urlString
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
}

// MARK: - MAIN ROOT VIEW
struct ContentView: View {
    @StateObject private var store = LawnCareStore()
    @State private var selectedTab = 0

    var body: some View {
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
                    Label("Galería", systemImage: "photo.on.rectangle.angled")
                }
                .tag(2)

            WebAdminView(store: store)
                .tabItem {
                    Label("Web & Servidor", systemImage: "globe.americas.fill")
                }
                .tag(3)
        }
        .accentColor(Brand.primary)
    }
}

// MARK: - TAB 1: CITAS & LEADS
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
                    // Header Status Bar
                    HStack(spacing: 12) {
                        StatusSummaryCard(title: "Pendientes", count: pendingCount, color: Brand.accent)
                        StatusSummaryCard(title: "Confirmadas", count: confirmedCount, color: Brand.primary)
                        StatusSummaryCard(title: "Completas", count: completedCount, color: .purple)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "Todas (\(store.leads.count))", isSelected: selectedFilter == "all") { selectedFilter = "all" }
                            FilterChip(title: "Pendientes", isSelected: selectedFilter == "pending") { selectedFilter = "pending" }
                            FilterChip(title: "Confirmadas", isSelected: selectedFilter == "confirmed") { selectedFilter = "confirmed" }
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
                        TextField("Buscar cliente, teléfono o calle...", text: $searchText)
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
                    .padding(.bottom, 12)

                    // Appointments List
                    if filteredLeads.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundStyle(.gray)
                            Text("No hay citas en este filtro")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Los clientes que soliciten cotización en tu página web aparecerán aquí.")
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
            .navigationTitle("Citas & Leads 🌿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(store.isOnline ? Brand.primary : .orange)
                            .frame(width: 8, height: 8)
                        Text(store.isOnline ? "En Línea" : "Offline")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewLeadSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
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
            // Top Row: Name, Status Badge, Quoted Price
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

            // Services requested
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

            // Date & Address Info
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

            // Action Buttons (WhatsApp, Call, Details)
            HStack(spacing: 10) {
                // WhatsApp Button
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

                // Call Button
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

                // Details Button
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

// MARK: - STATUS SUMMARY CARD
struct StatusSummaryCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.gray)
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

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
                        // Customer Header
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

                        // Change Status
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

                        // Quoted Amount Field
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

                        // Internal Notes
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

                        // Save Button
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

                        // Delete Appointment
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

// MARK: - TAB 2: DAR ESTIMADOS (QUOTE CALCULATOR)
struct EstimatorView: View {
    @ObservedObject var store: LawnCareStore

    @State private var clientName = ""
    @State private var clientPhone = ""
    @State private var lawnSize = "medium"    // small, medium, large, acreage
    @State private var grassHeight = "normal" // normal, tall, overgrown
    @State private var frequency = "biweekly" // onetime, biweekly, weekly

    // Addons
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
                        // Total Price Display Banner
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
                            Text("CLIENTE (OPCIONAL)")
                                .font(.caption.bold()).foregroundStyle(.gray)
                            HStack {
                                TextField("Nombre del cliente", text: $clientName)
                                    .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                                TextField("Teléfono", text: $clientPhone)
                                    .keyboardType(.phonePad)
                                    .padding(10).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                            }
                        }

                        // Lawn Size Picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TAMAÑO DE LA PROPIEDAD")
                                .font(.caption.bold()).foregroundStyle(.gray)

                            Picker("Tamaño", selection: $lawnSize) {
                                Text("Pequeño ($45)").tag("small")
                                Text("Mediano ($65)").tag("medium")
                                Text("Grande ($95)").tag("large")
                                Text("Acre+ ($160)").tag("acreage")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Grass Height
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CONDICIÓN DEL CÉSPED")
                                .font(.caption.bold()).foregroundStyle(.gray)

                            Picker("Condición", selection: $grassHeight) {
                                Text("Normal").tag("normal")
                                Text("Alto (+ $25)").tag("tall")
                                Text("Muy Crecido (+ $55)").tag("overgrown")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Frequency
                        VStack(alignment: .leading, spacing: 10) {
                            Text("FRECUENCIA")
                                .font(.caption.bold()).foregroundStyle(.gray)

                            Picker("Frecuencia", selection: $frequency) {
                                Text("Puntual").tag("onetime")
                                Text("Quincenal (-5%)").tag("biweekly")
                                Text("Semanal (-10%)").tag("weekly")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Additional Services (Toggles)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SERVICIOS EXTRA AÑADIDOS")
                                .font(.caption.bold()).foregroundStyle(.gray)

                            // Bushes
                            ToggleRow(icon: "scissors", title: "Poda de Arbustos / Setos", price: "$\(bushCount * 10)", isOn: $includeBushes)
                            if includeBushes {
                                Stepper("Cantidad de arbustos: \(bushCount)", value: $bushCount, in: 1...30)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal)
                            }

                            // Mulch
                            ToggleRow(icon: "shippingbox.fill", title: "Instalación de Mulch", price: "$\(mulchYards * 85)", isOn: $includeMulch)
                            if includeMulch {
                                Stepper("Yardas / Áreas: \(mulchYards)", value: $mulchYards, in: 1...10)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal)
                            }

                            // Trees
                            ToggleRow(icon: "leaf.fill", title: "Poda de Ramas de Árboles", price: "$90", isOn: $includeTrees)

                            // Cleanup
                            ToggleRow(icon: "trash.fill", title: "Limpieza General & Escombros", price: "$75", isOn: $includeCleanup)

                            // Edging
                            ToggleRow(icon: "square.dashed", title: "Bordeado Profundo de Aceras", price: "$35", isOn: $includeEdgingDethatch)
                        }

                        // Send & Share Buttons
                        VStack(spacing: 12) {
                            // WhatsApp direct
                            Button {
                                let phoneDigits = clientPhone.filter { $0.isNumber }
                                let phoneDial = phoneDigits.starts(with: "1") ? phoneDigits : "1\(phoneDigits)"
                                if let enc = quoteSummaryText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                                    let urlStr = phoneDigits.isEmpty ? "https://wa.me/?text=\(enc)" : "https://wa.me/\(phoneDial)?text=\(enc)"
                                    if let url = URL(string: urlStr) {
                                        UIApplication.shared.open(url)
                                    }
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

                            // Copy to clipboard
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

                            // Save as Lead
                            Button {
                                var services: [String] = ["Corte de Césped (\(lawnSizeName))"]
                                if includeBushes { services.append("Poda de Arbustos (\(bushCount))") }
                                if includeMulch { services.append("Mulch (\(mulchYards) yardas)") }
                                if includeTrees { services.append("Poda de Árboles") }
                                if includeCleanup { services.append("Limpieza General") }

                                Task {
                                    await store.createLead(
                                        name: clientName.isEmpty ? "Cliente Cotizado" : clientName,
                                        phone: clientPhone.isEmpty ? "No registrado" : clientPhone,
                                        services: services,
                                        address: "Por confirmar",
                                        date: "Por coordinar",
                                        time: "Horario habitual",
                                        frequency: frequency,
                                        description: "Cotización creada desde Calculadora de Estimados",
                                        amount: totalEstimate,
                                        notes: "Cotización enviada: $\(Int(totalEstimate))"
                                    )
                                    showCopiedAlert = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Guardar como Nueva Cita en Citas")
                                }
                                .font(.subheadline)
                                .foregroundStyle(Brand.primary)
                                .frame(maxWidth: .infinity)
                                .padding(10)
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
                Text("La cotización ha sido copiada y/o guardada exitosamente.")
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
            Image(systemName: icon)
                .foregroundStyle(Brand.primary)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Text(price)
                .font(.caption.bold())
                .foregroundStyle(Brand.accent)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Brand.primary))
        }
        .padding(12)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - TAB 3: GALERÍA WEB
struct GalleryAdminView: View {
    @ObservedObject var store: LawnCareStore
    @State private var showAddPhotoSheet = false

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Estas fotos se muestran en vivo en tu página web en la sección de trabajos.")
                            .font(.caption)
                            .foregroundStyle(.gray)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(store.gallery) { photo in
                                VStack(alignment: .leading, spacing: 6) {
                                    ZStack(alignment: .topTrailing) {
                                        // Image thumbnail
                                        AsyncImage(url: URL(string: photo.url)) { phase in
                                            switch phase {
                                            case .empty:
                                                Rectangle().fill(Brand.cardLight)
                                                    .overlay(ProgressView())
                                            case .success(let image):
                                                image.resizable().scaledToFill()
                                            case .failure:
                                                Rectangle().fill(Brand.cardLight)
                                                    .overlay(Image(systemName: "photo").foregroundStyle(.gray))
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                        // Delete Button
                                        Button {
                                            Task { await store.deleteGalleryPhoto(id: photo.id) }
                                        } label: {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(.red)
                                                .background(Circle().fill(.black.opacity(0.6)))
                                        }
                                        .padding(6)
                                    }

                                    Text(photo.title)
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    Text(photo.category)
                                        .font(.caption2)
                                        .foregroundStyle(Brand.primary)
                                }
                                .padding(8)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Galería de la Web 📸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddPhotoSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Subir Foto")
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
            .sheet(isPresented: $showAddPhotoSheet) {
                AddGalleryPhotoSheet(store: store)
            }
        }
    }
}

struct AddGalleryPhotoSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: LawnCareStore

    @State private var title = ""
    @State private var category = "Front Yard"
    @State private var imageURL = ""

    let categories = [
        "Front Yard",
        "Back Yard",
        "Mulch",
        "Tree Care",
        "Shrubs & Bushes",
        "Yard Cleanups",
        "Edging & Stripes"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Título del Trabajo")
                        .font(.caption.bold()).foregroundStyle(.gray)
                    TextField("ej. Corte Limpio y Bordes Front Yard", text: $title)
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

                    Text("URL de la Imagen")
                        .font(.caption.bold()).foregroundStyle(.gray)
                    TextField("https://... o ruta de foto", text: $imageURL)
                        .padding(12).background(Brand.card).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)

                    Spacer()

                    Button {
                        guard !title.isEmpty else { return }
                        let finalURL = imageURL.isEmpty ? "https://images.unsplash.com/photo-1558904541-efa8c4a08931?w=800" : imageURL
                        Task {
                            await store.addGalleryPhoto(title: title, category: category, urlString: finalURL)
                            dismiss()
                        }
                    } label: {
                        Text("Publicar Foto en la Web")
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
            .navigationTitle("Nueva Foto en la Web")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - TAB 4: WEB & SERVIDOR
struct WebAdminView: View {
    @ObservedObject var store: LawnCareStore
    @State private var serverInput = ""
    @State private var showSavedAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Brand.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Server Status Card
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
                                HStack {
                                    Text("Citas Registradas:")
                                        .font(.caption).foregroundStyle(.gray)
                                    Spacer()
                                    Text("\(stats.total_leads ?? 0)")
                                        .font(.caption.bold()).foregroundStyle(.white)
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

                        // Live Website Preview Button
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ACCESOS DIRECTOS DE TU NEGOCIO")
                                .font(.caption.bold()).foregroundStyle(.gray)

                            Button {
                                if let url = URL(string: "https://rodriguezlawncarenuevaa-production.up.railway.app") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "safari.fill")
                                        .foregroundStyle(Brand.primary)
                                    VStack(alignment: .leading) {
                                        Text("Abrir Sitio Web de Rodriguez LawnCare")
                                            .font(.subheadline.bold()).foregroundStyle(.white)
                                        Text("rodriguezlawncare.com / Railway")
                                            .font(.caption2).foregroundStyle(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption).foregroundStyle(.gray)
                                }
                                .padding()
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            // Dispatch phones
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
                            Text("URL DE LA API / SERVIDOR")
                                .font(.caption.bold()).foregroundStyle(.gray)

                            TextField("https://tu-servidor.up.railway.app", text: $serverInput)
                                .padding(12)
                                .background(Brand.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)

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

                        // App Version footer
                        VStack(spacing: 4) {
                            Text("Rodriguez LawnCare Manager • Versión 1.0.0")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            Text("Diseñado para la administración de clientes y estimados en iOS")
                                .font(.caption2)
                                .foregroundStyle(.gray.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Web & Ajustes ⚙️")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                serverInput = store.serverURL
            }
            .alert("Configuración Guardada", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Se ha actualizado la dirección del servidor.")
            }
        }
    }
}

