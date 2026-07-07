import CCubiomes
import Foundation

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

    var cubiomesType: Int32? {
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

public enum ClimateNoiseParameter: Int32, CaseIterable, Sendable {
    case temperature = 0
    case humidity = 1
    case continentalness = 2
    case erosion = 3
    case depth = 4
    case weirdness = 5
}

public struct ClimateBiomePossibilityRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let ranges: ClimateParameterRanges

    public init(version: MinecraftVersion, ranges: ClimateParameterRanges) {
        self.version = version
        self.ranges = ranges
    }
}

public struct ClimateBiomePossibilityResult: Equatable, Sendable {
    public let request: ClimateBiomePossibilityRequest
    public let biomeIDs: [Int32]

    public init(request: ClimateBiomePossibilityRequest, biomeIDs: [Int32]) {
        self.request = request
        self.biomeIDs = biomeIDs
    }
}

public struct LargestRectangleAnalysisRequest: Equatable, Sendable {
    public let ids: [Int32]
    public let width: Int32
    public let height: Int32
    public let matchingID: Int32

    public init(ids: [Int32], width: Int32, height: Int32, matchingID: Int32) {
        self.ids = ids
        self.width = width
        self.height = height
        self.matchingID = matchingID
    }
}

public struct LargestRectangleAnalysisResult: Equatable, Sendable {
    public let request: LargestRectangleAnalysisRequest
    public let area: Int32
    public let min: BlockPosition
    public let max: BlockPosition

    public init(request: LargestRectangleAnalysisRequest, area: Int32, min: BlockPosition, max: BlockPosition) {
        self.request = request
        self.area = area
        self.min = min
        self.max = max
    }
}

public struct MonteCarloBiomeSampleRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let dimension: MinecraftDimension
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32
    public let scale: Int32
    public let y: Int32
    public let requiredCoverage: Double
    public let confidence: Double
    public let allowedBiomeIDs: [Int32]
    public let excludedBiomeIDs: [Int32]

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
        requiredCoverage: Double,
        confidence: Double,
        allowedBiomeIDs: [Int32],
        excludedBiomeIDs: [Int32] = []
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
        self.requiredCoverage = requiredCoverage
        self.confidence = confidence
        self.allowedBiomeIDs = allowedBiomeIDs
        self.excludedBiomeIDs = excludedBiomeIDs
    }
}

public struct MonteCarloBiomeSampleResult: Equatable, Sendable {
    public let request: MonteCarloBiomeSampleRequest
    public let matched: Bool
    public let evaluatedSampleCount: Int
    public let successfulSampleCount: Int
    public let skippedSampleCount: Int
    public let averageSuccessPosition: BlockPosition?

    public init(
        request: MonteCarloBiomeSampleRequest,
        matched: Bool,
        evaluatedSampleCount: Int,
        successfulSampleCount: Int,
        skippedSampleCount: Int,
        averageSuccessPosition: BlockPosition?
    ) {
        self.request = request
        self.matched = matched
        self.evaluatedSampleCount = evaluatedSampleCount
        self.successfulSampleCount = successfulSampleCount
        self.skippedSampleCount = skippedSampleCount
        self.averageSuccessPosition = averageSuccessPosition
    }
}

public struct MonteCarloClimateNoiseSampleRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32
    public let scale: Int32
    public let parameter: ClimateNoiseParameter
    public let allowed: ClosedRange<Int32>
    public let requiredCoverage: Double
    public let confidence: Double

    public init(
        version: MinecraftVersion,
        seed: Int64,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        scale: Int32 = 4,
        parameter: ClimateNoiseParameter,
        allowed: ClosedRange<Int32>,
        requiredCoverage: Double,
        confidence: Double
    ) {
        self.version = version
        self.seed = seed
        self.originX = originX
        self.originZ = originZ
        self.width = width
        self.height = height
        self.scale = scale
        self.parameter = parameter
        self.allowed = allowed
        self.requiredCoverage = requiredCoverage
        self.confidence = confidence
    }
}

public struct MonteCarloClimateNoiseSampleResult: Equatable, Sendable {
    public let request: MonteCarloClimateNoiseSampleRequest
    public let matched: Bool
    public let evaluatedSampleCount: Int
    public let successfulSampleCount: Int
    public let averageSuccessPosition: BlockPosition?

    public init(
        request: MonteCarloClimateNoiseSampleRequest,
        matched: Bool,
        evaluatedSampleCount: Int,
        successfulSampleCount: Int,
        averageSuccessPosition: BlockPosition?
    ) {
        self.request = request
        self.matched = matched
        self.evaluatedSampleCount = evaluatedSampleCount
        self.successfulSampleCount = successfulSampleCount
        self.averageSuccessPosition = averageSuccessPosition
    }
}

public struct ClimateNoiseRangeRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seed: Int64
    public let originX: Int32
    public let originZ: Int32
    public let width: Int32
    public let height: Int32
    public let parameter: ClimateNoiseParameter

    public init(
        version: MinecraftVersion,
        seed: Int64,
        originX: Int32,
        originZ: Int32,
        width: Int32,
        height: Int32,
        parameter: ClimateNoiseParameter
    ) {
        self.version = version
        self.seed = seed
        self.originX = originX
        self.originZ = originZ
        self.width = width
        self.height = height
        self.parameter = parameter
    }
}

public struct ClimateNoiseRangeResult: Equatable, Sendable {
    public let request: ClimateNoiseRangeRequest
    public let minimum: Double
    public let maximum: Double
    public let minimumPosition: BlockPosition
    public let maximumPosition: BlockPosition

    public init(
        request: ClimateNoiseRangeRequest,
        minimum: Double,
        maximum: Double,
        minimumPosition: BlockPosition,
        maximumPosition: BlockPosition
    ) {
        self.request = request
        self.minimum = minimum
        self.maximum = maximum
        self.minimumPosition = minimumPosition
        self.maximumPosition = maximumPosition
    }

    public var scaledMinimum: Int32 {
        Int32(minimum)
    }

    public var scaledMaximum: Int32 {
        Int32(maximum)
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

public indirect enum CubiomesQueryCondition: Equatable, Sendable {
    case all([CubiomesQueryCondition])
    case any([CubiomesQueryCondition])
    case not(CubiomesQueryCondition)
    case reference(String)
    case at(relativeX: Int32, relativeZ: Int32, condition: CubiomesQueryCondition)
    case scaledCoordinates(numerator: Int32, denominator: Int32, condition: CubiomesQueryCondition)
    case biomeAt(relativeX: Int32, relativeZ: Int32, y: Int32, allowedBiomeIDs: [Int32])
    case biomeIsPossibleForClimate(relativeX: Int32, relativeZ: Int32, y: Int32, ranges: ClimateParameterRanges)
    case biomeArea(relativeRect: StructureRect, scale: Int32, y: Int32, filter: BiomeFilterSpec)
    case monteCarloBiomeSample(
        relativeRect: StructureRect,
        scale: Int32,
        y: Int32,
        requiredCoverage: Double,
        confidence: Double,
        allowedBiomeIDs: [Int32],
        excludedBiomeIDs: [Int32]
    )
    case monteCarloClimateNoiseSample(
        relativeRect: StructureRect,
        scale: Int32,
        parameter: ClimateNoiseParameter,
        allowed: ClosedRange<Int32>,
        requiredCoverage: Double,
        confidence: Double
    )
    case climateNoiseRange(relativeRect: StructureRect, parameter: ClimateNoiseParameter, allowed: ClosedRange<Int32>)
    case structures(relativeRect: StructureRect, types: [StructureType], minimumCount: Int)
    case structureCombination(relativeRect: StructureRect, requirements: [StructureCombinationRequirement])
    case approximateHeight(relativeX: Int32, relativeZ: Int32, allowed: ClosedRange<Int32>)
}

public enum CubiomesSearchKind: Equatable, Sendable {
    case seed
    case location
}

public struct CubiomesSearchProgress: Equatable, Sendable {
    public let kind: CubiomesSearchKind
    public let checkedSeeds: Int
    public let checkedLocations: Int
    public let matchedResults: Int
    public let maximumResults: Int
    public let currentSeed: Int64?
    public let currentPosition: BlockPosition?

    public init(
        kind: CubiomesSearchKind,
        checkedSeeds: Int,
        checkedLocations: Int,
        matchedResults: Int,
        maximumResults: Int,
        currentSeed: Int64?,
        currentPosition: BlockPosition?
    ) {
        self.kind = kind
        self.checkedSeeds = checkedSeeds
        self.checkedLocations = checkedLocations
        self.matchedResults = matchedResults
        self.maximumResults = maximumResults
        self.currentSeed = currentSeed
        self.currentPosition = currentPosition
    }
}

public final class CubiomesSearchCancellationToken: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    public init() {}

    public func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }
}

public struct LocationSearchRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seeds: [Int64]
    public let dimension: MinecraftDimension
    public let positions: [BlockPosition]
    public let conditions: [CubiomesQueryCondition]
    public let conditionReferences: [String: CubiomesQueryCondition]
    public let maximumResults: Int

    public init(
        version: MinecraftVersion,
        seeds: [Int64],
        dimension: MinecraftDimension,
        positions: [BlockPosition],
        conditions: [CubiomesQueryCondition],
        conditionReferences: [String: CubiomesQueryCondition] = [:],
        maximumResults: Int = Int.max
    ) {
        self.version = version
        self.seeds = seeds
        self.dimension = dimension
        self.positions = positions
        self.conditions = conditions
        self.conditionReferences = conditionReferences
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
    public let conditionReferences: [String: CubiomesQueryCondition]
    public let maximumResults: Int

    public init(
        version: MinecraftVersion,
        seeds: [Int64],
        dimension: MinecraftDimension,
        conditions: [CubiomesQueryCondition],
        conditionReferences: [String: CubiomesQueryCondition] = [:],
        maximumResults: Int = Int.max
    ) {
        self.version = version
        self.seeds = seeds
        self.dimension = dimension
        self.conditions = conditions
        self.conditionReferences = conditionReferences
        self.maximumResults = maximumResults
    }
}

public struct StructureCombinationRequirement: Equatable, Sendable {
    public let type: StructureType
    public let minimumCount: Int
    public let requiresViable: Bool

    public init(type: StructureType, minimumCount: Int = 1, requiresViable: Bool = false) {
        self.type = type
        self.minimumCount = minimumCount
        self.requiresViable = requiresViable
    }
}

public struct StructureCombinationSearchRequest: Equatable, Sendable {
    public let version: MinecraftVersion
    public let seeds: [Int64]
    public let dimension: MinecraftDimension
    public let rect: StructureRect
    public let requirements: [StructureCombinationRequirement]
    public let maximumResults: Int

    public init(
        version: MinecraftVersion,
        seeds: [Int64],
        dimension: MinecraftDimension,
        rect: StructureRect,
        requirements: [StructureCombinationRequirement],
        maximumResults: Int = Int.max
    ) {
        self.version = version
        self.seeds = seeds
        self.dimension = dimension
        self.rect = rect
        self.requirements = requirements
        self.maximumResults = maximumResults
    }
}

public struct StructureCombinationSearchResult: Equatable, Sendable {
    public let seed: Int64
    public let rect: StructureRect
    public let matchingLocations: [StructureLocation]
    public let countsByType: [StructureType: Int]

    public init(
        seed: Int64,
        rect: StructureRect,
        matchingLocations: [StructureLocation],
        countsByType: [StructureType: Int]
    ) {
        self.seed = seed
        self.rect = rect
        self.matchingLocations = matchingLocations
        self.countsByType = countsByType
    }
}

public enum QuadMonumentCoverage: Int32, Equatable, Sendable {
    case ninetyPercent = 90
    case ninetyFivePercent = 95
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
    public let monumentCoverage: QuadMonumentCoverage

    public init(
        type: StructureType,
        version: MinecraftVersion,
        seed: Int64,
        regionX: Int32,
        regionZ: Int32,
        regionWidth: Int32,
        regionHeight: Int32,
        maximumCount: Int32 = 128,
        requiresViableBiomes: Bool = true,
        monumentCoverage: QuadMonumentCoverage = .ninetyPercent
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
        self.monumentCoverage = monumentCoverage
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
    case invalidCoordinateScale(numerator: Int32, denominator: Int32)
    case invalidGridCellCount(expected: Int, actual: Int)
    case invalidMonteCarloParameters
    case unsupportedClimateNoise(MinecraftVersion)
    case unsupportedClimateNoiseParameter(ClimateNoiseParameter)
    case climateNoiseRangeFailed
    case missingConditionReference(String)
    case recursiveConditionReference(String)
    case unsupportedQuadSearch(StructureType, version: MinecraftVersion)
    case quadSearchFailed
}
