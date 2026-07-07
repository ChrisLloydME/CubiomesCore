# CubiomesCore Architecture

This package wraps bundled cubiomes C algorithms behind Swift domain APIs for AppKit-facing frontends. It intentionally does not expose cubiomes C entry points one by one.

## Source Boundaries

- `CoreTypes.swift`: public value models, request/result types, query conditions, search progress, cancellation token, and errors.
- `BiomesAndClimate.swift`: biome metadata, biome grid facade helpers, approximate height facade helpers, biome area statistics/filter/center analysis, climate limit/possible-biome APIs, Monte Carlo sampling facade, climate range facade, and largest-rectangle analysis.
- `CubiomesWorld.swift`: seed/version/dimension-scoped world operations that own short-lived `Generator`, `SurfaceNoise`, cache, and structure scan lifetimes.
- `Dimensions.swift`: Nether and End helpers, including dimension-specific biome grids, End surface/gateway/island analysis, and dimension-specific C noise lifetimes.
- `Search.swift`: deterministic synchronous seed/location finder loops, location sample generation, progress/cancellation handling, maximum-result semantics, and structure-combination search orchestration.
- `CubiomesCore.swift`: static facade for callers that prefer single-call APIs over retaining a `CubiomesWorld`.
- `InternalCubiomesBridge.swift`: internal helpers for C enum mapping, biome filter construction, piece conversion, condition evaluation, coordinate scaling, and C pointer result conversion.

## Public API Layers

- Model layer: `MinecraftVersion`, `MinecraftDimension`, `BlockPosition`, `StructureType`, biome/structure/climate result models.
- Map and analysis layer: biome grids, map tiles, approximate heights, Nether/End grids, biome statistics, biome filters, centers, structure overlays, variants, pieces, strongholds, spawn, slime chunks, climate possible-biome analysis, climate noise ranges, Monte Carlo biome/noise sampling, largest-rectangle analysis, and End helpers.
- Finder layer: `CubiomesQueryCondition`, `SeedSearchRequest`, `LocationSearchRequest`, `CubiomesSearchProgress`, and `CubiomesSearchCancellationToken`.
- Error layer: `CubiomesError` reports unsupported scales, structures, biome ids, grid sizes, volume sizes, search limits, coordinate scale mistakes, and C generation failures.

Existing public signatures and result ordering are preserved. New APIs are high-level Swift models and synchronous query entry points.

## Internal C Wrapper Lifecycle

`Generator`, noise structs, `BiomeFilter`, `StructureConfig`, piece arrays, quad buffers, and biome caches are created inside a single Swift call and never returned. Allocated biome caches are freed with `defer`. C callbacks, linked lists, seed-table persistence, and Lua state are not exposed from the package. Quad-hut and quad-monument 90%/95% seed tables are internal Swift data used only by bounded query APIs.

Some C finder helpers keep broad internal state or rely on table/pointer conventions that are not safe as public Swift boundaries. `BiomeAreaFilterRequest` is evaluated through an exact Swift biome grid check instead of exposing `checkForBiomes` lifetimes. `BiomeCenterRequest` uses deterministic Swift flood-fill over a generated biome grid instead of returning `getBiomeCenters` buffers. Public climate limit lookup reads an internal Swift copy of cubiomes' 1.18/1.19/1.20/1.21 climate tables and does not call `getBiomeParaLimits` directly.
`largestRectangle` uses a Swift matrix algorithm instead of directly wrapping `getLargestRec`, keeping that C helper out of the public wrapper lifecycle.

## Search Runtime Model

Seed and location finder calls are synchronous and deterministic:

- seeds are checked in request order;
- location positions are checked in request order inside each seed;
- results preserve discovery order;
- `maximumResults == 0` returns an empty array;
- negative maximum results throw `CubiomesError.invalidSearchLimit`;
- `CubiomesSearchCancellationToken` and legacy `shouldCancel` closures return partial results without throwing;
- `CubiomesSearchProgress` is emitted after each checked seed or location.

`CubiomesQueryCondition` supports AND via request arrays and `.all`, OR via `.any`, negation via `.not`, named references via request-local `conditionReferences`, relative child evaluation via `.at`, coordinate scaling via `.scaledCoordinates`, and leaf checks for biome-at, climate possible-biome, climate noise range, biome-area, Monte Carlo biome/noise samples, structures, structure combinations, and approximate height.

Structure combination search is synchronous and uses the same discovery ordering as seed search: seeds are evaluated in request order, locations inside each result are sorted by block Z, block X, and structure type.

## Deferred

- Full viewer `ConditionTree` hex serialization and every C++ branch detail are deferred. Swift named references are supported through request-local dictionaries with missing-reference and recursive-reference errors.
- `searchAll48` and full 48-bit base generation are deferred because they need durable threading, progress, cancellation, and persistence contracts.
- Quad-monument 90% and 95% bounded scans are implemented with internal seed-table data. Exact viewer quality scores remain internal because the public result model reports stable cluster geometry rather than seed-table quality classes.
- Full viewer climate min/max condition variants that expose locate-min/locate-max mode flags are deferred; the package exposes synchronous climate range results and a range condition leaf instead.
- Direct use of `getPossibleBiomesForLimits` remains internal/deferred; the public possible-biome API derives stable results through Swift range intersection over the internal climate limit table.
- Lua filters, Qt/AppKit UI, map rendering, screenshots, settings, resource bundles, and import/export workflows are outside package scope.
