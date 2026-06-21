import Foundation

/// The bundled OpenNGC resolver, parsed once on first use. Access it off the main
/// actor (the ~14k-row parse shouldn't block UI).
public enum SharedCatalog {
    public static let resolver: CatalogResolver = .bundled()
}

/// Resolves a raw target string (from a filename/folder, or user input) to a
/// catalog object.
///
/// Three indexes, tried in order: catalog **designation** (M/NGC/IC/Caldwell/
/// Barnard/…), cross-reference **identifier** (UGC/SH2/LBN/PK/vdB/…), and **common
/// name**. Plus a few fix-ups: mosaic-panel suffixes (`M 31 Panel 1` → M31),
/// `Xmas` → `Christmas`, and a small nickname table. Solar-system names are flagged
/// `.notDeepSky` rather than left unresolved. (Comet detection is left to the host
/// app, which knows its own naming; this resolver covers DSOs only.)
public struct CatalogResolver: Sendable {
    public enum Resolution: Sendable, Equatable {
        case object(id: String, commonName: String, ra: Double, dec: Double, kind: DSOKind)
        case notDeepSky          // Sun, Moon, a planet — real, but not a DSO
        case unresolved
    }

    private var byDesignation: [String: CatalogObject] = [:]
    private var byCommonName: [String: CatalogObject] = [:]
    private var byID: [String: CatalogObject] = [:]
    private let allObjects: [CatalogObject]

    private static let solarSystem: Set<String> = [
        "sun", "moon", "mercury", "venus", "mars", "jupiter", "saturn",
        "uranus", "neptune", "pluto"
    ]

    /// Well-known nicknames OpenNGC lacks a common name for, mapped to the
    /// canonical id. Only applied as a fallback, after the catalog indexes.
    private static let aliases: [String: String] = [
        "pinwheel galaxy": "M101",
        "seven sisters": "M45",
        "christmas tree": "NGC 2264",
        "christmas tree cluster": "NGC 2264",
        "gamma cygni nebula": "IC 1318",
        "pacman": "NGC 281",
        "pacman nebula": "NGC 281",
    ]

    /// Type words appended to a bare nickname to match catalog common names —
    /// "Owl" → "Owl Nebula", "Needle" → "Needle Galaxy".
    private static let typeSuffixes = ["Nebula", "Galaxy", "Cluster"]

    public init(objects: [CatalogObject]) {
        self.allObjects = objects
        for obj in objects {
            byID[obj.id] = obj
            for key in designationKeys(for: obj) where byDesignation[key] == nil {
                byDesignation[key] = obj
            }
            for name in obj.commonNames {
                let key = normalizeCommonName(name)
                if !key.isEmpty, byCommonName[key] == nil { byCommonName[key] = obj }
            }
        }
    }

    /// Convenience: build from the bundled catalog.
    public static func bundled() -> CatalogResolver { CatalogResolver(objects: OpenNGCCatalog.loadBundled()) }

    public func object(id: String) -> CatalogObject? { byID[id] }

    /// All catalog objects (for a map/chart overlay).
    public var catalogObjects: [CatalogObject] { allObjects }

    /// Free-text search over the catalog. Ranks exact/designation/prefix matches
    /// above substring matches. (Search *ranking/UI* is left to each app; this is a
    /// reasonable default.)
    public func search(_ query: String, limit: Int = 40) -> [CatalogObject] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }
        let nq = q.lowercased()
        let nd = Designation.normalize(q)
        var scored: [(rank: Int, obj: CatalogObject)] = []
        for o in allObjects {
            var rank = Int.max
            let idl = o.id.lowercased()
            if idl == nq || Designation.normalize(o.id) == nd { rank = 0 }
            else if idl.hasPrefix(nq) { rank = 2 }
            for cn in o.commonNames {
                let c = cn.lowercased()
                if c == nq { rank = min(rank, 1) }
                else if c.hasPrefix(nq) { rank = min(rank, 3) }
                else if c.contains(nq) { rank = min(rank, 4) }
            }
            if rank == Int.max {
                if idl.contains(nq) { rank = 5 }
                else if o.identifiers.contains(where: { $0.lowercased().contains(nq) }) { rank = 6 }
            }
            if rank < Int.max { scored.append((rank, o)) }
        }
        return scored.sorted { $0.rank != $1.rank ? $0.rank < $1.rank : $0.obj.id < $1.obj.id }
            .prefix(limit).map(\.obj)
    }

    // MARK: - Resolve

    public func resolve(_ raw: String) -> Resolution {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if Self.solarSystem.contains(trimmed.lowercased()) { return .notDeepSky }

        // Try the raw form, then progressively cleaned-up forms.
        for candidate in candidates(from: trimmed) {
            if let obj = byDesignation[Designation.normalize(candidate)] { return result(obj) }
            if let obj = byCommonName[normalizeCommonName(candidate)] { return result(obj) }
            if let id = Self.aliases[normalizeCommonName(candidate)], let obj = byID[id] { return result(obj) }
        }
        return .unresolved
    }

    private func result(_ o: CatalogObject) -> Resolution {
        .object(id: o.id, commonName: o.primaryCommonName, ra: o.ra, dec: o.dec, kind: o.kind)
    }

    /// Ordered candidate spellings to try for one raw target.
    private func candidates(from raw: String) -> [String] {
        var list = [raw]
        let depanel = raw.replacingOccurrences(
            of: #"\s+(panel\s*\d*|mosaic.*)$"#, with: "",
            options: [.regularExpression, .caseInsensitive])
        if depanel != raw { list.append(depanel) }
        if let m = raw.range(of: #"(?i)^caldwell\s+(\d+)$"#, options: .regularExpression) {
            let n = raw[m].filter(\.isNumber)
            list.append("C \(n)")
        }
        if raw.range(of: "xmas", options: .caseInsensitive) != nil {
            list.append(raw.replacingOccurrences(of: "xmas", with: "Christmas", options: .caseInsensitive))
        }
        if let r = raw.range(of: #"\s+\S+$"#, options: .regularExpression) {
            list.append(String(raw[raw.startIndex..<r.lowerBound]))
        }
        let bases = list
        for base in bases {
            let lower = base.lowercased()
            for suffix in Self.typeSuffixes where !lower.hasSuffix(" \(suffix.lowercased())") {
                list.append("\(base) \(suffix)")
            }
        }
        return list
    }

    // MARK: - Index keys

    private func designationKeys(for obj: CatalogObject) -> [String] {
        var keys: [String] = [Designation.normalize(obj.id), Designation.normalize(obj.name)]
        if let m = obj.messier { keys.append(Designation.normalize(m)) }
        for ident in obj.identifiers { keys.append(Designation.normalize(ident)) }
        if let n = number(obj.name, prefix: "C") { keys.append(Designation.normalize("Caldwell \(n)")) }
        if let n = number(obj.name, prefix: "B") { keys.append(Designation.normalize("Barnard \(n)")) }
        return keys.filter { !$0.isEmpty }
    }

    private func number(_ s: String, prefix: String) -> Int? {
        guard s.hasPrefix(prefix) else { return nil }
        return Int(s.dropFirst(prefix.count))
    }

    // MARK: - Normalization

    /// Lowercase, drop apostrophes/hyphens and a leading "the ", collapse whitespace.
    public func normalizeCommonName(_ s: String) -> String {
        var t = s.lowercased().replacingOccurrences(of: "'", with: "")
        t = t.replacingOccurrences(of: "’", with: "")
        t = t.replacingOccurrences(of: "-", with: "")
        t = t.replacingOccurrences(of: #"^the\s+"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespaces)
    }
}
