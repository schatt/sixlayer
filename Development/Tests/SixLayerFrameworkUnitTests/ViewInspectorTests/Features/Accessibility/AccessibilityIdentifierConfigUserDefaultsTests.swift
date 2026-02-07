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
    
    private let testSuiteName = "SixLayer.Accessibility.Tests"
    private let testUserDefaultsKeyPrefix = "Test.Accessibility."
    
    /// Convenience accessor for the isolated test UserDefaults suite
    private var testUserDefaults: UserDefaults {
        // This must match the suite used in BaseTestClass.initializeTestConfig()
        return UserDefaults(suiteName: testSuiteName) ?? .standard
    }
    
    /// Clean up test UserDefaults keys
    private func cleanupTestUserDefaults() {
        // Remove the entire persistent domain for the test suite to ensure
        // a completely clean state between tests.
        if let defaults = UserDefaults(suiteName: testSuiteName) {
            defaults.removePersistentDomain(forName: testSuiteName)
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
            let savedEnableAutoIDs = testUserDefaults.bool(forKey: "\(testUserDefaultsKeyPrefix)enableAutoIDs")
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
            let defaults = testUserDefaults
            defaults.set(false, forKey: "\(testUserDefaultsKeyPrefix)enableAutoIDs")
            defaults.set(false, forKey: "\(testUserDefaultsKeyPrefix)includeComponentNames")
            defaults.set(true, forKey: "\(testUserDefaultsKeyPrefix)enableUITestIntegration")
            defaults.set("SavedNamespace", forKey: "\(testUserDefaultsKeyPrefix)namespace")
            defaults.set("SavedPrefix", forKey: "\(testUserDefaultsKeyPrefix)globalPrefix")
            defaults.set(true, forKey: "\(testUserDefaultsKeyPrefix)enableDebugLogging")
            defaults.set("manual", forKey: "\(testUserDefaultsKeyPrefix)mode")
            
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
            let newConfig = AccessibilityIdentifierConfig(
                userDefaults: testUserDefaults,
                keyPrefix: testUserDefaultsKeyPrefix
            )
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
            let defaults = testUserDefaults
            #expect(defaults.object(forKey: "\(testUserDefaultsKeyPrefix)enableAutoIDs") != nil, "enableAutoIDs should be saved")
            #expect(defaults.object(forKey: "\(testUserDefaultsKeyPrefix)includeComponentNames") != nil, "includeComponentNames should be saved")
            #expect(defaults.object(forKey: "\(testUserDefaultsKeyPrefix)includeElementTypes") != nil, "includeElementTypes should be saved")
            #expect(defaults.object(forKey: "\(testUserDefaultsKeyPrefix)enableUITestIntegration") != nil, "enableUITestIntegration should be saved")
            #expect(defaults.object(forKey: "\(testUserDefaultsKeyPrefix)namespace") != nil, "namespace should be saved")
            #expect(defaults.object(forKey: "\(testUserDefaultsKeyPrefix)globalPrefix") != nil, "globalPrefix should be saved")
            #expect(defaults.object(forKey: "\(testUserDefaultsKeyPrefix)enableDebugLogging") != nil, "enableDebugLogging should be saved")
            #expect(defaults.object(forKey: "\(testUserDefaultsKeyPrefix)mode") != nil, "mode should be saved")
            
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
            let defaults = testUserDefaults
            defaults.set(false, forKey: "\(testUserDefaultsKeyPrefix)enableAutoIDs")
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
