import SwiftUI
import UserNotifications

#if canImport(UIKit) && os(iOS)
import UIKit

final class HanaAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        HanaInterfaceOrientationController.supportedInterfaceOrientations
    }

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        HanimeDownloadClient.handleBackgroundEvents(
            identifier: identifier,
            completionHandler: completionHandler
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
#endif

@main
struct HanaApp: App {
#if canImport(UIKit) && os(iOS)
    @UIApplicationDelegateAdaptor(HanaAppDelegate.self) private var appDelegate
#endif
    @StateObject private var services = HanaServices()
    @State private var servicesIdentity = UUID()
    @State private var reloadAction = HanaServiceReloadAction { _ in }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(servicesIdentity)
                .environmentObject(services)
                .environment(\.hanaReloadServices, reloadServicesAction)
                .onAppear {
                    setupReloadAction()
                }
        }
    }

    private var reloadServicesAction: HanaServiceReloadAction {
        reloadAction
    }

    private func setupReloadAction() {
        reloadAction = HanaServiceReloadAction { [services] baseURL in
            services.siteSession.cancel()
            servicesIdentity = UUID()
        }
    }
}
