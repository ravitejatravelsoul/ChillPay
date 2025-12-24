import SwiftUI

struct SignupView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var phone = ""
    @State private var bio = ""
    @State private var notificationsEnabled = true
    @State private var faceIDEnabled = false

    // DiceBear avatar fields
    @State private var avatarSeed = "raviteja"
    @State private var avatarStyle = "adventurer"

    // Country & currency selection
    @State private var selectedCurrencyOption: CountryCurrencyOption = {
        // Determine the default option based on the device locale.  If no matching
        // option exists, fall back to US/USD.
        let defaults = CurrencyManager.deviceCountryAndCurrencyDefaults()
        let country = defaults.country
        let currency = defaults.currency
        // Use a temporary list to search defaults; this duplicates the
        // options defined in CountryCurrencyPicker for convenience.
        let options: [CountryCurrencyOption] = [
            CountryCurrencyOption(countryCode: "US", currencyCode: "USD", countryName: "United States", currencySymbol: "$"),
            CountryCurrencyOption(countryCode: "IN", currencyCode: "INR", countryName: "India", currencySymbol: "₹"),
            CountryCurrencyOption(countryCode: "GB", currencyCode: "GBP", countryName: "United Kingdom", currencySymbol: "£"),
            CountryCurrencyOption(countryCode: "CA", currencyCode: "CAD", countryName: "Canada", currencySymbol: "C$"),
            CountryCurrencyOption(countryCode: "AU", currencyCode: "AUD", countryName: "Australia", currencySymbol: "A$"),
            CountryCurrencyOption(countryCode: "EU", currencyCode: "EUR", countryName: "Eurozone", currencySymbol: "€")
        ]
        return options.first(where: { $0.countryCode == country && $0.currencyCode == currency }) ?? options.first!
    }()

    @State private var errorMessage: String?
    var onSignupSuccess: () -> Void
    var onBack: () -> Void

    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 32)
                    Text("Sign Up")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(ChillTheme.darkText)

                    VStack(spacing: 14) {
                        ChillTextField(title: "Name", text: $name)
                        ChillTextField(title: "Email", text: $email)
                        ChillTextField(title: "Phone (optional)", text: $phone)
                        ChillTextField(title: "Bio (optional)", text: $bio)
                        ChillTextField(title: "Password", text: $password, isSecure: true)
                        Toggle("Enable notifications", isOn: $notificationsEnabled)
                            .foregroundColor(ChillTheme.darkText)
                        Toggle("Enable Face ID", isOn: $faceIDEnabled)
                            .foregroundColor(ChillTheme.darkText)

                        // Country + Currency selection
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Country & Currency")
                                .font(.headline)
                                .foregroundColor(ChillTheme.darkText)
                            CountryCurrencyPicker(selection: $selectedCurrencyOption)
                        }

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }.padding(.horizontal, 20)

                    VStack(spacing: 8) {
                        Text("Pick Your Avatar")
                            .font(.headline)
                            .foregroundColor(ChillTheme.darkText.opacity(0.85))
                        AvatarPickerView(avatarSeed: $avatarSeed, avatarStyle: $avatarStyle)
                    }
                    .padding(.horizontal, 8)

                    Button(action: {
                        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
                            errorMessage = "Please fill all required fields and pick an avatar."
                            return
                        }
                        errorMessage = nil
                        authService.signUpWithEmail(
                            email: email,
                            password: password,
                            name: name,
                            avatar: "", // legacy emoji avatar (not used now)
                            bio: bio,
                            phone: phone,
                            notificationsEnabled: notificationsEnabled,
                            faceIDEnabled: faceIDEnabled,
                            avatarSeed: avatarSeed,
                            avatarStyle: avatarStyle,
                            countryCode: selectedCurrencyOption.countryCode,
                            currencyCode: selectedCurrencyOption.currencyCode,
                            onProfileCreated: {
                                onSignupSuccess()
                            }
                        )
                    }) {
                        if authService.isCreatingUserProfile {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ChillTheme.accent))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Sign Up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background((!name.isEmpty && !email.isEmpty && !password.isEmpty) ? ChillTheme.accent : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .disabled(name.isEmpty || email.isEmpty || password.isEmpty || authService.isCreatingUserProfile)

                    Button("Back to Login") { onBack() }
                        .foregroundColor(.green)

                    Spacer(minLength: 32)
                }
                .padding(.bottom, keyboardHeight)
                .frame(maxWidth: .infinity)
            }
            .onTapGesture { hideKeyboard() }
            .onAppear { subscribeToKeyboardNotifications() }
            .onDisappear { unsubscribeFromKeyboardNotifications() }
        }
        // Always prefer the system colour scheme; default to light mode
        .preferredColorScheme(.light)
    }

    // MARK: Keyboard Handling
    private func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
            if let rect = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                let safeAreaBottom = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                    .windows.first?.safeAreaInsets.bottom ?? 0
                withAnimation {
                    keyboardHeight = rect.height - safeAreaBottom
                }
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            withAnimation { keyboardHeight = 0 }
        }
    }
    private func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
