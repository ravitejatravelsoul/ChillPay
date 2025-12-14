//
//  ChillPrimaryButton 2.swift
//  ChillPay
//
//  Created by Raviteja on 12/13/25.
//


import SwiftUI

/// Reusable primary action button for ChillPay.
/// Use this for all main actions like Add / Save / Create.
struct ChillPrimaryButton: View {
    let title: String
    var isDisabled: Bool = false
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: {
            if !isDisabled { action() }
        }) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .foregroundColor(.white)
        .background(isDisabled ? ChillTheme.softGray : ChillTheme.accent)
        .cornerRadius(14)
        .shadow(color: (isDisabled ? Color.clear : ChillTheme.accent.opacity(0.18)),
                radius: 8, x: 0, y: 3)
        .opacity(isDisabled ? 0.85 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDisabled)
        .disabled(isDisabled)
    }
}
