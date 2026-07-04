import XCTest
@testable import CubiomesCore

final class CubiomesCoreTests: XCTestCase {
    func testVersionStringParsingUsesCubiomesVersionTable() {
        XCTAssertEqual(MinecraftVersion("1.18"), .v1_18)
        XCTAssertEqual(MinecraftVersion("1.21"), .v1_21)
        XCTAssertNil(MinecraftVersion("not-a-version"))
    }

    func testFixedSeedCoordinateBiomeLookup() throws {
        let biome = try CubiomesCore.biome(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            x: 0,
            z: 0
        )

        XCTAssertEqual(biome.id, 14)
        XCTAssertEqual(biome.name, "mushroom_fields")
    }
}
