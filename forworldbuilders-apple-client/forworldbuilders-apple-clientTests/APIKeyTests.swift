//
//  APIKeyTests.swift
//  forworldbuilders-apple-clientTests
//
//  Created on 6/12/25.
//

import XCTest
import SwiftUI
@testable import forworldbuilders_apple_client

final class APIKeyTests: XCTestCase {
    var apiKeyManager: APIKeyManager!
    
    override func setUp() {
        super.setUp()
        apiKeyManager = APIKeyManager()
    }
    
    override func tearDown() {
        // Clean up API keys
        for provider in AIProvider.allCases {
            apiKeyManager.removeAPIKey(for: provider)
        }
        apiKeyManager = nil
        super.tearDown()
    }
    
    func testAPIKeyValidation() {
        // Test OpenAI key validation
        XCTAssertTrue(apiKeyManager.validateAPIKey("sk-abcdefghijklmnopqrstuvwxyz123456", for: .openai))
        XCTAssertFalse(apiKeyManager.validateAPIKey("invalid-key", for: .openai))
        XCTAssertFalse(apiKeyManager.validateAPIKey("sk-short", for: .openai))
        
        // Test Anthropic key validation
        XCTAssertTrue(apiKeyManager.validateAPIKey("sk-ant-abcdefghijklmnopqrstuvwxyz1234567890", for: .anthropic))
        XCTAssertFalse(apiKeyManager.validateAPIKey("sk-wrong-prefix", for: .anthropic))
        XCTAssertFalse(apiKeyManager.validateAPIKey("sk-ant-tooshort", for: .anthropic))
        
        // Test Google key validation
        XCTAssertTrue(apiKeyManager.validateAPIKey("AIzaSyAbcdefghijklmnopqrstuvwxyz1234567", for: .google))
        XCTAssertFalse(apiKeyManager.validateAPIKey("NotAGoogleKey", for: .google))
        XCTAssertFalse(apiKeyManager.validateAPIKey("AIzaTooShort", for: .google))
        
        // Test Grok key validation
        XCTAssertTrue(apiKeyManager.validateAPIKey("xai-abcdefghijklmnopqrstuvwxyz", for: .grok))
        XCTAssertFalse(apiKeyManager.validateAPIKey("wrong-prefix", for: .grok))
        XCTAssertFalse(apiKeyManager.validateAPIKey("xai-short", for: .grok))
    }
    
    func testSetAndGetAPIKey() {
        let testKey = "sk-testkey123456789012345678901234"
        let provider = AIProvider.openai
        
        // Set API key
        apiKeyManager.setAPIKey(testKey, for: provider)
        
        // Verify it was set
        XCTAssertTrue(apiKeyManager.hasAPIKey(for: provider))
        XCTAssertEqual(apiKeyManager.apiKeys[provider], testKey)
    }
    
    func testRemoveAPIKey() {
        let testKey = "sk-ant-testkey1234567890123456789012345678"
        let provider = AIProvider.anthropic
        
        // Set and then remove API key
        apiKeyManager.setAPIKey(testKey, for: provider)
        XCTAssertTrue(apiKeyManager.hasAPIKey(for: provider))
        
        apiKeyManager.removeAPIKey(for: provider)
        XCTAssertFalse(apiKeyManager.hasAPIKey(for: provider))
        XCTAssertNil(apiKeyManager.apiKeys[provider])
    }
    
    func testSelectedProvider() {
        // Initially no provider should be selected
        XCTAssertNil(apiKeyManager.selectedProvider)
        
        // Set an API key
        apiKeyManager.setAPIKey("sk-testkey123456789012345678901234", for: .openai)
        
        // Reload to trigger auto-selection
        apiKeyManager = APIKeyManager()
        
        // Now OpenAI should be selected
        XCTAssertEqual(apiKeyManager.selectedProvider, .openai)
    }
    
    func testModelSelection() {
        let provider = AIProvider.openai
        let model = "gpt-4"
        
        // Set selected model
        apiKeyManager.selectedModel[provider] = model
        
        // Verify model is set
        XCTAssertEqual(apiKeyManager.selectedModel[provider], model)
    }
    
    func testProviderProperties() {
        // Test OpenAI properties
        XCTAssertEqual(AIProvider.openai.baseURL, "https://api.openai.com/v1")
        XCTAssertEqual(AIProvider.openai.keyPrefix, "sk-")
        XCTAssertTrue(AIProvider.openai.modelOptions.contains("gpt-4"))
        
        // Test Anthropic properties
        XCTAssertEqual(AIProvider.anthropic.baseURL, "https://api.anthropic.com/v1")
        XCTAssertEqual(AIProvider.anthropic.keyPrefix, "sk-ant-")
        XCTAssertTrue(AIProvider.anthropic.modelOptions.contains("claude-3-opus-20240229"))
        
        // Test Google properties
        XCTAssertEqual(AIProvider.google.baseURL, "https://generativelanguage.googleapis.com/v1")
        XCTAssertEqual(AIProvider.google.keyPrefix, "AIza")
        XCTAssertTrue(AIProvider.google.modelOptions.contains("gemini-pro"))
        
        // Test Grok properties
        XCTAssertEqual(AIProvider.grok.baseURL, "https://api.x.ai/v1")
        XCTAssertEqual(AIProvider.grok.keyPrefix, "xai-")
        XCTAssertTrue(AIProvider.grok.modelOptions.contains("grok-1"))
    }
    
    func testAllProvidersEnumeration() {
        let allProviders = AIProvider.allCases
        XCTAssertEqual(allProviders.count, 4)
        XCTAssertTrue(allProviders.contains(.openai))
        XCTAssertTrue(allProviders.contains(.anthropic))
        XCTAssertTrue(allProviders.contains(.google))
        XCTAssertTrue(allProviders.contains(.grok))
    }
}