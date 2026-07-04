// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CubiomesCore",
    products: [
        .library(
            name: "CubiomesCore",
            targets: ["CubiomesCore"]
        ),
    ],
    targets: [
        .target(
            name: "CCubiomes",
            path: "cubiomes",
            sources: [
                "noise.c",
                "biomes.c",
                "layers.c",
                "biomenoise.c",
                "generator.c",
                "finders.c",
                "util.c",
                "quadbase.c",
            ],
            publicHeadersPath: ".",
            linkerSettings: [
                .linkedLibrary("m", .when(platforms: [.linux])),
                .linkedLibrary("pthread", .when(platforms: [.linux])),
            ]
        ),
        .target(
            name: "CubiomesCore",
            dependencies: ["CCubiomes"],
            path: "Sources/CubiomesCore"
        ),
        .testTarget(
            name: "CubiomesCoreTests",
            dependencies: ["CubiomesCore"],
            path: "Tests/CubiomesCoreTests"
        ),
    ]
)
