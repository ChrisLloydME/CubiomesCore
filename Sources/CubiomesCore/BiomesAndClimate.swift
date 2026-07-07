import CCubiomes

public extension CubiomesCore {
    static func biomeInfo(version: MinecraftVersion, id: Int32) -> BiomeInfo {
        primeClimateParameterLimitsCache()
        let mutatedID = getMutated(version.rawValue, id)
        return BiomeInfo(
            id: id,
            name: String(cString: biome2str(version.rawValue, id)),
            exists: biomeExists(version.rawValue, id) != 0,
            dimension: MinecraftDimension(rawValue: getDimension(id)) ?? .overworld,
            isOverworld: isOverworld(version.rawValue, id) != 0,
            mutatedID: mutatedID >= 0 ? mutatedID : nil,
            category: getCategory(version.rawValue, id)
        )
    }

    static func biomeClassification(id: Int32) -> BiomeClassification {
        BiomeClassification(
            id: id,
            isMesa: CCubiomes.isMesa(id) != 0,
            isShallowOcean: CCubiomes.isShallowOcean(id) != 0,
            isDeepOcean: CCubiomes.isDeepOcean(id) != 0,
            isOceanic: CCubiomes.isOceanic(id) != 0,
            isSnowy: CCubiomes.isSnowy(id) != 0
        )
    }

    static func biomeTerrainInfo(id: Int32) throws -> BiomeTerrainInfo {
        primeClimateParameterLimitsCache()
        var depth = Double(0)
        var scale = Double(0)
        var grass = Int32(0)
        guard getBiomeDepthAndScale(id, &depth, &scale, &grass) != 0 else {
            throw CubiomesError.unsupportedBiome(id: id)
        }
        return BiomeTerrainInfo(id: id, depth: depth, scale: scale, grass: grass)
    }

    static func areSimilarBiomes(version: MinecraftVersion, _ firstID: Int32, _ secondID: Int32) -> Bool {
        areSimilar(version.rawValue, firstID, secondID) != 0
    }

    static func biomes(
        version: MinecraftVersion,
        seed: Int64,
        dimension: MinecraftDimension,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        scale: Int32 = 4,
        y: Int32 = 63
    ) throws -> BiomeGridResult {
        let world = CubiomesWorld(version: version, seed: seed, dimension: dimension)
        return try world.biomes(
            originX: originX,
            originZ: originZ,
            width: width,
            height: height,
            scale: scale,
            y: y
        )
    }

    static func biomes(_ request: BiomeGridRequest) throws -> BiomeGridResult {
        let world = CubiomesWorld(
            version: request.version,
            seed: request.seed,
            dimension: request.dimension
        )
        return try world.biomes(request)
    }

    static func approximateHeights(
        version: MinecraftVersion,
        seed: Int64,
        dimension: MinecraftDimension,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32
    ) throws -> ApproximateHeightGridResult {
        let world = CubiomesWorld(version: version, seed: seed, dimension: dimension)
        return try world.approximateHeights(originX: originX, originZ: originZ, width: width, height: height)
    }

    static func approximateHeights(_ request: ApproximateHeightGridRequest) throws -> ApproximateHeightGridResult {
        let world = CubiomesWorld(
            version: request.version,
            seed: request.seed,
            dimension: request.dimension
        )
        return try world.approximateHeights(request)
    }

    static func climateParameterExtremes(version: MinecraftVersion) -> ClimateParameterRanges? {
        climateRanges(from: getBiomeParaExtremes(version.rawValue))
    }

    static func climateParameterLimits(version: MinecraftVersion, biomeID: Int32) -> ClimateParameterRanges? {
        cachedClimateParameterLimits(version: version, biomeID: biomeID)
    }

    static func possibleBiomesForClimate(_ request: ClimateBiomePossibilityRequest) -> ClimateBiomePossibilityResult {
        let biomeIDs = (0...186).compactMap { id -> Int32? in
            let biomeID = Int32(id)
            guard let limits = climateParameterLimits(version: request.version, biomeID: biomeID),
                  request.ranges.intersects(limits) else {
                return nil
            }
            return biomeID
        }
        return ClimateBiomePossibilityResult(request: request, biomeIDs: biomeIDs)
    }

    static func largestRectangle(_ request: LargestRectangleAnalysisRequest) throws -> LargestRectangleAnalysisResult {
        try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
        let expected = Int(Int64(request.width) * Int64(request.height))
        guard request.ids.count == expected else {
            throw CubiomesError.invalidGridCellCount(expected: expected, actual: request.ids.count)
        }
        let rectangle = largestMatchingRectangle(
            ids: request.ids,
            width: Int(request.width),
            height: Int(request.height),
            matchingID: request.matchingID
        )
        return LargestRectangleAnalysisResult(
            request: request,
            area: rectangle.area,
            min: rectangle.min,
            max: rectangle.max
        )
    }

    static func monteCarloBiomeSample(_ request: MonteCarloBiomeSampleRequest) throws -> MonteCarloBiomeSampleResult {
        try runMonteCarloBiomeSample(request)
    }

    static func monteCarloClimateNoiseSample(
        _ request: MonteCarloClimateNoiseSampleRequest
    ) throws -> MonteCarloClimateNoiseSampleResult {
        try runMonteCarloClimateNoiseSample(request)
    }

    static func climateNoiseRange(_ request: ClimateNoiseRangeRequest) throws -> ClimateNoiseRangeResult {
        try runClimateNoiseRange(request)
    }

    static func biomeAreaStatistics(
        _ request: BiomeAreaStatisticsRequest,
        shouldCancel: (() -> Bool)? = nil
    ) throws -> [BiomeAreaStatistics] {
        try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
        var results: [BiomeAreaStatistics] = []
        let totalCells = Int(Int64(request.width) * Int64(request.height))
        let sampleLimit = request.sampleLimit.map { max(0, min($0, totalCells)) } ?? totalCells

        for seed in request.seeds {
            for dimension in request.dimensions {
                if shouldCancel?() == true {
                    return results
                }
                var counts: [Int32: Int] = [:]
                if sampleLimit == totalCells {
                    let grid = try biomes(
                        version: request.version,
                        seed: seed,
                        dimension: dimension,
                        originX: request.originX,
                        originZ: request.originZ,
                        width: request.width,
                        height: request.height,
                        scale: request.scale,
                        y: request.y
                    )
                    for id in grid.ids {
                        counts[id, default: 0] += 1
                    }
                } else {
                    let world = CubiomesWorld(version: request.version, seed: seed, dimension: dimension)
                    for index in 0..<sampleLimit {
                        if shouldCancel?() == true {
                            return results
                        }
                        let x = request.originX + Int32(index % Int(request.width))
                        let z = request.originZ + Int32(index / Int(request.width))
                        let biome = try world.biome(x: x * request.scale, y: request.y, z: z * request.scale)
                        counts[biome.id, default: 0] += 1
                    }
                }
                results.append(BiomeAreaStatistics(
                    seed: seed,
                    dimension: dimension,
                    countsByBiomeID: counts,
                    distinctBiomeCount: counts.count,
                    sampledCellCount: sampleLimit
                ))
            }
        }
        return results
    }

    static func biomeAreaFilter(_ request: BiomeAreaFilterRequest) throws -> BiomeAreaFilterResult {
        try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
        guard [1, 4, 16, 64, 256].contains(request.scale) else {
            throw CubiomesError.unsupportedBiomeFilterScale(scale: request.scale)
        }
        let grid = try biomes(
            version: request.version,
            seed: request.seed,
            dimension: request.dimension,
            originX: request.originX,
            originZ: request.originZ,
            width: request.width,
            height: request.height,
            scale: request.scale,
            y: request.y
        )
        let biomeIDs = Set(grid.ids)
        let matched = request.filter.requiredBiomeIDs.allSatisfy { biomeIDs.contains($0) } &&
            request.filter.excludedBiomeIDs.allSatisfy { !biomeIDs.contains($0) } &&
            (request.filter.matchAnyBiomeIDs.isEmpty || request.filter.matchAnyBiomeIDs.contains { biomeIDs.contains($0) })
        return BiomeAreaFilterResult(request: request, matched: matched, completedFullGeneration: true)
    }

    static func biomeCenters(_ request: BiomeCenterRequest) throws -> [BiomeCenter] {
        try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
        guard biomeExists(request.version.rawValue, request.biomeID) != 0 else {
            throw CubiomesError.unsupportedBiome(id: request.biomeID)
        }
        if request.version.rawValue >= MinecraftVersion.v1_18.rawValue {
            guard climateParameterLimits(version: request.version, biomeID: request.biomeID) != nil else {
                throw CubiomesError.unsupportedBiome(id: request.biomeID)
            }
        }
        guard request.maximumCount > 0 else {
            return []
        }
        let grid = try biomes(
            version: request.version,
            seed: request.seed,
            dimension: .overworld,
            originX: request.originX,
            originZ: request.originZ,
            width: request.width,
            height: request.height,
            scale: 4,
            y: request.y
        )
        return biomeCentersFromGrid(grid, biomeID: request.biomeID, minimumSize: request.minimumSize, maximumCount: request.maximumCount)
    }
}

private func largestMatchingRectangle(
    ids: [Int32],
    width: Int,
    height: Int,
    matchingID: Int32
) -> (area: Int32, min: BlockPosition, max: BlockPosition) {
    var heights = Array(repeating: 0, count: width)
    var bestArea = 0
    var bestMin = BlockPosition(x: 0, z: 0)
    var bestMax = BlockPosition(x: 0, z: 0)

    for z in 0..<height {
        for x in 0..<width {
            let index = z * width + x
            heights[x] = ids[index] == matchingID ? heights[x] + 1 : 0
        }

        var stack: [Int] = []
        for x in 0...width {
            let currentHeight = x == width ? 0 : heights[x]
            while let last = stack.last, heights[last] > currentHeight {
                let top = stack.removeLast()
                let rectHeight = heights[top]
                let left = (stack.last ?? -1) + 1
                let rectWidth = x - left
                let area = rectWidth * rectHeight
                if area > bestArea {
                    bestArea = area
                    bestMin = BlockPosition(x: Int32(left), z: Int32(z - rectHeight + 1))
                    bestMax = BlockPosition(x: Int32(x - 1), z: Int32(z))
                }
            }
            stack.append(x)
        }
    }

    return (Int32(bestArea), bestMin, bestMax)
}

private func biomeCentersFromGrid(
    _ grid: BiomeGridResult,
    biomeID: Int32,
    minimumSize: Int32,
    maximumCount: Int32
) -> [BiomeCenter] {
    let width = Int(grid.request.width)
    let height = Int(grid.request.height)
    guard width > 0, height > 0, maximumCount > 0 else {
        return []
    }

    let minimum = max(Int(minimumSize), 1)
    var visited = Array(repeating: false, count: grid.ids.count)
    var centers: [BiomeCenter] = []
    centers.reserveCapacity(Int(min(maximumCount, 64)))

    for z in 0..<height {
        for x in 0..<width {
            let startIndex = z * width + x
            guard !visited[startIndex], grid.ids[startIndex] == biomeID else {
                continue
            }

            var queue = [(x: Int, z: Int)]()
            var head = 0
            var sumX = 0
            var sumZ = 0
            visited[startIndex] = true
            queue.append((x, z))

            while head < queue.count {
                let cell = queue[head]
                head += 1
                sumX += cell.x
                sumZ += cell.z

                let neighbors = [
                    (cell.x - 1, cell.z),
                    (cell.x + 1, cell.z),
                    (cell.x, cell.z - 1),
                    (cell.x, cell.z + 1),
                ]
                for neighbor in neighbors where neighbor.0 >= 0 && neighbor.0 < width && neighbor.1 >= 0 && neighbor.1 < height {
                    let index = neighbor.1 * width + neighbor.0
                    if !visited[index], grid.ids[index] == biomeID {
                        visited[index] = true
                        queue.append((neighbor.0, neighbor.1))
                    }
                }
            }

            guard queue.count >= minimum else {
                continue
            }
            let centerX = Int32(sumX / queue.count)
            let centerZ = Int32(sumZ / queue.count)
            centers.append(BiomeCenter(
                biomeID: biomeID,
                position: BlockPosition(
                    x: grid.request.originX + centerX * grid.request.scale,
                    z: grid.request.originZ + centerZ * grid.request.scale
                ),
                size: Int32(queue.count)
            ))
            if centers.count >= Int(maximumCount) {
                return centers
            }
        }
    }
    return centers
}
