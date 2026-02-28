//
//  LogEntry.swift
//  Example
//
//  Created by auhgnayuo on 2025/11/14.
//

import Foundation

struct LogEntry: Identifiable {
    let id = UUID()
    let time: String
    let type: LogType
    let category: LogCategory
    let message: String
    
    enum LogType: String {
        case sent = "发送"
        case received = "接收"
        case error = "错误"
    }
    
    enum LogCategory: String {
        case raw = "Raw"
        case broadcast = "Broadcast"
        case method = "Method"
        case system = "系统"
    }
    
    static func create(type: LogType, category: LogCategory, message: String) -> LogEntry {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let time = formatter.string(from: Date())
        
        return LogEntry(time: time, type: type, category: category, message: message)
    }
}
