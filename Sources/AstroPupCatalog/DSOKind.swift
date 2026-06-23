import Foundation

/// Visual category of a deep-sky object, mirroring AstroPup Sky's
/// `DeepSkyObject.Kind` so the glyphs match across the family. Apps that need
/// finer categories keep the raw OpenNGC type code on `CatalogObject.rawType`
/// and map it themselves.
public enum DSOKind: String, Codable, Sendable, CaseIterable {
    case galaxy, galaxyGroup, brightNebula, darkNebula, planetaryNebula, openCluster, globularCluster, star, other

    /// Localized label for the kind — the single source of truth for the family, so
    /// "Galaxy group" etc. can't drift between apps. Translations live in the
    /// package's `Localizable.xcstrings`.
    public var displayName: String {
        switch self {
        case .galaxy:           String(localized: "Galaxy", bundle: .module, comment: "DSO kind")
        case .galaxyGroup:      String(localized: "Galaxy group", bundle: .module, comment: "DSO kind: pair/group/cluster of galaxies")
        case .brightNebula:     String(localized: "Bright nebula", bundle: .module, comment: "DSO kind: emission/reflection/SNR")
        case .darkNebula:       String(localized: "Dark nebula", bundle: .module, comment: "DSO kind: absorption nebula")
        case .planetaryNebula:  String(localized: "Planetary nebula", bundle: .module, comment: "DSO kind")
        case .openCluster:      String(localized: "Open cluster", bundle: .module, comment: "DSO kind")
        case .globularCluster:  String(localized: "Globular cluster", bundle: .module, comment: "DSO kind")
        case .star:             String(localized: "Star", bundle: .module, comment: "DSO kind")
        case .other:            String(localized: "Other", bundle: .module, comment: "DSO kind")
        }
    }
}
