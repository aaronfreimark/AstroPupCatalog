import Foundation

/// One catalog object, retaining the cross-reference and common-name fields the
/// resolver indexes by. The `id` is the **canonical key**, produced in AstroPup
/// Sky's exact form so a resolved object can be written into Sky's `ImagedDSO` /
/// `FavoriteDSO` and matched there by string equality:
///
/// - Messier → `M31` (no space, no zero-pad)
/// - NGC / IC → `NGC 224` / `IC 405` (single space, leading zeros stripped)
/// - addendum / native-name objects → their raw OpenNGC name, verbatim (`C009`)
///
/// Keys are always **bare designations** — never namespace-prefixed — so an app
/// can safely union catalog ids with its own `"comet:…"` / `"planet:…"` ids in a
/// single `Set<String>`.
///
/// Raw OpenNGC fields (`rawType`, `bMag`, `vMag`, both axes, `identifiers`) are
/// retained so a consuming app can apply its own parse policies (magnitude
/// fallback, size axis, type→category mapping) instead of only pre-baked choices.
public struct CatalogObject: Sendable, Identifiable {
    public let id: String
    public let ra: Double          // radians, J2000
    public let dec: Double
    public let kind: DSOKind
    public let rawType: String     // raw OpenNGC type code, e.g. "G", "HII", "PN"
    public let messier: String?    // "M31" when in the Messier catalog
    public let name: String        // raw OpenNGC Name, e.g. "NGC0224", "C009", "B033"
    public var identifiers: [String]  // cross-refs: "UGC 00454", "SH 2-155"; also
                                      // absorbs folded supplemental designations
    public let commonNames: [String]  // e.g. ["Andromeda Galaxy"]
    public var majorAxis: Double?     // major-axis angular size, arcminutes (OpenNGC MajAx)
    public var minorAxis: Double?     // minor-axis angular size, arcminutes (OpenNGC MinAx)
    public var positionAngle: Double? // major-axis angle, degrees N→E (OpenNGC PosAng)
    public var bMag: Double?          // B-band magnitude (OpenNGC B-Mag)
    public var vMag: Double?          // V-band magnitude (OpenNGC V-Mag)
    public var source: String         // the catalog file this row was parsed from (provenance)

    public init(
        id: String, ra: Double, dec: Double, kind: DSOKind, rawType: String = "",
        messier: String? = nil, name: String, identifiers: [String] = [],
        commonNames: [String] = [], majorAxis: Double? = nil, minorAxis: Double? = nil,
        positionAngle: Double? = nil, bMag: Double? = nil, vMag: Double? = nil, source: String = ""
    ) {
        self.id = id; self.ra = ra; self.dec = dec; self.kind = kind; self.rawType = rawType
        self.messier = messier; self.name = name; self.identifiers = identifiers
        self.commonNames = commonNames; self.majorAxis = majorAxis; self.minorAxis = minorAxis
        self.positionAngle = positionAngle; self.bMag = bMag; self.vMag = vMag; self.source = source
    }

    public var primaryCommonName: String { commonNames.first ?? id }
}

extension CatalogObject {
    /// Catalog objects whose extent covers `(ra, dec)` (radians J2000), or that lie
    /// within `tolerance` radians of it — nearest centre first. Powers an identify
    /// tool ("what's at this spot?").
    public static func at(ra: Double, dec: Double, tolerance: Double, in catalog: [CatalogObject]) -> [CatalogObject] {
        let arcminToRad = Double.pi / 180 / 60
        var hits: [(obj: CatalogObject, sep: Double)] = []
        for obj in catalog {
            let d = sin(dec) * sin(obj.dec) + cos(dec) * cos(obj.dec) * cos(ra - obj.ra)
            let sep = acos(min(1, max(-1, d)))
            let radius = max((obj.majorAxis ?? 0) / 2 * arcminToRad, tolerance)
            if sep <= radius { hits.append((obj, sep)) }
        }
        return hits.sorted { $0.sep < $1.sep }.map(\.obj)
    }
}
