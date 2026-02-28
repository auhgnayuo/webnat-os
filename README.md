# Webnat

[![Swift](https://img.shields.io/badge/Swift-5.5-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2012%2B%20%7C%20macOS%2010.14%2B-lightgrey.svg)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[中文文档](./README_CN.md)

A lightweight WebView-Native bridge library for iOS and macOS. Supports multiple communication modes based on WebKit's `WKWebView` and `WKScriptMessageHandler`.

## Features

- **Multi-platform Support** - iOS 12+ and macOS 10.14+
- **iframe Support** - Automatic message forwarding between main frame and iframes
- **Three Communication Modes** - Bidirectional raw messages, broadcast messages, and method calls (RPC)
- **Timeout & Cancellation** - Built-in timeout control and active cancellation mechanism
- **Type Safety** - Full support for Swift 6 strict concurrency checking

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/auhgnayuo/webnat-os.git", from: "1.0.0")
]
```

Or in Xcode:

1. File → Add Package Dependencies...
2. Enter URL: `https://github.com/auhgnayuo/webnat-os.git`
3. Choose version rule
4. Click Add Package

## Related Projects

Webnat requires a Web-side implementation and also supports other Native platforms:

| Platform | Repository |
|----------|------------|
| Web (JavaScript/TypeScript) | [webnat-web](https://github.com/auhgnayuo/webnat-web) |
| Android (Kotlin) | [webnat-android](https://github.com/auhgnayuo/webnat-android) |
| HarmonyOS (ArkTS) | [webnat-ohos](https://github.com/auhgnayuo/webnat-ohos) |

## Usage

### 1. Initialization

```swift
import Webnat
import WebKit

let configuration = WKWebViewConfiguration()
Webnat.initialize(webViewConfiguration: configuration)
let webView = WKWebView(frame: .zero, configuration: configuration)
let webnat = Webnat.of(webView)
```

### 2. Wait for Web-side Connection

Connections are initiated by the **Web side (JavaScript)**. The Native side automatically receives and manages connections.

```swift
let connections = webnat.connections
print("Active connections: \(connections.count)")

if let connection = connections["connection-id"] {
    print("Connection found:", connection.id)
    print("Attributes:", connection.attributes ?? [:])
}
```

### 3. Send and Receive Messages

```swift
// Send raw message
webnat.raw("Hello from Native!", connection: connection)

// Listen for raw messages
let rawListener: RawBlockListener = { raw, connection in
    print("From \(connection.id):", raw)
}
webnat.onRaw(listener: rawListener)

// Broadcast
webnat.broadcast(name: "userLoggedIn", param: ["userId": 123], connection: connection)

// Listen for broadcasts
let broadcastListener: BroadcastBlockListener = { param, connection in
    print("Broadcast from \(connection.id):", param ?? "nil")
}
webnat.onBroadcast(name: "userLoggedIn", listener: broadcastListener)

// Stream broadcasts (iOS 13+)
if #available(iOS 13.0, *) {
    Task {
        for await (param, connection) in webnat.listenBroadcast(name: "userLoggedIn") {
            print("Broadcast from \(connection.id):", param ?? "nil")
        }
    }
}

// Call Web-side method (async, iOS 13+)
if #available(iOS 13.0, *) {
    Task {
        do {
            let result = try await webnat.method(
                "getUserInfo",
                param: ["userId": 123],
                timeout: 5.0,
                connection: connection
            )
            print("User info:", result ?? "nil")
        } catch {
            print("Error:", error)
        }
    }
}

// Register method for Web to call
let methodListener: MethodBlockListener = { param, callback, notify, connection in
    let userId = param?["userId"] as? Int ?? 0

    notify(["progress": 50])

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        callback(["userId": userId, "name": "User"], nil)
    }

    return {
        // Cancellation logic
    }
}
webnat.onMethod(name: "getUserInfo", listener: methodListener)
```

## License

This project is licensed under the MIT License.
