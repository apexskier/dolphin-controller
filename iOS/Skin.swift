import Foundation
import SwiftUI

extension EnvironmentValues {
    @Entry var skin = Skin.indigo
}

// https://gccontrollerlibrary.com/controllers/wired-gamecube-controller/
enum Skin: String, CaseIterable, Identifiable {
    case indigo
    case black
    case orange
    case platinum
    case emerald
    case white
    case clear
    case starlight
    case pearl
    case symphonic

    var id: Self { self }

    var name: String {
        switch self {
        case .indigo: return "Indigo"
        case .black: return "Jet Black"
        case .orange: return "Spice Orange"
        case .platinum: return "Platinum"
        case .emerald: return "Emerald Blue"
        case .white: return "White"
        case .clear: return "Clear"
        case .starlight: return "Starlight Gold"
        case .pearl: return "Pearl White"
        case .symphonic: return "Symphonic Green"
        }
    }

    var requiresSupport: Bool {
        switch self {
        case .indigo, .clear:
            return false
        default:
            return true
        }
    }

    var view: some View {
        switch self {
        case .clear:
            return AnyView(ClearSkinView())
        default:
            return AnyView(color)
        }
    }

    var color: Color {
        switch self {
        case .indigo:
            return Color(red: 106/256, green: 115/256, blue: 188/256)
        case .black:
            return Color(red: 45/256, green: 45/256, blue: 45/256)
        case .orange:
            return Color(red: 0.941, green: 0.569, blue: 0.239)
        case .platinum:
            return Color(red: 220/256, green: 220/256, blue: 220/256)
        case .emerald:
            return Color(red: 43/256, green: 199/256, blue: 199/256)
        case .white:
            return Color(red: 245/256, green: 245/256, blue: 245/256)
        case .clear:
            return .clear
        case .starlight:
            return Color(red: 238/256, green: 228/256, blue: 196/256)
        case .pearl:
            return Color(red: 250/256, green: 249/256, blue: 240/256)
        case .symphonic:
            return Color(red: 204/256, green: 231/256, blue: 200/256)
        }
    }

    enum Rarity: Hashable, CaseIterable, Comparable, Identifiable {
        case common
        case uncommon
        case rare

        var id: String { description }
    }

    var rarity: Rarity {
        switch self {
        case .indigo: return .common
        case .black: return .common
        case .orange: return .common
        case .platinum: return .common
        case .emerald: return .uncommon
        case .white: return .uncommon
        case .clear: return .uncommon
        case .starlight: return .rare
        case .pearl: return .uncommon
        case .symphonic: return .rare
        }
    }
}

extension Skin: CustomStringConvertible {
    var description: String { name }
}

extension Skin.Rarity: CustomStringConvertible {
    var description: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        }
    }
}
