import CCubiomes

#if os(Linux)
import Glibc
#else
import Darwin
#endif

extension StructureType {
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

    func quadSearchLowBits(monumentCoverage: QuadMonumentCoverage = .ninetyPercent) -> [UInt64] {
        switch self {
        case .swampHut:
            return [
                0x1272d, 0x17908, 0x367b9, 0x43f18, 0x487c9, 0x487ce, 0x50aa7,
                0x647b5, 0x65118, 0x75618, 0x79a0a, 0x89718, 0x9371a, 0x967ec,
                0xa3d0a, 0xa5918, 0xa591d, 0xa5a08, 0xb5e18, 0xc6749, 0xc6d9a,
                0xc751a, 0xd7108, 0xd717a, 0xe2739, 0xe9918, 0xee1c4, 0xf520a, 0,
            ]
        case .monument:
            if monumentCoverage == .ninetyFivePercent {
                return [
                    775_390_004_760, 40_643_008_242_473, 75_345_282_835_555,
                    85_241_165_147_001, 117_558_666_299_491, 141_849_622_061_865,
                    157_050_661_340_383, 184_103_120_915_339, 197_672_678_105_184,
                    201_305_970_722_015, 220_178_926_586_908, 206_145_729_365_528,
                    226_043_537_443_714, 143_737_608_964_985, 0,
                ]
            }
            return [
                35_634_735_275, 775_390_004_760, 3_752_034_493_314, 6_745_625_093_360,
                8_462_966_022_953, 9_735_142_779_473, 10_800_310_675_623, 11_692_781_183_913,
                15_412_128_852_232, 17_507_542_501_908, 20_824_655_119_255, 22_102_712_328_997,
                23_762_468_444_321, 25_706_129_919_032, 30_283_004_217_073, 35_236_458_175_272,
                36_751_575_034_122, 36_982_464_340_515, 40_643_008_242_473, 40_847_772_584_050,
                42_617_143_633_137, 43_070_165_094_018, 45_369_104_426_317, 46_388_621_658_318,
                49_815_561_472_240, 55_209_394_201_513, 60_038_078_292_777, 62_013_264_258_290,
                64_801_907_598_210, 64_967_875_136_377, 65_164_413_867_914, 69_458_426_726_932,
                69_968_838_232_145, 73_925_657_823_492, 75_345_282_835_555, 75_897_475_957_225,
                75_947_399_088_753, 77_139_067_906_027, 80_473_750_076_038, 80_869_462_923_905,
                85_241_165_147_001, 85_336_468_993_784, 85_712_034_064_849, 88_230_721_056_511,
                89_435_905_378_306, 91_999_539_429_616, 96_363_295_408_208, 96_666_172_090_448,
                97_326_737_469_569, 108_818_308_997_907, 110_070_523_643_664, 110_929_723_321_216,
                113_209_246_256_383, 117_558_666_299_491, 121_197_818_285_311, 141_209_514_904_082,
                141_849_622_061_865, 143_737_608_964_985, 152_637_010_423_035, 157_050_661_340_383,
                170_156_314_248_098, 177_801_560_427_026, 183_906_223_213_433, 184_103_120_915_339,
                185_417_015_970_809, 195_760_082_985_897, 197_672_678_105_184, 201_305_970_722_015,
                206_145_729_365_528, 208_212_283_032_595, 210_644_041_809_166, 211_691_066_673_180,
                211_760_287_392_362, 214_621_993_657_585, 215_210_467_388_591, 215_223_275_916_543,
                218_746_505_276_081, 220_178_926_586_908, 220_411_725_309_680, 222_407_767_385_304,
                222_506_989_413_161, 223_366_727_763_152, 226_043_537_443_714, 226_089_485_745_383,
                226_837_069_851_090, 228_023_683_672_163, 230_531_739_894_864, 233_072_899_009_401,
                233_864_998_978_601, 235_857_107_438_457, 236_329_873_695_639, 240_806_186_862_061,
                241_664_450_767_537, 244_715_407_566_485, 248_444_978_127_746, 249_746_467_672_705,
                252_133_692_983_502, 254_891_659_986_992, 256_867_224_807_089, 257_374_513_735_944,
                257_985_210_845_650, 258_999_812_908_248, 260_070_455_016_529, 260_286_388_529_265,
                261_039_958_084_216, 264_768_543_640_500, 265_956_699_301_296, 0,
            ]
        default:
            return [0]
        }
    }
}

let lower48Mask: UInt64 = 0x0000ffffffffffff

func primeClimateParameterLimitsCache() {
    // Kept as a no-op hook for stateful C wrappers that should not reach back
    // into cubiomes' climate limit table after generator/finder calls.
}

func cachedClimateParameterLimits(version: MinecraftVersion, biomeID: Int32) -> ClimateParameterRanges? {
    guard version.rawValue >= MinecraftVersion.v1_18.rawValue, (0...186).contains(biomeID) else {
        return nil
    }
    if version.rawValue > MinecraftVersion.v1_21_3.rawValue,
       let ranges = climateParameterLimits21WinterDropDiff[biomeID] {
        return ranges.value
    }
    if version.rawValue > MinecraftVersion.v1_19.rawValue,
       let ranges = climateParameterLimits20Diff[biomeID] {
        return ranges.value
    }
    if version.rawValue > MinecraftVersion.v1_18.rawValue,
       let ranges = climateParameterLimits19Diff[biomeID] {
        return ranges.value
    }
    return climateParameterLimits18[biomeID]?.value
}

private struct ClimateParameterLimitRow {
    let values: (Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32)

    var value: ClimateParameterRanges {
        ClimateParameterRanges(
            temperature: values.0...values.1,
            humidity: values.2...values.3,
            continentalness: values.4...values.5,
            erosion: values.6...values.7,
            depth: values.8...values.9,
            weirdness: values.10...values.11
        )
    }
}

private func climateRanges(
    _ temperatureMinimum: Int32,
    _ temperatureMaximum: Int32,
    _ humidityMinimum: Int32,
    _ humidityMaximum: Int32,
    _ continentalnessMinimum: Int32,
    _ continentalnessMaximum: Int32,
    _ erosionMinimum: Int32,
    _ erosionMaximum: Int32,
    _ depthMinimum: Int32,
    _ depthMaximum: Int32,
    _ weirdnessMinimum: Int32,
    _ weirdnessMaximum: Int32
) -> ClimateParameterLimitRow {
    ClimateParameterLimitRow(values: (
        temperatureMinimum,
        temperatureMaximum,
        humidityMinimum,
        humidityMaximum,
        continentalnessMinimum,
        continentalnessMaximum,
        erosionMinimum,
        erosionMaximum,
        depthMinimum,
        depthMaximum,
        weirdnessMinimum,
        weirdnessMaximum
    ))
}

private let climateParameterLimits18: [Int32: ClimateParameterLimitRow] = [
    0: climateRanges(-1500, 2000, Int32.min, Int32.max, -4550, -1900, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // ocean
    1: climateRanges(-4500, 5500, Int32.min, 1000, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // plains
    2: climateRanges(5500, Int32.max, Int32.min, Int32.max, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // desert
    3: climateRanges(Int32.min, 2000, Int32.min, 1000, -1899, Int32.max, 4500, 5500, Int32.min, Int32.max, Int32.min, Int32.max), // windswept_hills
    4: climateRanges(-4500, 5500, -1000, 3000, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // forest
    5: climateRanges(Int32.min, -1500, 1000, Int32.max, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // taiga
    6: climateRanges(-4500, Int32.max, Int32.min, Int32.max, -1100, Int32.max, 5500, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // swamp
    7: climateRanges(-4500, Int32.max, Int32.min, Int32.max, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, -500, 500), // river
    10: climateRanges(Int32.min, -4501, Int32.min, Int32.max, -4550, -1900, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // frozen_ocean
    11: climateRanges(Int32.min, -4501, Int32.min, Int32.max, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, -500, 500), // frozen_river
    12: climateRanges(Int32.min, -4500, Int32.min, 1000, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // snowy_plains
    14: climateRanges(Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, -10500, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // mushroom_fields
    16: climateRanges(-4500, 5500, Int32.min, Int32.max, -1900, -1100, -2225, Int32.max, Int32.min, Int32.max, Int32.min, 2666), // beach
    21: climateRanges(2000, 5500, 1000, Int32.max, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // jungle
    23: climateRanges(2000, 5500, 1000, 3000, -1899, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, -500, Int32.max), // sparse_jungle
    24: climateRanges(-1500, 2000, Int32.min, Int32.max, -10500, -4551, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // deep_ocean
    25: climateRanges(Int32.min, Int32.max, Int32.min, Int32.max, -1900, -1100, Int32.min, -2225, Int32.min, Int32.max, Int32.min, Int32.max), // stony_shore
    26: climateRanges(Int32.min, -4500, Int32.min, Int32.max, -1900, -1100, -2225, Int32.max, Int32.min, Int32.max, Int32.min, 2666), // snowy_beach
    27: climateRanges(-1500, 2000, 1000, 3000, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // birch_forest
    29: climateRanges(-1500, 2000, 3000, Int32.max, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // dark_forest
    30: climateRanges(Int32.min, -4500, -1000, Int32.max, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // snowy_taiga
    32: climateRanges(-4500, -1500, 3000, Int32.max, -1899, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, -500, Int32.max), // old_growth_pine_taiga
    34: climateRanges(Int32.min, 2000, 1000, Int32.max, -1899, Int32.max, 4500, 5500, Int32.min, Int32.max, Int32.min, Int32.max), // windswept_forest
    35: climateRanges(2000, 5500, Int32.min, -1000, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // savanna
    36: climateRanges(2000, 5500, Int32.min, -1000, -1100, Int32.max, Int32.min, 500, Int32.min, Int32.max, Int32.min, Int32.max), // savanna_plateau
    37: climateRanges(5500, Int32.max, Int32.min, 1000, -1899, Int32.max, Int32.min, 500, Int32.min, Int32.max, Int32.min, Int32.max), // badlands
    38: climateRanges(5500, Int32.max, 1000, Int32.max, -1899, Int32.max, Int32.min, 500, Int32.min, Int32.max, Int32.min, Int32.max), // wooded_badlands
    44: climateRanges(5500, Int32.max, Int32.min, Int32.max, -10500, -1900, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // warm_ocean
    45: climateRanges(2001, 5500, Int32.min, Int32.max, -4550, -1900, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // lukewarm_ocean
    46: climateRanges(-4500, -1501, Int32.min, Int32.max, -4550, -1900, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // cold_ocean
    48: climateRanges(2001, 5500, Int32.min, Int32.max, -10500, -4551, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // deep_lukewarm_ocean
    49: climateRanges(-4500, -1501, Int32.min, Int32.max, -10500, -4551, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // deep_cold_ocean
    50: climateRanges(Int32.min, -4501, Int32.min, Int32.max, -10500, -4551, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // deep_frozen_ocean
    129: climateRanges(-1500, 2000, Int32.min, -3500, -1899, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, -500, Int32.max), // sunflower_plains
    131: climateRanges(Int32.min, -1500, Int32.min, -1000, -1899, Int32.max, 4500, 5500, Int32.min, Int32.max, Int32.min, Int32.max), // windswept_gravelly_hills
    132: climateRanges(-1500, 2000, Int32.min, -3500, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, -500), // flower_forest
    140: climateRanges(Int32.min, -4500, Int32.min, -3500, -1899, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, -500, Int32.max), // ice_spikes
    155: climateRanges(-1500, 2000, 1000, 3000, -1899, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, -500, Int32.max), // old_growth_birch_forest
    160: climateRanges(-4500, -1500, 3000, Int32.max, -1900, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, -500), // old_growth_spruce_taiga
    163: climateRanges(-1500, Int32.max, Int32.min, 3000, -1899, 300, 4500, 5500, Int32.min, Int32.max, 501, Int32.max), // windswept_savanna
    165: climateRanges(5500, Int32.max, Int32.min, -1000, -1899, Int32.max, Int32.min, 500, Int32.min, Int32.max, Int32.min, Int32.max), // eroded_badlands
    168: climateRanges(2000, 5500, 3000, Int32.max, -1899, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, -500, Int32.max), // bamboo_jungle
    174: climateRanges(Int32.min, Int32.max, Int32.min, 6999, 3001, Int32.max, Int32.min, Int32.max, 1000, 9500, Int32.min, Int32.max), // dripstone_caves
    175: climateRanges(Int32.min, Int32.max, 2001, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, 1000, 9500, Int32.min, Int32.max), // lush_caves
    177: climateRanges(-4500, 2000, Int32.min, 3000, 300, Int32.max, -7799, 500, Int32.min, Int32.max, Int32.min, Int32.max), // meadow
    178: climateRanges(Int32.min, 2000, -1000, Int32.max, -1899, Int32.max, Int32.min, -3750, Int32.min, Int32.max, Int32.min, Int32.max), // grove
    179: climateRanges(Int32.min, 2000, Int32.min, -1000, -1899, Int32.max, Int32.min, -3750, Int32.min, Int32.max, Int32.min, Int32.max), // snowy_slopes
    180: climateRanges(Int32.min, 2000, Int32.min, Int32.max, -1899, Int32.max, Int32.min, -3750, Int32.min, Int32.max, -9333, -4001), // jagged_peaks
    181: climateRanges(Int32.min, 2000, Int32.min, Int32.max, -1899, Int32.max, Int32.min, -3750, Int32.min, Int32.max, 4000, 9333), // frozen_peaks
    182: climateRanges(2000, 5500, Int32.min, Int32.max, -1899, Int32.max, Int32.min, -3750, Int32.min, Int32.max, -9333, 9333), // stony_peaks
]

private let climateParameterLimits19Diff: [Int32: ClimateParameterLimitRow] = [
    165: climateRanges(5500, Int32.max, Int32.min, -1000, -1899, Int32.max, Int32.min, 500, Int32.min, Int32.max, -500, Int32.max), // eroded_badlands
    178: climateRanges(Int32.min, 2000, -1000, Int32.max, -1899, Int32.max, Int32.min, -3750, Int32.min, 10499, Int32.min, Int32.max), // grove
    179: climateRanges(Int32.min, 2000, Int32.min, -1000, -1899, Int32.max, Int32.min, -3750, Int32.min, 10499, Int32.min, Int32.max), // snowy_slopes
    180: climateRanges(Int32.min, 2000, Int32.min, Int32.max, -1899, Int32.max, Int32.min, -3750, Int32.min, 10499, -9333, -4001), // jagged_peaks
    183: climateRanges(Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max, Int32.min, 1818, 10500, Int32.max, Int32.min, Int32.max), // deep_dark
    184: climateRanges(2000, Int32.max, Int32.min, Int32.max, -1100, Int32.max, 5500, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // mangrove_swamp
]

private let climateParameterLimits20Diff: [Int32: ClimateParameterLimitRow] = [
    6: climateRanges(-4500, 2000, Int32.min, Int32.max, -1100, Int32.max, 5500, Int32.max, Int32.min, Int32.max, Int32.min, Int32.max), // swamp
    178: climateRanges(Int32.min, 2000, -1000, Int32.max, -1899, Int32.max, Int32.min, -3750, Int32.min, 10500, Int32.min, Int32.max), // grove
    179: climateRanges(Int32.min, 2000, Int32.min, -1000, -1899, Int32.max, Int32.min, -3750, Int32.min, 10500, Int32.min, Int32.max), // snowy_slopes
    180: climateRanges(Int32.min, 2000, Int32.min, Int32.max, -1899, Int32.max, Int32.min, -3750, Int32.min, 10500, -9333, -4000), // jagged_peaks
    181: climateRanges(Int32.min, 2000, Int32.min, Int32.max, -1899, Int32.max, Int32.min, -3750, Int32.min, 10500, 4000, 9333), // frozen_peaks
    182: climateRanges(2000, 5500, Int32.min, Int32.max, -1899, Int32.max, Int32.min, -3750, Int32.min, 10500, -9333, 9333), // stony_peaks
    185: climateRanges(-4500, 2000, Int32.min, -1000, 300, Int32.max, -7799, 500, Int32.min, Int32.max, 2666, Int32.max), // cherry_grove
]

private let climateParameterLimits21WinterDropDiff: [Int32: ClimateParameterLimitRow] = [
    186: climateRanges(-1500, 2000, 3000, Int32.max, 300, Int32.max, -7799, 500, Int32.min, Int32.max, 2666, Int32.max), // pale_garden
]

extension BiomeFilterSpec {
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

extension StructureRect {
    func offset(by position: BlockPosition) -> StructureRect {
        StructureRect(
            minX: minX + position.x,
            minZ: minZ + position.z,
            maxX: maxX + position.x,
            maxZ: maxZ + position.z
        )
    }
}

func pieceSummaries(from pieces: [Piece], count: Int32) -> [StructurePieceSummary] {
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

func matchesAll(
    _ conditions: [CubiomesQueryCondition],
    references: [String: CubiomesQueryCondition] = [:],
    version: MinecraftVersion,
    seed: Int64,
    dimension: MinecraftDimension,
    at position: BlockPosition
) throws -> Bool {
    var stack: [String] = []
    for condition in conditions {
        guard try matches(
            condition,
            references: references,
            referenceStack: &stack,
            version: version,
            seed: seed,
            dimension: dimension,
            at: position
        ) else {
            return false
        }
    }
    return true
}

func matches(
    _ condition: CubiomesQueryCondition,
    references: [String: CubiomesQueryCondition] = [:],
    referenceStack: inout [String],
    version: MinecraftVersion,
    seed: Int64,
    dimension: MinecraftDimension,
    at position: BlockPosition
) throws -> Bool {
    switch condition {
    case let .all(children):
        for child in children {
            guard try matches(
                child,
                references: references,
                referenceStack: &referenceStack,
                version: version,
                seed: seed,
                dimension: dimension,
                at: position
            ) else {
                return false
            }
        }
        return true

    case let .any(children):
        for child in children {
            if try matches(
                child,
                references: references,
                referenceStack: &referenceStack,
                version: version,
                seed: seed,
                dimension: dimension,
                at: position
            ) {
                return true
            }
        }
        return false

    case let .not(child):
        return try !matches(
            child,
            references: references,
            referenceStack: &referenceStack,
            version: version,
            seed: seed,
            dimension: dimension,
            at: position
        )

    case let .reference(name):
        guard let referenced = references[name] else {
            throw CubiomesError.missingConditionReference(name)
        }
        guard !referenceStack.contains(name) else {
            throw CubiomesError.recursiveConditionReference(name)
        }
        referenceStack.append(name)
        defer { _ = referenceStack.popLast() }
        return try matches(
            referenced,
            references: references,
            referenceStack: &referenceStack,
            version: version,
            seed: seed,
            dimension: dimension,
            at: position
        )

    case let .at(relativeX, relativeZ, child):
        let shifted = BlockPosition(x: position.x + relativeX, z: position.z + relativeZ)
        return try matches(
            child,
            references: references,
            referenceStack: &referenceStack,
            version: version,
            seed: seed,
            dimension: dimension,
            at: shifted
        )

    case let .scaledCoordinates(numerator, denominator, child):
        guard numerator > 0, denominator > 0 else {
            throw CubiomesError.invalidCoordinateScale(numerator: numerator, denominator: denominator)
        }
        let scaled = BlockPosition(
            x: scaleCoordinate(position.x, numerator: numerator, denominator: denominator),
            z: scaleCoordinate(position.z, numerator: numerator, denominator: denominator)
        )
        return try matches(
            child,
            references: references,
            referenceStack: &referenceStack,
            version: version,
            seed: seed,
            dimension: dimension,
            at: scaled
        )

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

    case let .biomeIsPossibleForClimate(relativeX, relativeZ, y, ranges):
        let biome = try CubiomesCore.biome(
            version: version,
            seed: seed,
            dimension: dimension,
            x: position.x + relativeX,
            y: y,
            z: position.z + relativeZ
        )
        let possible = CubiomesCore.possibleBiomesForClimate(ClimateBiomePossibilityRequest(
            version: version,
            ranges: ranges
        ))
        return possible.biomeIDs.contains(biome.id)

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

    case let .monteCarloBiomeSample(relativeRect, scale, y, requiredCoverage, confidence, allowedBiomeIDs, excludedBiomeIDs):
        let rect = relativeRect.offset(by: position)
        let scaled = scaledCellRect(rect, scale: scale)
        let result = try CubiomesCore.monteCarloBiomeSample(MonteCarloBiomeSampleRequest(
            version: version,
            seed: seed,
            dimension: dimension,
            originX: scaled.originX,
            originZ: scaled.originZ,
            width: scaled.width,
            height: scaled.height,
            scale: scale,
            y: y,
            requiredCoverage: requiredCoverage,
            confidence: confidence,
            allowedBiomeIDs: allowedBiomeIDs,
            excludedBiomeIDs: excludedBiomeIDs
        ))
        return result.matched

    case let .monteCarloClimateNoiseSample(relativeRect, scale, parameter, allowed, requiredCoverage, confidence):
        let rect = relativeRect.offset(by: position)
        let scaled = scaledCellRect(rect, scale: scale)
        let result = try CubiomesCore.monteCarloClimateNoiseSample(MonteCarloClimateNoiseSampleRequest(
            version: version,
            seed: seed,
            originX: scaled.originX,
            originZ: scaled.originZ,
            width: scaled.width,
            height: scaled.height,
            scale: scale,
            parameter: parameter,
            allowed: allowed,
            requiredCoverage: requiredCoverage,
            confidence: confidence
        ))
        return result.matched

    case let .climateNoiseRange(relativeRect, parameter, allowed):
        let rect = relativeRect.offset(by: position)
        let scaled = scaledCellRect(rect, scale: 4)
        let result = try CubiomesCore.climateNoiseRange(ClimateNoiseRangeRequest(
            version: version,
            seed: seed,
            originX: scaled.originX,
            originZ: scaled.originZ,
            width: scaled.width,
            height: scaled.height,
            parameter: parameter
        ))
        return result.scaledMinimum >= allowed.lowerBound && result.scaledMaximum <= allowed.upperBound

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

    case let .structureCombination(relativeRect, requirements):
        let rect = relativeRect.offset(by: position)
        return try structureCombinationMatch(
            version: version,
            seed: seed,
            dimension: dimension,
            rect: rect,
            requirements: requirements
        ) != nil

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

func structureCombinationMatch(
    version: MinecraftVersion,
    seed: Int64,
    dimension: MinecraftDimension,
    rect: StructureRect,
    requirements: [StructureCombinationRequirement]
) throws -> StructureCombinationSearchResult? {
    let requestedTypes = Array(Set(requirements.map { $0.type }))
    let locations = try CubiomesCore.structures(
        version: version,
        seed: seed,
        dimension: dimension,
        types: requestedTypes,
        rect: rect
    )
    let relevantLocations = locations.filter { location in
        requirements.contains { requirement in
            requirement.type == location.type && (!requirement.requiresViable || location.isViable)
        }
    }
    var counts: [StructureType: Int] = [:]
    for location in relevantLocations {
        counts[location.type, default: 0] += 1
    }
    for requirement in requirements {
        guard counts[requirement.type, default: 0] >= requirement.minimumCount else {
            return nil
        }
    }
    return StructureCombinationSearchResult(
        seed: seed,
        rect: rect,
        matchingLocations: relevantLocations.sorted {
            ($0.blockZ, $0.blockX, String(describing: $0.type)) <
                ($1.blockZ, $1.blockX, String(describing: $1.type))
        },
        countsByType: counts
    )
}

func runMonteCarloBiomeSample(_ request: MonteCarloBiomeSampleRequest) throws -> MonteCarloBiomeSampleResult {
    try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
    guard [1, 4, 16, 64, 256].contains(request.scale),
          request.requiredCoverage > 0,
          request.requiredCoverage <= 1,
          request.confidence > 0,
          request.confidence < 1,
          !request.allowedBiomeIDs.isEmpty else {
        throw CubiomesError.invalidMonteCarloParameters
    }

    var generator = Generator()
    setupGenerator(&generator, request.version.rawValue, 0)
    applySeed(&generator, request.dimension.rawValue, UInt64(bitPattern: request.seed))
    var rng = UInt64(0)
    setSeed(&rng, UInt64(bitPattern: request.seed))

    let range = Range(
        scale: request.scale,
        x: request.originX,
        z: request.originZ,
        sx: request.width,
        sz: request.height,
        y: request.scale == 1 ? request.y : request.y >> 2,
        sy: 1
    )
    var state = MonteCarloBiomeSampleState(
        allowed: biomeMask(request.allowedBiomeIDs),
        excluded: biomeMask(request.excludedBiomeIDs)
    )
    let code = withUnsafeMutablePointer(to: &state) { statePointer in
        monteCarloBiomes(
            &generator,
            range,
            &rng,
            request.requiredCoverage,
            request.confidence,
            monteCarloBiomeSampleCallback,
            UnsafeMutableRawPointer(statePointer)
        )
    }
    let average: BlockPosition?
    if state.successfulSampleCount > 0 {
        average = BlockPosition(
            x: Int32(state.xSum / Int64(state.successfulSampleCount)),
            z: Int32(state.zSum / Int64(state.successfulSampleCount))
        )
    } else {
        average = nil
    }
    return MonteCarloBiomeSampleResult(
        request: request,
        matched: code == 1,
        evaluatedSampleCount: state.evaluatedSampleCount,
        successfulSampleCount: state.successfulSampleCount,
        skippedSampleCount: state.skippedSampleCount,
        averageSuccessPosition: average
    )
}

func runMonteCarloClimateNoiseSample(
    _ request: MonteCarloClimateNoiseSampleRequest
) throws -> MonteCarloClimateNoiseSampleResult {
    try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
    guard request.version.rawValue >= MinecraftVersion.v1_18.rawValue else {
        throw CubiomesError.unsupportedClimateNoise(request.version)
    }
    guard [4, 16, 64, 256].contains(request.scale),
          request.requiredCoverage > 0,
          request.requiredCoverage <= 1,
          request.confidence > 0,
          request.confidence < 1 else {
        throw CubiomesError.invalidMonteCarloParameters
    }

    var generator = Generator()
    setupGenerator(&generator, request.version.rawValue, 0)
    setClimateParaSeed(&generator.bn, UInt64(bitPattern: request.seed), 0, request.parameter.rawValue, -1)
    var rng = UInt64(0)
    setSeed(&rng, UInt64(bitPattern: request.seed))
    let range = Range(
        scale: request.scale,
        x: request.originX,
        z: request.originZ,
        sx: request.width,
        sz: request.height,
        y: 0,
        sy: 1
    )
    var state = MonteCarloClimateNoiseSampleState(allowed: request.allowed)
    let code = withUnsafeMutablePointer(to: &state) { statePointer in
        monteCarloBiomes(
            &generator,
            range,
            &rng,
            request.requiredCoverage,
            request.confidence,
            monteCarloClimateNoiseSampleCallback,
            UnsafeMutableRawPointer(statePointer)
        )
    }
    let average: BlockPosition?
    if state.successfulSampleCount > 0 {
        average = BlockPosition(
            x: Int32(state.xSum / Int64(state.successfulSampleCount)),
            z: Int32(state.zSum / Int64(state.successfulSampleCount))
        )
    } else {
        average = nil
    }
    return MonteCarloClimateNoiseSampleResult(
        request: request,
        matched: code == 1,
        evaluatedSampleCount: state.evaluatedSampleCount,
        successfulSampleCount: state.successfulSampleCount,
        averageSuccessPosition: average
    )
}

func runClimateNoiseRange(_ request: ClimateNoiseRangeRequest) throws -> ClimateNoiseRangeResult {
    try CubiomesWorld.validateGridLike(width: request.width, height: request.height)
    guard request.version.rawValue >= MinecraftVersion.v1_18.rawValue else {
        throw CubiomesError.unsupportedClimateNoise(request.version)
    }
    guard request.parameter != .depth else {
        throw CubiomesError.unsupportedClimateNoiseParameter(request.parameter)
    }

    var generator = Generator()
    setupGenerator(&generator, request.version.rawValue, 0)
    setClimateParaSeed(&generator.bn, UInt64(bitPattern: request.seed), 0, request.parameter.rawValue, -1)
    var minimum = Double.greatestFiniteMagnitude
    var maximum = -Double.greatestFiniteMagnitude
    var state = ClimateNoiseRangeState()
    let code = withUnsafeMutablePointer(to: &state) { statePointer in
        withMutableClimateNoisePointer(in: &generator, parameter: request.parameter) { climatePointer in
            getParaRange(
                climatePointer,
                &minimum,
                &maximum,
                request.originX,
                request.originZ,
                request.width,
                request.height,
                UnsafeMutableRawPointer(statePointer),
                climateNoiseRangeCallback
            )
        }
    }
    guard code == 0 else {
        throw CubiomesError.climateNoiseRangeFailed
    }
    return ClimateNoiseRangeResult(
        request: request,
        minimum: minimum,
        maximum: maximum,
        minimumPosition: state.minimumPosition,
        maximumPosition: state.maximumPosition
    )
}

func scaledCellRect(_ rect: StructureRect, scale: Int32) -> (originX: Int32, originZ: Int32, width: Int32, height: Int32) {
    let x0 = floorDiv(rect.minX, scale)
    let z0 = floorDiv(rect.minZ, scale)
    let x1 = floorDiv(rect.maxX - 1, scale)
    let z1 = floorDiv(rect.maxZ - 1, scale)
    return (x0, z0, x1 - x0 + 1, z1 - z0 + 1)
}

func climateRanges(from pointer: UnsafePointer<Int32>?) -> ClimateParameterRanges? {
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

extension ClimateParameterRanges {
    func intersects(_ other: ClimateParameterRanges) -> Bool {
        temperature.overlaps(other.temperature) &&
            humidity.overlaps(other.humidity) &&
            continentalness.overlaps(other.continentalness) &&
            erosion.overlaps(other.erosion) &&
            depth.overlaps(other.depth) &&
            weirdness.overlaps(other.weirdness)
    }

    var cLimits: [(Int32, Int32)] {
        [
            (temperature.lowerBound, temperature.upperBound),
            (humidity.lowerBound, humidity.upperBound),
            (continentalness.lowerBound, continentalness.upperBound),
            (erosion.lowerBound, erosion.upperBound),
            (depth.lowerBound, depth.upperBound),
            (weirdness.lowerBound, weirdness.upperBound),
        ]
    }
}

func floorDiv(_ value: Int32, _ divisor: Int32) -> Int32 {
    precondition(divisor > 0)
    var quotient = value / divisor
    let remainder = value % divisor
    if remainder != 0 && value < 0 {
        quotient -= 1
    }
    return quotient
}

func scaleCoordinate(_ value: Int32, numerator: Int32, denominator: Int32) -> Int32 {
    let product = Int64(value) * Int64(numerator)
    return Int32(product / Int64(denominator))
}

private struct BiomeIDMask {
    var low: UInt64
    var high: UInt64
    var upper: UInt64

    func contains(_ id: Int32) -> Bool {
        switch id {
        case 0..<64:
            return (low & (UInt64(1) << UInt64(id))) != 0
        case 64..<128:
            return (high & (UInt64(1) << UInt64(id - 64))) != 0
        case 128..<192:
            return (upper & (UInt64(1) << UInt64(id - 128))) != 0
        default:
            return false
        }
    }
}

private struct MonteCarloBiomeSampleState {
    var allowed: BiomeIDMask
    var excluded: BiomeIDMask
    var evaluatedSampleCount = 0
    var successfulSampleCount = 0
    var skippedSampleCount = 0
    var xSum = Int64(0)
    var zSum = Int64(0)
}

private struct MonteCarloClimateNoiseSampleState {
    var allowed: ClosedRange<Int32>
    var evaluatedSampleCount = 0
    var successfulSampleCount = 0
    var xSum = Int64(0)
    var zSum = Int64(0)
}

private struct ClimateNoiseRangeState {
    var minimum = Double.greatestFiniteMagnitude
    var maximum = -Double.greatestFiniteMagnitude
    var minimumPosition = BlockPosition(x: 0, z: 0)
    var maximumPosition = BlockPosition(x: 0, z: 0)
}

private func biomeMask(_ ids: [Int32]) -> BiomeIDMask {
    var mask = BiomeIDMask(low: 0, high: 0, upper: 0)
    for id in ids {
        switch id {
        case 0..<64:
            mask.low |= UInt64(1) << UInt64(id)
        case 64..<128:
            mask.high |= UInt64(1) << UInt64(id - 64)
        case 128..<192:
            mask.upper |= UInt64(1) << UInt64(id - 128)
        default:
            continue
        }
    }
    return mask
}

private func monteCarloBiomeSampleCallback(
    generator: UnsafeMutablePointer<Generator>?,
    scale: Int32,
    x: Int32,
    y: Int32,
    z: Int32,
    data: UnsafeMutableRawPointer?
) -> Int32 {
    guard let generator, let data else {
        return -2
    }
    let state = data.assumingMemoryBound(to: MonteCarloBiomeSampleState.self)
    let biomeID = getBiomeAt(generator, scale, x, y, z)
    state.pointee.evaluatedSampleCount += 1
    if state.pointee.excluded.contains(biomeID) {
        return 0
    }
    if state.pointee.allowed.contains(biomeID) {
        let blockX = Int64(x * scale)
        let blockZ = Int64(z * scale)
        state.pointee.successfulSampleCount += 1
        state.pointee.xSum += blockX
        state.pointee.zSum += blockZ
        return 1
    }
    return 0
}

private func monteCarloClimateNoiseSampleCallback(
    generator: UnsafeMutablePointer<Generator>?,
    scale: Int32,
    x: Int32,
    y: Int32,
    z: Int32,
    data: UnsafeMutableRawPointer?
) -> Int32 {
    guard let generator, let data else {
        return -2
    }
    _ = y
    var noisePoint = Array(repeating: Int64(0), count: Int(NP_MAX))
    let value = noisePoint.withUnsafeMutableBufferPointer {
        sampleClimatePara(&generator.pointee.bn, $0.baseAddress, Double(x), Double(z))
    }
    let scaledValue = Int32(value * 10_000)
    let state = data.assumingMemoryBound(to: MonteCarloClimateNoiseSampleState.self)
    state.pointee.evaluatedSampleCount += 1
    if state.pointee.allowed.contains(scaledValue) {
        let blockX = Int64(x * scale)
        let blockZ = Int64(z * scale)
        state.pointee.successfulSampleCount += 1
        state.pointee.xSum += blockX
        state.pointee.zSum += blockZ
        return 1
    }
    return 0
}

private func climateNoiseRangeCallback(
    data: UnsafeMutableRawPointer?,
    x: Int32,
    z: Int32,
    value: Double
) -> Int32 {
    guard let data else {
        return 1
    }
    let state = data.assumingMemoryBound(to: ClimateNoiseRangeState.self)
    if value < state.pointee.minimum {
        state.pointee.minimum = value
        state.pointee.minimumPosition = BlockPosition(x: x << 2, z: z << 2)
    }
    if value > state.pointee.maximum {
        state.pointee.maximum = value
        state.pointee.maximumPosition = BlockPosition(x: x << 2, z: z << 2)
    }
    return 0
}

private func withMutableClimateNoisePointer<Result>(
    in generator: inout Generator,
    parameter: ClimateNoiseParameter,
    _ body: (UnsafeMutablePointer<DoublePerlinNoise>) throws -> Result
) rethrows -> Result {
    switch parameter {
    case .temperature:
        return try body(&generator.bn.climate.0)
    case .humidity:
        return try body(&generator.bn.climate.1)
    case .continentalness:
        return try body(&generator.bn.climate.2)
    case .erosion:
        return try body(&generator.bn.climate.3)
    case .depth:
        return try body(&generator.bn.climate.4)
    case .weirdness:
        return try body(&generator.bn.climate.5)
    }
}
