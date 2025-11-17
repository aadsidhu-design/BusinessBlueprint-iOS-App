//
//  NetworkMonitor.swift
//  VentureVoyage
//
//  Monitors network connectivity status
//  Provides real-time network status updates throughout the app
//

import Foundation
import Network
import SwiftUI

/// Monitors network connectivity and provides status updates
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .wifi

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.venturevoyage.networkmonitor")

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown

        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "Unknown"
            }
        }

        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "network"
            }
        }
    }

    private init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                self.isConnected = path.status == .satisfied

                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else {
                    self.connectionType = .unknown
                }

                // Notify user if connection is lost
                if !self.isConnected {
                    UserFeedbackManager.shared.showWarning("No internet connection. Some features may be limited.")
                }
            }
        }

        monitor.start(queue: queue)
        print("🌐 NetworkMonitor: Started monitoring network status")
    }

    private func stopMonitoring() {
        monitor.cancel()
        print("🌐 NetworkMonitor: Stopped monitoring network status")
    }
}

// MARK: - Network Status View

/// View to display network status indicator
struct NetworkStatusBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text("No Internet Connection")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.red)
            .cornerRadius(8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

extension View {
    /// Adds network status monitoring banner to the view
    func withNetworkStatus() -> some View {
        VStack(spacing: 0) {
            NetworkStatusBanner()
                .animation(.spring(), value: NetworkMonitor.shared.isConnected)

            self
        }
    }
}
