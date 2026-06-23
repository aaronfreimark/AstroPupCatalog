import XCTest
@testable import AstroPupCatalog

final class CatalogTests: XCTestCase {
    // Parse once; reuse across tests.
    static let resolver = CatalogResolver.bundled()
    private var resolver: CatalogResolver { Self.resolver }

    func testCatalogLoads() {
        XCTAssertGreaterThan(resolver.catalogObjects.count, 13_000)
    }

    func testMessierCanonicalKey() {
        guard case let .object(id, _, _, _, _) = resolver.resolve("M31") else {
            return XCTFail("M31 did not resolve")
        }
        XCTAssertEqual(id, "M31")                       // no space, no zero-pad (Sky's format)
    }

    func testNGCFormat() {
        guard case let .object(id, _, _, _, _) = resolver.resolve("NGC 7000") else {
            return XCTFail("NGC 7000 did not resolve")
        }
        XCTAssertEqual(id, "NGC 7000")                  // single space, zero-pad stripped
    }

    func testCanonicalKeysAreBareDesignations() {
        // Sky unions these ids with "comet:…" in one Set<String>; keys must never be prefixed.
        for o in resolver.catalogObjects {
            XCTAssertFalse(o.id.contains(":"), "key must be a bare designation: \(o.id)")
        }
    }

    func testRawFieldsExposed() {
        guard let m31 = resolver.object(id: "M31") else { return XCTFail("no M31") }
        XCTAssertFalse(m31.rawType.isEmpty)             // raw OpenNGC type code retained
        XCTAssertTrue(m31.vMag != nil || m31.bMag != nil)  // both magnitudes exposed
    }

    func testKindDisplayNamesResolveFromTheStringCatalog() {
        // The localized labels are the family's single source of truth (no drift).
        XCTAssertEqual(DSOKind.galaxy.displayName, "Galaxy")
        XCTAssertEqual(DSOKind.galaxyGroup.displayName, "Galaxy group")
        XCTAssertEqual(DSOKind.brightNebula.displayName, "Bright nebula")
        XCTAssertEqual(DSOKind.darkNebula.displayName, "Dark nebula")
        XCTAssertEqual(DSOKind.star.displayName, "Star")
    }

    func testSupplementalDedupFoldsDuplicatesOntoAPrimary() {
        // LBN 148 = Sh2-94 — same HII region, no NGC counterpart. One object now.
        XCTAssertNil(resolver.object(id: "LBN 148"))                                   // folded away
        XCTAssertTrue(resolver.object(id: "Sh2-94")?.identifiers.contains("LBN 148") ?? false)
        guard case let .object(id, _, _, _, _) = resolver.resolve("LBN 148") else {
            return XCTFail("LBN 148 should resolve")
        }
        XCTAssertEqual(id, "Sh2-94")                                                   // resolves to the primary
    }

    func testBrightAndDarkCoincidenceIsNotMerged() {
        // LBN 1116 (bright) and LDN 1730 (dark) coincide on the sky but are different
        // kinds — the dedup is same-class only, so they stay two objects.
        guard case let .object(bid, _, _, _, _) = resolver.resolve("LBN 1116"),
              case let .object(did, _, _, _, _) = resolver.resolve("LDN 1730") else {
            return XCTFail("both should resolve")
        }
        XCTAssertNotEqual(bid, did)
        XCTAssertEqual(resolver.object(id: "LDN 1730")?.kind, .darkNebula)
    }

    func testNebulaeSplitIntoBrightAndDark() {
        // Matches Sky: Sharpless/LBN/vdB = bright, LDN = dark.
        XCTAssertEqual(resolver.object(id: "Sh2-94")?.kind, .brightNebula)   // HII
        XCTAssertEqual(resolver.object(id: "LDN 1730")?.kind, .darkNebula)   // DrkN
    }

    func testNamedStarsResolveByProperName() {
        guard case let .object(id, name, _, _, kind) = resolver.resolve("Albireo") else {
            return XCTFail("Albireo did not resolve")
        }
        XCTAssertEqual(id, "Albireo")
        XCTAssertEqual(name, "Albireo")
        XCTAssertEqual(kind, .star)
        if case let .object(_, _, _, _, k) = resolver.resolve("Vega") { XCTAssertEqual(k, .star) }
        else { XCTFail("Vega did not resolve") }
    }

    func testNamedStarsLoadedAsPointSources() {
        let stars = resolver.catalogObjects.filter { $0.kind == .star }
        XCTAssertGreaterThan(stars.count, 400)                       // ~451 IAU named stars
        XCTAssertTrue(stars.allSatisfy { $0.rawType == "Star" })
        XCTAssertTrue(stars.allSatisfy { $0.majorAxis == nil })      // point sources, no extent
    }

    func testStarSearchByNameAndDesignation() {
        XCTAssertTrue(resolver.search("Vega").contains { $0.id == "Vega" })
        XCTAssertTrue(resolver.search("HD 172167").contains { $0.id == "Vega" })  // identifier search
    }

    func testAliasFolding_NorthAmerica() {
        // Sh2-117 and LBN 373 are SIMBAD-vetted duplicates of NGC 7000.
        guard case let .object(a, _, _, _, _) = resolver.resolve("Sh2-117"),
              case let .object(b, _, _, _, _) = resolver.resolve("LBN 373"),
              case let .object(c, _, _, _, _) = resolver.resolve("NGC 7000") else {
            return XCTFail("North America aliases did not resolve")
        }
        XCTAssertEqual(a, "NGC 7000")
        XCTAssertEqual(b, "NGC 7000")
        XCTAssertEqual(c, "NGC 7000")
    }

    func testAliasFolding_Iris_vdB() {
        // vdB 139 folds onto NGC 7023 (Iris) — kept despite SIMBAD modelling vdB as the star.
        guard case let .object(a, _, _, _, _) = resolver.resolve("vdB 139"),
              case let .object(b, _, _, _, _) = resolver.resolve("NGC 7023") else {
            return XCTFail("Iris aliases did not resolve")
        }
        XCTAssertEqual(a, b)
    }

    func testSolarSystemFlagged() {
        XCTAssertEqual(resolver.resolve("Jupiter"), .notDeepSky)
        XCTAssertEqual(resolver.resolve("not a real object xyzzy"), .unresolved)
    }
}
