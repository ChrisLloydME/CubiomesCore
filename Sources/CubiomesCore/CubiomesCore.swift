import CCubiomes

#if os(Linux)
import Glibc
#else
import Darwin
#endif

public enum CubiomesCore {
    public static func mapTile(_ request: MapTileRequest) throws -> MapTileResult {
        let world = CubiomesWorld(version: request.version, seed: request.seed, dimension: request.dimension)
        return try world.mapTile(request)
    }

    public static func structures(
        version: MinecraftVersion,
        seed: Int64,
        dimension: MinecraftDimension,
        types: [StructureType],
        rect: StructureRect
    ) throws -> [StructureLocation] {
        let world = CubiomesWorld(version: version, seed: seed, dimension: dimension)
        return try world.structures(types: types, rect: rect)
    }

    public static func structureVariant(
        type: StructureType,
        version: MinecraftVersion,
        seed: Int64,
        blockX: Int32,
        blockZ: Int32,
        biomeID: Int32 = -1
    ) throws -> StructureVariantSummary? {
        guard let requestedCType = type.cubiomesType else {
            throw CubiomesError.unsupportedStructureVariant(type, version: version)
        }
        var variant = StructureVariant()
        guard getVariant(&variant, requestedCType, version.rawValue, UInt64(bitPattern: seed), blockX, blockZ, biomeID) != 0 else {
            return nil
        }
        return StructureVariantSummary(
            type: type,
            abandoned: variant.abandoned != 0,
            giant: variant.giant != 0,
            underground: variant.underground != 0,
            airPocket: variant.airpocket != 0,
            basement: variant.basement != 0,
            cracked: variant.cracked != 0,
            size: Int32(variant.size),
            startPiece: Int32(variant.start),
            biomeID: Int32(variant.biome),
            rotation: Int32(variant.rotation),
            mirror: Int32(variant.mirror),
            position: BlockPosition3D(x: Int32(variant.x), y: Int32(variant.y), z: Int32(variant.z)),
            size3D: BlockPosition3D(x: Int32(variant.sx), y: Int32(variant.sy), z: Int32(variant.sz))
        )
    }

    public static func structurePieces(
        type: StructureType,
        version: MinecraftVersion,
        seed: Int64,
        chunkX: Int32,
        chunkZ: Int32,
        maximumPieces: Int32 = 400
    ) throws -> [StructurePieceSummary] {
        switch type {
        case .endCity:
            var pieces = Array(repeating: Piece(), count: Int(END_CITY_PIECES_MAX))
            let count = pieces.withUnsafeMutableBufferPointer {
                getEndCityPieces($0.baseAddress, UInt64(bitPattern: seed), chunkX, chunkZ)
            }
            return pieceSummaries(from: pieces, count: count)
        case .fortress:
            guard maximumPieces > 0 else { return [] }
            var pieces = Array(repeating: Piece(), count: Int(maximumPieces))
            let count = pieces.withUnsafeMutableBufferPointer {
                getFortressPieces($0.baseAddress, maximumPieces, version.rawValue, UInt64(bitPattern: seed), chunkX, chunkZ)
            }
            return pieceSummaries(from: pieces, count: count)
        default:
            throw CubiomesError.unsupportedStructurePieces(type)
        }
    }

    public static func structureConfig(type: StructureType, version: MinecraftVersion) throws -> StructureConfigInfo {
        try CubiomesWorld.structureConfig(for: type, version: version)
    }

    public static func structureAttempt(
        type: StructureType,
        version: MinecraftVersion,
        seed: Int64,
        regionX: Int32,
        regionZ: Int32
    ) throws -> StructureLocation? {
        guard let requestedCType = type.cubiomesType else {
            throw CubiomesError.unsupportedStructureConfig(type, version: version)
        }

        let config = try CubiomesWorld.structureConfig(for: type, version: version)
        var pos = Pos()
        guard getStructurePos(requestedCType, version.rawValue, UInt64(bitPattern: seed), regionX, regionZ, &pos) != 0 else {
            return nil
        }
        return StructureLocation(
            type: type,
            blockX: Int32(pos.x),
            blockZ: Int32(pos.z),
            regionX: regionX,
            regionZ: regionZ,
            dimension: config.dimension,
            isViable: false
        )
    }

    public static func isViableFeatureBiome(
        type: StructureType,
        version: MinecraftVersion,
        biomeID: Int32
    ) throws -> Bool {
        guard let requestedCType = type.cubiomesType, type.supportsFeatureBiomeCheck else {
            throw CubiomesError.unsupportedStructureBiomeCheck(type, version: version)
        }
        return CCubiomes.isViableFeatureBiome(version.rawValue, requestedCType, biomeID) != 0
    }

    public static func isViableStructurePosition(
        type: StructureType,
        version: MinecraftVersion,
        seed: Int64,
        dimension: MinecraftDimension,
        blockX: Int32,
        blockZ: Int32
    ) throws -> Bool {
        guard let requestedCType = type.cubiomesType else {
            throw CubiomesError.unsupportedStructure(type, version: version, dimension: dimension)
        }
        var generator = Generator()
        setupGenerator(&generator, version.rawValue, 0)
        applySeed(&generator, dimension.rawValue, UInt64(bitPattern: seed))
        return isViableStructurePos(requestedCType, &generator, blockX, blockZ, 0) != 0
    }

    public static func isViableStructureTerrain(
        type: StructureType,
        version: MinecraftVersion,
        seed: Int64,
        blockX: Int32,
        blockZ: Int32
    ) throws -> Bool {
        guard let requestedCType = type.cubiomesType else {
            throw CubiomesError.unsupportedStructure(type, version: version, dimension: .overworld)
        }
        var generator = Generator()
        setupGenerator(&generator, version.rawValue, 0)
        applySeed(&generator, MinecraftDimension.overworld.rawValue, UInt64(bitPattern: seed))
        return CCubiomes.isViableStructureTerrain(requestedCType, &generator, blockX, blockZ) != 0
    }

    public static func estimatedSpawn(version: MinecraftVersion, seed: Int64) -> BlockPosition {
        CubiomesWorld(version: version, seed: seed, dimension: .overworld).estimatedSpawn()
    }

    public static func spawn(version: MinecraftVersion, seed: Int64) -> BlockPosition {
        CubiomesWorld(version: version, seed: seed, dimension: .overworld).spawn()
    }

    public static func firstStrongholdApproximation(version: MinecraftVersion, seed: Int64) -> BlockPosition {
        CubiomesWorld(version: version, seed: seed, dimension: .overworld).firstStrongholdApproximation()
    }

    public static func strongholds(version: MinecraftVersion, seed: Int64, limit: Int = 128) -> [StructureLocation] {
        CubiomesWorld(version: version, seed: seed, dimension: .overworld).strongholds(limit: limit)
    }

    public static func isSlimeChunk(seed: Int64, chunkX: Int32, chunkZ: Int32) -> Bool {
        CCubiomes.isSlimeChunk(UInt64(bitPattern: seed), chunkX, chunkZ) != 0
    }

    public static func movedStructureSeed(baseSeed: Int64, regionX: Int32, regionZ: Int32) -> Int64 {
        Int64(bitPattern: moveStructure(UInt64(bitPattern: baseSeed), regionX, regionZ))
    }

    public static func shadowSeed(seed: Int64) -> Int64 {
        Int64(bitPattern: getShadow(UInt64(bitPattern: seed)))
    }

    public static func chunkGenerationSeed(seed: Int64, chunkX: Int32, chunkZ: Int32) -> Int64 {
        Int64(bitPattern: chunkGenerateRnd(UInt64(bitPattern: seed), chunkX, chunkZ))
    }

    public static func quadStructureClusters(_ request: QuadStructureSearchRequest) throws -> [QuadStructureCluster] {
        guard request.maximumCount > 0 else { return [] }
        guard [StructureType.swampHut, .monument].contains(request.type),
              let requestedCType = request.type.cubiomesType else {
            throw CubiomesError.unsupportedQuadSearch(request.type, version: request.version)
        }
        var config = StructureConfig()
        guard getStructureConfig(requestedCType, request.version.rawValue, &config) != 0 else {
            throw CubiomesError.unsupportedQuadSearch(request.type, version: request.version)
        }
        var rawPositions = Array(repeating: Pos(), count: Int(request.maximumCount))
        var lowBits = request.type.quadSearchLowBits(monumentCoverage: request.monumentCoverage)
        let searchRadius = request.type == .monument ? Int32(160) : Int32(128)
        let lowBitCount = request.type == .monument ? Int32(48) : Int32(20)
        let found = rawPositions.withUnsafeMutableBufferPointer { outBuffer in
            lowBits.withUnsafeMutableBufferPointer { lowBitBuffer in
                scanForQuads(
                    config,
                    searchRadius,
                    UInt64(bitPattern: request.seed) & lower48Mask,
                    lowBitBuffer.baseAddress,
                    lowBitCount,
                    UInt64(bitPattern: Int64(config.salt)),
                    request.regionX,
                    request.regionZ,
                    request.regionWidth,
                    request.regionHeight,
                    outBuffer.baseAddress,
                    request.maximumCount
                )
            }
        }
        guard found >= 0 else {
            throw CubiomesError.quadSearchFailed
        }

        var generator = Generator()
        setupGenerator(&generator, request.version.rawValue, 0)
        applySeed(&generator, MinecraftDimension.overworld.rawValue, UInt64(bitPattern: request.seed))

        var clusters: [QuadStructureCluster] = []
        for index in 0..<min(Int(found), rawPositions.count) {
            let region = rawPositions[index]
            var attemptPositions = [
                Pos(), Pos(), Pos(), Pos()
            ]
            let regionPairs: [(Int32, Int32)] = [(0, 0), (0, 1), (1, 0), (1, 1)]
            var attempts: [StructureLocation] = []
            for attemptIndex in 0..<4 {
                var pos = Pos()
                guard getStructurePos(
                    requestedCType,
                    request.version.rawValue,
                    UInt64(bitPattern: request.seed),
                    Int32(region.x) + regionPairs[attemptIndex].0,
                    Int32(region.z) + regionPairs[attemptIndex].1,
                    &pos
                ) != 0 else {
                    continue
                }
                let viable = isViableStructurePos(requestedCType, &generator, Int32(pos.x), Int32(pos.z), 0) != 0
                if request.requiresViableBiomes && !viable {
                    continue
                }
                attemptPositions[attemptIndex] = pos
                attempts.append(StructureLocation(
                    type: request.type,
                    blockX: Int32(pos.x),
                    blockZ: Int32(pos.z),
                    regionX: Int32(region.x) + regionPairs[attemptIndex].0,
                    regionZ: Int32(region.z) + regionPairs[attemptIndex].1,
                    dimension: .overworld,
                    isViable: viable
                ))
            }
            guard attempts.count == 4 else {
                continue
            }
            var spawningSpaces = Int32(0)
            var afk = attemptPositions.withUnsafeMutableBufferPointer {
                if request.type == .monument {
                    return getOptimalAfk($0.baseAddress, 58, 0, 58, &spawningSpaces)
                }
                return getOptimalAfk($0.baseAddress, 7, 7, 9, &spawningSpaces)
            }
            if request.type == .monument {
                afk.x -= 29
                afk.z -= 29
            }
            let movedSeed = moveStructure(UInt64(bitPattern: request.seed), -Int32(region.x), -Int32(region.z))
            let radius = isQuadBase(config, movedSeed, searchRadius)
            clusters.append(QuadStructureCluster(
                type: request.type,
                regionX: Int32(region.x),
                regionZ: Int32(region.z),
                attempts: attempts.sorted { ($0.blockZ, $0.blockX) < ($1.blockZ, $1.blockX) },
                afkPosition: BlockPosition(x: Int32(afk.x), z: Int32(afk.z)),
                spawningSpaces: spawningSpaces,
                enclosingRadius: radius
            ))
        }
        return clusters.sorted { ($0.regionZ, $0.regionX) < ($1.regionZ, $1.regionX) }
    }

    public static func biome(
        version: MinecraftVersion,
        seed: Int64,
        dimension: MinecraftDimension,
        x: Int32,
        z: Int32
    ) throws -> BiomeLookupResult {
        try biome(version: version, seed: seed, dimension: dimension, x: x, y: 63, z: z)
    }

    public static func biome(
        version: MinecraftVersion,
        seed: Int64,
        dimension: MinecraftDimension,
        x: Int32,
        y: Int32,
        z: Int32
    ) throws -> BiomeLookupResult {
        let world = CubiomesWorld(version: version, seed: seed, dimension: dimension)
        return try world.biome(x: x, y: y, z: z)
    }
}
