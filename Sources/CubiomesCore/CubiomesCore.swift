import CCubiomes

#if os(Linux)
import Glibc
#else
import Darwin
#endif

public struct MinecraftVersion: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init?(_ stringValue: String) {
        let parsed = stringValue.withCString { str2mc($0) }
        guard parsed != 0 else {
            return nil
        }
        self.rawValue = parsed
    }

    public var name: String {
        String(cString: mc2str(rawValue))
    }

    public static let beta1_7 = known("Beta 1.7")
    public static let beta1_8 = known("Beta 1.8")
    public static let v1_0 = known("1.0")
    public static let v1_1 = known("1.1")
    public static let v1_2 = known("1.2")
    public static let v1_3 = known("1.3")
    public static let v1_4 = known("1.4")
    public static let v1_5 = known("1.5")
    public static let v1_6 = known("1.6")
    public static let v1_7 = known("1.7")
    public static let v1_8 = known("1.8")
    public static let v1_9 = known("1.9")
    public static let v1_10 = known("1.10")
    public static let v1_11 = known("1.11")
    public static let v1_12 = known("1.12")
    public static let v1_13 = known("1.13")
    public static let v1_14 = known("1.14")
    public static let v1_15 = known("1.15")
    public static let v1_16_1 = known("1.16.1")
    public static let v1_16 = known("1.16")
    public static let v1_17 = known("1.17")
    public static let v1_18 = known("1.18")
    public static let v1_19_2 = known("1.19.2")
    public static let v1_19 = known("1.19")
    public static let v1_20 = known("1.20")
    public static let v1_21_1 = known("1.21.1")
    public static let v1_21_3 = known("1.21.3")
    public static let v1_21 = known("1.21")
    public static let newest = MinecraftVersion.v1_21

    private static func known(_ stringValue: String) -> MinecraftVersion {
        guard let version = MinecraftVersion(stringValue) else {
            preconditionFailure("Bundled cubiomes does not define Minecraft \(stringValue)")
        }
        return version
    }
}

public enum MinecraftDimension: Int32, Sendable {
    case nether = -1
    case overworld = 0
    case end = 1
}

public struct BiomeLookupResult: Equatable, Sendable {
    public let id: Int32
    public let name: String

    public init(id: Int32, name: String) {
        self.id = id
        self.name = name
    }
}

public struct BiomeInfo: Equatable, Sendable {
    public let id: Int32
    public let name: String
    public let exists: Bool
    public let dimension: MinecraftDimension
    public let isOverworld: Bool
    public let mutatedID: Int32?
    public let category: Int32

    public init(
        id: Int32,
        name: String,
        exists: Bool,
        dimension: MinecraftDimension,
        isOverworld: Bool,
        mutatedID: Int32?,
        category: Int32
    ) {
        self.id = id
        self.name = name
        self.exists = exists
        self.dimension = dimension
        self.isOverworld = isOverworld
        self.mutatedID = mutatedID
        self.category = category
    }
}

public struct BiomeGridRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let dimension: MinecraftDimension
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32
    public let scale: Int32
    public let y: Int32

    /// Creates a 2D biome range request.
    ///
    /// Results are returned in z-major row order: `ids[z * width + x]`.
    /// Cubiomes officially supports horizontal scales `1, 4, 16, 64, 256`
    /// through this generator entry point. Scale `1024` is intentionally
    /// rejected until the bundled C library exposes it as a supported range
    /// generation scale.
    public init(
        version: MinecraftVersion,
        seed: Int64,
        dimension: MinecraftDimension,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        scale: Int32 = 4,
        y: Int32 = 63
    ) {
        self.version = version
        self.seed = seed
        self.dimension = dimension
        self.originX = originX
        self.originZ = originZ
        self.width = width
        self.height = height
        self.scale = scale
        self.y = y
    }
}

public struct BiomeGridResult: Equatable, Sendable {
    public let request: BiomeGridRequest
    public let ids: [Int32]

    public init(request: BiomeGridRequest, ids: [Int32]) {
        self.request = request
        self.ids = ids
    }

    public var width: Int32 { request.width }
    public var height: Int32 { request.height }

    public func idAt(x: Int32, z: Int32) -> Int32? {
        guard x >= 0, z >= 0, x < width, z < height else {
            return nil
        }
        return ids[Int(z * width + x)]
    }
}

public struct ApproximateHeightGridRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let dimension: MinecraftDimension
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32

    /// Creates a surface height request at cubiomes' 1:4 horizontal scale.
    public init(
        version: MinecraftVersion,
        seed: Int64,
        dimension: MinecraftDimension,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32
    ) {
        self.version = version
        self.seed = seed
        self.dimension = dimension
        self.originX = originX
        self.originZ = originZ
        self.width = width
        self.height = height
    }
}

public struct ApproximateHeightGridResult: Equatable, Sendable {
    public let request: ApproximateHeightGridRequest
    public let heights: [Float]
    public let biomeIDs: [Int32]

    public init(request: ApproximateHeightGridRequest, heights: [Float], biomeIDs: [Int32]) {
        self.request = request
        self.heights = heights
        self.biomeIDs = biomeIDs
    }

    public var width: Int32 { request.width }
    public var height: Int32 { request.height }

    public func heightAt(x: Int32, z: Int32) -> Float? {
        guard x >= 0, z >= 0, x < width, z < height else {
            return nil
        }
        return heights[Int(z * width + x)]
    }

    public func biomeIDAt(x: Int32, z: Int32) -> Int32? {
        guard x >= 0, z >= 0, x < width, z < height else {
            return nil
        }
        return biomeIDs[Int(z * width + x)]
    }
}

public struct StructureRect: Equatable, Sendable {
    public let minX: Int32
    public let minZ: Int32
    public let maxX: Int32
    public let maxZ: Int32

    public init(minX: Int32, minZ: Int32, maxX: Int32, maxZ: Int32) {
        self.minX = minX
        self.minZ = minZ
        self.maxX = maxX
        self.maxZ = maxZ
    }

    public init(originX: Int32, originZ: Int32, width: Int32, height: Int32) {
        self.minX = originX
        self.minZ = originZ
        self.maxX = originX + width
        self.maxZ = originZ + height
    }

    public func contains(blockX: Int32, blockZ: Int32) -> Bool {
        blockX >= minX && blockX < maxX && blockZ >= minZ && blockZ < maxZ
    }
}

public enum StructureType: CaseIterable, Hashable, Sendable {
    case feature
    case village
    case desertPyramid
    case jungleTemple
    case swampHut
    case igloo
    case oceanRuin
    case shipwreck
    case monument
    case mansion
    case outpost
    case ruinedPortal
    case netherRuinedPortal
    case ancientCity
    case treasure
    case mineshaft
    case desertWell
    case geode
    case fortress
    case bastion
    case endCity
    case endGateway
    case endIsland
    case trailRuins
    case trialChambers
    case stronghold
    case slimeChunk

    fileprivate var cubiomesType: Int32? {
        switch self {
        case .feature: return 0
        case .village: return 5
        case .desertPyramid: return 1
        case .jungleTemple: return 2
        case .swampHut: return 3
        case .igloo: return 4
        case .oceanRuin: return 6
        case .shipwreck: return 7
        case .monument: return 8
        case .mansion: return 9
        case .outpost: return 10
        case .ruinedPortal: return 11
        case .netherRuinedPortal: return 12
        case .ancientCity: return 13
        case .treasure: return 14
        case .mineshaft: return 15
        case .desertWell: return 16
        case .geode: return 17
        case .fortress: return 18
        case .bastion: return 19
        case .endCity: return 20
        case .endGateway: return 21
        case .endIsland: return 22
        case .trailRuins: return 23
        case .trialChambers: return 24
        case .stronghold, .slimeChunk: return nil
        }
    }

    public var resourceName: String {
        guard let cubiomesType else {
            return String(describing: self)
        }
        return String(cString: struct2str(cubiomesType))
    }
}

public struct StructureConfigInfo: Equatable, Sendable {
    public let type: StructureType
    public let salt: Int32
    public let regionSize: Int32
    public let chunkRange: Int32
    public let dimension: MinecraftDimension
    public let rarity: Float

    public init(
        type: StructureType,
        salt: Int32,
        regionSize: Int32,
        chunkRange: Int32,
        dimension: MinecraftDimension,
        rarity: Float
    ) {
        self.type = type
        self.salt = salt
        self.regionSize = regionSize
        self.chunkRange = chunkRange
        self.dimension = dimension
        self.rarity = rarity
    }
}

public struct StructureLocation: Equatable, Sendable {
    public let type: StructureType
    public let blockX: Int32
    public let blockZ: Int32
    public let regionX: Int32
    public let regionZ: Int32
    public let dimension: MinecraftDimension
    public let isViable: Bool

    public init(
        type: StructureType,
        blockX: Int32,
        blockZ: Int32,
        regionX: Int32,
        regionZ: Int32,
        dimension: MinecraftDimension,
        isViable: Bool
    ) {
        self.type = type
        self.blockX = blockX
        self.blockZ = blockZ
        self.regionX = regionX
        self.regionZ = regionZ
        self.dimension = dimension
        self.isViable = isViable
    }
}

public struct BlockPosition: Equatable, Sendable {
    public let x: Int32
    public let z: Int32

    public init(x: Int32, z: Int32) {
        self.x = x
        self.z = z
    }
}

public enum CubiomesError: Error, Equatable, Sendable {
    case biomeLookupFailed
    case invalidBiomeGridSize(width: Int32, height: Int32)
    case unsupportedBiomeScale(scale: Int32, supported: [Int32])
    case biomeGridAllocationFailed
    case biomeGridGenerationFailed(code: Int32)
    case invalidStructureRect
    case unsupportedStructure(StructureType, version: MinecraftVersion, dimension: MinecraftDimension)
    case unsupportedStructureConfig(StructureType, version: MinecraftVersion)
    case approximateHeightMappingFailed(code: Int32)
}

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

    private static func validateGridLike(width: Int32, height: Int32) throws {
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

    fileprivate static func structureConfig(for type: StructureType, version: MinecraftVersion) throws -> StructureConfigInfo {
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

public enum CubiomesCore {
    public static func biomeInfo(version: MinecraftVersion, id: Int32) -> BiomeInfo {
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

    public static func areSimilarBiomes(version: MinecraftVersion, _ firstID: Int32, _ secondID: Int32) -> Bool {
        areSimilar(version.rawValue, firstID, secondID) != 0
    }

    public static func biomes(
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

    public static func biomes(_ request: BiomeGridRequest) throws -> BiomeGridResult {
        let world = CubiomesWorld(
            version: request.version,
            seed: request.seed,
            dimension: request.dimension
        )
        return try world.biomes(request)
    }

    public static func approximateHeights(
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

    public static func approximateHeights(_ request: ApproximateHeightGridRequest) throws -> ApproximateHeightGridResult {
        let world = CubiomesWorld(
            version: request.version,
            seed: request.seed,
            dimension: request.dimension
        )
        return try world.approximateHeights(request)
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

    public static func structureConfig(type: StructureType, version: MinecraftVersion) throws -> StructureConfigInfo {
        try CubiomesWorld.structureConfig(for: type, version: version)
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

private func floorDiv(_ value: Int32, _ divisor: Int32) -> Int32 {
    precondition(divisor > 0)
    var quotient = value / divisor
    let remainder = value % divisor
    if remainder != 0 && value < 0 {
        quotient -= 1
    }
    return quotient
}
