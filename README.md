# CubiomesCore

CubiomesCore is a Swift Package that wraps the bundled
[cubiomes](https://github.com/Cubitect/cubiomes) C library behind Swift domain
APIs. It is meant for macOS frontends that need Minecraft Java Edition seed,
biome, structure, and location-finder logic without pulling in the Cubiomes
Viewer Qt application.

The package keeps cubiomes generator, noise, filter, callback, RNG, cache, and
linked-list lifetimes inside Swift calls. Public APIs use Swift request and
result models instead of exposing the C functions one by one.

## What It Covers

- Minecraft version and dimension models.
- Single biome lookup, biome grids, map tile data, and approximate height grids.
- Overworld, Nether, and End biome helpers.
- Structure config, attempts, viability checks, overlays, pieces, variants,
  strongholds, spawn, and slime chunks.
- Seed and location finder queries with condition trees, references, logic
  gates, coordinate scaling, progress, cancellation, and maximum-result limits.
- Biome area statistics, include/exclude filters, biome centers, climate ranges,
  possible-biome checks, climate noise range checks, Monte Carlo samples, and
  largest-rectangle analysis.
- Bounded quad-hut and quad-monument searches, including internal 90% and 95%
  monument seed-table data.

The package does not implement AppKit, Qt, rendering, screenshots, resource
bundles, settings, Lua scripting, saved seed files, CSV export, or other
application workflows.

## Requirements

- Swift 5.9 or newer.
- macOS or Linux.
- No external package dependencies.

## Add It to a Package

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/<owner>/CubiomesCore.git", branch: "main"),
],
targets: [
    .target(
        name: "YourAppCore",
        dependencies: ["CubiomesCore"]
    ),
]
```

For local development, point SwiftPM at this checkout instead:

```swift
.package(path: "../CubiomesCore")
```

## Quick Examples

Lookup the biome at a fixed coordinate:

```swift
import CubiomesCore

let biome = try CubiomesCore.biome(
    version: .v1_18,
    seed: 262,
    dimension: .overworld,
    x: 0,
    y: 63,
    z: 0
)

print(biome.id, biome.name)
```

Generate a biome grid in z-major row order:

```swift
let grid = try CubiomesCore.biomes(
    version: .v1_18,
    seed: 262,
    dimension: .overworld,
    originX: -64,
    originZ: -64,
    width: 32,
    height: 32,
    scale: 4,
    y: 63
)

let centerID = grid.idAt(x: 16, z: 16)
```

Find seeds with a high-level query condition:

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

Run a location finder with cancellation and progress:

```swift
let token = CubiomesSearchCancellationToken()
let positions = CubiomesCore.locationSamples(mode: .squareSpiral, count: 512, spacing: 64)

let locations = try CubiomesCore.findLocations(LocationSearchRequest(
    version: .v1_18,
    seeds: [262],
    dimension: .overworld,
    positions: positions,
    conditions: [
        .approximateHeight(relativeX: 0, relativeZ: 0, allowed: 60...90),
    ],
    maximumResults: 16
), cancellationToken: token) { progress in
    if progress.checkedLocations > 200 {
        token.cancel()
    }
}
```

## Coordinate Rules

- Biome grid IDs are returned in z-major row order: `ids[z * width + x]`.
- `originX` and `originZ` use the coordinate space implied by `scale`.
- Supported biome-grid scales are `1`, `4`, `16`, `64`, and `256`.
- Finder positions are block positions. Relative condition coordinates are
  added to the current seed or location position before evaluation.
- `maximumResults == 0` returns an empty result. Negative limits throw
  `CubiomesError.invalidSearchLimit`.
- Cancellation returns partial results without throwing.

## Documentation

- [API documentation](Docs/API.md)
- [Architecture notes](Docs/CubiomesCoreArchitecture.md)
- [Viewer non-UI coverage matrix](Docs/CubiomesCoreCoverage.md)
- [Original cubiomes README](cubiomes/README.md)

## Development

```sh
swift build
swift test
git diff --check
```

The test suite uses fixed Minecraft versions, seeds, coordinates, dimensions,
structures, condition trees, cancellation tokens, and result ordering checks.

## License

This repository keeps the existing GPLv3 license from the Cubiomes Viewer
source tree. The bundled cubiomes C sources retain their upstream license terms.

This is not an official Minecraft product. It is not approved by or associated
with Mojang or Microsoft.
