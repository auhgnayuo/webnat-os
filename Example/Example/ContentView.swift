//
//  ContentView.swift
//  Example
//
//  Created by auhgnayuo on 2025/11/14.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var viewModel = WebnatViewModel()
    
    // 获取 webnat_web example 的 URL
    // 这里假设在开发环境中可以通过本地服务器访问
    // 实际使用时需要根据实际情况调整 URL
    private var webURL: URL {
        // 开发环境：使用本地服务器
        // 生产环境：需要部署 webnat_web 的 example 到服务器
        if let url = URL(string: "http://172.16.71.254:5173/") {
            return url
        }
        // 备用：使用本地文件（需要先构建 webnat_web example）
        return Bundle.main.bundleURL.appendingPathComponent("webnat_web_example/index.html")
    }
    
    var body: some View {
        TabView {
            // 第一个 Tab: Web 界面
            WebTabView(url: webURL, viewModel: viewModel)
                .tabItem {
                    Label("Web", systemImage: "globe")
                }
            
            // 第二个 Tab: 原生界面
            NativeTabView(viewModel: viewModel)
                .tabItem {
                    Label("原生", systemImage: "app.fill")
                }
        }
    }
}

// Web 界面 Tab
struct WebTabView: View {
    let url: URL
    @ObservedObject var viewModel: WebnatViewModel
    
    var body: some View {
        WebViewWrapper(url: url) { webView in
            viewModel.setup(webView: webView)
        }
        .edgesIgnoringSafeArea([])
    }
}

// 原生界面 Tab
struct NativeTabView: View {
    @ObservedObject var viewModel: WebnatViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制面板
            VStack(spacing: 12) {
                HStack {
                    Text("Native 控制面板")
                        .font(.headline)
                    Spacer()
                    Text("连接数: \(viewModel.connectionCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.sendRaw()
                    }) {
                        Label("发送 Raw", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        viewModel.sendBroadcast()
                    }) {
                        Label("发送 Broadcast", systemImage: "megaphone.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        viewModel.sendMethod()
                    }) {
                        Label("发送 Method", systemImage: "function")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                HStack {
                    Button(action: {
                        viewModel.clearLogs()
                    }) {
                        Label("清空日志", systemImage: "trash")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                    }
                    Spacer()
                }
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            
            Divider()
            
            // 日志显示区域
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.logs) { log in
                            LogRowView(log: log)
                                .id(log.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.logs.count) { _ in
                    if let lastLog = viewModel.logs.last {
                        withAnimation {
                            proxy.scrollTo(lastLog.id, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

struct LogRowView: View {
    let log: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(log.time)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
            
            Text(log.type.rawValue)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(typeColor)
                .foregroundColor(.white)
                .cornerRadius(4)
            
            Text("\(log.category.rawValue): \(log.message)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(borderColor, lineWidth: 2)
        )
    }
    
    private var typeColor: Color {
        switch log.type {
        case .sent:
            return .green
        case .received:
            return .blue
        case .error:
            return .red
        }
    }
    
    private var backgroundColor: Color {
        switch log.type {
        case .sent:
            return Color.green.opacity(0.1)
        case .received:
            return Color.blue.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch log.type {
        case .sent:
            return .green
        case .received:
            return .blue
        case .error:
            return .red
        }
    }
}

#Preview {
    ContentView()
}
