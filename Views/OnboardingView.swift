import SwiftUI

struct OnboardingView: View {
    var onContinue: () -> Void

    /// Track the current page of the onboarding carousel.
    @State private var currentPage: Int = 0

    /// The number of pages in the carousel. Adjust this if you add or remove pages.
    private let pageCount: Int = 3

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 20)
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        systemImage: "person.3.fill",
                        title: "Create a group",
                        description: "Invite your friends and split expenses together."
                    )
                    .tag(0)

                    OnboardingPageView(
                        systemImage: "person.badge.plus",
                        title: "Add your friends",
                        description: "Keep your circle close by adding friends to your account."
                    )
                    .tag(1)

                    OnboardingPageView(
                        systemImage: "plus.square.on.square",
                        title: "Add expenses",
                        description: "Log every expense and ChillPay calculates who owes whom."
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentPage)
                .frame(maxHeight: .infinity)

                // Continue/Skip primary button
                ChillPrimaryButton(
                    title: currentPage < pageCount - 1 ? "Next" : "Get Started",
                    isDisabled: false
                ) {
                    if currentPage < pageCount - 1 {
                        // Move to next page
                        withAnimation { currentPage += 1 }
                    } else {
                        // Dismiss onboarding
                        onContinue()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

/// A single page in the onboarding carousel.
private struct OnboardingPageView: View {
    let systemImage: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(ChillTheme.accent)

            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ChillTheme.darkText)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.title3)
                .foregroundColor(ChillTheme.darkText.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
        }
    }
}
