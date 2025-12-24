import SwiftUI

/// Represents a selectable country and currency option.  Conforms to
/// `Identifiable` for use in lists and pickers.
struct CountryCurrencyOption: Identifiable {
    let id = UUID()
    let countryCode: String
    let currencyCode: String
    let countryName: String
    let currencySymbol: String
}

/// A reusable SwiftUI component that allows users to select a country and
/// currency combination.  Each row displays the country flag, name,
/// currency code and symbol.  The list can be extended as desired.  The
/// selected option is bound to the caller via `selection`.
struct CountryCurrencyPicker: View {
    /// The currently selected country/currency option.
    @Binding var selection: CountryCurrencyOption
    /// Whether to show as a list or a picker.  If `true`, uses a Form
    /// presentation; otherwise uses a menu style.  Default is `false`.
    var presentAsList: Bool = false

    /// Predefined options.  Add more locales as needed; at minimum include
    /// US/USD and IN/INR.
    private let options: [CountryCurrencyOption] = [
        CountryCurrencyOption(countryCode: "US", currencyCode: "USD", countryName: "United States", currencySymbol: "$"),
        CountryCurrencyOption(countryCode: "IN", currencyCode: "INR", countryName: "India", currencySymbol: "₹"),
        CountryCurrencyOption(countryCode: "GB", currencyCode: "GBP", countryName: "United Kingdom", currencySymbol: "£"),
        CountryCurrencyOption(countryCode: "CA", currencyCode: "CAD", countryName: "Canada", currencySymbol: "C$"),
        CountryCurrencyOption(countryCode: "AU", currencyCode: "AUD", countryName: "Australia", currencySymbol: "A$"),
        CountryCurrencyOption(countryCode: "EU", currencyCode: "EUR", countryName: "Eurozone", currencySymbol: "€")
    ]

    var body: some View {
        if presentAsList {
            List(options) { option in
                HStack {
                    Text(flag(for: option.countryCode))
                    VStack(alignment: .leading) {
                        Text(option.countryName)
                        Text("\(option.currencyCode) · \(option.currencySymbol)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if option.id == selection.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { selection = option }
            }
        } else {
            Menu {
                ForEach(options) { option in
                    Button(action: { selection = option }) {
                        HStack {
                            Text(flag(for: option.countryCode))
                            Text("\(option.countryName) (\(option.currencyCode) \(option.currencySymbol))")
                        }
                    }
                }
            } label: {
                HStack {
                    Text(flag(for: selection.countryCode))
                    Text("\(selection.countryName) (\(selection.currencyCode) \(selection.currencySymbol))")
                        .font(.subheadline)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(ChillTheme.card)
                .cornerRadius(8)
            }
        }
    }

    /// Convert a country code into a flag emoji.  Falls back to an empty
    /// string if the conversion fails.
    private func flag(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flagString = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                flagString.append(String(unicode))
            }
        }
        return flagString
    }
}