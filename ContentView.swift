import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    @EnvironmentObject private var services: HanaServices
    @AppStorage(HanaSettingsKey.appearanceMode) private var appearanceMode = HanaAppearanceMode.system.rawValue
#if !os(macOS)
    @AppStorage(HanaSettingsKey.themeColor) private var themeColor = HanaThemeColor.defaultValue
#endif
    @State private var selectedTab: AppTab = .discover
#if os(macOS)
    @State private var macOSNavigationPath: [HanaRoute] = []
#endif

    private var appThemeColor: Color {
#if os(macOS)
        .pink
#else
        (HanaThemeColor(rawValue: themeColor) ?? .pink).color
#endif
    }

#if os(macOS)
    private var macOSSidebarProfileTitle: String {
        services.siteSession.isLoggedIn ? services.siteSession.displayName : "未登录"
    }
#endif

    var body: some View {
        let appContent = rootContent
            .sheet(item: Binding(
                get: { services.siteSession.activeFlow },
                set: { services.siteSession.activeFlow = $0 }
            )) { flow in
                SiteWebSessionSheet(
                    flow: flow,
                    onComplete: { cookies in
                        completeSiteWebFlow(with: cookies)
                    },
                    onCancel: {
                        services.siteSession.cancel()
                    }
                )
            }
            .task {
                await refreshLoginStateFromStoredCookies()
                await synchronizeDownloadsAtLaunch()
                await services.updateChecker.checkAutomaticallyIfNeeded()
            }
            .hanaUpdateAlert(update: Binding(
                get: { services.updateChecker.availableUpdate },
                set: { services.updateChecker.availableUpdate = $0 }
            ))
            .tint(appThemeColor)
            .accentColor(appThemeColor)

#if os(macOS)
        appContent
            .onAppear {
                applyMacOSAppearance()
            }
            .onChange(of: appearanceMode) { _ in
                applyMacOSAppearance()
            }
#else
        appContent
            .preferredColorScheme(HanaAppearanceMode(rawValue: appearanceMode)?.colorScheme)
#endif
    }

#if os(macOS)
    private func applyMacOSAppearance() {
        let mode = HanaAppearanceMode(rawValue: appearanceMode) ?? .system
        mode.applyToApplication()
    }
#endif

    @ViewBuilder
    private var rootContent: some View {
#if os(macOS)
        NavigationView {
            VStack(spacing: 0) {
                List(selection: $selectedTab) {
                    NavigationLink(value: AppTab.discover) {
                        Label("发现", systemImage: "sparkles")
                    }
                    NavigationLink(value: AppTab.subscriptions) {
                        Label("订阅", systemImage: "play.rectangle.on.rectangle")
                    }
                    NavigationLink(value: AppTab.favorites) {
                        Label("收藏", systemImage: "heart")
                    }
                    NavigationLink(value: AppTab.search) {
                        Label("搜索", systemImage: "magnifyingglass")
                    }
                }
                .listStyle(.sidebar)

                MacOSSidebarProfileButton(
                    title: macOSSidebarProfileTitle,
                    imageData: services.profileAvatarStore.imageData,
                    isSelected: selectedTab == .profile
                ) {
                    selectedTab = .profile
                    macOSNavigationPath.removeAll()
                }
            }
            .navigationTitle("Hana")
            .frame(minWidth: 210, idealWidth: 240, maxWidth: 280)
        } detail: {
            NavigationStack(path: $macOSNavigationPath) {
                tabContent(for: selectedTab)
                    .navigationDestination(for: HanaRoute.self, destination: destination)
            }
        }
        .onChange(of: selectedTab) { _ in
            macOSNavigationPath.removeAll()
        }
#else
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeScreen()
                    .navigationDestination(for: HanaRoute.self, destination: destination)
            }
            .tabItem {
                Label("发现", systemImage: "sparkles")
            }
            .tag(AppTab.discover)

            NavigationStack {
                SubscriptionsScreen()
                    .navigationDestination(for: HanaRoute.self, destination: destination)
            }
            .tabItem {
                Label("订阅", systemImage: "play.rectangle.on.rectangle")
            }
            .tag(AppTab.subscriptions)

            NavigationStack {
                FavoritesScreen()
                    .navigationDestination(for: HanaRoute.self, destination: destination)
            }
            .tabItem {
                Label("收藏", systemImage: "heart")
            }
            .tag(AppTab.favorites)

            NavigationStack {
                ProfileScreen()
                    .navigationDestination(for: HanaRoute.self, destination: destination)
            }
            .tabItem {
                ProfileTabLabel()
            }
            .tag(AppTab.profile)

            NavigationStack {
                SearchScreen()
                    .navigationDestination(for: HanaRoute.self, destination: destination)
            }
            .tabItem {
                Label("搜索", systemImage: "magnifyingglass")
            }
            .tag(AppTab.search)
        }
#endif
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .discover:
            HomeScreen()
        case .subscriptions:
            SubscriptionsScreen()
        case .favorites:
            FavoritesScreen()
        case .profile:
            ProfileScreen()
        case .search:
            SearchScreen()
        }
    }

    @ViewBuilder
    private func destination(_ route: HanaRoute) -> some View {
        switch route {
        case .video(let code):
            VideoDetailScreen(videoCode: code)
        case .search(let criteria):
            SearchScreen(initialCriteria: criteria)
        case .lockedSearch(let criteria):
            SearchScreen(initialCriteria: criteria, locksQueryEditing: true)
        case .profileDetail:
            ProfileDetailScreen()
        case .watchHistory:
            WatchHistoryScreen()
        case .watchLater:
            WatchLaterScreen()
        case .playlists:
            PlaylistsScreen()
        case .remotePlaylist(let playlist):
            RemotePlaylistDetailScreen(playlist: playlist)
        case .hKeyframes:
            HKeyframeManagementScreen()
        case .downloads:
            DownloadsScreen()
        case .settings:
            SettingsScreen()
        }
    }

    private func completeSiteWebFlow(with cookies: [HTTPCookie]) {
        let kind = services.siteSession.activeFlow?.kind
        services.siteSession.complete(with: cookies)
        if kind == .login {
            Task { await refreshLoginState() }
        }
    }

    private func refreshLoginStateFromStoredCookies() async {
        await services.siteSession.syncDefaultWebCookies()
        guard services.siteSession.hasStoredCookies || services.siteSession.isLoggedIn else {
            services.profileAvatarStore.clear()
            return
        }
        await verifyCurrentUser()
    }

    private func refreshLoginState() async {
        await services.siteSession.syncDefaultWebCookies()
        await verifyCurrentUser()
    }

    private func verifyCurrentUser() async {
        do {
            let user = try await services.repository.currentUser()
            await services.applyLoginState(user: user)
        } catch {
            if services.siteSession.handle(error) {
                return
            }
            await services.applyLoginState(user: nil)
        }
    }

    private func synchronizeDownloadsAtLaunch() async {
        let records = JSONPersistenceManager.shared.loadDownloadQueue()
        await HanaDownloadRecordSynchronizer.synchronize(
            downloadClient: services.downloadClient,
            records: records
        )
    }
}

#if os(macOS)
private struct MacOSSidebarProfileButton: View {
    let title: String
    let imageData: Data?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                MacOSSidebarProfileAvatar(imageData: imageData)

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 56, alignment: .center)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .accessibilityLabel(title)
        .accessibilityHint("打开我的")
    }
}

private struct MacOSSidebarProfileAvatar: View {
    let imageData: Data?
    private let side: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(.secondary.opacity(0.16))

            avatarContent
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(.secondary.opacity(0.22), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let imageData,
           let image = NSImage(data: imageData) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: side - 4))
                .foregroundStyle(.secondary)
        }
    }
}
#endif

private struct ProfileTabLabel: View {
    @EnvironmentObject private var services: HanaServices

    var body: some View {
        Label {
            Text("我的")
        } icon: {
            ProfileTabIcon(imageData: services.profileAvatarStore.imageData)
        }
    }
}

private struct ProfileTabIcon: View {
    let imageData: Data?
    private let side = HanaProfileAvatarStore.tabIconPointSize

    var body: some View {
#if canImport(UIKit)
        if let imageData,
           let image = UIImage(data: imageData, scale: HanaProfileAvatarStore.tabIconImageScale)?.withRenderingMode(.alwaysOriginal) {
            Image(uiImage: image)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: side, height: side)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .frame(width: side, height: side)
        }
#else
        Image(systemName: "person.crop.circle.fill")
            .frame(width: side, height: side)
#endif
    }
}

private enum AppTab: Hashable {
    case discover
    case subscriptions
    case favorites
    case profile
    case search
}
