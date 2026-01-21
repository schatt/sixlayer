//
//  AccessibilityIdentifierConfigUserDefaultsTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE: Tests for UserDefaults persistence in AccessibilityIdentifierConfig
//  Following TDD: Write tests first, then implement functionality
//
//  TESTING SCOPE: UserDefaults save/load functionality for configuration
//  - Saving configuration to UserDefaults
//  - Loading configuration from UserDefaults
//  - Defaults when no saved config exists
//  - Persistence across app launches
//
//  METHODOLOGY: TDD Red-Green-Refactor cycle
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("AccessibilityIdentifierConfig UserDefaults Persistence")
open class AccessibilityIdentifierConfigUserDefaultsTests: BaseTestClass {
    
    // MARK: - Test Setup
    
    private let testUserDefaultsKeyPrefix = "SixLayer.Accessibility.Test"
    
    /// Clean up test UserDefaults keys
    private func cleanupTestUserDefaults() {
        let keys = [
            "\(testUserDefaultsKeyPrefix).enableAutoIDs",
            "\(testUserDefaultsKeyPrefix).includeComponentNames",
            "\(testUserDefaultsKeyPrefix).includeElementTypes",
            "\(testUserDefaultsKeyPrefix).enableUITestIntegration",
            "\(testUserDefaultsKeyPrefix).namespace",
            "\(testUserDefaultsKeyPrefix).globalPrefix",
            "\(testUserDefaultsKeyPrefix).enableDebugLogging",
            "\(testUserDefaultsKeyPrefix).mode"
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    // MARK: - TDD Red Phase: Tests That Should Fail Initially
    
    @Test @MainActor func testSaveToUserDefaultsSavesConfiguration() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: A configuration with custom values
            config.enableAutoIDs = false
            config.includeComponentNames = false
            config.includeElementTypes = false
            config.enableUITestIntegration = true
            config.namespace = "TestNamespace"
            config.globalPrefix = "TestPrefix"
            config.enableDebugLogging = true
            config.mode = .manual
            
            // When: Saving to UserDefaults
            // TDD: This method doesn't exist yet - test should fail
            config.saveToUserDefaults()
            
            // Then: Values should be saved to UserDefaults
            // Note: We'll check the actual keys once we implement the method
            let savedEnableAutoIDs = UserDefaults.standard.bool(forKey: "SixLayer.Accessibility.enableAutoIDs")
            #expect(savedEnableAutoIDs == false, "enableAutoIDs should be saved to UserDefaults")
        }
    }
    
    @Test @MainActor func testLoadFromUserDefaultsLoadsConfiguration() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Saved configuration in UserDefaults
            UserDefaults.standard.set(false, forKey: "SixLayer.Accessibility.enableAutoIDs")
            UserDefaults.standard.set(false, forKey: "SixLayer.Accessibility.includeComponentNames")
            UserDefaults.standard.set(true, forKey: "SixLayer.Accessibility.enableUITestIntegration")
            UserDefaults.standard.set("SavedNamespace", forKey: "SixLayer.Accessibility.namespace")
            UserDefaults.standard.set("SavedPrefix", forKey: "SixLayer.Accessibility.globalPrefix")
            UserDefaults.standard.set(true, forKey: "SixLayer.Accessibility.enableDebugLogging")
            UserDefaults.standard.set("manual", forKey: "SixLayer.Accessibility.mode")
            
            // Reset config to defaults first
            config.resetToDefaults()
            
            // When: Loading from UserDefaults
            // TDD: This method doesn't exist yet - test should fail
            config.loadFromUserDefaults()
            
            // Then: Configuration should be loaded from UserDefaults
            #expect(config.enableAutoIDs == false, "enableAutoIDs should be loaded from UserDefaults")
            #expect(config.includeComponentNames == false, "includeComponentNames should be loaded from UserDefaults")
            #expect(config.enableUITestIntegration == true, "enableUITestIntegration should be loaded from UserDefaults")
            #expect(config.namespace == "SavedNamespace", "namespace should be loaded from UserDefaults")
            #expect(config.globalPrefix == "SavedPrefix", "globalPrefix should be loaded from UserDefaults")
            #expect(config.enableDebugLogging == true, "enableDebugLogging should be loaded from UserDefaults")
            #expect(config.mode == .manual, "mode should be loaded from UserDefaults")
            
            // Cleanup
            cleanupTestUserDefaults()
        }
    }
    
    @Test @MainActor func testLoadFromUserDefaultsRespectsDefaultsWhenNoSavedConfig() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: No saved configuration in UserDefaults (clean state)
            cleanupTestUserDefaults()
            
            // Reset config to defaults
            config.resetToDefaults()
            
            // When: Loading from UserDefaults (no saved values)
            config.loadFromUserDefaults()
            
            // Then: Configuration should keep default values
            #expect(config.enableAutoIDs == true, "enableAutoIDs should keep default value when no saved config")
            #expect(config.includeComponentNames == true, "includeComponentNames should keep default value")
            #expect(config.includeElementTypes == true, "includeElementTypes should keep default value")
            #expect(config.enableUITestIntegration == false, "enableUITestIntegration should keep default value")
            #expect(config.namespace == "", "namespace should keep default value")
            #expect(config.globalPrefix == "", "globalPrefix should keep default value")
            #expect(config.enableDebugLogging == false, "enableDebugLogging should keep default value")
            #expect(config.mode == .automatic, "mode should keep default value")
        }
    }
    
    @Test @MainActor func testConfigurationPersistenceAcrossAppLaunches() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: A configuration with custom values
            config.enableAutoIDs = false
            config.namespace = "PersistentNamespace"
            config.globalPrefix = "PersistentPrefix"
            config.enableUITestIntegration = true
            
            // When: Saving to UserDefaults
            config.saveToUserDefaults()
            
            // Simulate app restart: create new config instance
            let newConfig = AccessibilityIdentifierConfig()
            newConfig.resetToDefaults()
            
            // Load from UserDefaults
            newConfig.loadFromUserDefaults()
            
            // Then: Configuration should be restored
            #expect(newConfig.enableAutoIDs == false, "enableAutoIDs should persist across app launches")
            #expect(newConfig.namespace == "PersistentNamespace", "namespace should persist across app launches")
            #expect(newConfig.globalPrefix == "PersistentPrefix", "globalPrefix should persist across app launches")
            #expect(newConfig.enableUITestIntegration == true, "enableUITestIntegration should persist across app launches")
            
            // Cleanup
            cleanupTestUserDefaults()
        }
    }
    
    @Test @MainActor func testSaveToUserDefaultsSavesAllProperties() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: A configuration with all properties set
            config.enableAutoIDs = false
            config.includeComponentNames = false
            config.includeElementTypes = false
            config.enableUITestIntegration = true
            config.namespace = "AllPropsNamespace"
            config.globalPrefix = "AllPropsPrefix"
            config.enableDebugLogging = true
            config.mode = .semantic
            
            // When: Saving to UserDefaults
            config.saveToUserDefaults()
            
            // Then: All properties should be saved
            #expect(UserDefaults.standard.object(forKey: "SixLayer.Accessibility.enableAutoIDs") != nil, "enableAutoIDs should be saved")
            #expect(UserDefaults.standard.object(forKey: "SixLayer.Accessibility.includeComponentNames") != nil, "includeComponentNames should be saved")
            #expect(UserDefaults.standard.object(forKey: "SixLayer.Accessibility.includeElementTypes") != nil, "includeElementTypes should be saved")
            #expect(UserDefaults.standard.object(forKey: "SixLayer.Accessibility.enableUITestIntegration") != nil, "enableUITestIntegration should be saved")
            #expect(UserDefaults.standard.object(forKey: "SixLayer.Accessibility.namespace") != nil, "namespace should be saved")
            #expect(UserDefaults.standard.object(forKey: "SixLayer.Accessibility.globalPrefix") != nil, "globalPrefix should be saved")
            #expect(UserDefaults.standard.object(forKey: "SixLayer.Accessibility.enableDebugLogging") != nil, "enableDebugLogging should be saved")
            #expect(UserDefaults.standard.object(forKey: "SixLayer.Accessibility.mode") != nil, "mode should be saved")
            
            // Cleanup
            cleanupTestUserDefaults()
        }
    }
    
    @Test @MainActor func testLoadFromUserDefaultsOnlyLoadsIfKeyExists() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Only some keys saved in UserDefaults
            UserDefaults.standard.set(false, forKey: "SixLayer.Accessibility.enableAutoIDs")
            // Don't save includeComponentNames - should keep default
            
            // Reset config to defaults
            config.resetToDefaults()
            #expect(config.enableAutoIDs == true, "Should start with default")
            #expect(config.includeComponentNames == true, "Should start with default")
            
            // When: Loading from UserDefaults
            config.loadFromUserDefaults()
            
            // Then: Only saved values should be loaded, others keep defaults
            #expect(config.enableAutoIDs == false, "enableAutoIDs should be loaded from UserDefaults")
            #expect(config.includeComponentNames == true, "includeComponentNames should keep default when not saved")
            
            // Cleanup
            cleanupTestUserDefaults()
        }
    }
}
