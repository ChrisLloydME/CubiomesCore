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

    func testBiomeGridCanCoverFixedCoordinateLookup() throws {
        let grid = try CubiomesCore.biomes(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            originX: -1,
            originZ: -1,
            width: 3,
            height: 3,
            scale: 1,
            y: 63
        )

        XCTAssertEqual(grid.ids.count, 9)
        XCTAssertEqual(grid.idAt(x: 1, z: 1), 14)
    }

    func testBiomeGridUsesZMajorRowOrder() throws {
        let originX: Int32 = -8
        let originZ: Int32 = -8
        let width: Int32 = 4
        let height: Int32 = 3
        let grid = try CubiomesCore.biomes(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            originX: originX,
            originZ: originZ,
            width: width,
            height: height,
            scale: 1,
            y: 63
        )

        XCTAssertEqual(grid.ids.count, Int(width * height))

        for z in 0..<height {
            for x in 0..<width {
                let single = try CubiomesCore.biome(
                    version: .v1_18,
                    seed: 262,
                    dimension: .overworld,
                    x: originX + x,
                    y: 63,
                    z: originZ + z
                )
                XCTAssertEqual(grid.ids[Int(z * width + x)], single.id)
            }
        }
    }

    func testBiomeGridRejectsScale1024UntilCubiomesSupportsIt() throws {
        XCTAssertThrowsError(
            try CubiomesCore.biomes(
                version: .v1_18,
                seed: 262,
                dimension: .overworld,
                originX: 0,
                originZ: 0,
                width: 1,
                height: 1,
                scale: 1024,
                y: 63
            )
        ) { error in
            XCTAssertEqual(
                error as? CubiomesError,
                .unsupportedBiomeScale(scale: 1024, supported: [1, 4, 16, 64, 256])
            )
        }
    }

    func testStructureOverlayAPIProducesStableFieldsInsideRect() throws {
        let rect = StructureRect(originX: -2048, originZ: -2048, width: 4096, height: 4096)
        let structures = try CubiomesCore.structures(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            types: [.village],
            rect: rect
        )

        for structure in structures {
            XCTAssertEqual(structure.type, .village)
            XCTAssertEqual(structure.dimension, .overworld)
            XCTAssertTrue(rect.contains(blockX: structure.blockX, blockZ: structure.blockZ))
        }
    }

    func testUnsupportedStructureDimensionReturnsEmptyArray() throws {
        let structures = try CubiomesCore.structures(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            types: [.fortress],
            rect: StructureRect(originX: -512, originZ: -512, width: 1024, height: 1024)
        )

        XCTAssertTrue(structures.isEmpty)
    }
}
