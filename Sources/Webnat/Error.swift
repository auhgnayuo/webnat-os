//
//  Error.swift
//  Webnat
//
//  Created by Auhgnayuo on 2024/12/9.
//

import Foundation

/// Webnat 错误域常量
///
/// 用于标识 Webnat 框架产生的错误，值为 `"WebnatErrorDomain"`。
public let WebnatErrorDomain = "WebnatErrorDomain"

/// Webnat 错误码定义
public struct WebnatErrorCode {
    /// 未知错误
    ///
    /// 无法识别或分类的错误
    public static let unknown = -1
    
    /// 请求已取消
    ///
    /// 当用户主动取消某个操作（如 RPC 方法调用）时触发
    public static let cancelled = -999
    
    /// 请求超时
    ///
    /// 当操作或调用超时（如 RPC 方法调用超过指定超时时间）时触发
    public static let timeout = -1001
    
    /// 连接已关闭
    ///
    /// 当尝试向已关闭的连接发送消息时触发
    public static let closed = -1004

    /// 方法未实现
    ///
    /// 当调用的方法在对端（Web/Native）未注册处理器时触发
    public static let unimplemented = -1010
    
    /// 消息反序列化失败
    ///
    /// 当接收到的消息无法解析为 Swift 可用对象时触发
    public static let deserializationFailed = -1011
    
    /// 消息序列化失败
    ///
    /// 当消息对象无法转换为 JSON 格式时触发
    public static let serializationFailed = -1012

    private init() {}
}

extension NSError {
    /// 便利构造器：创建 Webnat 错误
    ///
    /// 使用统一的错误域 "WebnatErrorDomain" 创建错误对象
    ///
    /// - Parameters:
    ///   - code: 错误码
    ///   - msg: 错误消息
    convenience init(_ code: Int, _ msg: String) {
        self.init(domain: WebnatErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: msg])
    }

    /// 从任意对象反序列化为 Error
    ///
    /// 此方法用于将从 JavaScript 端接收到的错误对象转换为 Swift Error
    ///
    /// 支持的输入格式：
    /// 1. 字典格式：{ "code": Int, "message": String } 或其它系统常见字段命名（区分大小写，不同风格均支持）
    /// 2. 其他类型：将对象描述作为错误消息
    static func from(_ obj: Any) -> NSError {
        if let obj = obj as? NSError {
            return obj
        }
        guard let obj = obj as? [String: Any] else {
            // 非字典对象时，直接用整个对象描述作为错误
            return NSError(domain: WebnatErrorDomain, code: WebnatErrorCode.unknown, userInfo: [
                NSLocalizedDescriptionKey: "\(obj)"
            ])
        }
        
        let code = {
            // 支持多种常见 code 字段变体
            let v = obj["code"] ?? obj["errcode"] ?? obj["errCode"] ?? obj["errorcode"] ?? obj["errorCode"]
            if let v = v as? Int {
                return v
            }
            if let v = v as? String {
                return Int(v) ?? WebnatErrorCode.unknown
            }
            return WebnatErrorCode.unknown
        }()
        
        let msg = {
            // 支持多种常见 message/msg 字段变体
            if let v = (obj["message"] ?? obj["msg"] ?? obj["errmsg"] ?? obj["errMsg"] ?? obj["errormsg"] ?? obj["errorMsg"] ?? obj["errormessage"] ?? obj["errorMessage"]) {
                return "\(v)"
            }
            return "Unknown Error"
        }()
        
        return NSError(domain: WebnatErrorDomain, code: code, userInfo: [
            NSLocalizedDescriptionKey: msg
        ])
    }
    
    /// 构造未知错误
    static func unknown(_ obj: Sendable?) -> NSError {
        return NSError(WebnatErrorCode.unknown, "Unknown Error\(obj == nil ? "" : ": \(obj!)")")
    }
    
    /// 构造操作取消错误
    static func cancelled() -> NSError {
        return NSError(WebnatErrorCode.cancelled, "Operation Cancelled")
    }
    
    /// 构造超时错误
    static func timeout() -> NSError {
        return NSError(WebnatErrorCode.timeout, "Operation Timeout")
    }
    
    /// 构造连接关闭错误
    static func closed() -> NSError {
        return NSError(WebnatErrorCode.closed, "Connection Closed")
    }
    
    /// 构造未实现错误
    static func unimplemented(_ obj: Any?) -> NSError {
        return NSError(WebnatErrorCode.unimplemented, "Unimplemented Method\(obj == nil ? "" : ": \(obj!)")")
    }
    
    /// 构造反序列化失败错误
    static func deserializationFailed(_ obj: Any?) -> NSError {
        return NSError(WebnatErrorCode.deserializationFailed, "Deserialization Failed\(obj == nil ? "" : ": \(obj!)")")
    }
    
    /// 构造序列化失败错误
    static func serializationFailed(_ obj: Any?) -> NSError {
        return NSError(WebnatErrorCode.serializationFailed, "Serialization Failed\(obj == nil ? "" : ": \(obj!)")")
    }
    
    /// 转为 JSON 格式（便于返回 JS 或日志）
    ///
    /// 将 `NSError` 转换为字典格式，包含 `code` 和 `message` 字段。
    ///
    /// - Returns: 包含错误码和错误消息的字典
    func toJson() -> [String: Sendable] {
        return [
            "code": code,
            "message": localizedDescription
        ]
    }
}
