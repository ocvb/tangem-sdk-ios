// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TangemSdk",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TangemSdk",
            targets: [
                "TangemSdk",
            ]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TangemSdk",
            dependencies: [
                "TangemSdk_secp256k1",
                "Bls_Signature",
            ],
            path: "TangemSdk/TangemSdk",
            exclude: [
                "Crypto/secp256k1",
                "Frameworks",
                "module.modulemap",
                "TangemSdk.h",
            ],
            resources: [
                .process("Common/Localization/de.lproj"),
                .process("Common/Localization/en.lproj"),
                .process("Common/Localization/fr.lproj"),
                .process("Common/Localization/it.lproj"),
                .process("Common/Localization/ru.lproj"),
                .process("Common/Localization/zh-Hant.lproj"),
                .copy("Haptics/"),
                .copy("Crypto/BIP39/Wordlists/english.txt"),
            ]
        ),
        .target(
            name: "TangemSdk_secp256k1",
            path: "TangemSdk/TangemSdk/Crypto/secp256k1"
        ),
        .binaryTarget(
            name: "Bls_Signature",
            path: "TangemSdk/TangemSdk/Frameworks/Bls_Signature.xcframework"
        ),
        .testTarget(
            name: "TangemSdkTests",
            dependencies: [
                "TangemSdk",
            ],
            path: "TangemSdk/TangemSdkTests",
            resources: [
                .copy("Jsons/"),
            ]
        ),
    ]
)
