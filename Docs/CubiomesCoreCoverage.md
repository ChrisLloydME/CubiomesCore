# CubiomesCore Viewer Non-UI Coverage Matrix

This matrix tracks Cubiomes Viewer non-UI capabilities against the Swift Package API surface. It is based on the current `Package.swift`, `Sources/CubiomesCore`, `Tests/CubiomesCoreTests`, `cubiomes/*.h`, `cubiomes/*.c`, `cubiomes/README.md`, `src/search*`, `src/world*`, `src/tab*.cpp`, `src/scripts.cpp`, `README.md`, and `buildguide.md`.

## Scope Rules

- Public Swift APIs expose domain models and synchronous query entry points for AppKit-facing code.
- C generator, layer, noise, filter, RNG, piece-list, and callback lifetimes stay internal to the Package.
- Qt UI, AppKit UI, rendering widgets, settings, import/export workflows, Lua runtime integration, and bundled resources are not part of CubiomesCore.
- Cubiomes C algorithm behavior is not changed.

## Matrix

| Capability family | Viewer / cubiomes evidence | Swift API coverage | Status | Tests |
|---|---|---|---|---|
| Version and dimension model | `biomes.h`, `util.h`, README version support | `MinecraftVersion`, `MinecraftDimension` | 已覆盖 | `testVersionStringParsingUsesCubiomesVersionTable` |
| Single biome lookup | `generator.h:getBiomeAt`, cubiomes README example | `CubiomesWorld.biome`, `CubiomesCore.biome` | 已覆盖 | `testFixedSeedCoordinateBiomeLookup` |
| Biome grid / map data | `generator.h:genBiomes`, `world.cpp` quad map generation, `tabbiomes.cpp` statistics | `BiomeGridRequest/Result`, `MapTileRequest/Result` | 本轮补齐 | `testBiomeGridUsesZMajorRowOrder`, `testMapTileCombinesBiomeHeightAndStructureOverlayData` |
| Approximate height map | `generator.h:mapApproxHeight`, `search.cpp:F_HEIGHT`, `world.cpp` height shading | `ApproximateHeightGridRequest/Result`, map tile height inclusion | 本轮补齐 | `testApproximateHeightGridProducesStableShape`, `testMapTileCombinesBiomeHeightAndStructureOverlayData` |
| Biome metadata and classification | `biomes.h`, `biomenoise.h:getBiomeDepthAndScale` | `BiomeInfo`, `BiomeClassification`, `BiomeTerrainInfo`, climate ranges | 已覆盖 | `testBiomeInfoWrapsCubiomesMetadataHelpers`, `testBiomeClassificationAndTerrainInfoWrapPureCubiomesHelpers` |
| Biome area statistics | `tabbiomes.cpp:runStatistics` | `BiomeAreaStatisticsRequest`, `biomeAreaStatistics` | 本轮补齐 | `testBiomeStatisticsAndAreaFilterUseStableGridSemantics` |
| Biome include/exclude/match-any filters | `finders.h:BiomeFilter`, `checkForBiomes`, `search.cpp:F_BIOME*` | `BiomeFilterSpec`, `BiomeAreaFilterRequest/Result` | 本轮补齐 | `testBiomeStatisticsAndAreaFilterUseStableGridSemantics`, `testMediumAreaStructureAndFilterRegressionDoesNotObviouslyRegress` |
| Biome center locate | `finders.h:getBiomeCenters`, `tabbiomes.cpp:runLocate`, `search.cpp:F_BIOME_CENTER` | `BiomeCenterRequest`, `BiomeCenter`, with Swift guard for unsupported biome ids | 本轮补齐 | `testBiomeCentersReturnEmptyResultsAndValidateShape` |
| Structure config and attempt positions | `finders.h:getStructureConfig/getStructurePos`, cubiomes README structure example | `StructureType`, `StructureConfigInfo`, `StructureLocation`, `structureAttempt` | 已覆盖 | `testStructureConfigExposesNewConfiguredStructureTypes`, `testStructureAttemptAndViabilityHelpersExposeSingleRegionChecks` |
| Structure overlay for map/frontends | `world.h:getStructs`, `world.cpp`, `tabstructures.cpp:runStructs` | `structures(types:rect:)`, map tile `structureTypes` | 本轮补齐 | `testStructureOverlayAPIProducesStableFieldsInsideRect`, `testMapTileCombinesBiomeHeightAndStructureOverlayData` |
| Structure viability | `finders.h:isViableStructurePos/isViableFeatureBiome/isViableStructureTerrain`, `search.cpp` structure filters | `isViableFeatureBiome`, `isViableStructurePosition`, `isViableStructureTerrain` | 已覆盖 | `testStructureAttemptAndViabilityHelpersExposeSingleRegionChecks` |
| Strongholds, spawn, slime chunks | `finders.h:initFirstStronghold/nextStronghold/getSpawn/isSlimeChunk`, `tabstructures.cpp` | `estimatedSpawn`, `spawn`, `strongholds`, `isSlimeChunk` | 已覆盖 | `testDirectStrongholdAndSlimeAPIsReturnStableShapes` |
| Structure variants | `finders.h:StructureVariant/getVariant`, `search.cpp:isVariantOk`, `world.h:VarPos` | `StructureVariantSummary`, `structureVariant` | 本轮补齐 | `testStructureVariantPiecesAndQuadSearchBoundaries` |
| Structure piece summaries | `finders.h:Piece/getEndCityPieces/getFortressPieces`, `search.cpp` end ship / dense fortress checks | `StructurePieceSummary`, `structurePieces` for End City and Fortress | 本轮补齐 | `testStructureVariantPiecesAndQuadSearchBoundaries` |
| Quad hut / quad structure scan | `quadbase.h:scanForQuads/getOptimalAfk/isQuadBase`, `search.cpp:findQuadStructs` | `QuadStructureSearchRequest`, `QuadStructureCluster` for bounded quad-hut scans; limited to stable packaged data | 本轮补齐 | `testStructureVariantPiecesAndQuadSearchBoundaries` |
| Quad monument search | `src/seedtables.h`, `search.cpp:F_QM_90/F_QM_95`, viewer-specific seed tables | Not public yet | 暂缓 | Needs stable packaging of seed tables or regenerated constants |
| Full 48-bit seed-base search | `quadbase.h:searchAll48`, callback, files, thread stop flag | Not public | 暂缓 | Needs explicit threading, progress, cancellation, and persistence design |
| Location finder sampling and batch checks | `tablocations.cpp`, `search.cpp:testTreeAt` | `LocationSampleMode`, `locationSamples`, `LocationSearchRequest`, `findLocations`; simplified stable condition model | 本轮补齐 | `testLocationAndSeedFinderExposeDeterministicBatchSemantics` |
| Seed finder batch checks | `searchthread.cpp`, `search.cpp:ConditionTree` | `SeedSearchRequest`, `findSeeds`; simplified stable condition model | 本轮补齐 | `testLocationAndSeedFinderExposeDeterministicBatchSemantics` |
| Complex ConditionTree helper gates | `search.h:FilterInfo`, `search.cpp:_testTreeAt`, OR/NOT/scale/spiral branches | Partially represented by `CubiomesQueryCondition`; full tree not public | 暂缓 | Requires stable condition schema and branch semantics |
| Climate noise range checks | `finders.h:getParaRange/getBiomeParaLimits`, `search.cpp:F_CLIMATE_*` | Existing climate limit/extreme wrappers only | 暂缓 | Callback-driven range search needs a public progress/cancel model |
| Largest rectangle / possible biomes by climate limits | `finders.h:getPossibleBiomesForLimits/getLargestRec` | Not public | 暂缓 | Needs Swift matrix model and validation around 1.18+ only semantics |
| Nether 2D and 3D biome analysis | `biomenoise.h:mapNether2D/mapNether3D`, `search.cpp:F_BIOME_NETHER*` | `NetherBiomeGridRequest/Result`, `NetherBiomeVolumeRequest/Result` | 本轮补齐 | `testSpecializedNetherAndEndBiomeMapsProduceStableValues`, `testNetherVolumeAndEndAnalysisExposeDimensionSpecificShapes` |
| End biome, surface, island, gateway analysis | `biomenoise.h:mapEnd*`, `finders.h:getEndIslands/isEndChunkEmpty/getFixedEndGateways/getLinkedGatewayPos` | `EndBiomeGridRequest/Result`, `EndChunkAnalysis`, `EndSurfaceHeightGridResult`, gateways/islands | 本轮补齐 | `testEndSpecificHelpersReturnStableGatewayAndIslandData`, `testNetherVolumeAndEndAnalysisExposeDimensionSpecificShapes` |
| Monte Carlo biome/noise sampling | `finders.h:monteCarloBiomes`, `search.cpp:F_BIOME_SAMPLE/F_NOISE_SAMPLE` | Not public | 暂缓 | C callback and statistical semantics need a Swift-native result contract |
| Lua filters | `scripts.cpp`, `scripts.h`, `search.cpp:F_LUA`, bundled `lua/` | Not public | 不属于 Package 范围 | Scripting runtime, editor integration, and sandboxing are app-layer concerns |
| Qt map rendering, icons, colors, screenshots | `world.cpp`, `mapview.cpp`, `rc/`, `util.h:biomesToImage/savePPM` | Not public | 不属于 Package 范围 | Rendering and resources belong to frontend/app targets |
| Settings, CSV export, file seed import | `tab*.cpp`, `config.cpp`, `util.h:loadSavedSeeds` | Not public | 不属于 Package 范围 | File IO and app preferences are frontend/workflow concerns |

## Deferred Rationale

- `searchAll48`, `monteCarloBiomes`, `getParaRange`, and full `ConditionTree` depend on callback, stop flag, threading, or multi-pass maybe-state semantics. They should not be exposed until CubiomesCore has a deliberate Swift cancellation/progress model.
- Quad-monument support depends on viewer seed tables outside the current SwiftPM C target. It can be added once those constants are packaged as internal data with regression tests.
- Lua, Qt UI, rendering, settings, import/export, and screenshots are intentionally excluded to keep CubiomesCore a non-UI domain package.
