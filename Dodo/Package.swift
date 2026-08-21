// swift-tools-version: 5.10.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let projectDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

@dynamicMemberLookup struct TheosConfiguration {
    private let dict: [String: String]
    
    init(at path: String) {
        let configURL = URL(fileURLWithPath: path, relativeTo: projectDir)
        guard let infoString = try? String(contentsOf: configURL, encoding: .utf8) else {
            fatalError("Could not find Theos SPM config. Have you run `make spm` yet?")
        }
        let pairs = infoString
            .split(separator: "\n")
            .map { $0.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map(String.init) }
            .map { ($0[0], $0[1]) }
        dict = Dictionary(uniqueKeysWithValues: pairs)
    }
    
    subscript(
        key: String,
        or defaultValue: @autoclosure () -> String? = nil
    ) -> String {
        if let value = dict[key] {
            return value
        } else if let def = defaultValue() {
            return def
        } else {
            fatalError("""
            Could not get value of key '\(key)' from Theos SPM config. \
            Try running `make spm` again.
            """)
        }
    }
    
    subscript(dynamicMember key: String) -> String { self[key] }
}

let conf = TheosConfiguration(at: "../.theos/spm_config")
let theosPath = conf.theos
let sdk = conf.sdk
let resourceDir = conf.swiftResourceDir
let deploymentTarget = conf.deploymentTarget
let triple = "arm64-apple-ios\(deploymentTarget)"

let libFlags: [String] = [
    "-F\(theosPath)/vendor/lib", "-F\(theosPath)/lib",
    "-I\(theosPath)/vendor/include", "-I\(theosPath)/include"
]

let cFlags: [String] = libFlags + [
    "-target", triple, "-isysroot", sdk,
    "-Wno-unused-command-line-argument", "-Qunused-arguments",
]

let cxxFlags: [String] = [
]

let swiftFlags: [String] = libFlags + [
    "-target", triple, "-sdk", sdk, "-resource-dir", resourceDir,
    "-load-plugin-executable", "\(theosPath)/lib/Shook.framework/Plugins/ShookMacros#ShookMacros"
]

let package = Package(
    name: "Dodo",
    platforms: [.iOS(deploymentTarget)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Dodo",
            targets: ["Dodo"]
        ),
    ],
    dependencies: [
        .package(name: "Shook", path: "\(theosPath)/mod/shook")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DodoLoader",
            dependencies: ["Dodo"],
            cSettings: [.unsafeFlags(cFlags)],
            cxxSettings: [.unsafeFlags(cxxFlags)],
            swiftSettings: [.unsafeFlags(swiftFlags)]
        ),
        .target(
            name: "Dodo",
            dependencies: ["DodoC", "Shook"],
            cSettings: [.unsafeFlags(cFlags)],
            cxxSettings: [.unsafeFlags(cxxFlags)],
            swiftSettings: [.unsafeFlags(swiftFlags)]
        ),
        .target(
            name: "DodoC",
            cSettings: [.unsafeFlags(cFlags)],
            cxxSettings: [.unsafeFlags(cxxFlags)],
            swiftSettings: [.unsafeFlags(swiftFlags)]
        ),
    ]
)
