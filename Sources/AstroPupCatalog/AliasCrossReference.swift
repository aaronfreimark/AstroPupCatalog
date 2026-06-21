import Foundation

/// Folds supplemental-catalog objects (Sharpless/LDN/LBN/vdB/PK/Abell) onto the
/// canonical OpenNGC object they're a duplicate of, using a **precomputed,
/// SIMBAD-vetted alias map** (`OpenNGC/alias-map.json`) rather than a runtime
/// positional heuristic. So `Sh2-117`, `LBN 373`, and `NGC 7000` all resolve to
/// one object (the supplemental designations are absorbed as identifiers), while
/// genuinely-new supplemental objects pass through standalone.
///
/// The map is generated offline (`scripts/crossmatch-catalogs.py` +
/// `verify-matches-simbad.py` in the Gallery repo) and is the authoritative,
/// reviewable cross-identification — see the package's `OpenNGC/SOURCE.md`.
enum AliasCrossReference {

    /// `designation → canonical designation`, both normalized.
    private struct Map { let entries: [String: String] }

    static func merge(canonical: [CatalogObject], supplemental: [CatalogObject]) -> [CatalogObject] {
        let map = loadMap()

        // Index canonical objects by every designation they answer to.
        var byDesignation: [String: Int] = [:]
        for (i, c) in canonical.enumerated() {
            for key in [c.id, c.name, c.messier].compactMap({ $0 }) {
                let n = Designation.normalize(key)
                if !n.isEmpty, byDesignation[n] == nil { byDesignation[n] = i }
            }
        }

        var result = canonical
        var leftovers: [CatalogObject] = []
        for s in supplemental {
            // Is this supplemental designation a known duplicate of a canonical object?
            if let target = map.entries[Designation.normalize(s.id)],
               let idx = byDesignation[target] {
                result[idx].identifiers.append(s.id)   // absorb its designation
            } else {
                leftovers.append(s)                    // genuinely new object
            }
        }
        result.append(contentsOf: leftovers)
        return result
    }

    private struct AliasFile: Decodable { let aliases: [String: String] }

    private static func loadMap() -> Map {
        guard let url = Bundle.module.url(forResource: "alias-map", withExtension: "json", subdirectory: "OpenNGC"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(AliasFile.self, from: data)
        else { return Map(entries: [:]) }
        var entries: [String: String] = [:]
        for (k, v) in file.aliases {
            entries[Designation.normalize(k)] = Designation.normalize(v)
        }
        return Map(entries: entries)
    }
}
