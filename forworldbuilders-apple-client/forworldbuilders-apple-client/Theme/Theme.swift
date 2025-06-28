//
//  Theme.swift
//  forworldbuilders-apple-client
//
//  Created on 6/11/25.
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let accent = Color("AccentColor")
    let secondaryAccent = Color("SecondaryAccent")
    let background = Color(.systemBackground)
    let secondaryBackground = Color(.secondarySystemBackground)
    let tertiaryBackground = Color(.tertiarySystemBackground)
    let text = Color(.label)
    let secondaryText = Color(.secondaryLabel)
    let tertiaryText = Color(.tertiaryLabel)
    
    // Element Type Colors
    let characterColor = Color(red: 0.298, green: 0.686, blue: 0.314) // Green
    let locationColor = Color(red: 0.0, green: 0.478, blue: 1.0) // Blue
    let itemColor = Color(red: 1.0, green: 0.584, blue: 0.0) // Orange
    let eventColor = Color(red: 0.545, green: 0.0, blue: 0.545) // Purple
    let conceptColor = Color(red: 1.0, green: 0.843, blue: 0.0) // Yellow
    let organizationColor = Color(red: 0.863, green: 0.078, blue: 0.235) // Red
    let generalColor = Color.secondary
    
    func colorForElementType(_ type: ElementType) -> Color {
        switch type {
        case .character: return characterColor
        case .location: return locationColor
        case .item: return itemColor
        case .event: return eventColor
        case .concept: return conceptColor
        case .organization: return organizationColor
        case .general: return generalColor
        }
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.accentColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.accentColor)
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func primaryButtonStyle() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButtonStyle() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
}