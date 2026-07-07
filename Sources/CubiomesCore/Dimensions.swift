import CCubiomes

public extension CubiomesCore {
    static func netherBiomes(
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

    static func netherBiomes(_ request: NetherBiomeGridRequest) throws -> NetherBiomeGridResult {
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

    static func netherBiomeVolume(_ request: NetherBiomeVolumeRequest) throws -> NetherBiomeVolumeResult {
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

    static func endBiomes(
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

    static func endBiomes(_ request: EndBiomeGridRequest) throws -> EndBiomeGridResult {
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

    static func endSurfaceHeights(_ request: EndSurfaceHeightGridRequest) throws -> EndSurfaceHeightGridResult {
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

    static func endChunkAnalysis(version: MinecraftVersion, seed: Int64, chunkX: Int32, chunkZ: Int32) -> EndChunkAnalysis {
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

    static func endIslands(version: MinecraftVersion, seed: Int64, chunkX: Int32, chunkZ: Int32) -> [EndIslandInfo] {
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

    static func fixedEndGateways(version: MinecraftVersion, seed: Int64) -> [BlockPosition] {
        var positions = Array(repeating: Pos(), count: 20)
        positions.withUnsafeMutableBufferPointer {
            getFixedEndGateways(version.rawValue, UInt64(bitPattern: seed), $0.baseAddress)
        }
        return positions.map { BlockPosition(x: Int32($0.x), z: Int32($0.z)) }
    }

    static func linkedEndGateway(version: MinecraftVersion, seed: Int64, source: BlockPosition) -> EndGatewayLink {
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

    static func endSurfaceHeight(version: MinecraftVersion, seed: Int64, x: Int32, z: Int32) -> Int32 {
        Int32(getEndSurfaceHeight(version.rawValue, UInt64(bitPattern: seed), x, z))
    }
}
