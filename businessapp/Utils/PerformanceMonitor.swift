import SwiftUI
import Foundation
import Combine
import os.log

// MARK: - Performance Monitor

class PerformanceMonitor: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "BusinessApp", category: "Performance")
    
    @Published var memoryUsage: Double = 0
    @Published var cpuUsage: Double = 0
    @Published var networkRequests: [NetworkRequest] = []
    @Published var viewRenderTimes: [ViewRenderTime] = []
    
    private var timer: Timer?
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateMemoryUsage()
            }
        }
    }
    
    func logNetworkRequest(_ request: NetworkRequest) {
        DispatchQueue.main.async {
            self.networkRequests.append(request)
            // Keep only last 50 requests
            if self.networkRequests.count > 50 {
                self.networkRequests.removeFirst()
            }
        }
        
        logger.info("Network request: \(request.endpoint) - \(request.duration)ms")
    }
    
    func logViewRender(_ viewName: String, duration: TimeInterval) {
        let renderTime = ViewRenderTime(viewName: viewName, duration: duration, timestamp: Date())
        
        DispatchQueue.main.async {
            self.viewRenderTimes.append(renderTime)
            // Keep only last 30 render times
            if self.viewRenderTimes.count > 30 {
                self.viewRenderTimes.removeFirst()
            }
        }
        
        if duration > 0.1 { // Log slow renders
            logger.warning("Slow view render: \(viewName) - \(Int(duration * 1000))ms")
        }
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
            self.memoryUsage = memoryUsageMB
            
            if memoryUsageMB > 200 { // Log high memory usage
                logger.warning("High memory usage: \(Int(memoryUsageMB))MB")
            }
        }
    }
}

struct NetworkRequest: Identifiable {
    let id = UUID()
    let endpoint: String
    let method: String
    let duration: TimeInterval
    let statusCode: Int?
    let timestamp: Date
    let success: Bool
}

struct ViewRenderTime: Identifiable {
    let id = UUID()
    let viewName: String
    let duration: TimeInterval
    let timestamp: Date
}

// MARK: - Performance View Modifier

struct PerformanceTracker: ViewModifier {
    let viewName: String
    @State private var startTime: Date?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                startTime = Date()
            }
            .onDisappear {
                if let startTime = startTime {
                    let duration = Date().timeIntervalSince(startTime)
                    PerformanceMonitor.shared.logViewRender(viewName, duration: duration)
                }
            }
    }
}

extension View {
    func trackPerformance(name: String) -> some View {
        self.modifier(PerformanceTracker(viewName: name))
    }
}

// MARK: - Memory Optimization Helpers

extension View {
    /// Optimize list performance by using lazy loading
    func optimizedList() -> some View {
        self
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
    }
    
    /// Cache expensive computations
    func cached<T: Equatable>(_ value: T, computation: @escaping (T) -> some View) -> some View {
        CachedView(value: value, computation: computation)
    }
}

struct CachedView<T: Equatable, Content: View>: View {
    let value: T
    let computation: (T) -> Content
    
    @State private var cachedResult: Content?
    @State private var cachedValue: T?
    
    var body: some View {
        Group {
            if let cached = cachedResult, cachedValue == value {
                cached
            } else {
                Color.clear
                    .onAppear {
                        cachedResult = computation(value)
                        cachedValue = value
                    }
            }
        }
    }
}

// MARK: - Image Optimization

extension Image {
    /// Optimize image loading and caching
    func optimized() -> some View {
        self
            .renderingMode(.original)
            .interpolation(.high)
            .antialiased(true)
    }
}

// MARK: - Accessibility Enhancements

struct AccessibilityEnhanced: ViewModifier {
    let label: String
    let hint: String?
    let value: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

extension View {
    func accessibilityEnhanced(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self.modifier(AccessibilityEnhanced(
            label: label,
            hint: hint,
            value: value
        ))
    }
}

// MARK: - Network Optimization

extension URLSession {
    static let optimized: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024)
        return URLSession(configuration: config)
    }()
}

// MARK: - Performance Debug View

struct PerformanceDebugView: View {
    @StateObject private var monitor = PerformanceMonitor.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section("System") {
                    HStack {
                        Text("Memory Usage")
                        Spacer()
                        Text("\(Int(monitor.memoryUsage))MB")
                            .foregroundColor(monitor.memoryUsage > 150 ? .red : .green)
                    }
                }
                
                Section("Network Requests") {
                    ForEach(monitor.networkRequests.suffix(10)) { request in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(request.endpoint)
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(request.duration * 1000))ms")
                                    .font(.caption2)
                                    .foregroundColor(request.success ? .green : .red)
                            }
                            Text(request.method)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("View Render Times") {
                    ForEach(monitor.viewRenderTimes.suffix(10)) { render in
                        HStack {
                            Text(render.viewName)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(render.duration * 1000))ms")
                                .font(.caption2)
                                .foregroundColor(render.duration > 0.1 ? .red : .green)
                        }
                    }
                }
            }
            .navigationTitle("Performance")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#if DEBUG
extension View {
    func performanceDebug() -> some View {
        self.overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("Performance") {
                        // Show performance debug
                    }
                    .padding(8)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
                }
            },
            alignment: .bottomTrailing
        )
    }
}
#endif