//
//  BasicComplianceTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for basic automatic compliance tests (Issue #172)
//

import SwiftUI
import SixLayerFramework

struct BasicComplianceTestView: View {
    let onBackToMain: () -> Void
    
    var body: some View {
        platformScrollViewContainer {
            platformVStack(spacing: 24) {
                platformText("Basic Compliance Test View")
                    .font(.headline)
                    .automaticCompliance()
                
                // Back to main page button
                platformButton("Back to Main") {
                    onBackToMain()
                }
                .accessibilityIdentifier("back-to-main-button")
                .padding(.bottom)
                
                // Test 1: General .basicAutomaticCompliance() with identifier
                platformVStack(alignment: .leading, spacing: 8) {
                    platformText("General Basic Compliance (Identifier)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()
                    
                    platformText("Test Content")
                        .basicAutomaticCompliance(identifierName: "testView")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
                
                // Test 2: General .basicAutomaticCompliance() with label
                platformVStack(alignment: .leading, spacing: 8) {
                    platformText("General Basic Compliance (Label)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()
                    
                    platformText("Test Content")
                        .basicAutomaticCompliance(identifierName: "testViewWithLabel", accessibilityLabel: "Test label")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
                
                // Test 3: Text.basicAutomaticCompliance() with identifier
                platformVStack(alignment: .leading, spacing: 8) {
                    platformText("Text Basic Compliance (Identifier)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()
                    
                    platformText("Hello")
                        .basicAutomaticCompliance(identifierName: "helloText")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
                
                // Test 4: Text.basicAutomaticCompliance() with label
                platformVStack(alignment: .leading, spacing: 8) {
                    platformText("Text Basic Compliance (Label)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()
                    
                    platformText("Hello")
                        .basicAutomaticCompliance(identifierName: "helloTextWithLabel", accessibilityLabel: "Hello text")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
                
                // Test 5: Identifier sanitization (spaces and uppercase)
                platformVStack(alignment: .leading, spacing: 8) {
                    platformText("Identifier Sanitization (Spaces/Uppercase)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()
                    
                    platformText("Test")
                        .basicAutomaticCompliance(
                            identifierName: "TestButton",
                            identifierLabel: "Save File"
                        )
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
                
                // Test 6: Identifier sanitization (special characters)
                platformVStack(alignment: .leading, spacing: 8) {
                    platformText("Identifier Sanitization (Special Characters)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()
                    
                    platformText("Test")
                        .basicAutomaticCompliance(
                            identifierName: "TestButton",
                            identifierLabel: "Save & Load!"
                        )
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
                
                // Test 7: Image.basicAutomaticCompliance() with identifier
                platformVStack(alignment: .leading, spacing: 8) {
                    platformText("Image Basic Compliance (Identifier)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()
                    
                    Image(systemName: "star")
                        .basicAutomaticCompliance(identifierName: "starImage")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Basic Compliance Test")
    }
}
