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
