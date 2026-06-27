import SwiftUI
import UIKit

extension View {
    @ViewBuilder
    func hanaSearchInput(text: Binding<String>, isEnabled: Bool) -> some View {
        if isEnabled {
            searchable(text: text, prompt: "关键词")
        } else {
            self
        }
    }

    @ViewBuilder
    func hanaNavigationSubtitle(_ subtitle: String?) -> some View {
        self
    }

    @ViewBuilder
    func hanaSystemBackground() -> some View {
        background(Color(uiColor: .systemBackground))
    }

    @ViewBuilder
    func hanaMobileNavigationChrome() -> some View {
#if os(iOS)
        navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.visible, for: .tabBar)
#else
        self
#endif
    }

    @ViewBuilder
    func hanaInlineNavigationTitleDisplayMode() -> some View {
#if os(iOS)
        navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }

    @ViewBuilder
    func hanaPreviewImagePagerStyle(showIndex: Bool) -> some View {
#if os(iOS)
        tabViewStyle(.page(indexDisplayMode: showIndex ? .automatic : .never))
#else
        self
#endif
    }

    @ViewBuilder
    func hanaEmailKeyboard() -> some View {
        keyboardType(.emailAddress)
    }

    @ViewBuilder
    func hanaURLKeyboard() -> some View {
        keyboardType(.URL)
    }

    @ViewBuilder
    func hanaTextInputAutocapitalizationNever() -> some View {
        textInputAutocapitalization(.never)
    }

    @ViewBuilder
    func hanaNumberKeyboard() -> some View {
        keyboardType(.numberPad)
    }
}

enum HanaPasteboard {
    static var string: String? {
        get {
            UIPasteboard.general.string
        }
        set {
            UIPasteboard.general.string = newValue
        }
    }
}
