//
//  EdgeCaseTests.swift
//  forworldbuilders-apple-clientTests
//
//  Created by Owner on 6/11/25.
//

import XCTest
import SwiftUI
@testable import forworldbuilders_apple_client

final class EdgeCaseTests: XCTestCase {
    
    var dataStore: DataStore!
    
    override func setUpWithError() throws {
        // Clear UserDefaults for isolated tests
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "ForWorldBuildersData")
        defaults.removeObject(forKey: "ForWorldBuildersActivity")
        
        dataStore = DataStore()
    }
    
    override func tearDownWithError() throws {
        dataStore = nil
    }
    
    // MARK: - DataStore Edge Cases
    
    func testOperationsOnNonExistentWorld() {
        let fakeWorldId = UUID()
        let element = WorldElement(worldId: fakeWorldId, type: .character, title: "Test")
        
        // These operations should not crash or affect the data store
        dataStore.addElement(to: fakeWorldId, element: element)
        dataStore.updateElement(in: fakeWorldId, element: element)
        dataStore.deleteElement(from: fakeWorldId, elementId: element.id)
        
        let relationship = ElementRelationship(fromElementId: UUID(), toElementId: UUID(), type: .relatedTo)
        dataStore.addRelationship(to: fakeWorldId, relationship: relationship)
        dataStore.deleteRelationship(from: fakeWorldId, relationshipId: relationship.id)
        
        // DataStore should remain empty
        XCTAssertTrue(dataStore.worlds.isEmpty)
        XCTAssertTrue(dataStore.recentActivity.isEmpty)
    }
    
    func testOperationsOnNonExistentElement() {
        let world = World(title: "Test World", desc: "Test")
        dataStore.addWorld(world)
        
        let fakeElementId = UUID()
        
        // Should not crash
        dataStore.deleteElement(from: world.id, elementId: fakeElementId)
        dataStore.updateElementMentions(in: world.id, elementId: fakeElementId, mentions: [])
        
        let foundElement = dataStore.findElement(by: fakeElementId, in: world.id)
        XCTAssertNil(foundElement)
        
        let relationships = dataStore.getRelationships(for: fakeElementId, in: world.id)
        XCTAssertTrue(relationships.isEmpty)
    }
    
    func testUpdateNonExistentWorld() {
        let fakeWorld = World(title: "Fake World", desc: "Does not exist")
        
        // Should not crash or add the world
        dataStore.updateWorld(fakeWorld)
        
        XCTAssertTrue(dataStore.worlds.isEmpty)
    }
    
    func testUpdateNonExistentElement() {
        let world = World(title: "Test World", desc: "Test")
        dataStore.addWorld(world)
        
        let fakeElement = WorldElement(worldId: world.id, type: .character, title: "Fake Element")
        
        // Should not crash or add the element
        dataStore.updateElement(in: world.id, element: fakeElement)
        
        XCTAssertTrue(dataStore.worlds.first?.elements.isEmpty ?? false)
    }
    
    func testDeleteNonExistentRelationship() {
        let world = World(title: "Test World", desc: "Test")
        dataStore.addWorld(world)
        
        let fakeRelationshipId = UUID()
        
        // Should not crash
        dataStore.deleteRelationship(from: world.id, relationshipId: fakeRelationshipId)
        
        XCTAssertTrue(dataStore.worlds.first?.relationships.isEmpty ?? false)
    }
    
    func testActivityHistoryLimit() {
        let world = World(title: "Test World", desc: "Test")
        dataStore.addWorld(world)
        
        // Add more than 100 activities (the limit)
        for i in 0..<120 {
            let element = WorldElement(worldId: world.id, type: .character, title: "Element \(i)")
            dataStore.addElement(to: world.id, element: element)
        }
        
        // Should be limited to 100 + 1 (world creation)
        XCTAssertLessThanOrEqual(dataStore.recentActivity.count, 101)
    }
    
    // MARK: - Model Edge Cases
    
    func testWorldElementWithEmptyValues() {
        let worldId = UUID()
        let element = WorldElement(
            worldId: worldId,
            type: .character,
            title: "",
            content: "",
            tags: []
        )
        
        XCTAssertEqual(element.title, "")
        XCTAssertEqual(element.content, "")
        XCTAssertTrue(element.tags.isEmpty)
        XCTAssertTrue(element.mentions.isEmpty)
    }
    
    func testWorldWithEmptyValues() {
        let world = World(title: "", desc: "")
        
        XCTAssertEqual(world.title, "")
        XCTAssertEqual(world.desc, "")
        XCTAssertTrue(world.elements.isEmpty)
        XCTAssertTrue(world.relationships.isEmpty)
        XCTAssertEqual(world.elementCount, 0)
    }
    
    func testElementRelationshipWithEmptyDescription() {
        let relationship = ElementRelationship(
            fromElementId: UUID(),
            toElementId: UUID(),
            type: .relatedTo,
            description: ""
        )
        
        XCTAssertEqual(relationship.description, "")
        XCTAssertNotNil(relationship.id)
        XCTAssertNotNil(relationship.created)
    }
    
    func testElementMentionWithZeroLength() {
        let mention = ElementMention(
            elementId: UUID(),
            elementTitle: "",
            startIndex: 0,
            length: 0
        )
        
        XCTAssertEqual(mention.length, 0)
        XCTAssertEqual(mention.range.length, 0)
        XCTAssertEqual(mention.elementTitle, "")
    }
    
    func testActivityItemWithNilValues() {
        let activity = ActivityItem(
            type: .worldCreated,
            worldId: UUID(),
            worldTitle: "Test World"
        )
        
        XCTAssertNil(activity.elementId)
        XCTAssertNil(activity.elementTitle)
        XCTAssertNil(activity.elementType)
        XCTAssertNil(activity.relationshipId)
        XCTAssertEqual(activity.details, "")
    }
    
    // MARK: - Theme System Edge Cases
    
    func testThemeWithInvalidColors() {
        let theme = AppTheme(
            name: "invalid_theme",
            displayName: "Invalid Theme",
            isDark: false,
            primaryColor: "INVALID",
            secondaryColor: "GGGGGG",
            accentColor: "",
            backgroundColor: "XXXXXX",
            surfaceColor: "123",
            textPrimaryColor: "ZZZZZZ",
            textSecondaryColor: "!@#$%^"
        )
        
        // Should fallback to default colors
        XCTAssertNotNil(theme.primaryUIColor)
        XCTAssertNotNil(theme.secondaryUIColor)
        XCTAssertNotNil(theme.accentUIColor)
        XCTAssertNotNil(theme.backgroundUIColor)
        XCTAssertNotNil(theme.surfaceUIColor)
        XCTAssertNotNil(theme.textPrimaryUIColor)
        XCTAssertNotNil(theme.textSecondaryUIColor)
    }
    
    func testThemeManagerWithCorruptedData() {
        // Simulate corrupted theme data in UserDefaults
        let defaults = UserDefaults.standard
        defaults.set("corrupted data", forKey: "ForWorldBuildersTheme")
        defaults.set("more corrupted data", forKey: "ForWorldBuildersCustomThemes")
        
        let themeManager = ThemeManager()
        
        // Should fallback to default theme
        XCTAssertEqual(themeManager.currentTheme.name, "default_light")
        XCTAssertEqual(themeManager.availableThemes.count, 9) // Only built-in themes
    }
    
    func testDeleteNonExistentCustomTheme() {
        let themeManager = ThemeManager()
        let fakeTheme = AppTheme(
            name: "fake",
            displayName: "Fake",
            isDark: false,
            primaryColor: "000000",
            secondaryColor: "000000",
            accentColor: "000000",
            backgroundColor: "000000",
            surfaceColor: "000000",
            textPrimaryColor: "000000",
            textSecondaryColor: "000000"
        )
        
        let initialCount = themeManager.availableThemes.count
        
        // Should not crash
        themeManager.deleteCustomTheme(fakeTheme)
        
        XCTAssertEqual(themeManager.availableThemes.count, initialCount)
    }
    
    // MARK: - Search and Performance Edge Cases
    
    func testSearchInEmptyWorld() {
        let world = World(title: "Empty World", desc: "No elements")
        dataStore.addWorld(world)
        
        let elements = dataStore.getElementsForMentions(in: world.id)
        XCTAssertTrue(elements.isEmpty)
        
        let relationships = dataStore.getRelationships(for: UUID(), in: world.id)
        XCTAssertTrue(relationships.isEmpty)
    }
    
    func testSearchWithInvalidWorldId() {
        let fakeWorldId = UUID()
        
        let elements = dataStore.getElementsForMentions(in: fakeWorldId)
        XCTAssertTrue(elements.isEmpty)
        
        let foundElement = dataStore.findElement(by: UUID(), in: fakeWorldId)
        XCTAssertNil(foundElement)
        
        let relationships = dataStore.getRelationships(for: UUID(), in: fakeWorldId)
        XCTAssertTrue(relationships.isEmpty)
        
        let activity = dataStore.getRecentActivity(for: fakeWorldId)
        XCTAssertTrue(activity.isEmpty)
    }
    
    func testLargeContentHandling() {
        let world = World(title: "Test World", desc: "Test")
        dataStore.addWorld(world)
        
        // Create element with very large content
        let largeContent = String(repeating: "This is a very long content string. ", count: 1000)
        let element = WorldElement(
            worldId: world.id,
            type: .character,
            title: "Large Element",
            content: largeContent,
            tags: Array(repeating: "tag", count: 100)
        )
        
        dataStore.addElement(to: world.id, element: element)
        
        let foundElement = dataStore.findElement(by: element.id, in: world.id)
        XCTAssertNotNil(foundElement)
        XCTAssertEqual(foundElement?.content.count, largeContent.count)
        XCTAssertEqual(foundElement?.tags.count, 100)
    }
    
    func testManySmallElements() {
        let world = World(title: "Test World", desc: "Test")
        dataStore.addWorld(world)
        
        // Add many small elements
        for i in 0..<1000 {
            let element = WorldElement(
                worldId: world.id,
                type: ElementType.allCases[i % ElementType.allCases.count],
                title: "Element \(i)",
                content: "Content \(i)"
            )
            dataStore.addElement(to: world.id, element: element)
        }
        
        XCTAssertEqual(dataStore.worlds.first?.elements.count, 1000)
        
        // Test searching through many elements
        let elements = dataStore.getElementsForMentions(in: world.id)
        XCTAssertEqual(elements.count, 1000)
        
        // Test excluding elements
        let firstElement = dataStore.worlds.first?.elements.first
        let excludedElements = dataStore.getElementsForMentions(in: world.id, excluding: firstElement?.id)
        XCTAssertEqual(excludedElements.count, 999)
    }
    
    // MARK: - Color Extension Edge Cases
    
    func testColorHexEdgeCases() {
        // Test various invalid formats
        XCTAssertNil(Color(hex: ""))
        XCTAssertNil(Color(hex: "X"))
        XCTAssertNil(Color(hex: "XX"))
        XCTAssertNil(Color(hex: "XXXX"))
        XCTAssertNil(Color(hex: "XXXXX"))
        XCTAssertNil(Color(hex: "XXXXXXX"))
        XCTAssertNil(Color(hex: "XXXXXXXXX"))
        XCTAssertNil(Color(hex: "INVALID"))
        XCTAssertNil(Color(hex: "!@#$%^"))
        XCTAssertNil(Color(hex: "GGGGGG"))
        
        // Test valid edge cases
        XCTAssertNotNil(Color(hex: "000"))
        XCTAssertNotNil(Color(hex: "FFF"))
        XCTAssertNotNil(Color(hex: "000000"))
        XCTAssertNotNil(Color(hex: "FFFFFF"))
        XCTAssertNotNil(Color(hex: "12345678")) // 8-digit ARGB
        
        // Test with prefixes that should be stripped
        XCTAssertNotNil(Color(hex: "#FF0000"))
        XCTAssertNotNil(Color(hex: "0xFF0000"))
    }
    
    // MARK: - Data Integrity Tests
    
    func testConcurrentDataStoreOperations() {
        let world = World(title: "Concurrent Test", desc: "Test")
        dataStore.addWorld(world)
        
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 100
        
        // Simulate concurrent operations
        DispatchQueue.concurrentPerform(iterations: 100) { i in
            let element = WorldElement(
                worldId: world.id,
                type: ElementType.allCases[i % ElementType.allCases.count],
                title: "Concurrent Element \(i)"
            )
            
            DispatchQueue.main.async {
                self.dataStore.addElement(to: world.id, element: element)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // All elements should be added
        XCTAssertEqual(dataStore.worlds.first?.elements.count, 100)
    }
    
    func testDataStorePersistenceAfterCorruption() {
        // Add some valid data
        let world = World(title: "Test World", desc: "Test")
        dataStore.addWorld(world)
        
        // Corrupt the saved data
        UserDefaults.standard.set("corrupted", forKey: "ForWorldBuildersData")
        UserDefaults.standard.set("corrupted", forKey: "ForWorldBuildersActivity")
        
        // Create new data store - should handle corruption gracefully
        let newDataStore = DataStore()
        
        XCTAssertTrue(newDataStore.worlds.isEmpty)
        XCTAssertTrue(newDataStore.recentActivity.isEmpty)
        
        // Should be able to add new data after corruption
        let newWorld = World(title: "New World", desc: "After corruption")
        newDataStore.addWorld(newWorld)
        
        XCTAssertEqual(newDataStore.worlds.count, 1)
        XCTAssertEqual(newDataStore.worlds.first?.title, "New World")
    }
    
    func testElementTemplateEdgeCases() {
        // Test template with empty values
        let emptyTemplate = ElementTemplate(
            name: "",
            type: .character,
            description: "",
            contentTemplate: "",
            suggestedTags: []
        )
        
        XCTAssertEqual(emptyTemplate.name, "")
        XCTAssertEqual(emptyTemplate.description, "")
        XCTAssertEqual(emptyTemplate.contentTemplate, "")
        XCTAssertTrue(emptyTemplate.suggestedTags.isEmpty)
        
        // Test template with very long values
        let longString = String(repeating: "A", count: 10000)
        let longTemplate = ElementTemplate(
            name: longString,
            type: .character,
            description: longString,
            contentTemplate: longString,
            suggestedTags: Array(repeating: longString, count: 100)
        )
        
        XCTAssertEqual(longTemplate.name.count, 10000)
        XCTAssertEqual(longTemplate.contentTemplate.count, 10000)
        XCTAssertEqual(longTemplate.suggestedTags.count, 100)
    }
    
    // MARK: - Memory and Performance Edge Cases
    
    func testMemoryUsageWithLargeDataset() {
        let world = World(title: "Memory Test", desc: "Testing memory usage")
        dataStore.addWorld(world)
        
        // Add a large number of elements with substantial content
        for i in 0..<500 {
            let content = String(repeating: "Content for element \(i). ", count: 100)
            let element = WorldElement(
                worldId: world.id,
                type: ElementType.allCases[i % ElementType.allCases.count],
                title: "Memory Test Element \(i)",
                content: content,
                tags: Array(0..<10).map { "tag\(i)-\($0)" }
            )
            dataStore.addElement(to: world.id, element: element)
        }
        
        // Add many relationships
        let elements = dataStore.worlds.first!.elements
        for i in 0..<250 {
            let relationship = ElementRelationship(
                fromElementId: elements[i].id,
                toElementId: elements[(i + 1) % elements.count].id,
                type: RelationshipType.allCases[i % RelationshipType.allCases.count],
                description: "Memory test relationship \(i)"
            )
            dataStore.addRelationship(to: world.id, relationship: relationship)
        }
        
        XCTAssertEqual(dataStore.worlds.first?.elements.count, 500)
        XCTAssertEqual(dataStore.worlds.first?.relationships.count, 250)
        
        // Test that operations still work efficiently
        measure {
            let foundElement = dataStore.findElement(by: elements[250].id, in: world.id)
            XCTAssertNotNil(foundElement)
        }
    }
    
    func testDeepRelationshipChains() {
        let world = World(title: "Relationship Chain Test", desc: "Testing deep chains")
        dataStore.addWorld(world)
        
        // Create a chain of 100 elements
        var elements: [WorldElement] = []
        for i in 0..<100 {
            let element = WorldElement(
                worldId: world.id,
                type: ElementType.allCases[i % ElementType.allCases.count],
                title: "Chain Element \(i)"
            )
            dataStore.addElement(to: world.id, element: element)
            elements.append(element)
        }
        
        // Create a chain of relationships
        for i in 0..<99 {
            let relationship = ElementRelationship(
                fromElementId: elements[i].id,
                toElementId: elements[i + 1].id,
                type: .connectedTo,
                description: "Chain link \(i)"
            )
            dataStore.addRelationship(to: world.id, relationship: relationship)
        }
        
        // Test getting relationships for elements in the chain
        let firstElementRelationships = dataStore.getRelationships(for: elements[0].id, in: world.id)
        XCTAssertEqual(firstElementRelationships.count, 1)
        
        let middleElementRelationships = dataStore.getRelationships(for: elements[50].id, in: world.id)
        XCTAssertEqual(middleElementRelationships.count, 2) // Connected to previous and next
        
        let lastElementRelationships = dataStore.getRelationships(for: elements[99].id, in: world.id)
        XCTAssertEqual(lastElementRelationships.count, 1)
    }
}