//
//  AppScaffold.swift
//  ChillPay
//
//  Created by Raviteja on 9/29/25.
//


import SwiftUI

struct AppScaffold<Content: View>: View {
    let title: String
    let showAdd: Bool
    let addAction: (() -> Void)?
    let showSettings: Bool
    let settingsAction: (() -> Void)? // e.g., open global/settings sheet
    let content: () -> Content

    init(
        title: String,
        showAdd: Bool = false,
        addAction: (() -> Void)? = nil,
        showSettings: Bool = true,
        settingsAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.showAdd = showAdd
        self.addAction = addAction
        self.showSettings = showSettings
        self.settingsAction = settingsAction
        self.content = content
    }

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ChillTheme.darkText)
                    Spacer()
                    if showAdd, let addAction {
                        Button(action: addAction) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(ChillTheme.accent)
                                .shadow(color: ChillTheme.lightShadow, radius: 4)
                        }
                        .accessibilityLabel("Add \(title)")
                    }
                    if showSettings, let settingsAction {
                        Button(action: settingsAction) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 26))
                                .foregroundColor(ChillTheme.accent)
                        }
                        .accessibilityLabel("Settings")
                        .padding(.leading, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                content()
            }
        }
    }
}