import Foundation
import Combine

/// A singleton responsible for managing the current user's locale and
/// currency preferences. This class centralizes currency formatting logic
/// across the entire app and publishes updates whenever the user changes
/// their country or currency codes.
final class CurrencyManager: ObservableObject {

    // MARK: - Singleton
    static let shared = CurrencyManager()

    // MARK: - Published Properties
    @Published var countryCode: String
    @Published var currencyCode: String

    private let countryKey = "currencyManager.countryCode"
    private let currencyKey = "currencyManager.currencyCode"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let defaults = UserDefaults.standard
        let (defaultCountry, defaultCurrency) = CurrencyManager.deviceCountryAndCurrencyDefaults()

        self.countryCode = defaults.string(forKey: countryKey) ?? defaultCountry
        self.currencyCode = defaults.string(forKey: currencyKey) ?? defaultCurrency

        // Persist changes automatically whenever the codes are updated.
        $countryCode
            .sink { [weak self] newValue in
                guard let self else { return }
                UserDefaults.standard.setValue(newValue, forKey: self.countryKey)
            }
            .store(in: &cancellables)

        $currencyCode
            .sink { [weak self] newValue in
                guard let self else { return }
                UserDefaults.standard.setValue(newValue, forKey: self.currencyKey)
            }
            .store(in: &cancellables)
    }

    // MARK: - Derived Locale & Symbol
    private var locale: Locale {
        var components: [String: String] = [:]
        components[NSLocale.Key.languageCode.rawValue] = Locale.current.language.languageCode?.identifier ?? "en"
        components[NSLocale.Key.countryCode.rawValue] = countryCode
        components[NSLocale.Key.currencyCode.rawValue] = currencyCode
        let identifier = Locale.identifier(fromComponents: components)
        return Locale(identifier: identifier)
    }

    var symbol: String {
        let loc = locale
        return loc.currencySymbol ?? Locale.current.currencySymbol ?? "$"
    }

    var code: String { currencyCode }

    // MARK: - Formatting
    func format(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = symbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: amount))
        ?? "\(symbol)\(String(format: "%.2f", amount))"
    }

    func format(amount: Double, in currency: Currency) -> String {
        var components: [String: String] = [:]
        components[NSLocale.Key.languageCode.rawValue] = Locale.current.language.languageCode?.identifier ?? "en"
        components[NSLocale.Key.countryCode.rawValue] = countryCode
        components[NSLocale.Key.currencyCode.rawValue] = currency.rawValue

        let identifier = Locale.identifier(fromComponents: components)
        let loc = Locale(identifier: identifier)
        let symbolForCurrency = loc.currencySymbol ?? currency.symbol

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = loc
        formatter.currencyCode = currency.rawValue
        formatter.currencySymbol = symbolForCurrency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: amount))
        ?? "\(symbolForCurrency)\(String(format: "%.2f", amount))"
    }

    func convert(amount: Double, from source: Currency) -> Double {
        let target = Currency.from(code: currencyCode)
        return source.convert(amount, to: target)
    }

    // MARK: - Updating Settings
    func update(countryCode: String, currencyCode: String) {
        self.countryCode = countryCode
        self.currencyCode = currencyCode
    }

    func resetToDeviceLocale() {
        let (region, currency) = CurrencyManager.deviceCountryAndCurrencyDefaults()
        update(countryCode: region, currencyCode: currency)
    }

    /// Returns best-effort defaults from the current device locale (no iOS16 deprecation warnings).
    static func deviceCountryAndCurrencyDefaults() -> (country: String, currency: String) {
        let nsLocale = Locale.current as NSLocale
        let country = (nsLocale.object(forKey: .countryCode) as? String) ?? "US"
        let currency = (nsLocale.object(forKey: .currencyCode) as? String) ?? "USD"
        return (country, currency)
    }
}
