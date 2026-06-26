import SwiftUI

extension View {
    func hanaUpdateAlert(update: Binding<HanaAvailableUpdate?>) -> some View {
        modifier(HanaUpdateAlertModifier(update: update))
    }
}

private struct HanaUpdateAlertModifier: ViewModifier {
    @Environment(\.openURL) private var openURL
    @AppStorage(HanaSettingsKey.updateLinkDestination) private var updateLinkDestination = HanaUpdateLinkDestination.defaultValue
    @Binding var update: HanaAvailableUpdate?

    private var isPresented: Binding<Bool> {
        Binding {
            update != nil
        } set: { isPresented in
            if !isPresented {
                update = nil
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .alert(
                update?.title ?? "发现新版本",
                isPresented: isPresented,
                actions: {
                    Button(openButtonTitle) {
                        if let update {
                            openUpdateDestination(update)
                        }
                        update = nil
                    }
                    Button("稍后", role: .cancel) {
                        update = nil
                    }
                },
                message: {
                    Text(update?.message ?? "")
                }
            )
    }

    private var destination: HanaUpdateLinkDestination {
#if os(iOS)
        HanaUpdateLinkDestination(rawValue: updateLinkDestination) ?? .github
#else
        .github
#endif
    }

    private var openButtonTitle: String {
        return destination.buttonTitle
    }

    private func openUpdateDestination(_ update: HanaAvailableUpdate) {
        guard let launchURL = destination.launchURL else {
            openURL(update.releaseURL)
            return
        }

        openURL(launchURL)
    }
}
