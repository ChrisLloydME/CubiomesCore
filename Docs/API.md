# CubiomesCore API

This document describes the Swift API surface intended for app code. It does
not list the bundled cubiomes C functions. Those remain implementation details
inside the package.

## Entry Points

Use `CubiomesCore` for one-shot static calls:

```swift
let spawn = CubiomesCore.spawn(version: .v1_18, seed: 262)
let structures = try CubiomesCore.structures(
    types: [.village, .monument],
    version: .v1_18,
    seed: 262,
    dimension: .overworld,
    rect: StructureRect(originX: -4096, originZ: -4096, width: 8192, height: 8192)
)
```

Use `CubiomesWorld` when several calls share the same version, seed, and
dimension:

```swift
let world = CubiomesWorld(version: .v1_18, seed: 262, dimension: .overworld)
let biome = try world.biome(x: 0, y: 63, z: 0)
let strongholds = world.strongholds(limit: 128)
```

Both entry points preserve the same coordinate and ordering rules.

## Versions and Dimensions

`MinecraftVersion` wraps cubiomes version IDs and can be built from a version
string:

```swift
let version = MinecraftVersion("1.18") ?? .v1_18
print(version.name)
```

Common constants include `.v1_18`, `.v1_19`, `.v1_20`, `.v1_21`, and `.newest`.

`MinecraftDimension` has three values:

- `.overworld`
- `.nether`
- `.end`

## Biomes and Map Data

### Single Biome Lookup

```swift
let result = try CubiomesCore.biome(
    version: .v1_18,
    seed: 262,
    dimension: .overworld,
    x: 0,
    y: 63,
    z: 0
)
```

The result contains the cubiomes biome ID and name.

### Biome Grids

```swift
let grid = try CubiomesCore.biomes(BiomeGridRequest(
    version: .v1_18,
    seed: 262,
    dimension: .overworld,
    originX: -64,
    originZ: -64,
    width: 32,
    height: 32,
    scale: 4,
    y: 63
))
```

Grid IDs are z-major: `ids[z * width + x]`. Use `grid.idAt(x:z:)` for bounds
checked access.

Supported horizontal scales are `1`, `4`, `16`, `64`, and `256`.

### Map Tiles and Approximate Heights

`MapTileRequest` combines biome IDs, optional approximate heights, and optional
structure overlays:

```swift
let tile = try CubiomesCore.mapTile(MapTileRequest(
    version: .v1_18,
    seed: 262,
    dimension: .overworld,
    originX: -512,
    originZ: -512,
    width: 128,
    height: 128,
    scale: 4,
    includesApproximateHeights: true,
    structureTypes: [.village, .ruinedPortal]
))
```

Use `ApproximateHeightGridRequest` when the frontend only needs height data.

## Dimension-Specific Helpers

Nether helpers:

- `netherBiomes(_:)`
- `netherBiomeVolume(_:)`

End helpers:

- `endBiomes(_:)`
- `endSurfaceHeights(_:)`
- `endChunkAnalysis(version:seed:chunkX:chunkZ:)`
- `endIslands(version:seed:chunkX:chunkZ:)`
- `fixedEndGateways(version:seed:)`
- `linkedEndGateway(version:seed:source:)`
- `endSurfaceHeight(version:seed:x:z:)`

Use these APIs when a dimension has cubiomes-specific generation rules that do
not fit the generic Overworld grid path.

## Structures

### Structure Config and Attempts

```swift
let config = try CubiomesCore.structureConfig(type: .village, version: .v1_18)
let attempt = try CubiomesCore.structureAttempt(
    type: .village,
    version: .v1_18,
    seed: 262,
    regionX: 0,
    regionZ: 0,
    requiresViableBiome: true
)
```

`StructureLocation` reports block coordinates, region coordinates, dimension,
type, and biome viability.

### Structure Overlays

```swift
let locations = try CubiomesCore.structures(
    types: [.village, .ruinedPortal],
    version: .v1_18,
    seed: 262,
    dimension: .overworld,
    rect: StructureRect(originX: -4096, originZ: -4096, width: 8192, height: 8192)
)
```

Results are sorted by block Z, block X, and structure type where the API
combines multiple structure families.

### Viability, Pieces, Variants, and Direct Seeds

Useful direct helpers include:

- `isViableFeatureBiome(type:version:seed:blockX:blockZ:)`
- `isViableStructurePosition(type:version:seed:blockX:blockZ:)`
- `isViableStructureTerrain(type:version:seed:blockX:blockZ:)`
- `structureVariant(type:version:seed:blockX:blockZ:)`
- `structurePieces(type:version:seed:blockX:blockZ:)`
- `estimatedSpawn(version:seed:)`
- `spawn(version:seed:)`
- `strongholds(version:seed:limit:)`
- `isSlimeChunk(seed:chunkX:chunkZ:)`
- `movedStructureSeed(baseSeed:regionX:regionZ:)`
- `shadowSeed(seed:)`
- `chunkGenerationSeed(seed:chunkX:chunkZ:)`

### Quad Structures

```swift
let clusters = try CubiomesCore.quadStructureClusters(QuadStructureSearchRequest(
    type: .swampHut,
    version: .v1_18,
    seed: 262,
    regionX: -16,
    regionZ: -16,
    regionWidth: 32,
    regionHeight: 32,
    maximumCount: 4,
    requiresViableBiomes: true
))
```

`.monument` searches use internal 90% or 95% seed-table data through
`QuadMonumentCoverage`.

## Seed and Location Finder

### Sampling Locations

```swift
let positions = CubiomesCore.locationSamples(
    mode: .squareSpiral,
    count: 512,
    spacing: 64
)
```

`squareSpiral` returns deterministic positions starting at `(0, 0)`.
`radialGrid` returns a deterministic grid ordered by distance from origin.

### Seed Finder

```swift
let matches = try CubiomesCore.findSeeds(SeedSearchRequest(
    version: .v1_18,
    seeds: [1, 262],
    dimension: .overworld,
    conditions: [
        .biomeAt(relativeX: 0, relativeZ: 0, y: 63, allowedBiomeIDs: [14]),
    ],
    maximumResults: 1
))
```

Seeds are checked in request order. Results preserve discovery order.

### Location Finder

```swift
let matches = try CubiomesCore.findLocations(LocationSearchRequest(
    version: .v1_18,
    seeds: [262],
    dimension: .overworld,
    positions: positions,
    conditions: [
        .approximateHeight(relativeX: 0, relativeZ: 0, allowed: 60...90),
    ],
    maximumResults: 16
))
```

The finder checks positions in request order for each seed.

### Progress and Cancellation

```swift
let token = CubiomesSearchCancellationToken()

let matches = try CubiomesCore.findSeeds(SeedSearchRequest(
    version: .v1_18,
    seeds: (0..<10_000).map(Int64.init),
    dimension: .overworld,
    conditions: [
        .structures(
            relativeRect: StructureRect(originX: -512, originZ: -512, width: 1024, height: 1024),
            types: [.village],
            minimumCount: 1
        ),
    ]
), cancellationToken: token) { progress in
    if progress.checkedSeeds > 1_000 {
        token.cancel()
    }
}
```

Cancellation returns partial results. It does not throw.

`maximumResults == 0` returns an empty array. A negative maximum throws
`CubiomesError.invalidSearchLimit`.

## Query Conditions

`CubiomesQueryCondition` supports logic and reusable branches:

- `.all([condition])`
- `.any([condition])`
- `.not(condition)`
- `.reference("name")`
- `.at(relativeX:relativeZ:condition:)`
- `.scaledCoordinates(numerator:denominator:condition:)`

Requests also accept `conditionReferences`:

```swift
let mushroomOrigin = CubiomesQueryCondition.biomeAt(
    relativeX: 0,
    relativeZ: 0,
    y: 63,
    allowedBiomeIDs: [14]
)

let request = SeedSearchRequest(
    version: .v1_18,
    seeds: [1, 262],
    dimension: .overworld,
    conditions: [.reference("mushroom-origin")],
    conditionReferences: ["mushroom-origin": mushroomOrigin]
)
```

Missing references throw `CubiomesError.missingConditionReference`. Recursive
references throw `CubiomesError.recursiveConditionReference`.

Leaf conditions include:

- `.biomeAt`
- `.biomeIsPossibleForClimate`
- `.biomeArea`
- `.monteCarloBiomeSample`
- `.monteCarloClimateNoiseSample`
- `.climateNoiseRange`
- `.structures`
- `.structureCombination`
- `.approximateHeight`

## Biome and Climate Analysis

Biome metadata:

- `biomeInfo(version:id:)`
- `biomeClassification(id:)`
- `biomeTerrainInfo(id:)`
- `areSimilarBiomes(version:_:)`

Area analysis:

- `biomeAreaStatistics(_:)`
- `biomeAreaFilter(_:)`
- `biomeCenters(_:)`

Climate and matrix analysis:

- `climateParameterExtremes(version:)`
- `climateParameterLimits(version:biomeID:)`
- `possibleBiomesForClimate(_:)`
- `climateNoiseRange(_:)`
- `monteCarloBiomeSample(_:)`
- `monteCarloClimateNoiseSample(_:)`
- `largestRectangle(_:)`

Climate limit lookup uses an internal Swift copy of the cubiomes 1.18 through
1.21 climate tables. The public API does not expose `getBiomeParaLimits` or
`getPossibleBiomesForLimits`.

## Structure Combination Search

Use `findStructureCombinations(_:)` when a seed must contain several structure
families inside one rectangle:

```swift
let result = try CubiomesCore.findStructureCombinations(StructureCombinationSearchRequest(
    version: .v1_18,
    seeds: [1, 262],
    dimension: .overworld,
    rect: StructureRect(originX: -4096, originZ: -4096, width: 8192, height: 8192),
    requirements: [
        StructureCombinationRequirement(type: .village, minimumCount: 1),
        StructureCombinationRequirement(type: .ruinedPortal, minimumCount: 1),
    ],
    maximumResults: 1
))
```

Each result includes the seed, the searched rectangle, matching locations, and
counts by structure type.

## Errors

Most throwing APIs report `CubiomesError`. Important cases include:

- `unsupportedBiome`
- `unsupportedBiomeScale`
- `unsupportedStructure`
- `unsupportedStructureConfig`
- `invalidBiomeGridSize`
- `invalidVolumeSize`
- `invalidSearchLimit`
- `invalidCoordinateScale`
- `invalidGridCellCount`
- `invalidMonteCarloParameters`
- `unsupportedClimateNoise`
- `unsupportedClimateNoiseParameter`
- `missingConditionReference`
- `recursiveConditionReference`
- `unsupportedQuadSearch`

C generation and allocation failures are reported as explicit error cases such
as `biomeGridAllocationFailed`, `biomeGridGenerationFailed`, and
`climateNoiseRangeFailed`.

## Internal Boundaries

The package keeps these details internal:

- cubiomes `Generator`, `SurfaceNoise`, layer, and cache lifetimes;
- C biome filter and structure config storage;
- C piece arrays and quad buffers;
- C callbacks and stop flags;
- internal climate and quad-monument seed tables.

App code should depend on Swift request and result models. If an API needs C
pointer ownership knowledge to call safely, it belongs inside CubiomesCore.
