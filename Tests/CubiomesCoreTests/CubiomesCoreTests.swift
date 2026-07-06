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

    func testBiomeInfoWrapsCubiomesMetadataHelpers() {
        let info = CubiomesCore.biomeInfo(version: .v1_18, id: 14)

        XCTAssertEqual(info.name, "mushroom_fields")
        XCTAssertTrue(info.exists)
        XCTAssertEqual(info.dimension, .overworld)
        XCTAssertTrue(info.isOverworld)
        XCTAssertNil(info.mutatedID)
    }

    func testBiomeClassificationAndTerrainInfoWrapPureCubiomesHelpers() throws {
        let badlands = CubiomesCore.biomeClassification(id: 37)
        XCTAssertTrue(badlands.isMesa)
        XCTAssertFalse(badlands.isOceanic)

        let ocean = CubiomesCore.biomeClassification(id: 0)
        XCTAssertTrue(ocean.isShallowOcean)
        XCTAssertTrue(ocean.isOceanic)
        XCTAssertFalse(ocean.isDeepOcean)

        let plains = try CubiomesCore.biomeTerrainInfo(id: 1)
        XCTAssertEqual(plains.depth, 0.125, accuracy: 0.0001)
        XCTAssertEqual(plains.scale, 0.05, accuracy: 0.0001)
        XCTAssertEqual(plains.grass, 62)

        XCTAssertThrowsError(try CubiomesCore.biomeTerrainInfo(id: 999)) { error in
            XCTAssertEqual(error as? CubiomesError, .unsupportedBiome(id: 999))
        }
    }

    func testApproximateHeightGridProducesStableShape() throws {
        let heights = try CubiomesCore.approximateHeights(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            originX: 0,
            originZ: 0,
            width: 2,
            height: 2
        )

        XCTAssertEqual(heights.heights.count, 4)
        XCTAssertEqual(heights.biomeIDs.count, 4)
        XCTAssertNotNil(heights.heightAt(x: 1, z: 1))
        XCTAssertNotNil(heights.biomeIDAt(x: 1, z: 1))
    }

    func testSpecializedNetherAndEndBiomeMapsProduceStableValues() throws {
        let nether = try CubiomesCore.netherBiomes(seed: 262, originX: 0, originZ: 0, width: 3, height: 2)
        XCTAssertEqual(nether.ids, [171, 171, 171, 171, 171, 171])
        XCTAssertEqual(nether.idAt(x: 2, z: 1), 171)

        let endAtScale4 = try CubiomesCore.endBiomes(
            version: .v1_18,
            seed: 262,
            originX: 0,
            originZ: 0,
            width: 3,
            height: 2,
            scale: 4
        )
        XCTAssertEqual(endAtScale4.ids, [9, 9, 9, 9, 9, 9])

        let endAtScale16 = try CubiomesCore.endBiomes(
            version: .v1_18,
            seed: 262,
            originX: 0,
            originZ: 0,
            width: 3,
            height: 2,
            scale: 16
        )
        XCTAssertEqual(endAtScale16.ids, [9, 9, 9, 9, 9, 9])

        XCTAssertThrowsError(
            try CubiomesCore.endBiomes(version: .v1_18, seed: 262, originX: 0, originZ: 0, width: 1, height: 1, scale: 1)
        ) { error in
            XCTAssertEqual(error as? CubiomesError, .unsupportedBiomeScale(scale: 1, supported: [4, 16]))
        }
    }

    func testStructureConfigExposesNewConfiguredStructureTypes() throws {
        let config = try CubiomesCore.structureConfig(type: .trialChambers, version: .v1_21_1)

        XCTAssertEqual(config.type, .trialChambers)
        XCTAssertEqual(config.dimension, .overworld)
        XCTAssertEqual(config.regionSize, 34)
        XCTAssertEqual(StructureType.trialChambers.resourceName, "trial_chambers")
    }

    func testDirectStrongholdAndSlimeAPIsReturnStableShapes() {
        let strongholds = CubiomesCore.strongholds(version: .v1_18, seed: 262, limit: 3)

        XCTAssertEqual(strongholds.count, 3)
        XCTAssertTrue(strongholds.allSatisfy { $0.type == .stronghold && $0.dimension == .overworld })
        _ = CubiomesCore.firstStrongholdApproximation(version: .v1_18, seed: 262)
        _ = CubiomesCore.isSlimeChunk(seed: 262, chunkX: 0, chunkZ: 0)
    }

    func testStructureAttemptAndViabilityHelpersExposeSingleRegionChecks() throws {
        let attempt = try XCTUnwrap(CubiomesCore.structureAttempt(
            type: .village,
            version: .v1_18,
            seed: 262,
            regionX: 0,
            regionZ: 0
        ))

        XCTAssertEqual(attempt.type, .village)
        XCTAssertEqual(attempt.blockX, 192)
        XCTAssertEqual(attempt.blockZ, 208)
        XCTAssertEqual(attempt.dimension, .overworld)
        XCTAssertFalse(attempt.isViable)

        XCTAssertTrue(try CubiomesCore.isViableFeatureBiome(type: .village, version: .v1_18, biomeID: 1))
        XCTAssertFalse(try CubiomesCore.isViableFeatureBiome(type: .village, version: .v1_18, biomeID: 14))
        XCTAssertFalse(try CubiomesCore.isViableStructurePosition(
            type: .village,
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            blockX: 0,
            blockZ: 0
        ))
        XCTAssertTrue(try CubiomesCore.isViableStructureTerrain(
            type: .village,
            version: .v1_18,
            seed: 262,
            blockX: 192,
            blockZ: 208
        ))

        XCTAssertThrowsError(try CubiomesCore.structureAttempt(
            type: .stronghold,
            version: .v1_18,
            seed: 262,
            regionX: 0,
            regionZ: 0
        )) { error in
            XCTAssertEqual(error as? CubiomesError, .unsupportedStructureConfig(.stronghold, version: .v1_18))
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

    func testEndSpecificHelpersReturnStableGatewayAndIslandData() {
        let gateways = CubiomesCore.fixedEndGateways(version: .v1_18, seed: 262)
        XCTAssertEqual(gateways.count, 20)
        XCTAssertEqual(gateways.prefix(3), [
            BlockPosition(x: -96, z: -1),
            BlockPosition(x: -57, z: 77),
            BlockPosition(x: 77, z: 56),
        ])

        let link = CubiomesCore.linkedEndGateway(version: .v1_18, seed: 262, source: gateways[0])
        XCTAssertEqual(link.source, BlockPosition(x: -96, z: -1))
        XCTAssertEqual(link.destination, BlockPosition(x: -1137, z: 0))
        XCTAssertEqual(CubiomesCore.endSurfaceHeight(version: .v1_18, seed: 262, x: 0, z: 0), 62)

        let islands = CubiomesCore.endIslands(version: .v1_18, seed: 262, chunkX: -4, chunkZ: 1)
        XCTAssertEqual(islands, [EndIslandInfo(x: -61, y: 70, z: 28, radius: 4)])
    }

    func testSeedAndClimateHelpersExposeStablePureCubiomesValues() {
        XCTAssertEqual(CubiomesCore.shadowSeed(seed: 262), -7_379_792_620_528_906_481)
        XCTAssertEqual(CubiomesCore.movedStructureSeed(baseSeed: 262, regionX: -1, regionZ: -1), 474_771_116_515)
        XCTAssertEqual(CubiomesCore.chunkGenerationSeed(seed: 262, chunkX: 1, chunkZ: -2), 181_162_256_108_945)

        let extremes = CubiomesCore.climateParameterExtremes(version: .v1_18)
        XCTAssertEqual(extremes?.temperature, -4501...5500)
        XCTAssertEqual(extremes?.depth, 1000...10500)
        XCTAssertNil(CubiomesCore.climateParameterExtremes(version: .v1_17))

        let plains = CubiomesCore.climateParameterLimits(version: .v1_18, biomeID: 1)
        XCTAssertNotNil(plains)
        XCTAssertNil(CubiomesCore.climateParameterLimits(version: .v1_17, biomeID: 1))
    }

    func testMapTileCombinesBiomeHeightAndStructureOverlayData() throws {
        let tile = try CubiomesCore.mapTile(MapTileRequest(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            originX: 0,
            originZ: 0,
            width: 128,
            height: 128,
            scale: 4,
            includesApproximateHeights: true,
            structureTypes: [.village]
        ))

        XCTAssertEqual(tile.biomes.ids.count, 16_384)
        XCTAssertEqual(tile.approximateHeights?.heights.count, 16_384)
        XCTAssertEqual(tile.biomes.idAt(x: 0, z: 0), 14)
        XCTAssertEqual(tile.structures.first?.type, .village)
        XCTAssertEqual(tile.structures.first?.blockX, 192)
        XCTAssertEqual(tile.structures.first?.blockZ, 208)
    }

    func testBiomeStatisticsAndAreaFilterUseStableGridSemantics() throws {
        let request = BiomeAreaStatisticsRequest(
            version: .v1_18,
            seeds: [262],
            dimensions: [.overworld],
            originX: -1,
            originZ: -1,
            width: 3,
            height: 3,
            scale: 1
        )
        let stats = try CubiomesCore.biomeAreaStatistics(request)

        XCTAssertEqual(stats.count, 1)
        XCTAssertEqual(stats[0].seed, 262)
        XCTAssertEqual(stats[0].sampledCellCount, 9)
        XCTAssertEqual(stats[0].countsByBiomeID[14], 9)
        XCTAssertEqual(stats[0].distinctBiomeCount, 1)

        let includeMushroom = try CubiomesCore.biomeAreaFilter(BiomeAreaFilterRequest(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            originX: 0,
            originZ: 0,
            width: 1,
            height: 1,
            scale: 1,
            filter: BiomeFilterSpec(requiredBiomeIDs: [14])
        ))
        XCTAssertTrue(includeMushroom.matched)
        XCTAssertTrue(includeMushroom.completedFullGeneration)

        let excludeMushroom = try CubiomesCore.biomeAreaFilter(BiomeAreaFilterRequest(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            originX: 0,
            originZ: 0,
            width: 1,
            height: 1,
            scale: 1,
            filter: BiomeFilterSpec(excludedBiomeIDs: [14])
        ))
        XCTAssertFalse(excludeMushroom.matched)
    }

    func testBiomeCentersReturnEmptyResultsAndValidateShape() throws {
        let centers = try CubiomesCore.biomeCenters(BiomeCenterRequest(
            version: .v1_18,
            seed: 262,
            originX: -16,
            originZ: -16,
            width: 32,
            height: 32,
            biomeID: 14,
            minimumSize: 1,
            tolerance: 0,
            maximumCount: 8
        ))

        XCTAssertLessThanOrEqual(centers.count, 8)
        XCTAssertTrue(centers.allSatisfy { $0.biomeID == 14 && $0.size > 0 })

        XCTAssertThrowsError(try CubiomesCore.biomeCenters(BiomeCenterRequest(
            version: .v1_18,
            seed: 262,
            originX: 0,
            originZ: 0,
            width: 8,
            height: 8,
            biomeID: 999,
            maximumCount: 8
        ))) { error in
            XCTAssertEqual(error as? CubiomesError, .unsupportedBiome(id: 999))
        }
    }

    func testLocationAndSeedFinderExposeDeterministicBatchSemantics() throws {
        let samples = CubiomesCore.locationSamples(mode: .squareSpiral, count: 5, spacing: 16)
        XCTAssertEqual(samples, [
            BlockPosition(x: 0, z: 0),
            BlockPosition(x: 16, z: 0),
            BlockPosition(x: 16, z: 16),
            BlockPosition(x: 0, z: 16),
            BlockPosition(x: -16, z: 16),
        ])

        let seedMatches = try CubiomesCore.findSeeds(SeedSearchRequest(
            version: .v1_18,
            seeds: [1, 262],
            dimension: .overworld,
            conditions: [.biomeAt(relativeX: 0, relativeZ: 0, y: 63, allowedBiomeIDs: [14])]
        ))
        XCTAssertEqual(seedMatches, [262])

        let locationMatches = try CubiomesCore.findLocations(LocationSearchRequest(
            version: .v1_18,
            seeds: [262],
            dimension: .overworld,
            positions: [BlockPosition(x: 0, z: 0), BlockPosition(x: 4096, z: 4096)],
            conditions: [.biomeAt(relativeX: 0, relativeZ: 0, y: 63, allowedBiomeIDs: [14])],
            maximumResults: 1
        ))
        XCTAssertEqual(locationMatches, [LocationSearchResult(seed: 262, position: BlockPosition(x: 0, z: 0))])

        let cancelled = try CubiomesCore.findSeeds(SeedSearchRequest(
            version: .v1_18,
            seeds: [262],
            dimension: .overworld,
            conditions: [.biomeAt(relativeX: 0, relativeZ: 0, y: 63, allowedBiomeIDs: [14])]
        ), shouldCancel: { true })
        XCTAssertTrue(cancelled.isEmpty)
    }

    func testStructureVariantPiecesAndQuadSearchBoundaries() throws {
        let variant = try CubiomesCore.structureVariant(
            type: .village,
            version: .v1_18,
            seed: 262,
            blockX: 192,
            blockZ: 208,
            biomeID: 1
        )
        XCTAssertEqual(variant?.type, .village)

        let endPieces = try CubiomesCore.structurePieces(
            type: .endCity,
            version: .v1_18,
            seed: 262,
            chunkX: 0,
            chunkZ: 0
        )
        XCTAssertLessThanOrEqual(endPieces.count, 421)

        XCTAssertThrowsError(try CubiomesCore.structurePieces(
            type: .village,
            version: .v1_18,
            seed: 262,
            chunkX: 0,
            chunkZ: 0
        )) { error in
            XCTAssertEqual(error as? CubiomesError, .unsupportedStructurePieces(.village))
        }

        XCTAssertThrowsError(try CubiomesCore.quadStructureClusters(QuadStructureSearchRequest(
            type: .monument,
            version: .v1_18,
            seed: 262,
            regionX: 0,
            regionZ: 0,
            regionWidth: 1,
            regionHeight: 1
        ))) { error in
            XCTAssertEqual(error as? CubiomesError, .unsupportedQuadSearch(.monument, version: .v1_18))
        }
    }

    func testNetherVolumeAndEndAnalysisExposeDimensionSpecificShapes() throws {
        let volume = try CubiomesCore.netherBiomeVolume(NetherBiomeVolumeRequest(
            seed: 262,
            originX: 0,
            originY: 0,
            originZ: 0,
            width: 2,
            height: 2,
            depth: 2
        ))

        XCTAssertEqual(volume.ids.count, 8)
        XCTAssertEqual(volume.idAt(x: 0, y: 0, z: 0), 171)
        XCTAssertEqual(volume.idAt(x: 1, y: 1, z: 1), 171)

        let endChunk = CubiomesCore.endChunkAnalysis(version: .v1_18, seed: 262, chunkX: 0, chunkZ: 0)
        XCTAssertEqual(endChunk.chunkX, 0)
        XCTAssertEqual(endChunk.chunkZ, 0)
        XCTAssertFalse(endChunk.isEmpty)

        let heights = try CubiomesCore.endSurfaceHeights(EndSurfaceHeightGridRequest(
            version: .v1_18,
            seed: 262,
            originX: 0,
            originZ: 0,
            width: 2,
            height: 2
        ))
        XCTAssertEqual(heights.heights.count, 4)
        XCTAssertEqual(heights.heightAt(x: 0, z: 0), 62)
    }

    func testMediumAreaStructureAndFilterRegressionDoesNotObviouslyRegress() throws {
        let start = Date()
        let structures = try CubiomesCore.structures(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            types: [.village, .desertPyramid, .ruinedPortal],
            rect: StructureRect(originX: -4096, originZ: -4096, width: 8192, height: 8192)
        )
        let filter = try CubiomesCore.biomeAreaFilter(BiomeAreaFilterRequest(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            originX: -512,
            originZ: -512,
            width: 256,
            height: 256,
            scale: 4,
            filter: BiomeFilterSpec(matchAnyBiomeIDs: [1, 14])
        ))

        XCTAssertFalse(structures.isEmpty)
        XCTAssertEqual(structures, structures.sorted {
            ($0.blockZ, $0.blockX, String(describing: $0.type)) <
                ($1.blockZ, $1.blockX, String(describing: $1.type))
        })
        XCTAssertTrue(filter.matched)
        XCTAssertLessThan(Date().timeIntervalSince(start), 10.0)
    }

    func testLargeAreaBiomeGenerationDoesNotObviouslyRegress() throws {
        let start = Date()
        let grid = try CubiomesCore.biomes(
            version: .v1_18,
            seed: 262,
            dimension: .overworld,
            originX: -2048,
            originZ: -2048,
            width: 128,
            height: 128,
            scale: 4,
            y: 63
        )

        XCTAssertEqual(grid.ids.count, 16_384)
        XCTAssertLessThan(Date().timeIntervalSince(start), 10.0)
    }
}
