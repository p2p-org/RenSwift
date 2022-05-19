// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RenVMSwift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RenVMSwift",
            targets: ["RenVMSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.2.0"),
        .package(url: "https://github.com/p2p-org/solana-swift.git", branch: "refactor/pwn-3297")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RenVMSwift",
            dependencies: [
                .product(name: "SolanaSwift", package: "solana-swift")
            ]
        ),
        .testTarget(
            name: "RenVMSwiftTests",
            dependencies: ["RenVMSwift",.product(name: "RxBlocking", package: "RxSwift")]),
    ]
)
