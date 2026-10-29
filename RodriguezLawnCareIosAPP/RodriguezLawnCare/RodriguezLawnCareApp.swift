import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        return true
    }

    // Displays top banner, plays sound and sets badge outside and inside the app
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    // Handles user tapping the top banner outside the app
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    // Background fetch: executes when iOS wakes the app in background to check for new leads
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let url = URL(string: "https://web-production-b6891b.up.railway.app/api/leads") else {
            completionHandler(.noData)
            return
        }

        var req = URLRequest(url: url)
        req.timeoutInterval = 10
        URLSession.shared.dataTask(with: req) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(.failed)
                return
            }

            do {
                let decoded = try JSONDecoder().decode(LeadListResponse.self, from: data)
                let knownIds = (UserDefaults.standard.array(forKey: "known_lead_ids_bg") as? [Int]) ?? []
                let knownSet = Set(knownIds)

                var newLeadsFound = 0
                for lead in decoded.leads {
                    if !knownSet.contains(lead.id) {
                        newLeadsFound += 1
                        self.postSystemNotification(lead: lead)
                    }
                }

                UserDefaults.standard.set(decoded.leads.map { $0.id }, forKey: "known_lead_ids_bg")
                completionHandler(newLeadsFound > 0 ? .newData : .noData)
            } catch {
                completionHandler(.noData)
            }
        }.resume()
    }

    private func postSystemNotification(lead: Lead) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 ¡NUEVA CITA / COTIZACIÓN WEB!"
        content.subtitle = "\(lead.name) • \(lead.phone)"
        let svcs = lead.services?.joined(separator: ", ") ?? "Corte de Césped"
        content.body = "Servicios: \(svcs) | \(lead.description ?? "Nueva solicitud desde la página web")"
        content.sound = .defaultCritical
        content.badge = 1
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: "bg_lead_\(lead.id)_\(Int(Date().timeIntervalSince1970))", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

@main
struct rodriguezlawncareiosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .accentColor(Color(red: 0.13, green: 0.77, blue: 0.36))
        }
    }
}
