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

public struct BiomeClassification: Equatable, Sendable {
    public let id: Int32
    public let isMesa: Bool
    public let isShallowOcean: Bool
    public let isDeepOcean: Bool
    public let isOceanic: Bool
    public let isSnowy: Bool

    public init(
        id: Int32,
        isMesa: Bool,
        isShallowOcean: Bool,
        isDeepOcean: Bool,
        isOceanic: Bool,
        isSnowy: Bool
    ) {
        self.id = id
        self.isMesa = isMesa
        self.isShallowOcean = isShallowOcean
        self.isDeepOcean = isDeepOcean
        self.isOceanic = isOceanic
        self.isSnowy = isSnowy
    }
}

public struct BiomeTerrainInfo: Equatable, Sendable {
    public let id: Int32
    public let depth: Double
    public let scale: Double
    public let grass: Int32

    public init(id: Int32, depth: Double, scale: Double, grass: Int32) {
        self.id = id
        self.depth = depth
        self.scale = scale
        self.grass = grass
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

public struct MapTileRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let dimension: MinecraftDimension
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32
    public let scale: Int32
    public let y: Int32
    public let includesApproximateHeights: Bool
    public let structureTypes: [StructureType]

    public init(
        version: MinecraftVersion,
        seed: Int64,
        dimension: MinecraftDimension,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        scale: Int32 = 4,
        y: Int32 = 63,
        includesApproximateHeights: Bool = false,
        structureTypes: [StructureType] = []
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
        self.includesApproximateHeights = includesApproximateHeights
        self.structureTypes = structureTypes
    }
}

public struct MapTileResult: Equatable, Sendable {
    public let request: MapTileRequest
    public let biomes: BiomeGridResult
    public let approximateHeights: ApproximateHeightGridResult?
    public let structures: [StructureLocation]

    public init(
        request: MapTileRequest,
        biomes: BiomeGridResult,
        approximateHeights: ApproximateHeightGridResult?,
        structures: [StructureLocation]
    ) {
        self.request = request
        self.biomes = biomes
        self.approximateHeights = approximateHeights
        self.structures = structures
    }
}

public struct NetherBiomeGridRequest: Equatable, Sendable {
    public let seed: Int64
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32

    /// Creates a Nether biome request at cubiomes' native 1:4 horizontal scale and y=0.
    public init(seed: Int64, originX: Int32, originZ: Int32, width: Int32, height: Int32) {
        self.seed = seed
        self.originX = originX
        self.originZ = originZ
        self.width = width
        self.height = height
    }
}

public struct NetherBiomeGridResult: Equatable, Sendable {
    public let request: NetherBiomeGridRequest
    public let ids: [Int32]

    public init(request: NetherBiomeGridRequest, ids: [Int32]) {
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

public struct NetherBiomeVolumeRequest: Equatable, Sendable {
    public let seed: Int64
    public let originX: Int32
    public let originY: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32
    public let depth: Int32
    public let confidence: Float

    /// Creates a 3D Nether biome request at cubiomes' native 1:4 scale.
    public init(
        seed: Int64,
        originX: Int32,
        originY: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        depth: Int32,
        confidence: Float = 1.0
    ) {
        self.seed = seed
        self.originX = originX
        self.originY = originY
        self.originZ = originZ
        self.width = width
        self.height = height
        self.depth = depth
        self.confidence = confidence
    }
}

public struct NetherBiomeVolumeResult: Equatable, Sendable {
    public let request: NetherBiomeVolumeRequest
    public let ids: [Int32]

    public init(request: NetherBiomeVolumeRequest, ids: [Int32]) {
        self.request = request
        self.ids = ids
    }

    public func idAt(x: Int32, y: Int32, z: Int32) -> Int32? {
        guard x >= 0, y >= 0, z >= 0,
              x < request.width, y < request.height, z < request.depth else {
            return nil
        }
        return ids[Int(y * request.width * request.depth + z * request.width + x)]
    }
}

public struct EndBiomeGridRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32
    public let scale: Int32

    /// Creates an End biome request. Supported scales are 4 and 16.
    public init(
        version: MinecraftVersion,
        seed: Int64,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        scale: Int32 = 4
    ) {
        self.version = version
        self.seed = seed
        self.originX = originX
        self.originZ = originZ
        self.width = width
        self.height = height
        self.scale = scale
    }
}

public struct EndBiomeGridResult: Equatable, Sendable {
    public let request: EndBiomeGridRequest
    public let ids: [Int32]

    public init(request: EndBiomeGridRequest, ids: [Int32]) {
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

public struct EndChunkAnalysis: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let chunkX: Int32
    public let chunkZ: Int32
    public let isEmpty: Bool
    public let islands: [EndIslandInfo]

    public init(
        version: MinecraftVersion,
        seed: Int64,
        chunkX: Int32,
        chunkZ: Int32,
        isEmpty: Bool,
        islands: [EndIslandInfo]
    ) {
        self.version = version
        self.seed = seed
        self.chunkX = chunkX
        self.chunkZ = chunkZ
        self.isEmpty = isEmpty
        self.islands = islands
    }
}

public struct EndSurfaceHeightGridRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32

    public init(version: MinecraftVersion, seed: Int64, originX: Int32, originZ: Int32, width: Int32, height: Int32) {
        self.version = version
        self.seed = seed
        self.originX = originX
        self.originZ = originZ
        self.width = width
        self.height = height
    }
}

public struct EndSurfaceHeightGridResult: Equatable, Sendable {
    public let request: EndSurfaceHeightGridRequest
    public let heights: [Int32]

    public init(request: EndSurfaceHeightGridRequest, heights: [Int32]) {
        self.request = request
        self.heights = heights
    }

    public func heightAt(x: Int32, z: Int32) -> Int32? {
        guard x >= 0, z >= 0, x < request.width, z < request.height else {
            return nil
        }
        return heights[Int(z * request.width + x)]
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

public struct StructurePieceSummary: Equatable, Sendable {
    public let name: String?
    public let type: Int32
    public let depth: Int32
    public let rotation: Int32
    public let position: BlockPosition3D
    public let boundingBoxMin: BlockPosition3D
    public let boundingBoxMax: BlockPosition3D

    public init(
        name: String?,
        type: Int32,
        depth: Int32,
        rotation: Int32,
        position: BlockPosition3D,
        boundingBoxMin: BlockPosition3D,
        boundingBoxMax: BlockPosition3D
    ) {
        self.name = name
        self.type = type
        self.depth = depth
        self.rotation = rotation
        self.position = position
        self.boundingBoxMin = boundingBoxMin
        self.boundingBoxMax = boundingBoxMax
    }
}

public struct BlockPosition3D: Equatable, Sendable {
    public let x: Int32
    public let y: Int32
    public let z: Int32

    public init(x: Int32, y: Int32, z: Int32) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct StructureVariantSummary: Equatable, Sendable {
    public let type: StructureType
    public let abandoned: Bool
    public let giant: Bool
    public let underground: Bool
    public let airPocket: Bool
    public let basement: Bool
    public let cracked: Bool
    public let size: Int32
    public let startPiece: Int32
    public let biomeID: Int32
    public let rotation: Int32
    public let mirror: Int32
    public let position: BlockPosition3D
    public let size3D: BlockPosition3D

    public init(
        type: StructureType,
        abandoned: Bool,
        giant: Bool,
        underground: Bool,
        airPocket: Bool,
        basement: Bool,
        cracked: Bool,
        size: Int32,
        startPiece: Int32,
        biomeID: Int32,
        rotation: Int32,
        mirror: Int32,
        position: BlockPosition3D,
        size3D: BlockPosition3D
    ) {
        self.type = type
        self.abandoned = abandoned
        self.giant = giant
        self.underground = underground
        self.airPocket = airPocket
        self.basement = basement
        self.cracked = cracked
        self.size = size
        self.startPiece = startPiece
        self.biomeID = biomeID
        self.rotation = rotation
        self.mirror = mirror
        self.position = position
        self.size3D = size3D
    }
}

public struct EndIslandInfo: Equatable, Sendable {
    public let x: Int32
    public let y: Int32
    public let z: Int32
    public let radius: Int32

    public init(x: Int32, y: Int32, z: Int32, radius: Int32) {
        self.x = x
        self.y = y
        self.z = z
        self.radius = radius
    }
}

public struct EndGatewayLink: Equatable, Sendable {
    public let source: BlockPosition
    public let destination: BlockPosition

    public init(source: BlockPosition, destination: BlockPosition) {
        self.source = source
        self.destination = destination
    }
}

public struct ClimateParameterRanges: Equatable, Sendable {
    public let temperature: ClosedRange<Int32>
    public let humidity: ClosedRange<Int32>
    public let continentalness: ClosedRange<Int32>
    public let erosion: ClosedRange<Int32>
    public let depth: ClosedRange<Int32>
    public let weirdness: ClosedRange<Int32>

    public init(
        temperature: ClosedRange<Int32>,
        humidity: ClosedRange<Int32>,
        continentalness: ClosedRange<Int32>,
        erosion: ClosedRange<Int32>,
        depth: ClosedRange<Int32>,
        weirdness: ClosedRange<Int32>
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.continentalness = continentalness
        self.erosion = erosion
        self.depth = depth
        self.weirdness = weirdness
    }
}

public struct BiomeAreaStatisticsRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seeds: [Int64]
    public let dimensions: [MinecraftDimension]
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32
    public let scale: Int32
    public let y: Int32
    public let sampleLimit: Int?

    public init(
        version: MinecraftVersion,
        seeds: [Int64],
        dimensions: [MinecraftDimension],
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        scale: Int32 = 4,
        y: Int32 = 63,
        sampleLimit: Int? = nil
    ) {
        self.version = version
        self.seeds = seeds
        self.dimensions = dimensions
        self.originX = originX
        self.originZ = originZ
        self.width = width
        self.height = height
        self.scale = scale
        self.y = y
        self.sampleLimit = sampleLimit
    }
}

public struct BiomeAreaStatistics: Equatable, Sendable {
    public let seed: Int64
    public let dimension: MinecraftDimension
    public let countsByBiomeID: [Int32: Int]
    public let distinctBiomeCount: Int
    public let sampledCellCount: Int

    public init(
        seed: Int64,
        dimension: MinecraftDimension,
        countsByBiomeID: [Int32: Int],
        distinctBiomeCount: Int,
        sampledCellCount: Int
    ) {
        self.seed = seed
        self.dimension = dimension
        self.countsByBiomeID = countsByBiomeID
        self.distinctBiomeCount = distinctBiomeCount
        self.sampledCellCount = sampledCellCount
    }
}

public struct BiomeFilterSpec: Equatable, Sendable {
    public let requiredBiomeIDs: [Int32]
    public let excludedBiomeIDs: [Int32]
    public let matchAnyBiomeIDs: [Int32]
    public let allowsApproximateFiltering: Bool
    public let forcesOceanVariants: Bool

    public init(
        requiredBiomeIDs: [Int32] = [],
        excludedBiomeIDs: [Int32] = [],
        matchAnyBiomeIDs: [Int32] = [],
        allowsApproximateFiltering: Bool = false,
        forcesOceanVariants: Bool = true
    ) {
        self.requiredBiomeIDs = requiredBiomeIDs
        self.excludedBiomeIDs = excludedBiomeIDs
        self.matchAnyBiomeIDs = matchAnyBiomeIDs
        self.allowsApproximateFiltering = allowsApproximateFiltering
        self.forcesOceanVariants = forcesOceanVariants
    }
}

public struct BiomeAreaFilterRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let dimension: MinecraftDimension
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32
    public let scale: Int32
    public let y: Int32
    public let filter: BiomeFilterSpec

    public init(
        version: MinecraftVersion,
        seed: Int64,
        dimension: MinecraftDimension,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        scale: Int32 = 4,
        y: Int32 = 63,
        filter: BiomeFilterSpec
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
        self.filter = filter
    }
}

public struct BiomeAreaFilterResult: Equatable, Sendable {
    public let request: BiomeAreaFilterRequest
    public let matched: Bool
    public let completedFullGeneration: Bool

    public init(request: BiomeAreaFilterRequest, matched: Bool, completedFullGeneration: Bool) {
        self.request = request
        self.matched = matched
        self.completedFullGeneration = completedFullGeneration
    }
}

public struct BiomeCenterRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32
    public let biomeID: Int32
    public let minimumSize: Int32
    public let tolerance: Int32
    public let maximumCount: Int32
    public let y: Int32

    public init(
        version: MinecraftVersion,
        seed: Int64,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        biomeID: Int32,
        minimumSize: Int32 = 1,
        tolerance: Int32 = 0,
        maximumCount: Int32 = 4096,
        y: Int32 = 63
    ) {
        self.version = version
        self.seed = seed
        self.originX = originX
        self.originZ = originZ
        self.width = width
        self.height = height
        self.biomeID = biomeID
        self.minimumSize = minimumSize
        self.tolerance = tolerance
        self.maximumCount = maximumCount
        self.y = y
    }
}

public struct BiomeCenter: Equatable, Sendable {
    public let biomeID: Int32
    public let position: BlockPosition
    public let size: Int32

    public init(biomeID: Int32, position: BlockPosition, size: Int32) {
        self.biomeID = biomeID
        self.position = position
        self.size = size
    }
}

public enum LocationSampleMode: Equatable, Sendable {
    case squareSpiral
    case radialGrid
}

public enum CubiomesQueryCondition: Equatable, Sendable {
    case biomeAt(relativeX: Int32, relativeZ: Int32, y: Int32, allowedBiomeIDs: [Int32])
    case biomeArea(relativeRect: StructureRect, scale: Int32, y: Int32, filter: BiomeFilterSpec)
    case structures(relativeRect: StructureRect, types: [StructureType], minimumCount: Int)
    case approximateHeight(relativeX: Int32, relativeZ: Int32, allowed: ClosedRange<Int32>)
}

public struct LocationSearchRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seeds: [Int64]
    public let dimension: MinecraftDimension
    public let positions: [BlockPosition]
    public let conditions: [CubiomesQueryCondition]
    public let maximumResults: Int

    public init(
        version: MinecraftVersion,
        seeds: [Int64],
        dimension: MinecraftDimension,
        positions: [BlockPosition],
        conditions: [CubiomesQueryCondition],
        maximumResults: Int = Int.max
    ) {
        self.version = version
        self.seeds = seeds
        self.dimension = dimension
        self.positions = positions
        self.conditions = conditions
        self.maximumResults = maximumResults
    }
}

public struct LocationSearchResult: Equatable, Sendable {
    public let seed: Int64
    public let position: BlockPosition

    public init(seed: Int64, position: BlockPosition) {
        self.seed = seed
        self.position = position
    }
}

public struct SeedSearchRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seeds: [Int64]
    public let dimension: MinecraftDimension
    public let conditions: [CubiomesQueryCondition]
    public let maximumResults: Int

    public init(
        version: MinecraftVersion,
        seeds: [Int64],
        dimension: MinecraftDimension,
        conditions: [CubiomesQueryCondition],
        maximumResults: Int = Int.max
    ) {
        self.version = version
        self.seeds = seeds
        self.dimension = dimension
        self.conditions = conditions
        self.maximumResults = maximumResults
    }
}

public struct QuadStructureSearchRequest: Equatable, Sendable {
    public let type: StructureType
    public let version: MinecraftVersion
    public let seed: Int64
    public let regionX: Int32
    public let regionZ: Int32
    public let regionWidth: Int32
    public let regionHeight: Int32
    public let maximumCount: Int32
    public let requiresViableBiomes: Bool

    public init(
        type: StructureType,
        version: MinecraftVersion,
        seed: Int64,
        regionX: Int32,
        regionZ: Int32,
        regionWidth: Int32,
        regionHeight: Int32,
        maximumCount: Int32 = 128,
        requiresViableBiomes: Bool = true
    ) {
        self.type = type
        self.version = version
        self.seed = seed
        self.regionX = regionX
        self.regionZ = regionZ
        self.regionWidth = regionWidth
        self.regionHeight = regionHeight
        self.maximumCount = maximumCount
        self.requiresViableBiomes = requiresViableBiomes
    }
}

public struct QuadStructureCluster: Equatable, Sendable {
    public let type: StructureType
    public let regionX: Int32
    public let regionZ: Int32
    public let attempts: [StructureLocation]
    public let afkPosition: BlockPosition
    public let spawningSpaces: Int32
    public let enclosingRadius: Float

    public init(
        type: StructureType,
        regionX: Int32,
        regionZ: Int32,
        attempts: [StructureLocation],
        afkPosition: BlockPosition,
        spawningSpaces: Int32,
        enclosingRadius: Float
    ) {
        self.type = type
        self.regionX = regionX
        self.regionZ = regionZ
        self.attempts = attempts
        self.afkPosition = afkPosition
        self.spawningSpaces = spawningSpaces
        self.enclosingRadius = enclosingRadius
    }
}

public enum CubiomesError: Error, Equatable, Sendable {
    case biomeLookupFailed
    case unsupportedBiome(id: Int32)
    case invalidBiomeGridSize(width: Int32, height: Int32)
    case unsupportedBiomeScale(scale: Int32, supported: [Int32])
    case biomeGridAllocationFailed
    case biomeGridGenerationFailed(code: Int32)
    case invalidStructureRect
    case unsupportedStructure(StructureType, version: MinecraftVersion, dimension: MinecraftDimension)
    case unsupportedStructureConfig(StructureType, version: MinecraftVersion)
    case unsupportedStructureBiomeCheck(StructureType, version: MinecraftVersion)
    case approximateHeightMappingFailed(code: Int32)
    case endBiomeGridGenerationFailed(code: Int32)
    case netherBiomeGridGenerationFailed(code: Int32)
    case invalidVolumeSize(width: Int32, height: Int32, depth: Int32)
    case unsupportedStructureVariant(StructureType, version: MinecraftVersion)
    case unsupportedStructurePieces(StructureType)
    case unsupportedBiomeFilterScale(scale: Int32)
    case invalidSearchLimit(Int)
    case unsupportedQuadSearch(StructureType, version: MinecraftVersion)
    case quadSearchFailed
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

    fileprivate static func validateGridLike(width: Int32, height: Int32) throws {
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

    fileprivate static func validateSearchLimit(_ limit: Int) throws {
        guard limit >= 0 else {
            throw CubiomesError.invalidSearchLimit(limit)
        }
    }

    fileprivate static func validateVolume(width: Int32, height: Int32, depth: Int32) throws {
        guard width > 0, height > 0, depth > 0 else {
            throw CubiomesError.invalidVolumeSize(width: width, height: height, depth: depth)
        }
        guard Int64(width) * Int64(height) * Int64(depth) <= Int64(Int32.max) else {
            throw CubiomesError.invalidVolumeSize(width: width, height: height, depth: depth)
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
    public static func mapTile(_ request: MapTileRequest) throws -> MapTileResult {
        let world = CubiomesWorld(version: request.version, seed: request.seed, dimension: request.dimension)
        return try world.mapTile(request)
    }

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

    public static func biomeClassification(id: Int32) -> BiomeClassification {
        BiomeClassification(
            id: id,
            isMesa: CCubiomes.isMesa(id) != 0,
            isShallowOcean: CCubiomes.isShallowOcean(id) != 0,
            isDeepOcean: CCubiomes.isDeepOcean(id) != 0,
            isOceanic: CCubiomes.isOceanic(id) != 0,
            isSnowy: CCubiomes.isSnowy(id) != 0
        )
    }

    public static func biomeTerrainInfo(id: Int32) throws -> BiomeTerrainInfo {
        var depth = Double(0)
        var scale = Double(0)
        var grass = Int32(0)
        guard getBiomeDepthAndScale(id, &depth, &scale, &grass) != 0 else {
            throw CubiomesError.unsupportedBiome(id: id)
        }
        return BiomeTerrainInfo(id: id, depth: depth, scale: scale, grass: grass)
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

    public static func netherBiomes(
        seed: Int64,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32
    ) throws -> NetherBiomeGridResult {
        try netherBiomes(NetherBiomeGridRequest(
            seed: seed,
            originX: originX,
            originZ: originZ,
            width: width,
            height: height
        ))
    }

    public static func netherBiomes(_ request: NetherBiomeGridRequest) throws -> NetherBiomeGridResult {
        try CubiomesWorld.validateGridLike(width: request.width, height: request.height)

        let count = Int(Int64(request.width) * Int64(request.height))
        var ids = Array(repeating: Int32(0), count: count)
        var noise = NetherNoise()
        setNetherSeed(&noise, UInt64(bitPattern: request.seed))
        let code = ids.withUnsafeMutableBufferPointer {
            mapNether2D(&noise, $0.baseAddress, request.originX, request.originZ, request.width, request.height)
        }
        guard code == 0 else {
            throw CubiomesError.netherBiomeGridGenerationFailed(code: code)
        }
        return NetherBiomeGridResult(request: request, ids: ids)
    }

    public static func netherBiomeVolume(_ request: NetherBiomeVolumeRequest) throws -> NetherBiomeVolumeResult {
        try CubiomesWorld.validateVolume(width: request.width, height: request.height, depth: request.depth)

        let count = Int(Int64(request.width) * Int64(request.height) * Int64(request.depth))
        var ids = Array(repeating: Int32(0), count: count)
        var noise = NetherNoise()
        setNetherSeed(&noise, UInt64(bitPattern: request.seed))
        let range = Range(
            scale: 4,
            x: request.originX,
            z: request.originZ,
            sx: request.width,
            sz: request.depth,
            y: request.originY,
            sy: request.height
        )
        let code = ids.withUnsafeMutableBufferPointer {
            mapNether3D(&noise, $0.baseAddress, range, request.confidence)
        }
        guard code == 0 else {
            throw CubiomesError.netherBiomeGridGenerationFailed(code: code)
        }
        return NetherBiomeVolumeResult(request: request, ids: ids)
    }

    public static func endBiomes(
        version: MinecraftVersion,
        seed: Int64,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        scale: Int32 = 4
    ) throws -> EndBiomeGridResult {
        try endBiomes(EndBiomeGridRequest(
            version: version,
            seed: seed,
            originX: originX,
            originZ: originZ,
            width: width,
            height: height,
            scale: scale
        ))
    }

    public static func endBiomes(_ request: EndBiomeGridRequest) throws -> EndBiomeGridResult {
        try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
        guard [4, 16].contains(request.scale) else {
            throw CubiomesError.unsupportedBiomeScale(scale: request.scale, supported: [4, 16])
        }

        let count = Int(Int64(request.width) * Int64(request.height))
        var ids = Array(repeating: Int32(0), count: count)
        var noise = EndNoise()
        setEndSeed(&noise, request.version.rawValue, UInt64(bitPattern: request.seed))
        let code = ids.withUnsafeMutableBufferPointer { buffer in
            if request.scale == 16 {
                return mapEndBiome(&noise, buffer.baseAddress, request.originX, request.originZ, request.width, request.height)
            }
            return mapEnd(&noise, buffer.baseAddress, request.originX, request.originZ, request.width, request.height)
        }
        guard code == 0 else {
            throw CubiomesError.endBiomeGridGenerationFailed(code: code)
        }
        return EndBiomeGridResult(request: request, ids: ids)
    }

    public static func endSurfaceHeights(_ request: EndSurfaceHeightGridRequest) throws -> EndSurfaceHeightGridResult {
        try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
        var heights: [Int32] = []
        heights.reserveCapacity(Int(request.width * request.height))
        for z in 0..<request.height {
            for x in 0..<request.width {
                heights.append(endSurfaceHeight(
                    version: request.version,
                    seed: request.seed,
                    x: request.originX + x,
                    z: request.originZ + z
                ))
            }
        }
        return EndSurfaceHeightGridResult(request: request, heights: heights)
    }

    public static func endChunkAnalysis(version: MinecraftVersion, seed: Int64, chunkX: Int32, chunkZ: Int32) -> EndChunkAnalysis {
        var endNoise = EndNoise()
        setEndSeed(&endNoise, version.rawValue, UInt64(bitPattern: seed))
        var surfaceNoise = SurfaceNoise()
        initSurfaceNoise(&surfaceNoise, MinecraftDimension.end.rawValue, UInt64(bitPattern: seed))
        let empty = isEndChunkEmpty(&endNoise, &surfaceNoise, UInt64(bitPattern: seed), chunkX, chunkZ) != 0
        return EndChunkAnalysis(
            version: version,
            seed: seed,
            chunkX: chunkX,
            chunkZ: chunkZ,
            isEmpty: empty,
            islands: endIslands(version: version, seed: seed, chunkX: chunkX, chunkZ: chunkZ)
        )
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

    public static func endIslands(version: MinecraftVersion, seed: Int64, chunkX: Int32, chunkZ: Int32) -> [EndIslandInfo] {
        var islands = Array(repeating: EndIsland(), count: 2)
        let count = islands.withUnsafeMutableBufferPointer {
            getEndIslands($0.baseAddress, version.rawValue, UInt64(bitPattern: seed), chunkX, chunkZ)
        }
        guard count > 0 else {
            return []
        }
        return islands.prefix(Int(count)).map {
            EndIslandInfo(x: Int32($0.x), y: Int32($0.y), z: Int32($0.z), radius: Int32($0.r))
        }
    }

    public static func fixedEndGateways(version: MinecraftVersion, seed: Int64) -> [BlockPosition] {
        var positions = Array(repeating: Pos(), count: 20)
        positions.withUnsafeMutableBufferPointer {
            getFixedEndGateways(version.rawValue, UInt64(bitPattern: seed), $0.baseAddress)
        }
        return positions.map { BlockPosition(x: Int32($0.x), z: Int32($0.z)) }
    }

    public static func linkedEndGateway(version: MinecraftVersion, seed: Int64, source: BlockPosition) -> EndGatewayLink {
        var endNoise = EndNoise()
        setEndSeed(&endNoise, version.rawValue, UInt64(bitPattern: seed))
        var surfaceNoise = SurfaceNoise()
        initSurfaceNoise(&surfaceNoise, MinecraftDimension.end.rawValue, UInt64(bitPattern: seed))
        let destination = getLinkedGatewayPos(
            &endNoise,
            &surfaceNoise,
            UInt64(bitPattern: seed),
            Pos(x: source.x, z: source.z)
        )
        return EndGatewayLink(
            source: source,
            destination: BlockPosition(x: Int32(destination.x), z: Int32(destination.z))
        )
    }

    public static func endSurfaceHeight(version: MinecraftVersion, seed: Int64, x: Int32, z: Int32) -> Int32 {
        Int32(getEndSurfaceHeight(version.rawValue, UInt64(bitPattern: seed), x, z))
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

    public static func climateParameterExtremes(version: MinecraftVersion) -> ClimateParameterRanges? {
        climateRanges(from: getBiomeParaExtremes(version.rawValue))
    }

    public static func climateParameterLimits(version: MinecraftVersion, biomeID: Int32) -> ClimateParameterRanges? {
        climateRanges(from: getBiomeParaLimits(version.rawValue, biomeID))
    }

    public static func biomeAreaStatistics(
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

    public static func biomeAreaFilter(_ request: BiomeAreaFilterRequest) throws -> BiomeAreaFilterResult {
        try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
        guard [1, 4, 16, 64, 256].contains(request.scale) else {
            throw CubiomesError.unsupportedBiomeFilterScale(scale: request.scale)
        }

        var generator = Generator()
        setupGenerator(&generator, request.version.rawValue, request.filter.generatorFlags)
        var filter = request.filter.makeCFilter(version: request.version)
        let range = Range(
            scale: request.scale,
            x: request.originX,
            z: request.originZ,
            sx: request.width,
            sz: request.height,
            y: request.scale == 1 ? request.y : request.y >> 2,
            sy: 1
        )
        let code = checkForBiomes(
            &generator,
            nil,
            range,
            request.dimension.rawValue,
            UInt64(bitPattern: request.seed),
            &filter,
            nil
        )
        return BiomeAreaFilterResult(request: request, matched: code > 0, completedFullGeneration: code == 1)
    }

    public static func biomeCenters(_ request: BiomeCenterRequest) throws -> [BiomeCenter] {
        try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
        guard biomeExists(request.version.rawValue, request.biomeID) != 0 else {
            throw CubiomesError.unsupportedBiome(id: request.biomeID)
        }
        if request.version.rawValue >= MinecraftVersion.v1_18.rawValue {
            guard getBiomeParaLimits(request.version.rawValue, request.biomeID) != nil else {
                throw CubiomesError.unsupportedBiome(id: request.biomeID)
            }
        }
        guard request.maximumCount > 0 else {
            return []
        }
        var generator = Generator()
        setupGenerator(&generator, request.version.rawValue, 0)
        applySeed(&generator, MinecraftDimension.overworld.rawValue, UInt64(bitPattern: request.seed))
        let range = Range(
            scale: 4,
            x: request.originX,
            z: request.originZ,
            sx: request.width,
            sz: request.height,
            y: request.y >> 2,
            sy: 1
        )
        var positions = Array(repeating: Pos(), count: Int(request.maximumCount))
        var sizes = Array(repeating: Int32(0), count: Int(request.maximumCount))
        let found = positions.withUnsafeMutableBufferPointer { positionBuffer in
            sizes.withUnsafeMutableBufferPointer { sizeBuffer in
                getBiomeCenters(
                    positionBuffer.baseAddress,
                    sizeBuffer.baseAddress,
                    request.maximumCount,
                    &generator,
                    range,
                    request.biomeID,
                    request.minimumSize,
                    request.tolerance,
                    nil
                )
            }
        }
        guard found > 0 else {
            return []
        }
        return (0..<min(Int(found), positions.count)).map { index in
            BiomeCenter(
                biomeID: request.biomeID,
                position: BlockPosition(x: Int32(positions[index].x), z: Int32(positions[index].z)),
                size: sizes[index]
            )
        }
    }

    public static func locationSamples(
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

    public static func findLocations(
        _ request: LocationSearchRequest,
        shouldCancel: (() -> Bool)? = nil
    ) throws -> [LocationSearchResult] {
        try CubiomesWorld.validateSearchLimit(request.maximumResults)
        guard request.maximumResults > 0 else { return [] }
        var results: [LocationSearchResult] = []
        for seed in request.seeds {
            for position in request.positions {
                if shouldCancel?() == true {
                    return results
                }
                if try matchesAll(request.conditions, version: request.version, seed: seed, dimension: request.dimension, at: position) {
                    results.append(LocationSearchResult(seed: seed, position: position))
                    if results.count >= request.maximumResults {
                        return results
                    }
                }
            }
        }
        return results
    }

    public static func findSeeds(
        _ request: SeedSearchRequest,
        shouldCancel: (() -> Bool)? = nil
    ) throws -> [Int64] {
        try CubiomesWorld.validateSearchLimit(request.maximumResults)
        guard request.maximumResults > 0 else { return [] }
        var results: [Int64] = []
        for seed in request.seeds {
            if shouldCancel?() == true {
                return results
            }
            if try matchesAll(request.conditions, version: request.version, seed: seed, dimension: request.dimension, at: BlockPosition(x: 0, z: 0)) {
                results.append(seed)
                if results.count >= request.maximumResults {
                    return results
                }
            }
        }
        return results
    }

    public static func quadStructureClusters(_ request: QuadStructureSearchRequest) throws -> [QuadStructureCluster] {
        guard request.maximumCount > 0 else { return [] }
        guard request.type == .swampHut,
              let requestedCType = request.type.cubiomesType else {
            throw CubiomesError.unsupportedQuadSearch(request.type, version: request.version)
        }
        var config = StructureConfig()
        guard getStructureConfig(requestedCType, request.version.rawValue, &config) != 0 else {
            throw CubiomesError.unsupportedQuadSearch(request.type, version: request.version)
        }
        var rawPositions = Array(repeating: Pos(), count: Int(request.maximumCount))
        var lowBits: [UInt64] = [
            0x1272d, 0x17908, 0x367b9, 0x43f18, 0x487c9, 0x487ce, 0x50aa7,
            0x647b5, 0x65118, 0x75618, 0x79a0a, 0x89718, 0x9371a, 0x967ec,
            0xa3d0a, 0xa5918, 0xa591d, 0xa5a08, 0xb5e18, 0xc6749, 0xc6d9a,
            0xc751a, 0xd7108, 0xd717a, 0xe2739, 0xe9918, 0xee1c4, 0xf520a, 0
        ]
        let found = rawPositions.withUnsafeMutableBufferPointer { outBuffer in
            lowBits.withUnsafeMutableBufferPointer { lowBitBuffer in
                scanForQuads(
                    config,
                    128,
                    UInt64(bitPattern: request.seed) & lower48Mask,
                    lowBitBuffer.baseAddress,
                    20,
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
            let afk = attemptPositions.withUnsafeMutableBufferPointer {
                getOptimalAfk($0.baseAddress, 7, 7, 9, &spawningSpaces)
            }
            let movedSeed = moveStructure(UInt64(bitPattern: request.seed), -Int32(region.x), -Int32(region.z))
            let radius = isQuadBase(config, movedSeed, 160)
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

private extension StructureType {
    var supportsFeatureBiomeCheck: Bool {
        switch self {
        case .desertPyramid, .jungleTemple, .swampHut, .igloo, .oceanRuin, .shipwreck,
             .ruinedPortal, .netherRuinedPortal, .ancientCity, .treasure, .mineshaft,
             .desertWell, .fortress, .bastion, .endCity, .endGateway, .trailRuins,
             .trialChambers, .monument, .outpost, .village, .mansion:
            return true
        case .feature, .geode, .endIsland, .stronghold, .slimeChunk:
            return false
        }
    }
}

private let lower48Mask: UInt64 = 0x0000ffffffffffff

private extension BiomeFilterSpec {
    var generatorFlags: UInt32 {
        var flags = UInt32(0)
        if forcesOceanVariants {
            flags |= UInt32(BF_FORCED_OCEAN)
        }
        return flags
    }

    var filterFlags: UInt32 {
        var flags = generatorFlags
        if allowsApproximateFiltering {
            flags |= UInt32(BF_APPROX)
        }
        return flags
    }

    func makeCFilter(version: MinecraftVersion) -> BiomeFilter {
        var filter = BiomeFilter()
        var required = requiredBiomeIDs
        var excluded = excludedBiomeIDs
        var matchAny = matchAnyBiomeIDs
        required.withUnsafeMutableBufferPointer { requiredBuffer in
            excluded.withUnsafeMutableBufferPointer { excludedBuffer in
                matchAny.withUnsafeMutableBufferPointer { matchAnyBuffer in
                    setupBiomeFilter(
                        &filter,
                        version.rawValue,
                        filterFlags,
                        requiredBuffer.baseAddress,
                        Int32(requiredBuffer.count),
                        excludedBuffer.baseAddress,
                        Int32(excludedBuffer.count),
                        matchAnyBuffer.baseAddress,
                        Int32(matchAnyBuffer.count)
                    )
                }
            }
        }
        return filter
    }
}

private extension StructureRect {
    func offset(by position: BlockPosition) -> StructureRect {
        StructureRect(
            minX: minX + position.x,
            minZ: minZ + position.z,
            maxX: maxX + position.x,
            maxZ: maxZ + position.z
        )
    }
}

private func pieceSummaries(from pieces: [Piece], count: Int32) -> [StructurePieceSummary] {
    guard count > 0 else {
        return []
    }
    return (0..<min(Int(count), pieces.count)).map { index in
        let piece = pieces[index]
        let name = piece.name.map { String(cString: $0) }
        return StructurePieceSummary(
            name: name,
            type: Int32(piece.type),
            depth: Int32(piece.depth),
            rotation: Int32(piece.rot),
            position: BlockPosition3D(x: Int32(piece.pos.x), y: Int32(piece.pos.y), z: Int32(piece.pos.z)),
            boundingBoxMin: BlockPosition3D(x: Int32(piece.bb0.x), y: Int32(piece.bb0.y), z: Int32(piece.bb0.z)),
            boundingBoxMax: BlockPosition3D(x: Int32(piece.bb1.x), y: Int32(piece.bb1.y), z: Int32(piece.bb1.z))
        )
    }
}

private func matchesAll(
    _ conditions: [CubiomesQueryCondition],
    version: MinecraftVersion,
    seed: Int64,
    dimension: MinecraftDimension,
    at position: BlockPosition
) throws -> Bool {
    for condition in conditions {
        guard try matches(condition, version: version, seed: seed, dimension: dimension, at: position) else {
            return false
        }
    }
    return true
}

private func matches(
    _ condition: CubiomesQueryCondition,
    version: MinecraftVersion,
    seed: Int64,
    dimension: MinecraftDimension,
    at position: BlockPosition
) throws -> Bool {
    switch condition {
    case let .biomeAt(relativeX, relativeZ, y, allowedBiomeIDs):
        let biome = try CubiomesCore.biome(
            version: version,
            seed: seed,
            dimension: dimension,
            x: position.x + relativeX,
            y: y,
            z: position.z + relativeZ
        )
        return allowedBiomeIDs.contains(biome.id)

    case let .biomeArea(relativeRect, scale, y, filter):
        let rect = relativeRect.offset(by: position)
        let scaled = scaledCellRect(rect, scale: scale)
        let result = try CubiomesCore.biomeAreaFilter(BiomeAreaFilterRequest(
            version: version,
            seed: seed,
            dimension: dimension,
            originX: scaled.originX,
            originZ: scaled.originZ,
            width: scaled.width,
            height: scaled.height,
            scale: scale,
            y: y,
            filter: filter
        ))
        return result.matched

    case let .structures(relativeRect, types, minimumCount):
        let rect = relativeRect.offset(by: position)
        let locations = try CubiomesCore.structures(
            version: version,
            seed: seed,
            dimension: dimension,
            types: types,
            rect: rect
        )
        return locations.count >= minimumCount

    case let .approximateHeight(relativeX, relativeZ, allowed):
        let grid = try CubiomesCore.approximateHeights(
            version: version,
            seed: seed,
            dimension: dimension,
            originX: floorDiv(position.x + relativeX, 4),
            originZ: floorDiv(position.z + relativeZ, 4),
            width: 1,
            height: 1
        )
        guard let height = grid.heightAt(x: 0, z: 0) else {
            return false
        }
        return allowed.contains(Int32(height))
    }
}

private func scaledCellRect(_ rect: StructureRect, scale: Int32) -> (originX: Int32, originZ: Int32, width: Int32, height: Int32) {
    let x0 = floorDiv(rect.minX, scale)
    let z0 = floorDiv(rect.minZ, scale)
    let x1 = floorDiv(rect.maxX - 1, scale)
    let z1 = floorDiv(rect.maxZ - 1, scale)
    return (x0, z0, x1 - x0 + 1, z1 - z0 + 1)
}

private func climateRanges(from pointer: UnsafePointer<Int32>?) -> ClimateParameterRanges? {
    guard let pointer else {
        return nil
    }
    let values = UnsafeBufferPointer(start: pointer, count: 12).map { Int32($0) }
    return ClimateParameterRanges(
        temperature: values[0]...values[1],
        humidity: values[2]...values[3],
        continentalness: values[4]...values[5],
        erosion: values[6]...values[7],
        depth: values[8]...values[9],
        weirdness: values[10]...values[11]
    )
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
