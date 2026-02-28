import Foundation

/// JavaScriptAliveKeeper - JavaScript 保活管理器
///
/// 用于保持与 JavaScript 的心跳活跃状态，防止系统挂起 JS 执行。
///
/// **工作原理**：
/// - 该类会周期性地调用提供的心跳回调，以维持 JS 侧的活跃性
/// - 支持引用计数，只有在至少有一个引用时才启动心跳定时器
/// - 心跳定时器仅在有引用时激活，无引用时自动停止
///
/// **主要场景**：
/// - WebView 失活（比如不在窗口上，系统会尽可能挂起 JS 执行）
/// - Native 侧调用 JS 侧的异步延迟方法，还未处理完，这个时候 JS 挂起，就不会再执行
/// - 通过 `evaluateJavaScript`，可以让 JS 短暂运行，保持执行环境活跃
///
/// **生命周期管理**：
/// - `increaseReference()` 增加引用计数
/// - `decreaseReference()` 减少引用计数
/// - 当引用计数为 0 时，自动停止心跳定时器
///
/// - Note: 这是内部类，不应直接使用

@MainActor
final class JavaScriptAliveKeeper {
    /// 心跳定时器的触发间隔（秒）
    private let timerInterval: TimeInterval

    /// 心跳回调函数，每次心跳时都会调用
    private let heartbeat: () -> Void

    /// 以指定心跳时间间隔和回调初始化
    ///
    /// - Parameters:
    ///   - timerInterval: 定时器触发的周期（秒），用于定时检查是否应该触发心跳
    ///   - heartbeat: 心跳回调函数
    init(timerInterval: TimeInterval, heartbeat: @escaping (() -> Void)) {
        self.timerInterval = timerInterval
        self.heartbeat = heartbeat
    }

    /// 心跳间隔（秒），实际触发心跳的间隔，必须大于 0
    ///
    /// 修改此值将影响下次心跳的计划时间。若赋值小于等于 0，则保持原值不变。
    var heartbeatInterval: TimeInterval = 1 {
        didSet {
            if heartbeatInterval <= 0 {
                // 不允许非正数，恢复上一个有效值并打印警告
                heartbeatInterval = oldValue
                print("Invalid heartbeatInterval, using previous value: \(oldValue)")
            } else {
                // 更新下次心跳计划时间，保持间隔不变
                if let next = nextHeartbeatTime {
                    nextHeartbeatTime = next.addingTimeInterval(heartbeatInterval - oldValue)
                }
            }
        }
    }

    /// 当前引用计数（有多少对象/连接需要保持心跳）
    private var referenceCount = 0

    /// 下次心跳计划的时间点
    private var nextHeartbeatTime: Date?

    /// 管理心跳的 GCD 定时器
    private var timer: DispatchSourceTimer?

    /// 增加引用计数
    ///
    /// 当第一个引用到来时自动启动心跳定时器
    func increaseReference() {
        referenceCount += 1
        if referenceCount == 1 {
            startTimer()
        }
    }

    /// 减少引用计数
    ///
    /// 当引用计数减为 0 时自动停止心跳定时器
    func decreaseReference() {
        referenceCount = max(referenceCount - 1, 0)
        if referenceCount == 0 {
            stopTimer()
        }
    }

    /// 推迟下次心跳时间
    ///
    /// 立即把下次心跳推迟到当前时间后的一个心跳间隔
    func delay() {
        nextHeartbeatTime = Date().addingTimeInterval(heartbeatInterval)
    }

    /// 启动心跳定时器
    ///
    /// 若定时器已存在则先停止。定时器每隔 `timerInterval` 检查是否到下次心跳时间。
    private func startTimer() {
        stopTimer()
        nextHeartbeatTime = Date().addingTimeInterval(heartbeatInterval)
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.setEventHandler { [weak self] in
            guard let self, let next = self.nextHeartbeatTime else { return }
            let now = Date()
            // 已到计划心跳时间，触发心跳并重新计划下次心跳
            if now >= next {
                self.heartbeat()
                self.nextHeartbeatTime = now.addingTimeInterval(self.heartbeatInterval)
            }
        }
        t.schedule(deadline: .now() + timerInterval, repeating: timerInterval)
        t.resume()
        timer = t
    }

    /// 停止心跳定时器
    ///
    /// 释放定时器资源，防止内存泄漏
    private func stopTimer() {
        guard let t = timer else { return }
        t.setEventHandler(handler: nil)
        t.cancel()
        timer = nil
    }
}
