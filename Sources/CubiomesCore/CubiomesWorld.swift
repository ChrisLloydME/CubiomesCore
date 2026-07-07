import CCubiomes

#if os(Linux)
import Glibc
#else
import Darwin
#endif

public final class CubiomesWorld: @unchecked Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let dimension: MinecraftDimension

    public init(version: MinecraftVersion, seed: Int64, dimension: MinecraftDimension) {
        self.version = version
        self.seed = seed
        self.dimension = dimension
    }

    public func biome(x: Int32, z: Int32) throws -> BiomeLookupResult {
        try biome(x: x, y: 63, z: z)
    }

    public func biome(x: Int32, y: Int32, z: Int32) throws -> BiomeLookupResult {
        var generator = Generator()
        initialize(&generator)
        let biomeID = getBiomeAt(&generator, 1, x, y, z)
        guard biomeID >= 0 else {
            throw CubiomesError.biomeLookupFailed
        }

        return BiomeLookupResult(
            id: biomeID,
            name: String(cString: biome2str(version.rawValue, biomeID))
        )
    }

    public func biomes(
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        scale: Int32 = 4,
        y: Int32 = 63
    ) throws -> BiomeGridResult {
        let request = BiomeGridRequest(
            version: version,
            seed: seed,
            dimension: dimension,
            originX: originX,
            originZ: originZ,
            width: width,
            height: height,
            scale: scale,
            y: y
        )
        return try biomes(request)
    }

    public func biomes(_ request: BiomeGridRequest) throws -> BiomeGridResult {
        try Self.validateGrid(request)

        let range = Range(
            scale: request.scale,
            x: request.originX,
            z: request.originZ,
            sx: request.width,
            sz: request.height,
            y: request.y,
            sy: 1
        )
        var generator = Generator()
        initialize(&generator)

        guard let cache = allocCache(&generator, range) else {
            throw CubiomesError.biomeGridAllocationFailed
        }
        defer { free(cache) }

        let code = genBiomes(&generator, cache, range)
        guard code == 0 else {
            throw CubiomesError.biomeGridGenerationFailed(code: code)
        }

        let count = Int(Int64(request.width) * Int64(request.height))
        let ids = UnsafeBufferPointer(start: cache, count: count).map { Int32($0) }
        return BiomeGridResult(request: request, ids: ids)
    }

    public func approximateHeights(
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32
    ) throws -> ApproximateHeightGridResult {
        let request = ApproximateHeightGridRequest(
            version: version,
            seed: seed,
            dimension: dimension,
            originX: originX,
            originZ: originZ,
            width: width,
            height: height
        )
        return try approximateHeights(request)
    }

    public func approximateHeights(_ request: ApproximateHeightGridRequest) throws -> ApproximateHeightGridResult {
        try Self.validateGridLike(width: request.width, height: request.height)

        let count = Int(Int64(request.width) * Int64(request.height))
        var heights = Array(repeating: Float(0), count: count)
        var ids = Array(repeating: Int32(0), count: count)
        var generator = Generator()
        initialize(&generator)
        var surfaceNoise = SurfaceNoise()
        initSurfaceNoise(&surfaceNoise, request.dimension.rawValue, UInt64(bitPattern: request.seed))

        let code = heights.withUnsafeMutableBufferPointer { heightBuffer in
            ids.withUnsafeMutableBufferPointer { idBuffer in
                mapApproxHeight(
                    heightBuffer.baseAddress,
                    idBuffer.baseAddress,
                    &generator,
                    &surfaceNoise,
                    request.originX,
                    request.originZ,
                    request.width,
                    request.height
                )
            }
        }
        guard code == 0 else {
            throw CubiomesError.approximateHeightMappingFailed(code: code)
        }

        return ApproximateHeightGridResult(request: request, heights: heights, biomeIDs: ids)
    }

    public func structures(types: [StructureType], rect: StructureRect) throws -> [StructureLocation] {
        try Self.validateRect(rect)

        var locations: [StructureLocation] = []
        for type in types {
            switch type {
            case .stronghold:
                try appendStrongholds(in: rect, to: &locations)
            case .slimeChunk:
                appendSlimeChunks(in: rect, to: &locations)
            case .mineshaft:
                try appendMineshafts(in: rect, to: &locations)
            default:
                try appendConfiguredStructures(type, in: rect, to: &locations)
            }
        }
        return locations.sorted {
            ($0.blockZ, $0.blockX, String(describing: $0.type)) <
                ($1.blockZ, $1.blockX, String(describing: $1.type))
        }
    }

    public func mapTile(_ request: MapTileRequest) throws -> MapTileResult {
        let biomeRequest = BiomeGridRequest(
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
        let biomeGrid = try biomes(biomeRequest)
        let heightGrid: ApproximateHeightGridResult?
        if request.includesApproximateHeights {
            heightGrid = try approximateHeights(
                originX: request.originX,
                originZ: request.originZ,
                width: request.width,
                height: request.height
            )
        } else {
            heightGrid = nil
        }
        let structureRect = StructureRect(
            originX: request.originX * request.scale,
            originZ: request.originZ * request.scale,
            width: request.width * request.scale,
            height: request.height * request.scale
        )
        let structureLocations = request.structureTypes.isEmpty
            ? []
            : try structures(types: request.structureTypes, rect: structureRect)
        return MapTileResult(
            request: request,
            biomes: biomeGrid,
            approximateHeights: heightGrid,
            structures: structureLocations
        )
    }

    public func structureConfig(for type: StructureType) throws -> StructureConfigInfo {
        try Self.structureConfig(for: type, version: version)
    }

    public func estimatedSpawn() -> BlockPosition {
        var generator = Generator()
        initialize(&generator)
        let pos = estimateSpawn(&generator, nil)
        return BlockPosition(x: Int32(pos.x), z: Int32(pos.z))
    }

    public func spawn() -> BlockPosition {
        var generator = Generator()
        initialize(&generator)
        let pos = getSpawn(&generator)
        return BlockPosition(x: Int32(pos.x), z: Int32(pos.z))
    }

    public func firstStrongholdApproximation() -> BlockPosition {
        var iterator = StrongholdIter()
        let pos = initFirstStronghold(&iterator, version.rawValue, UInt64(bitPattern: seed))
        return BlockPosition(x: Int32(pos.x), z: Int32(pos.z))
    }

    public func strongholds(limit: Int = 128) -> [StructureLocation] {
        guard dimension == .overworld, limit > 0 else {
            return []
        }

        var iterator = StrongholdIter()
        _ = initFirstStronghold(&iterator, version.rawValue, UInt64(bitPattern: seed))
        var generator = Generator()
        initialize(&generator)
        var locations: [StructureLocation] = []

        for index in 0..<limit {
            let remaining = nextStronghold(&iterator, &generator)
            locations.append(StructureLocation(
                type: .stronghold,
                blockX: Int32(iterator.pos.x),
                blockZ: Int32(iterator.pos.z),
                regionX: Int32(index),
                regionZ: Int32(iterator.ringnum),
                dimension: dimension,
                isViable: true
            ))
            if remaining <= 0 {
                break
            }
        }

        return locations
    }

    public func isSlimeChunk(chunkX: Int32, chunkZ: Int32) -> Bool {
        dimension == .overworld && CubiomesCore.isSlimeChunk(seed: seed, chunkX: chunkX, chunkZ: chunkZ)
    }

    private func initialize(_ generator: inout Generator) {
        primeClimateParameterLimitsCache()
        setupGenerator(&generator, version.rawValue, 0)
        applySeed(&generator, dimension.rawValue, UInt64(bitPattern: seed))
    }

    private static func validateGrid(_ request: BiomeGridRequest) throws {
        try validateGridLike(width: request.width, height: request.height)
        let supportedScales: [Int32] = [1, 4, 16, 64, 256]
        guard supportedScales.contains(request.scale) else {
            throw CubiomesError.unsupportedBiomeScale(scale: request.scale, supported: supportedScales)
        }
    }

    static func validateGridLike(width: Int32, height: Int32) throws {
        guard width > 0, height > 0 else {
            throw CubiomesError.invalidBiomeGridSize(width: width, height: height)
        }
        guard Int64(width) * Int64(height) <= Int64(Int32.max) else {
            throw CubiomesError.invalidBiomeGridSize(width: width, height: height)
        }
    }

    private static func validateRect(_ rect: StructureRect) throws {
        guard rect.minX < rect.maxX, rect.minZ < rect.maxZ else {
            throw CubiomesError.invalidStructureRect
        }
    }

    static func validateSearchLimit(_ limit: Int) throws {
        guard limit >= 0 else {
            throw CubiomesError.invalidSearchLimit(limit)
        }
    }

    static func validateVolume(width: Int32, height: Int32, depth: Int32) throws {
        guard width > 0, height > 0, depth > 0 else {
            throw CubiomesError.invalidVolumeSize(width: width, height: height, depth: depth)
        }
        guard Int64(width) * Int64(height) * Int64(depth) <= Int64(Int32.max) else {
            throw CubiomesError.invalidVolumeSize(width: width, height: height, depth: depth)
        }
    }

    static func structureConfig(for type: StructureType, version: MinecraftVersion) throws -> StructureConfigInfo {
        guard let requestedCType = type.cubiomesType else {
            throw CubiomesError.unsupportedStructureConfig(type, version: version)
        }

        var config = StructureConfig()
        guard getStructureConfig(requestedCType, version.rawValue, &config) != 0 else {
            throw CubiomesError.unsupportedStructureConfig(type, version: version)
        }

        return StructureConfigInfo(
            type: type,
            salt: config.salt,
            regionSize: Int32(config.regionSize),
            chunkRange: Int32(config.chunkRange),
            dimension: MinecraftDimension(rawValue: Int32(config.dim)) ?? .overworld,
            rarity: config.rarity
        )
    }

    private func appendConfiguredStructures(
        _ type: StructureType,
        in rect: StructureRect,
        to locations: inout [StructureLocation]
    ) throws {
        guard let requestedCType = type.cubiomesType else {
            throw CubiomesError.unsupportedStructure(type, version: version, dimension: dimension)
        }

        var config = StructureConfig()
        guard getStructureConfig(requestedCType, version.rawValue, &config) != 0 else {
            throw CubiomesError.unsupportedStructure(type, version: version, dimension: dimension)
        }

        guard config.dim == dimension.rawValue else {
            return
        }

        let regionBlockSize = Int32(config.regionSize) * 16
        let minRegionX = floorDiv(rect.minX, regionBlockSize)
        let maxRegionX = floorDiv(rect.maxX - 1, regionBlockSize)
        let minRegionZ = floorDiv(rect.minZ, regionBlockSize)
        let maxRegionZ = floorDiv(rect.maxZ - 1, regionBlockSize)
        var generator = Generator()
        initialize(&generator)

        for regionZ in minRegionZ...maxRegionZ {
            for regionX in minRegionX...maxRegionX {
                var pos = Pos()
                let structureType = Int32(config.structType)
                guard getStructurePos(structureType, version.rawValue, UInt64(bitPattern: seed), regionX, regionZ, &pos) != 0 else {
                    continue
                }
                let blockX = Int32(pos.x)
                let blockZ = Int32(pos.z)
                guard rect.contains(blockX: blockX, blockZ: blockZ) else {
                    continue
                }
                let viable = isViableStructurePos(structureType, &generator, blockX, blockZ, 0) != 0
                locations.append(StructureLocation(
                    type: type,
                    blockX: blockX,
                    blockZ: blockZ,
                    regionX: regionX,
                    regionZ: regionZ,
                    dimension: dimension,
                    isViable: viable
                ))
            }
        }
    }

    private func appendMineshafts(in rect: StructureRect, to locations: inout [StructureLocation]) throws {
        var config = StructureConfig()
        guard getStructureConfig(15, version.rawValue, &config) != 0 else {
            throw CubiomesError.unsupportedStructure(.mineshaft, version: version, dimension: dimension)
        }
        guard dimension == .overworld else {
            return
        }

        let minChunkX = floorDiv(rect.minX, 16)
        let maxChunkX = floorDiv(rect.maxX - 1, 16)
        let minChunkZ = floorDiv(rect.minZ, 16)
        let maxChunkZ = floorDiv(rect.maxZ - 1, 16)
        let chunkWidth = maxChunkX - minChunkX + 1
        let chunkHeight = maxChunkZ - minChunkZ + 1
        let capacity = Int(chunkWidth * chunkHeight)
        guard capacity > 0 else { return }

        var positions = Array(repeating: Pos(), count: capacity)
        let found = positions.withUnsafeMutableBufferPointer {
            getMineshafts(version.rawValue, UInt64(bitPattern: seed), minChunkX, minChunkZ, maxChunkX, maxChunkZ, $0.baseAddress, Int32(capacity))
        }
        guard found > 0 else { return }

        for index in 0..<min(Int(found), positions.count) {
            let blockX = Int32(positions[index].x)
            let blockZ = Int32(positions[index].z)
            guard rect.contains(blockX: blockX, blockZ: blockZ) else {
                continue
            }
            locations.append(StructureLocation(
                type: .mineshaft,
                blockX: blockX,
                blockZ: blockZ,
                regionX: floorDiv(blockX, 16),
                regionZ: floorDiv(blockZ, 16),
                dimension: dimension,
                isViable: true
            ))
        }
    }

    private func appendStrongholds(in rect: StructureRect, to locations: inout [StructureLocation]) throws {
        guard dimension == .overworld else {
            return
        }

        var iterator = StrongholdIter()
        _ = initFirstStronghold(&iterator, version.rawValue, UInt64(bitPattern: seed))
        var generator = Generator()
        initialize(&generator)
        var index: Int32 = 0

        while true {
            let remaining = nextStronghold(&iterator, &generator)
            let blockX = Int32(iterator.pos.x)
            let blockZ = Int32(iterator.pos.z)
            if rect.contains(blockX: blockX, blockZ: blockZ) {
                locations.append(StructureLocation(
                    type: .stronghold,
                    blockX: blockX,
                    blockZ: blockZ,
                    regionX: index,
                    regionZ: Int32(iterator.ringnum),
                    dimension: dimension,
                    isViable: true
                ))
            }
            index += 1
            if remaining <= 0 {
                break
            }
        }
    }

    private func appendSlimeChunks(in rect: StructureRect, to locations: inout [StructureLocation]) {
        guard dimension == .overworld else {
            return
        }

        let minChunkX = floorDiv(rect.minX, 16)
        let maxChunkX = floorDiv(rect.maxX - 1, 16)
        let minChunkZ = floorDiv(rect.minZ, 16)
        let maxChunkZ = floorDiv(rect.maxZ - 1, 16)

        for chunkZ in minChunkZ...maxChunkZ {
            for chunkX in minChunkX...maxChunkX {
                guard CCubiomes.isSlimeChunk(UInt64(bitPattern: seed), chunkX, chunkZ) != 0 else {
                    continue
                }
                let blockX = chunkX << 4
                let blockZ = chunkZ << 4
                guard rect.contains(blockX: blockX, blockZ: blockZ) else {
                    continue
                }
                locations.append(StructureLocation(
                    type: .slimeChunk,
                    blockX: blockX,
                    blockZ: blockZ,
                    regionX: chunkX,
                    regionZ: chunkZ,
                    dimension: dimension,
                    isViable: true
                ))
            }
        }
    }
}
