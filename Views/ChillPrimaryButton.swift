import SwiftUI

/// A reusable primary button for ChillPay.
///
/// This component encapsulates the styling for primary actions across the app.
/// It uses the app's accent colour for the enabled state and a muted grey when
/// disabled. The button stretches to fill its available width by default and
/// applies consistent padding, corner radius and font weight.
///
/// Usage:
/// ```swift
/// ChillPrimaryButton(title: "Add Expense", isDisabled: viewModel.isSaving) {
///     viewModel.saveExpense()
/// }
/// ```
struct ChillPrimaryButton: View {
    /// The button label. Keep it short and descriptive.
    let title: String
    /// Whether the button should be disabled. When disabled the button dims
    /// and the tap action is ignored.
    let isDisabled: Bool
    /// Action performed when the button is tapped.
    let action: () -> Void

    var body: some View {
        Button(action: {
            // Prevent the action from firing if disabled
            if !isDisabled {
                action()
            }
        }) {
            Text(title)
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isDisabled ? ChillTheme.softGray : ChillTheme.accent)
                .cornerRadius(ChillTheme.cardRadius)
        }
        .disabled(isDisabled)
    }
}