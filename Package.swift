// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LibrimeKit",
  platforms: [
    .iOS(.v14)
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "LibrimeKit",
      targets: ["LibrimeKit"])
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .binaryTarget(
      name: "librime",
      path: "Frameworks/librime.xcframework"),
    .binaryTarget(
      name: "boost_atomic",
      path: "Frameworks/boost_atomic.xcframework"),
    .binaryTarget(
      name: "boost_filesystem",
      path: "Frameworks/boost_filesystem.xcframework"),
    .binaryTarget(
      name: "boost_regex",
      path: "Frameworks/boost_regex.xcframework"),
    .binaryTarget(
      name: "boost_system",
      path: "Frameworks/boost_system.xcframework"),
    .binaryTarget(
      name: "libglog",
      path: "Frameworks/libglog.xcframework"),
    .binaryTarget(
      name: "libleveldb",
      path: "Frameworks/libleveldb.xcframework"),
    .binaryTarget(
      name: "libmarisa",
      path: "Frameworks/libmarisa.xcframework"),
    .binaryTarget(
      name: "libopencc",
      path: "Frameworks/libopencc.xcframework"),
    .binaryTarget(
      name: "libyaml-cpp",
      path: "Frameworks/libyaml-cpp.xcframework"),
    .target(
      name: "LibrimeKit",
      dependencies: [
        "librime",
        "boost_atomic",
        "boost_filesystem",
        "boost_regex",
        "boost_system",
        "libglog",
        "libleveldb",
        "libmarisa",
        "libopencc",
        "libyaml-cpp",
      ],
      path: "Sources/ObjC",
      cSettings: [
        .headerSearchPath("Sources/C")
      ],
      cxxSettings: [
        .headerSearchPath("Sources/C")
        //        .unsafeFlags(["-DLEOPARD", "-DHAVE_CONFIG_H"]),
      ],
      linkerSettings: [
        .linkedLibrary("c++"),
        .linkedFramework("CoreFoundation"),
      ]),
    .testTarget(
      name: "LibrimeKitTests",
      dependencies: ["LibrimeKit"],
      resources: [
        .copy("Resources/SharedSupport"),
        .copy("Resources/user"),
      ]
      //      swiftSettings: [
      //        .unsafeFlags(["-enable-experimental-cxx-interop"]),
      //      ]
    ),
  ])
