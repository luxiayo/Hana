import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var services: HanaServices
    @State private var state: LoadableState<HanimeHomePage> = .idle

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                ProgressView("加载首页")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let homePage):
                if homePage.sections.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "film")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("首页暂无内容")
                            .foregroundStyle(.secondary)
                    }
                } else if let banner = homePage.banner {
                    HomeHeroContentTransition(
                        banner: banner,
                        sections: homePage.sections
                    )
                } else {
                    ScrollView {
                        HomeSectionsView(sections: homePage.sections)
                            .padding(.top, 16)
                        .padding(.bottom)
                    }
                    .hanaSystemBackground()
                }
            case .failed(let message):
                VStack(spacing: 12) {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(.headline)
                    Button("重试") {
                        Task { await loadHome() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Hana")
        .hanaMobileNavigationChrome()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                NavigationLink {
                    PreviewMonthScreen()
                } label: {
                    Label("预告", systemImage: "calendar")
                }
            }
        }
        .task {
            if case .idle = state {
                await loadHome()
            }
        }
        .onChange(of: services.siteSession.lastCookieSyncAt) { _ in
            Task { await loadHome() }
        }
    }

    private func loadHome() async {
        state = .loading
        do {
            state = .loaded(try await services.repository.homePage())
        } catch {
            if services.siteSession.handle(error) {
                state = .failed("需要 Cloudflare 验证")
            } else {
                state = .failed(error.localizedDescription)
            }
        }
    }
}
