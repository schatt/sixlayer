//
//  NotificationExamplesView.swift
//  SixLayerFrameworkRealUITests
//
//  Examples of Layer 1 notification functions
//  Issue #166
//

import SwiftUI
import SixLayerFramework

struct NotificationExamplesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ExampleSection(title: "Alert Presentation") {
                AlertExamples()
            }
            
            ExampleSection(title: "Notification Functions") {
                NotificationFunctionExamples()
            }
        }
        .padding()
    }
}

struct AlertExamples: View {
    @State private var showAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alert Presentation")
                .font(.headline)
            
            platformPresentAlert_L1(
                title: "Test Alert",
                message: "This is a test alert message"
            )
            .frame(height: 100)
            
            Button("Show Alert") {
                showAlert = true
            }
            .buttonStyle(.borderedProminent)
            .alert("Test Alert", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text("This is a test alert message")
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct NotificationFunctionExamples: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notification Functions")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• platformRequestNotificationPermission_L1")
                    .font(.caption)
                Text("• platformShowNotification_L1")
                    .font(.caption)
                Text("• platformUpdateBadge_L1")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            Text("Note: These are async/throwing functions that don't return Views")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}
