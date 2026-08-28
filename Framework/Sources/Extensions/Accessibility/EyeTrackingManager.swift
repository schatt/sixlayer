//
//  EyeTrackingManager.swift
//  SixLayerFramework
//
//  Eye tracking navigation support for accessibility and advanced interaction
//

import SwiftUI
import Foundation

#if os(iOS)
import UIKit
#endif

// MARK: - Eye Tracking Configuration

/// Configuration for eye tracking navigation
public struct EyeTrackingConfig {
    /// Sensitivity level for eye tracking
    public var sensitivity: EyeTrackingSensitivity
    /// Dwell time required for activation
    public var dwellTime: TimeInterval
    /// Whether to enable visual feedback
    public var visualFeedback: Bool
    /// Whether to enable haptic feedback
    public var hapticFeedback: Bool
    /// Calibration settings
    public var calibration: EyeTrackingCalibration
    
    public init(
        sensitivity: EyeTrackingSensitivity = .medium,
        dwellTime: TimeInterval = 1.0,
        visualFeedback: Bool = true,
        hapticFeedback: Bool = true,
        calibration: EyeTrackingCalibration = EyeTrackingCalibration()
    ) {
        self.sensitivity = sensitivity
        self.dwellTime = dwellTime
        self.visualFeedback = visualFeedback
        self.hapticFeedback = hapticFeedback
        self.calibration = calibration
    }
}

/// Eye tracking sensitivity levels
public enum EyeTrackingSensitivity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case adaptive = "adaptive"
    
    public var threshold: Double {
        switch self {
        case .low: return 0.8
        case .medium: return 0.6
        case .high: return 0.4
        case .adaptive: return 0.6
        }
    }
}

/// Eye tracking calibration settings
public struct EyeTrackingCalibration {
    public var isCalibrated: Bool
    public var accuracy: Double
    public var lastCalibrationDate: Date?
    public var calibrationPoints: [CGPoint]
    
    public init(
        isCalibrated: Bool = false,
        accuracy: Double = 0.0,
        lastCalibrationDate: Date? = nil,
        calibrationPoints: [CGPoint] = []
    ) {
        self.isCalibrated = isCalibrated
        self.accuracy = accuracy
        self.lastCalibrationDate = lastCalibrationDate
        self.calibrationPoints = calibrationPoints
    }
}

// MARK: - Eye Tracking Events

/// Eye tracking gaze event
public struct EyeTrackingGazeEvent: Equatable {
    public let position: CGPoint
    public let timestamp: Date
    public let confidence: Double
    public let isStable: Bool
    
    public init(position: CGPoint, timestamp: Date = Date(), confidence: Double, isStable: Bool = false) {
        self.position = position
        self.timestamp = timestamp
        self.confidence = confidence
        self.isStable = isStable
    }
}

/// Eye tracking dwell event
public struct EyeTrackingDwellEvent {
    public let targetView: AnyView
    public let position: CGPoint
    public let duration: TimeInterval
    public let timestamp: Date
    
    public init(targetView: AnyView, position: CGPoint, duration: TimeInterval, timestamp: Date = Date()) {
        self.targetView = targetView
        self.position = position
        self.duration = duration
        self.timestamp = timestamp
    }
}

// MARK: - Eye Tracking Manager

/// Main eye tracking manager for navigation and interaction
@MainActor
public class EyeTrackingManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isEnabled: Bool = false
    @Published public var isCalibrated: Bool = false
    @Published public var currentGaze: CGPoint = .zero
    @Published public var isTracking: Bool = false
    @Published public var lastGazeEvent: EyeTrackingGazeEvent?
    @Published public var dwellTarget: AnyView?
    @Published public var dwellProgress: Double = 0.0
    
    // MARK: - Private Properties
    
    public var config: EyeTrackingConfig
    private var dwellTimer: Timer?
    private var lastGazeTimestamp: Date = Date()
    private var gazeHistory: [EyeTrackingGazeEvent] = []
    private var dwellStartTime: Date?
    private var currentTarget: AnyView?
    
    // MARK: - Initialization
    
    public init(config: EyeTrackingConfig = EyeTrackingConfig()) {
        self.config = config
        self.isCalibrated = config.calibration.isCalibrated
    }
    
    // MARK: - Public Methods
    
    /// Enable eye tracking
    public func enable() {
        guard !isEnabled else { return }
        
        // Check if eye tracking is available on this device
        guard isEyeTrackingAvailable() else {
            print("Eye tracking not available on this device")
            return
        }
        
        isEnabled = true
        startTracking()
    }
    
    /// Disable eye tracking
    public func disable() {
        guard isEnabled else { return }
        
        isEnabled = false
        stopTracking()
        clearDwellTimer()
    }
    
    /// Update configuration
    public func updateConfig(_ newConfig: EyeTrackingConfig) {
        self.config = newConfig
        self.isCalibrated = newConfig.calibration.isCalibrated
    }
    
    /// Process gaze event
    public func processGazeEvent(_ event: EyeTrackingGazeEvent) {
        guard isEnabled else { return }
        
        lastGazeEvent = event
        currentGaze = event.position
        lastGazeTimestamp = event.timestamp
        
        // Add to gaze history
        gazeHistory.append(event)
        if gazeHistory.count > 100 {
            gazeHistory.removeFirst()
        }
        
        // Check for dwell events
        checkForDwellEvent(at: event.position)
    }
    
    /// Start calibration process
    public func startCalibration() {
        // This would typically start a calibration UI
        // For now, we'll simulate calibration completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.completeCalibration()
        }
    }
    
    /// Complete calibration
    public func completeCalibration() {
        var newCalibration = config.calibration
        newCalibration.isCalibrated = true
        newCalibration.accuracy = 0.85
        newCalibration.lastCalibrationDate = Date()
        
        config.calibration = newCalibration
        isCalibrated = true
    }
    
    // MARK: - Private Methods
    
    private func isEyeTrackingAvailable() -> Bool {
        #if os(iOS)
        // Check if device supports eye tracking (typically iPad Pro with Face ID)
        return UIDevice.current.userInterfaceIdiom == .pad
        #elseif os(macOS)
        // macOS doesn't have built-in eye tracking
        return false
        #else
        return false
        #endif
    }
    
    private func startTracking() {
        isTracking = true
        // In a real implementation, this would start the eye tracking system
    }
    
    private func stopTracking() {
        isTracking = false
        clearDwellTimer()
    }
    
    private func checkForDwellEvent(at position: CGPoint) {
        // Find the view at the gaze position
        // This is a simplified implementation
        let targetView = findViewAtPosition(position)
        
        if let target = targetView {
            if currentTarget == nil {
                // Start dwelling on new target
                currentTarget = target
                dwellTarget = target
                dwellStartTime = Date()
                startDwellTimer()
            } else {
                // Switch to different target (we can't compare AnyView directly)
                clearDwellTimer()
                currentTarget = target
                dwellTarget = target
                dwellStartTime = Date()
                startDwellTimer()
            }
        } else {
            // No target, clear dwell
            clearDwellTimer()
        }
    }
    
    private func findViewAtPosition(_ position: CGPoint) -> AnyView? {
        // This is a simplified implementation
        // In a real app, this would use hit testing to find the view at the position
        return nil
    }
    
    private func startDwellTimer() {
        clearDwellTimer()
        
        dwellTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDwellProgress()
            }
        }
    }
    
    private func updateDwellProgress() {
        guard let startTime = dwellStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / config.dwellTime, 1.0)
        
        dwellProgress = progress
        
        if progress >= 1.0 {
            // Dwell completed
            completeDwell()
        }
    }
    
    private func completeDwell() {
        guard let target = currentTarget,
              let startTime = dwellStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let _ = EyeTrackingDwellEvent(
            targetView: target,
            position: currentGaze,
            duration: duration
        )
        
        // Trigger haptic feedback if enabled
        if config.hapticFeedback {
            triggerHapticFeedback()
        }
        
        // Clear dwell state
        clearDwellTimer()
    }
    
    private func clearDwellTimer() {
        dwellTimer?.invalidate()
        dwellTimer = nil
        dwellStartTime = nil
        currentTarget = nil
        dwellTarget = nil
        dwellProgress = 0.0
    }
    
    private func triggerHapticFeedback() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
}

// MARK: - Eye Tracking View Modifier

/// View modifier for eye tracking support
public struct EyeTrackingModifier: ViewModifier {
    @StateObject private var eyeTrackingManager = EyeTrackingManager()
    private let config: EyeTrackingConfig?
    private let onGaze: ((EyeTrackingGazeEvent) -> Void)?
    private let onDwell: ((EyeTrackingDwellEvent) -> Void)?
    
    public init(
        config: EyeTrackingConfig? = nil,
        onGaze: ((EyeTrackingGazeEvent) -> Void)? = nil,
        onDwell: ((EyeTrackingDwellEvent) -> Void)? = nil
    ) {
        self.config = config
        self.onGaze = onGaze
        self.onDwell = onDwell
    }
    
    public func body(content: Content) -> some View {
        UnhostedInspection.split(
            unhosted: {
                content.automaticCompliance(named: "EyeTrackingModifier")
            },
            hosted: {
                content
                    .environmentObject(eyeTrackingManager)
                    .onAppear {
                        if let config = config {
                            eyeTrackingManager.updateConfig(config)
                        }
                        eyeTrackingManager.enable()
                    }
                    .onDisappear {
                        eyeTrackingManager.disable()
                    }
                    .overlay(
                        EyeTrackingFeedbackOverlay(manager: eyeTrackingManager)
                    )
                    .automaticCompliance(named: "EyeTrackingModifier")
            }
        )
    }
}

// MARK: - Eye Tracking Feedback Overlay

private struct EyeTrackingFeedbackOverlay: View {
    @ObservedObject var manager: EyeTrackingManager
    
    var body: some View {
        Group {
            if manager.isEnabled && manager.config.visualFeedback {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .position(manager.currentGaze)
                    .opacity(manager.isTracking ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: manager.currentGaze)
            }
        }
        .automaticCompliance(named: "EyeTrackingFeedbackOverlay")
    }
}

// MARK: - View Extension

public extension View {
    /// Enable eye tracking for this view
    func eyeTrackingEnabled(
        config: EyeTrackingConfig? = nil,
        onGaze: ((EyeTrackingGazeEvent) -> Void)? = nil,
        onDwell: ((EyeTrackingDwellEvent) -> Void)? = nil
    ) -> some View {
        self.modifier(EyeTrackingModifier(config: config, onGaze: onGaze, onDwell: onDwell))
    }
}
