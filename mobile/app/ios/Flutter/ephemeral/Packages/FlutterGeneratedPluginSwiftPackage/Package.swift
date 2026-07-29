// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "webview_flutter_wkwebview", path: "../.packages/webview_flutter_wkwebview-3.25.1"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.4.1"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "mobile_scanner", path: "../.packages/mobile_scanner-7.2.0"),
        .package(name: "device_info_plus", path: "../.packages/device_info_plus-12.4.0"),
        .package(name: "local_auth_darwin", path: "../.packages/local_auth_darwin-1.6.1"),
        .package(name: "image_picker_ios", path: "../.packages/image_picker_ios-0.8.13+6"),
        .package(name: "flutter_secure_storage_darwin", path: "../.packages/flutter_secure_storage_darwin-0.3.2"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-19.5.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "mobile-scanner", package: "mobile_scanner"),
                .product(name: "device-info-plus", package: "device_info_plus"),
                .product(name: "local-auth-darwin", package: "local_auth_darwin"),
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "flutter-secure-storage-darwin", package: "flutter_secure_storage_darwin"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
