// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Jojo",
    platforms: [
      .macOS(.v12), .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "JojoModels",
            targets: ["JojoModels"]
        ),
        .library(
          name: "JojoServer",
          targets: ["JojoServer"]
        ),
        .executable(name: "simulators", targets: ["simulators"]),
        .executable(
          name: "jojod",
          targets: ["jojod"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        .package(path: "Packages/SimulatorServices")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "JojoModels",
            dependencies: []),
        .target(
          name: "JojoServer",
          dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt"),

            "JojoModels",
                "SimulatorServices"
          ]
        ),
        .executableTarget(name: "jojod", dependencies: ["JojoServer"]),
        .executableTarget(name: "simulators", dependencies: ["SimulatorServices"])
    ]
)
