//
//  Listener.swift
//  Webnat
//
//  Created by auhgnayuo on 2025/11/9.
//

/// Listener - 用于包装监听器（如方法监听、消息监听等）
///
/// 说明：
/// - 通过 Any 类型存放监听器闭包或对象
/// - 支持引用判等（同一实例引用才认为相等）
/// - 用于便捷管理和注销监听器
@MainActor
final class Listener: Equatable {
    /// 被包装的监听对象，可以是任意类型（如监听器 closure、对象等）
    let value: Any

    /// 初始化监听器包装类
    /// - Parameter value: 需要包装的监听器（闭包、对象等）
    init(value: Any) {
        self.value = value
    }

    /// Equatable 协议实现，通过引用判等区分唯一性
    /// - Parameters:
    ///   - lhs: 左侧 Listener 实例
    ///   - rhs: 右侧 Listener 实例
    /// - Returns: 是否为同一实例（引用相等）
    nonisolated static func == (lhs: Listener, rhs: Listener) -> Bool {
        return lhs === rhs
    }
}
