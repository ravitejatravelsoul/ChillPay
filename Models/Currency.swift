import Foundation

enum Currency: String, Codable, CaseIterable, Identifiable {
    case usd, inr, eur, gbp, aud, jpy, cad, chf, other

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .inr: return "₹"
        case .eur: return "€"
        case .gbp: return "£"
        case .aud: return "A$"
        case .jpy: return "¥"
        case .cad: return "C$"
        case .chf: return "CHF"
        case .other: return "¤"
        }
    }

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
        case .other: return "Other"
        }
    }
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
        case .other: return 1.0
        }
    }
    func convert(_ amount: Double, to: Currency) -> Double {
        let usdAmount = amount * conversionRateToUSD
        return usdAmount / to.conversionRateToUSD
    }

    /// Attempt to map an ISO‑4217 currency code (e.g. "USD", "INR") to a known `Currency` case.
    ///
    /// This helper enables converting amounts for arbitrary user currencies using
    /// the built‑in conversion rates defined in this enum.  If the code is not
    /// recognized, `.other` is returned.
    ///
    /// - Parameter code: The ISO currency code, case‑insensitive.
    /// - Returns: A matching `Currency` case, or `.other` for unknown codes.
    static func from(code: String) -> Currency {
        switch code.uppercased() {
        case "USD": return .usd
        case "INR": return .inr
        case "EUR": return .eur
        case "GBP": return .gbp
        case "AUD": return .aud
        case "JPY": return .jpy
        case "CAD": return .cad
        case "CHF": return .chf
        default: return .other
        }
    }
}
