// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ParseObjC",
    defaultLocalization: "en",
    platforms: [.iOS(.v12),
                .watchOS(.v2)],
    products: [
        .library(name: "ParseObjC", targets: ["ParseCore"]),
        .library(name: "ParseFacebookUtilsiOS", targets: ["ParseFacebookUtilsiOS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/parse-community/Bolts-ObjC.git", from: "1.10.0"),
        .package(url: "https://github.com/facebook/facebook-ios-sdk.git", from: "15.1.0")
    ],
    targets: [
        .target(
            name: "ParseCore",
            dependencies: [.product(name: "Bolts", package: "Bolts-ObjC")],
            path: "Parse/Parse",
            exclude: ["Resources/Parse-iOS.Info.plist", "Resources/Parse-watchOS.Info.plist"],
            resources: [.process("Resources")],
            publicHeadersPath: "Source",
            cSettings: [.headerSearchPath("Internal/**")]),
        .target(
            name: "ParseFacebookUtils",
            dependencies: [
                "ParseCore",
                .product(name: "Bolts", package: "Bolts-ObjC"),
                .product(name: "FacebookCore", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FacebookLogin", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS]))],
            path: "ParseFacebookUtils/ParseFacebookUtils",
            exclude: ["exclude", "Resources/Info-iOS.plist"],
            resources: [.process("Resources")],
            publicHeadersPath: "Source"),
        .target(name: "ParseFacebookUtilsiOS",
               dependencies: [
                "ParseFacebookUtils"
               ],
                path: "ParseFacebookUtilsiOS/ParseFacebookUtilsiOS",
                exclude: ["exclude", "Resources/Info-iOS.plist"],
                resources: [.process("Resources")],
                publicHeadersPath: "Source",
                cSettings: [.headerSearchPath("Internal/**")]),
    ]
)
