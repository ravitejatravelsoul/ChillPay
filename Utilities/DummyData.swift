//
//  DummyData.swift
//  ChillPay
//
//  Created by Raviteja on 9/12/25.
//


import Foundation

struct DummyData {
    static let sampleUsers = [
        User(id: UUID(), name: "Alice"),
        User(id: UUID(), name: "Bob"),
        User(id: UUID(), name: "Charlie")
    ]
    
    static let sampleGroups = [
        Group(
            id: UUID(),
            name: "Trip to Goa",
            members: sampleUsers,
            expenses: []
        )
    ]
}