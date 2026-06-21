import Foundation

/// Loads and parses the bundled OpenNGC catalog (core + supplements). Mirrors
/// AstroPup Sky's parser — same column indices, same canonical-key and coordinate
/// logic — and retains the raw fields apps need for their own parse policies.
public enum OpenNGCCatalog {

    private enum Col {
        static let name = 0, type = 1, ra = 2, dec = 3, majAx = 5, minAx = 6, posAng = 7
        static let bMag = 8, vMag = 9
        static let messier = 23, ngc = 24, ic = 25
        static let identifiers = 27, commonNames = 28
        static let minFields = 29
    }

    /// Canonical OpenNGC catalog (wins on collisions; never folded away).
    static let canonicalFiles = ["NGC", "addendum"]
    /// Supplemental catalogs, folded onto canonical objects via the alias map.
    static let supplementalFiles = ["sharpless", "ldn", "lbn", "pk", "abell", "vdb"]
    static var catalogFiles: [String] { canonicalFiles + supplementalFiles }

    /// The unified catalog: canonical OpenNGC objects with SIMBAD-vetted
    /// supplemental designations folded in, plus genuinely-new supplemental objects.
    public static func loadBundled() -> [CatalogObject] {
        let canonical = canonicalFiles.flatMap(parseFile)
        let supplemental = supplementalFiles.flatMap(parseFile)
        return AliasCrossReference.merge(canonical: canonical, supplemental: supplemental)
    }

    private static func parseFile(_ resource: String) -> [CatalogObject] {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "csv", subdirectory: "Catalog"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }   // missing supplemental files are simply skipped
        return parse(text, source: resource)
    }

    public static func parse(_ text: String, source: String = "") -> [CatalogObject] {
        var result: [CatalogObject] = []
        var isFirst = true
        for rawLine in text.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline) {
            if isFirst { isFirst = false; continue }
            let f = rawLine.split(separator: ";", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard f.count >= Col.minFields, let obj = parseRow(f, source: source) else { continue }
            result.append(obj)
        }
        return result
    }

    private static func parseRow(_ f: [String], source: String = "") -> CatalogObject? {
        // Skip non-objects (duplicates, stars, novae) as Sky does.
        switch f[Col.type] {
        case "Dup", "*", "**", "NonEx", "Nova": return nil
        default: break
        }
        guard let ra = parseRA(f[Col.ra]), let dec = parseDec(f[Col.dec]) else { return nil }

        let messier: String? = {
            let raw = f[Col.messier]
            guard !raw.isEmpty, let n = Int(raw) else { return nil }
            return "M\(n)"
        }()
        let id = messier ?? prettifyName(f[Col.name])

        return CatalogObject(
            id: id,
            ra: ra, dec: dec,
            kind: mapKind(f[Col.type]),
            rawType: f[Col.type],
            messier: messier,
            name: f[Col.name],
            identifiers: splitList(f[Col.identifiers]),
            commonNames: splitList(f[Col.commonNames]),
            majorAxis: f.indices.contains(Col.majAx) ? Double(f[Col.majAx]) : nil,
            minorAxis: f.indices.contains(Col.minAx) ? Double(f[Col.minAx]) : nil,
            positionAngle: f.indices.contains(Col.posAng) ? Double(f[Col.posAng]) : nil,
            bMag: f.indices.contains(Col.bMag) ? Double(f[Col.bMag]) : nil,
            vMag: f.indices.contains(Col.vMag) ? Double(f[Col.vMag]) : nil,
            source: source
        )
    }

    /// OpenNGC type code → visual category (mirrors Sky's mapping).
    private static func mapKind(_ raw: String) -> DSOKind {
        switch raw {
        case "G": return .galaxy
        case "GPair", "GTrpl", "GGroup": return .galaxyGroup
        case "PN": return .planetaryNebula
        case "OCl", "Cl+N": return .openCluster
        case "GCl": return .globularCluster
        case "Neb", "EmN", "RfN", "HII", "SNR", "DrkN": return .nebula
        default: return .other
        }
    }

    private static func splitList(_ s: String) -> [String] {
        s.isEmpty ? [] : s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func parseRA(_ s: String) -> Double? {
        let p = s.split(separator: ":")
        guard p.count == 3, let h = Double(p[0]), let m = Double(p[1]), let sec = Double(p[2]) else { return nil }
        return (h + m / 60 + sec / 3600) * .pi / 12
    }
    private static func parseDec(_ s: String) -> Double? {
        guard !s.isEmpty else { return nil }
        let neg = s.first == "-"
        let body = (s.first == "-" || s.first == "+") ? String(s.dropFirst()) : s
        let p = body.split(separator: ":")
        guard p.count == 3, let d = Double(p[0]), let m = Double(p[1]), let sec = Double(p[2]) else { return nil }
        let mag = d + m / 60 + sec / 3600
        return (neg ? -mag : mag) * .pi / 180
    }
    private static func prettifyName(_ raw: String) -> String {
        for prefix in ["NGC", "IC"] where raw.hasPrefix(prefix) {
            if let n = Int(raw.dropFirst(prefix.count)) { return "\(prefix) \(n)" }
        }
        return raw
    }
}
