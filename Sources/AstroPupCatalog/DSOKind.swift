import Foundation

/// Visual category of a deep-sky object, mirroring AstroPup Sky's
/// `DeepSkyObject.Kind` so the glyphs match across the family. Apps that need
/// finer categories keep the raw OpenNGC type code on `CatalogObject.rawType`
/// and map it themselves.
public enum DSOKind: String, Codable, Sendable, CaseIterable {
    case galaxy, galaxyGroup, nebula, planetaryNebula, openCluster, globularCluster, star, other

    public var displayName: String {
        switch self {
        case .galaxy: "Galaxy"
        case .galaxyGroup: "Galaxy group"
        case .nebula: "Nebula"
        case .planetaryNebula: "Planetary nebula"
        case .openCluster: "Open cluster"
        case .globularCluster: "Globular cluster"
        case .star: "Star"
        case .other: "Other"
        }
    }
}
