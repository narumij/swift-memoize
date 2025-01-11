// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Memoize",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Memoize",
            targets: ["Memoize"]
        ),
        .executable(
            name: "MemoizeClient",
            targets: ["MemoizeClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
        .package(url: "https://github.com/narumij/swift-ac-collections.git",
                 revision: "e0b9448c7794afa433df7706d2cf54f0478d76ec"),
//                 from: "0.1.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "MemoizeMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "Memoize", dependencies: [
          "MemoizeMacros",
          .product(name: "AcCollections", package: "swift-ac-collections"),
        ]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "MemoizeClient", dependencies: ["Memoize"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "MemoizeTests",
            dependencies: [
                "MemoizeMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        
          .target(name: "MemoizeCache", dependencies: [
            "MemoizeMacros",
            .product(name: "AcCollections", package: "swift-ac-collections"),
          ]),

          .testTarget(
              name: "MemoizeCacheTests",
              dependencies: [
                  "MemoizeCache"
              ]
          ),
    ]
)
