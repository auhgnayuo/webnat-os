//
//  ScriptMessageHandler.swift
//  Webnat
//
//  Created by Auhgnayuo on 2024/12/9.
//

import WebKit

/// 脚本消息处理器
///
/// 用于拦截 WKWebView 通过 `window.webkit.messageHandlers.__native_webnat__.postMessage()` 发送的消息，
/// 并转发给 `Webnat` 进行统一分发和处理。
///
/// 实现 `WKScriptMessageHandler` 协议，作为 Web 端与 Native 端之间的消息桥接。
///
/// - Note: 这是内部类，不应直接使用
class ScriptMessageHandler: NSObject {
    // 该类当前没有任何属性和方法，仅作为 WKScriptMessageHandler 的适配桥接
}

// MARK: - WKScriptMessageHandler 协议实现
extension ScriptMessageHandler: WKScriptMessageHandler {
    /// WKWebView 收到来自前端脚本的消息时回调
    ///
    /// 当 Web 端通过 `window.webkit.messageHandlers.__native_webnat__.postMessage()` 发送消息时，
    /// 此方法会被系统调用，然后转发给对应的 `Webnat` 实例进行处理。
    ///
    /// - Parameters:
    ///   - userContentController: 消息控制器
    ///   - message: 前端通过 `postMessage` 发送的消息对象，`body` 通常已自动转换为字典类型
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // 尝试取出消息关联的 WebView
        if let webView = message.webView {
            // 获取（或创建）与该 WebView 绑定的 Webnat 实例，并把收到的消息进行消息转发和处理
            let webnat = Webnat.of(webView)
            webnat.userContentController(userContentController, didReceive: message)
        }
    }
}
