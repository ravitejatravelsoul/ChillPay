import Foundation

/// Represents a fiat currency supported by the app.  Each case contains
/// a human‑readable symbol and a conversion rate relative to US dollars.
/// These rates are static and for demonstration purposes only – in a
/// production app you would fetch live exchange rates from a backend or
/// service.  The `id` property allows use in SwiftUI pickers.
enum Currency: String, Codable, CaseIterable, Identifiable {
    case usd
    case eur
    case gbp
    case jpy
    case inr
    case cad
    case aud
    case chf
    
    /// Required for `Identifiable` conformance.
    var id: String { rawValue }
    
    /// ISO 4217 code for the currency.  Although the raw value is the
    /// lower‑case version, consumers should use this property to display
    /// codes to the user.
    var code: String {
        rawValue.uppercased()
    }
    
    /// A symbol appropriate for the currency.  For some currencies the
    /// symbol may be the same as the code (e.g. `JPY`), while others have
    /// dedicated glyphs (e.g. `$`).
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .inr: return "₹"
        case .cad: return "$"
        case .aud: return "$"
        case .chf: return "CHF"
        }
    }
    
    /// A brief name for the currency used in selection lists.
    var displayName: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        case .inr: return "Indian Rupee"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .chf: return "Swiss Franc"
        }
    }
    
    /// Static conversion rates from the currency to US dollars.  These
    /// values are approximate and only for demonstration.  For example
    /// `eur.conversionRateToUSD = 1.08` means 1 EUR ≈ 1.08 USD.
    var conversionRateToUSD: Double {
        switch self {
        case .usd: return 1.0
        case .eur: return 1.08
        case .gbp: return 1.25
        case .jpy: return 0.0068
        case .inr: return 0.012
        case .cad: return 0.74
        case .aud: return 0.66
        case .chf: return 1.12
        }
    }
    
    /// Convert a monetary value from this currency into another currency.
    /// The conversion is performed by going through US dollars as an
    /// intermediate – this simplifies the math and avoids the need to
    /// maintain a full matrix of exchange rates.
    /// - Parameters:
    ///   - amount: The amount to convert.
    ///   - to: The target currency.
    /// - Returns: The converted amount.
    func convert(_ amount: Double, to: Currency) -> Double {
        // Convert into USD, then into the target currency
        let usdAmount = amount * conversionRateToUSD
        return usdAmount / to.conversionRateToUSD
    }
}