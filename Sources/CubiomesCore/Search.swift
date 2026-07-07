public extension CubiomesCore {
    static func locationSamples(
        mode: LocationSampleMode,
        count: Int,
        spacing: Int32,
        origin: BlockPosition = BlockPosition(x: 0, z: 0)
    ) -> [BlockPosition] {
        guard count > 0, spacing != 0 else {
            return []
        }
        switch mode {
        case .squareSpiral:
            var samples: [BlockPosition] = []
            samples.reserveCapacity(count)
            var rx: Int32 = 0
            var rz: Int32 = 0
            var segmentIndex = 0
            var segmentLength = 1
            var dx: Int32 = 1
            var dz: Int32 = 0
            for _ in 0..<count {
                samples.append(BlockPosition(x: origin.x + spacing * rx, z: origin.z + spacing * rz))
                rx += dx
                rz += dz
                segmentIndex += 1
                if segmentIndex == segmentLength {
                    segmentIndex = 0
                    let previousDX = dx
                    dx = -dz
                    dz = previousDX
                    if dz == 0 {
                        segmentLength += 1
                    }
                }
            }
            return samples
        case .radialGrid:
            var candidates: [(x: Int32, z: Int32, distance: Float)] = []
            let radiusSquaredMax = Float(count) / Float.pi
            let radius = Int32(radiusSquaredMax.squareRoot())
            if radius > 0 {
                for x in 1...radius {
                    for z in 0...x {
                        let distance = Float(x * x + z * z)
                        if distance <= radiusSquaredMax {
                            candidates.append((x, z, distance))
                        }
                    }
                }
            }
            candidates.sort { $0.distance < $1.distance }
            var samples = [origin]
            for candidate in candidates {
                let x = spacing * candidate.x
                let z = spacing * candidate.z
                if z == 0 || x == z {
                    samples.append(contentsOf: [
                        BlockPosition(x: origin.x + x, z: origin.z + z),
                        BlockPosition(x: origin.x - z, z: origin.z + x),
                        BlockPosition(x: origin.x - x, z: origin.z - z),
                        BlockPosition(x: origin.x + z, z: origin.z - x),
                    ])
                } else {
                    samples.append(contentsOf: [
                        BlockPosition(x: origin.x + x, z: origin.z + z),
                        BlockPosition(x: origin.x + z, z: origin.z + x),
                        BlockPosition(x: origin.x - z, z: origin.z + x),
                        BlockPosition(x: origin.x - x, z: origin.z + z),
                        BlockPosition(x: origin.x - x, z: origin.z - z),
                        BlockPosition(x: origin.x - z, z: origin.z - x),
                        BlockPosition(x: origin.x + z, z: origin.z - x),
                        BlockPosition(x: origin.x + x, z: origin.z - z),
                    ])
                }
                if samples.count >= count {
                    return Array(samples.prefix(count))
                }
            }
            return Array(samples.prefix(count))
        }
    }

    static func findLocations(
        _ request: LocationSearchRequest,
        shouldCancel: (() -> Bool)? = nil
    ) throws -> [LocationSearchResult] {
        try findLocations(request, cancellationToken: nil, progress: nil, shouldCancel: shouldCancel)
    }

    static func findLocations(
        _ request: LocationSearchRequest,
        cancellationToken: CubiomesSearchCancellationToken?,
        progress: ((CubiomesSearchProgress) -> Void)? = nil
    ) throws -> [LocationSearchResult] {
        try findLocations(request, cancellationToken: cancellationToken, progress: progress, shouldCancel: nil)
    }

    private static func findLocations(
        _ request: LocationSearchRequest,
        cancellationToken: CubiomesSearchCancellationToken?,
        progress: ((CubiomesSearchProgress) -> Void)?,
        shouldCancel: (() -> Bool)?
    ) throws -> [LocationSearchResult] {
        try CubiomesWorld.validateSearchLimit(request.maximumResults)
        guard request.maximumResults > 0 else { return [] }
        var results: [LocationSearchResult] = []
        var checkedLocations = 0
        var checkedSeeds = 0
        for seed in request.seeds {
            checkedSeeds += 1
            for position in request.positions {
                if cancellationToken?.isCancelled == true || shouldCancel?() == true {
                    return results
                }
                if try matchesAll(
                    request.conditions,
                    references: request.conditionReferences,
                    version: request.version,
                    seed: seed,
                    dimension: request.dimension,
                    at: position
                ) {
                    results.append(LocationSearchResult(seed: seed, position: position))
                }
                checkedLocations += 1
                progress?(CubiomesSearchProgress(
                    kind: .location,
                    checkedSeeds: checkedSeeds,
                    checkedLocations: checkedLocations,
                    matchedResults: results.count,
                    maximumResults: request.maximumResults,
                    currentSeed: seed,
                    currentPosition: position
                ))
                if results.count >= request.maximumResults {
                    return results
                }
            }
        }
        return results
    }

    static func findSeeds(
        _ request: SeedSearchRequest,
        shouldCancel: (() -> Bool)? = nil
    ) throws -> [Int64] {
        try findSeeds(request, cancellationToken: nil, progress: nil, shouldCancel: shouldCancel)
    }

    static func findSeeds(
        _ request: SeedSearchRequest,
        cancellationToken: CubiomesSearchCancellationToken?,
        progress: ((CubiomesSearchProgress) -> Void)? = nil
    ) throws -> [Int64] {
        try findSeeds(request, cancellationToken: cancellationToken, progress: progress, shouldCancel: nil)
    }

    private static func findSeeds(
        _ request: SeedSearchRequest,
        cancellationToken: CubiomesSearchCancellationToken?,
        progress: ((CubiomesSearchProgress) -> Void)?,
        shouldCancel: (() -> Bool)?
    ) throws -> [Int64] {
        try CubiomesWorld.validateSearchLimit(request.maximumResults)
        guard request.maximumResults > 0 else { return [] }
        var results: [Int64] = []
        var checkedSeeds = 0
        for seed in request.seeds {
            if cancellationToken?.isCancelled == true || shouldCancel?() == true {
                return results
            }
            if try matchesAll(
                request.conditions,
                references: request.conditionReferences,
                version: request.version,
                seed: seed,
                dimension: request.dimension,
                at: BlockPosition(x: 0, z: 0)
            ) {
                results.append(seed)
            }
            checkedSeeds += 1
            progress?(CubiomesSearchProgress(
                kind: .seed,
                checkedSeeds: checkedSeeds,
                checkedLocations: 0,
                matchedResults: results.count,
                maximumResults: request.maximumResults,
                currentSeed: seed,
                currentPosition: nil
            ))
            if results.count >= request.maximumResults {
                return results
            }
        }
        return results
    }

    static func findStructureCombinations(
        _ request: StructureCombinationSearchRequest,
        cancellationToken: CubiomesSearchCancellationToken? = nil,
        progress: ((CubiomesSearchProgress) -> Void)? = nil
    ) throws -> [StructureCombinationSearchResult] {
        try CubiomesWorld.validateSearchLimit(request.maximumResults)
        guard request.maximumResults > 0 else { return [] }
        var results: [StructureCombinationSearchResult] = []
        var checkedSeeds = 0
        for seed in request.seeds {
            if cancellationToken?.isCancelled == true {
                return results
            }
            if let match = try structureCombinationMatch(
                version: request.version,
                seed: seed,
                dimension: request.dimension,
                rect: request.rect,
                requirements: request.requirements
            ) {
                results.append(match)
            }
            checkedSeeds += 1
            progress?(CubiomesSearchProgress(
                kind: .seed,
                checkedSeeds: checkedSeeds,
                checkedLocations: 0,
                matchedResults: results.count,
                maximumResults: request.maximumResults,
                currentSeed: seed,
                currentPosition: nil
            ))
            if results.count >= request.maximumResults {
                return results
            }
        }
        return results
    }
}
