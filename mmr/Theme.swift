//
//  Theme.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI

// MARK: - Theme Configuration
struct Theme {
    
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color.blue
        static let secondary = Color.purple
        static let accent = Color.cyan
        
        // Background Colors
        static let background = Color.black
        static let backgroundSecondary = Color.gray.opacity(0.1)
        
        // Glass Effect Colors
        static let glassBackground = Color.white.opacity(0.1)
        static let glassBorder = Color.white.opacity(0.2)
        static let glassShadow = Color.black.opacity(0.3)
        
        // Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
        
        // System Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
    }
    
    // MARK: - Typography
    struct Typography {
        // Font Sizes
        static let largeTitle: CGFloat = 34
        static let title1: CGFloat = 28
        static let title2: CGFloat = 22
        static let title3: CGFloat = 20
        static let headline: CGFloat = 17
        static let body: CGFloat = 17
        static let callout: CGFloat = 16
        static let subheadline: CGFloat = 15
        static let footnote: CGFloat = 13
        static let caption1: CGFloat = 12
        static let caption2: CGFloat = 11
        
        // Font Weights
        static let light = Font.Weight.light
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
        
        // Custom Fonts
        static func customFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return .system(size: size, weight: weight, design: .default)
        }
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Shadow
    struct Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let large = (color: Color.black.opacity(0.2), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let glass = (color: Color.black.opacity(0.3), radius: CGFloat(10), x: CGFloat(0), y: CGFloat(5))
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    }
}

// MARK: - Glass Effect ViewModifier
struct GlassmorphismModifier: ViewModifier {
    let cornerRadius: CGFloat
    let opacity: Double
    let blur: CGFloat
    let borderWidth: CGFloat
    
    init(
        cornerRadius: CGFloat = Theme.CornerRadius.medium,
        opacity: Double = 0.1,
        blur: CGFloat = 10,
        borderWidth: CGFloat = 1
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.blur = blur
        self.borderWidth = borderWidth
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.Colors.glassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Theme.Colors.glassBorder, lineWidth: borderWidth)
                    )
            )
            .shadow(
                color: Theme.Shadow.glass.color,
                radius: Theme.Shadow.glass.radius,
                x: Theme.Shadow.glass.x,
                y: Theme.Shadow.glass.y
            )
    }
}

// MARK: - View Extensions
extension View {
    func glassmorphism(
        cornerRadius: CGFloat = Theme.CornerRadius.medium,
        opacity: Double = 0.1,
        blur: CGFloat = 10,
        borderWidth: CGFloat = 1
    ) -> some View {
        self.modifier(
            GlassmorphismModifier(
                cornerRadius: cornerRadius,
                opacity: opacity,
                blur: blur,
                borderWidth: borderWidth
            )
        )
    }
    
    func glassCard() -> some View {
        self
            .padding(Theme.Spacing.md)
            .glassmorphism(cornerRadius: Theme.CornerRadius.large)
    }
    
    func glassButton() -> some View {
        self
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .glassmorphism(cornerRadius: Theme.CornerRadius.small)
    }
}