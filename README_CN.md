# Webnat

[![Swift](https://img.shields.io/badge/Swift-5.5-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2012%2B%20%7C%20macOS%2010.14%2B-lightgrey.svg)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Webnat 是一个用于 Native (iOS/macOS) 与 Web 之间通信的 Swift 库。支持多种通信模式，基于 WebKit 的 `WKWebView` 和 `WKScriptMessageHandler`。

## 特性

- **多平台支持** - 支持 iOS 12+ 和 macOS 10.14+
- **iframe 支持** - 自动处理主框架和 iframe 之间的消息转发
- **三种通信模式** - 支持双向的原始消息、广播消息和方法调用（RPC）
- **超时和取消** - 内置超时控制和主动取消机制
- **类型安全** - 完全支持 Swift 6 严格并发检查

## 安装

### Swift Package Manager

在你的 `Package.swift` 文件中添加：

```swift
dependencies: [
    .package(url: "https://github.com/auhgnayuo/webnat-os.git", from: "1.0.2")
]
```

或在 Xcode 中：

1. File → Add Package Dependencies...
2. 输入仓库地址：`https://github.com/auhgnayuo/webnat-os.git`
3. 选择版本规则
4. 点击 Add Package

## 相关项目

Webnat 需要配合 Web 端实现使用，同时也支持其他 Native 平台：

| 平台 | 仓库 |
|------|------|
| Web (JavaScript/TypeScript) | [webnat-web](https://github.com/auhgnayuo/webnat-web) |
| Android (Kotlin) | [webnat-android](https://github.com/auhgnayuo/webnat-android) |
| HarmonyOS (ArkTS) | [webnat-ohos](https://github.com/auhgnayuo/webnat-ohos) |

## 基本使用

### 1. 初始化

```swift
import Webnat
import WebKit

let configuration = WKWebViewConfiguration()
Webnat.initialize(webViewConfiguration: configuration)
let webView = WKWebView(frame: .zero, configuration: configuration)
let webnat = Webnat.of(webView)
```

### 2. 等待 Web 端建立连接

连接是由 **Web 端（JavaScript）主动发起**的，Native 端会自动接收和管理连接。

```swift
// Web 端（JavaScript）会发送 "open" 消息来建立连接
// Native 端自动创建 Connection 实例并存储在 webnat.connections 中

// 访问所有活跃连接
let connections = webnat.connections
print("当前有 \(connections.count) 个连接")

// 通过 ID 获取特定连接
if let connection = connections["connection-id"] {
    print("找到连接:", connection.id)
    print("连接属性:", connection.attributes ?? [:])
}
```

### 3. 发送和接收消息

```swift
// 发送原始消息
webnat.raw("Hello from Native!", connection: connection)

// 监听原始消息
let rawListener: RawBlockListener = { raw, connection in
    print("From \(connection.id):", raw)
}
webnat.onRaw(listener: rawListener)

// 广播消息
webnat.broadcast(name: "userLoggedIn", param: ["userId": 123], connection: connection)

// 监听广播消息
let broadcastListener: BroadcastBlockListener = { param, connection in
    print("Broadcast from \(connection.id):", param ?? "nil")
}
webnat.onBroadcast(name: "userLoggedIn", listener: broadcastListener)

// 流式监听广播消息（iOS 13+）
if #available(iOS 13.0, *) {
    Task {
        for await (param, connection) in webnat.listenBroadcast(name: "userLoggedIn") {
            print("Broadcast from \(connection.id):", param ?? "nil")
        }
    }
}

// 调用 Web 端方法
webnat.method(
    "getUserInfo",
    param: ["userId": 123],
    timeout: 5.0,
    connection: connection
) { result, error in
    if let error = error {
        print("Error:", error)
    } else {
        print("User info:", result ?? "nil")
    }
}

// 异步方式调用 Web 端方法（iOS 13+）
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

// 注册方法供 Web 调用
let methodListener: MethodBlockListener = { param, callback, notify, connection in
    let userId = param?["userId"] as? Int ?? 0

    // 可以发送途中的通知（如进度更新）
    notify(["progress": 50])

    // 模拟异步操作
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        callback(["userId": userId, "name": "User"], nil)
    }

    return {
        // 取消操作的逻辑
    }
}
webnat.onMethod(name: "getUserInfo", listener: methodListener)
```

## 协议

本项目采用 MIT 协议开源。
