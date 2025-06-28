//
//  forworldbuilders_apple_clientTests.swift
//  forworldbuilders-apple-clientTests
//
//  Created by Owner on 6/11/25.
//

import XCTest
import SwiftUI
@testable import forworldbuilders_apple_client

final class forworldbuilders_apple_clientTests: XCTestCase {
    
    var dataStore: DataStore!
    var themeManager: ThemeManager!
    
    override func setUpWithError() throws {
        // Clear UserDefaults for isolated tests
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "ForWorldBuildersData")
        defaults.removeObject(forKey: "ForWorldBuildersActivity")
        defaults.removeObject(forKey: "ForWorldBuildersTheme")
        defaults.removeObject(forKey: "ForWorldBuildersCustomThemes")
        
        dataStore = DataStore()
        themeManager = ThemeManager()
    }
    
    override func tearDownWithError() throws {
        dataStore = nil
        themeManager = nil
    }
    
    // MARK: - Model Tests
    
    func testElementTypeProperties() {
        let character = ElementType.character
        XCTAssertEqual(character.rawValue, "Character")
        XCTAssertEqual(character.icon, "person.fill")
        XCTAssertNotNil(character.color)
        
        let location = ElementType.location
        XCTAssertEqual(location.rawValue, "Location")
        XCTAssertEqual(location.icon, "map.fill")
        
        // Test all cases exist
        XCTAssertEqual(ElementType.allCases.count, 10)
    }
    
    func testRelationshipTypeProperties() {
        let relatedTo = RelationshipType.relatedTo
        XCTAssertEqual(relatedTo.rawValue, "Related To")
        XCTAssertEqual(relatedTo.icon, "link")
        
        let childOf = RelationshipType.childOf
        XCTAssertEqual(childOf.rawValue, "Child Of")
        XCTAssertEqual(childOf.icon, "arrow.up")
        
        // Test all cases exist
        XCTAssertEqual(RelationshipType.allCases.count, 10)
    }
    
    func testWorldElementCreation() {
        let worldId = UUID()
        let element = WorldElement(
            worldId: worldId,
            type: .character,
            title: "Test Character",
            content: "A brave warrior",
            tags: ["hero", "warrior"]
        )
        
        XCTAssertEqual(element.worldId, worldId)
        XCTAssertEqual(element.type, .character)
        XCTAssertEqual(element.title, "Test Character")
        XCTAssertEqual(element.content, "A brave warrior")
        XCTAssertEqual(element.tags, ["hero", "warrior"])
        XCTAssertTrue(element.mentions.isEmpty)
        XCTAssertNotNil(element.id)
        XCTAssertNotNil(element.created)
        XCTAssertNotNil(element.lastModified)
    }
    
    func testWorldCreation() {
        let world = World(title: "Test World", desc: "A fantasy realm")
        
        XCTAssertEqual(world.title, "Test World")
        XCTAssertEqual(world.desc, "A fantasy realm")
        XCTAssertTrue(world.elements.isEmpty)
        XCTAssertTrue(world.relationships.isEmpty)
        XCTAssertEqual(world.elementCount, 0)
        XCTAssertNotNil(world.id)
        XCTAssertNotNil(world.created)
        XCTAssertNotNil(world.lastModified)
    }
    
    func testWorldElementCount() {
        let world = World(title: "Test", desc: "Test")
        XCTAssertEqual(world.elementCount(for: .character), 0)
        
        // This would need to be tested with a mutable copy in practice
        var mutableWorld = world
        let character = WorldElement(worldId: world.id, type: .character, title: "Hero")
        let location = WorldElement(worldId: world.id, type: .location, title: "Castle")
        
        mutableWorld.elements = [character, location]
        XCTAssertEqual(mutableWorld.elementCount(for: .character), 1)
        XCTAssertEqual(mutableWorld.elementCount(for: .location), 1)
        XCTAssertEqual(mutableWorld.elementCount(for: .event), 0)
    }
    
    func testElementRelationshipCreation() {
        let fromId = UUID()
        let toId = UUID()
        let relationship = ElementRelationship(
            fromElementId: fromId,
            toElementId: toId,
            type: .childOf,
            description: "Test relationship"
        )
        
        XCTAssertEqual(relationship.fromElementId, fromId)
        XCTAssertEqual(relationship.toElementId, toId)
        XCTAssertEqual(relationship.type, .childOf)
        XCTAssertEqual(relationship.description, "Test relationship")
        XCTAssertNotNil(relationship.id)
        XCTAssertNotNil(relationship.created)
    }
    
    func testElementMentionCreation() {
        let elementId = UUID()
        let mention = ElementMention(
            elementId: elementId,
            elementTitle: "Test Element",
            startIndex: 5,
            length: 10
        )
        
        XCTAssertEqual(mention.elementId, elementId)
        XCTAssertEqual(mention.elementTitle, "Test Element")
        XCTAssertEqual(mention.startIndex, 5)
        XCTAssertEqual(mention.length, 10)
        XCTAssertNotNil(mention.id)
        
        let range = mention.range
        XCTAssertEqual(range.location, 5)
        XCTAssertEqual(range.length, 10)
    }
    
    func testActivityItemCreation() {
        let worldId = UUID()
        let elementId = UUID()
        let activity = ActivityItem(
            type: .elementCreated,
            worldId: worldId,
            worldTitle: "Test World",
            elementId: elementId,
            elementTitle: "Test Element",
            elementType: .character,
            details: "Created new character"
        )
        
        XCTAssertEqual(activity.type, .elementCreated)
        XCTAssertEqual(activity.worldId, worldId)
        XCTAssertEqual(activity.worldTitle, "Test World")
        XCTAssertEqual(activity.elementId, elementId)
        XCTAssertEqual(activity.elementTitle, "Test Element")
        XCTAssertEqual(activity.elementType, .character)
        XCTAssertEqual(activity.details, "Created new character")
        XCTAssertNotNil(activity.id)
        XCTAssertNotNil(activity.timestamp)
    }
    
    func testActivityTypeProperties() {
        let created = ActivityType.elementCreated
        XCTAssertEqual(created.rawValue, "Element Created")
        XCTAssertEqual(created.icon, "plus.circle")
        XCTAssertNotNil(created.color)
        
        let modified = ActivityType.elementModified
        XCTAssertEqual(modified.rawValue, "Element Modified")
        XCTAssertEqual(modified.icon, "pencil.circle.fill")
        
        // Test all cases exist
        XCTAssertEqual(ActivityType.allCases.count, 7)
    }
    
    // MARK: - DataStore Tests
    
    func testDataStoreInitialization() {
        XCTAssertTrue(dataStore.worlds.isEmpty)
        XCTAssertTrue(dataStore.recentActivity.isEmpty)
    }
    
    func testAddWorld() {
        let world = World(title: "Test World", desc: "Description")
        
        dataStore.addWorld(world)
        
        XCTAssertEqual(dataStore.worlds.count, 1)
        XCTAssertEqual(dataStore.worlds.first?.title, "Test World")
        XCTAssertEqual(dataStore.recentActivity.count, 1)
        XCTAssertEqual(dataStore.recentActivity.first?.type, .worldCreated)
    }
    
    func testDeleteWorld() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        XCTAssertEqual(dataStore.worlds.count, 1)
        
        dataStore.deleteWorld(world)
        
        XCTAssertTrue(dataStore.worlds.isEmpty)
    }
    
    func testUpdateWorld() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        var updatedWorld = world
        updatedWorld.desc = "Updated description"
        
        dataStore.updateWorld(updatedWorld)
        
        XCTAssertEqual(dataStore.worlds.first?.desc, "Updated description")
        XCTAssertEqual(dataStore.recentActivity.count, 2) // Add + Update
        XCTAssertEqual(dataStore.recentActivity.first?.type, .worldModified)
    }
    
    func testAddElement() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element = WorldElement(worldId: world.id, type: .character, title: "Hero")
        dataStore.addElement(to: world.id, element: element)
        
        XCTAssertEqual(dataStore.worlds.first?.elements.count, 1)
        XCTAssertEqual(dataStore.worlds.first?.elements.first?.title, "Hero")
        XCTAssertEqual(dataStore.recentActivity.count, 2) // World + Element
        XCTAssertEqual(dataStore.recentActivity.first?.type, .elementCreated)
    }
    
    func testUpdateElement() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element = WorldElement(worldId: world.id, type: .character, title: "Hero")
        dataStore.addElement(to: world.id, element: element)
        
        var updatedElement = element
        updatedElement.title = "Updated Hero"
        
        dataStore.updateElement(in: world.id, element: updatedElement)
        
        XCTAssertEqual(dataStore.worlds.first?.elements.first?.title, "Updated Hero")
        XCTAssertEqual(dataStore.recentActivity.count, 3) // World + Add + Update
        XCTAssertEqual(dataStore.recentActivity.first?.type, .elementModified)
    }
    
    func testDeleteElement() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element = WorldElement(worldId: world.id, type: .character, title: "Hero")
        dataStore.addElement(to: world.id, element: element)
        
        XCTAssertEqual(dataStore.worlds.first?.elements.count, 1)
        
        dataStore.deleteElement(from: world.id, elementId: element.id)
        
        XCTAssertTrue(dataStore.worlds.first?.elements.isEmpty ?? false)
        XCTAssertEqual(dataStore.recentActivity.count, 3) // World + Add + Delete
        XCTAssertEqual(dataStore.recentActivity.first?.type, .elementDeleted)
    }
    
    func testAddRelationship() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element1 = WorldElement(worldId: world.id, type: .character, title: "Hero")
        let element2 = WorldElement(worldId: world.id, type: .location, title: "Castle")
        
        dataStore.addElement(to: world.id, element: element1)
        dataStore.addElement(to: world.id, element: element2)
        
        let relationship = ElementRelationship(
            fromElementId: element1.id,
            toElementId: element2.id,
            type: .locatedIn
        )
        
        dataStore.addRelationship(to: world.id, relationship: relationship)
        
        XCTAssertEqual(dataStore.worlds.first?.relationships.count, 1)
        XCTAssertEqual(dataStore.recentActivity.first?.type, .relationshipCreated)
    }
    
    func testDeleteRelationship() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element1 = WorldElement(worldId: world.id, type: .character, title: "Hero")
        let element2 = WorldElement(worldId: world.id, type: .location, title: "Castle")
        
        dataStore.addElement(to: world.id, element: element1)
        dataStore.addElement(to: world.id, element: element2)
        
        let relationship = ElementRelationship(
            fromElementId: element1.id,
            toElementId: element2.id,
            type: .locatedIn
        )
        
        dataStore.addRelationship(to: world.id, relationship: relationship)
        XCTAssertEqual(dataStore.worlds.first?.relationships.count, 1)
        
        dataStore.deleteRelationship(from: world.id, relationshipId: relationship.id)
        
        XCTAssertTrue(dataStore.worlds.first?.relationships.isEmpty ?? false)
        XCTAssertEqual(dataStore.recentActivity.first?.type, .relationshipDeleted)
    }
    
    func testGetRelationships() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element1 = WorldElement(worldId: world.id, type: .character, title: "Hero")
        let element2 = WorldElement(worldId: world.id, type: .location, title: "Castle")
        let element3 = WorldElement(worldId: world.id, type: .character, title: "Villain")
        
        dataStore.addElement(to: world.id, element: element1)
        dataStore.addElement(to: world.id, element: element2)
        dataStore.addElement(to: world.id, element: element3)
        
        let relationship1 = ElementRelationship(fromElementId: element1.id, toElementId: element2.id, type: .locatedIn)
        let relationship2 = ElementRelationship(fromElementId: element1.id, toElementId: element3.id, type: .enemyOf)
        let relationship3 = ElementRelationship(fromElementId: element2.id, toElementId: element3.id, type: .connectedTo)
        
        dataStore.addRelationship(to: world.id, relationship: relationship1)
        dataStore.addRelationship(to: world.id, relationship: relationship2)
        dataStore.addRelationship(to: world.id, relationship: relationship3)
        
        let element1Relationships = dataStore.getRelationships(for: element1.id, in: world.id)
        XCTAssertEqual(element1Relationships.count, 2)
        
        let element2Relationships = dataStore.getRelationships(for: element2.id, in: world.id)
        XCTAssertEqual(element2Relationships.count, 2)
        
        let element3Relationships = dataStore.getRelationships(for: element3.id, in: world.id)
        XCTAssertEqual(element3Relationships.count, 2)
    }
    
    func testUpdateElementMentions() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element = WorldElement(worldId: world.id, type: .character, title: "Hero")
        dataStore.addElement(to: world.id, element: element)
        
        let mention = ElementMention(elementId: UUID(), elementTitle: "Other", startIndex: 0, length: 5)
        let mentions = [mention]
        
        dataStore.updateElementMentions(in: world.id, elementId: element.id, mentions: mentions)
        
        XCTAssertEqual(dataStore.worlds.first?.elements.first?.mentions.count, 1)
        XCTAssertEqual(dataStore.worlds.first?.elements.first?.mentions.first?.elementTitle, "Other")
    }
    
    func testGetElementsForMentions() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element1 = WorldElement(worldId: world.id, type: .character, title: "Hero")
        let element2 = WorldElement(worldId: world.id, type: .location, title: "Castle")
        
        dataStore.addElement(to: world.id, element: element1)
        dataStore.addElement(to: world.id, element: element2)
        
        // Get all elements for mentions
        let allElements = dataStore.getElementsForMentions(in: world.id)
        XCTAssertEqual(allElements.count, 2)
        
        // Get elements excluding one
        let excludedElements = dataStore.getElementsForMentions(in: world.id, excluding: element1.id)
        XCTAssertEqual(excludedElements.count, 1)
        XCTAssertEqual(excludedElements.first?.title, "Castle")
    }
    
    func testFindElement() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element = WorldElement(worldId: world.id, type: .character, title: "Hero")
        dataStore.addElement(to: world.id, element: element)
        
        let foundElement = dataStore.findElement(by: element.id, in: world.id)
        XCTAssertNotNil(foundElement)
        XCTAssertEqual(foundElement?.title, "Hero")
        
        let notFoundElement = dataStore.findElement(by: UUID(), in: world.id)
        XCTAssertNil(notFoundElement)
    }
    
    func testGetRecentActivity() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element = WorldElement(worldId: world.id, type: .character, title: "Hero")
        dataStore.addElement(to: world.id, element: element)
        
        let recentActivity = dataStore.getRecentActivity(limit: 10)
        XCTAssertEqual(recentActivity.count, 2) // World + Element
        
        let worldActivity = dataStore.getRecentActivity(for: world.id, limit: 10)
        XCTAssertEqual(worldActivity.count, 2)
    }
    
    func testDeleteElementRemovesRelationships() {
        let world = World(title: "Test World", desc: "Description")
        dataStore.addWorld(world)
        
        let element1 = WorldElement(worldId: world.id, type: .character, title: "Hero")
        let element2 = WorldElement(worldId: world.id, type: .location, title: "Castle")
        
        dataStore.addElement(to: world.id, element: element1)
        dataStore.addElement(to: world.id, element: element2)
        
        let relationship = ElementRelationship(fromElementId: element1.id, toElementId: element2.id, type: .locatedIn)
        dataStore.addRelationship(to: world.id, relationship: relationship)
        
        XCTAssertEqual(dataStore.worlds.first?.relationships.count, 1)
        
        // Delete element should also remove its relationships
        dataStore.deleteElement(from: world.id, elementId: element1.id)
        
        XCTAssertTrue(dataStore.worlds.first?.relationships.isEmpty ?? false)
    }
    
    // MARK: - Theme System Tests
    
    func testAppThemeCreation() {
        let theme = AppTheme(
            name: "test_theme",
            displayName: "Test Theme",
            isDark: false,
            primaryColor: "007AFF",
            secondaryColor: "8E8E93",
            accentColor: "AF52DE",
            backgroundColor: "FFFFFF",
            surfaceColor: "F2F2F7",
            textPrimaryColor: "000000",
            textSecondaryColor: "3C3C43"
        )
        
        XCTAssertEqual(theme.name, "test_theme")
        XCTAssertEqual(theme.displayName, "Test Theme")
        XCTAssertFalse(theme.isDark)
        XCTAssertEqual(theme.primaryColor, "007AFF")
        XCTAssertNotNil(theme.id)
        
        // Test color conversion
        XCTAssertNotNil(theme.primaryUIColor)
        XCTAssertNotNil(theme.backgroundUIColor)
    }
    
    func testBuiltInThemes() {
        let builtInThemes = AppTheme.builtInThemes
        XCTAssertEqual(builtInThemes.count, 9)
        
        // Test that we have both light and dark themes
        let lightThemes = builtInThemes.filter { !$0.isDark }
        let darkThemes = builtInThemes.filter { $0.isDark }
        
        XCTAssertGreaterThan(lightThemes.count, 0)
        XCTAssertGreaterThan(darkThemes.count, 0)
        
        // Test specific themes exist
        XCTAssertTrue(builtInThemes.contains { $0.name == "default_light" })
        XCTAssertTrue(builtInThemes.contains { $0.name == "default_dark" })
        XCTAssertTrue(builtInThemes.contains { $0.name == "cyberpunk" })
    }
    
    func testThemeManagerInitialization() {
        XCTAssertNotNil(themeManager.currentTheme)
        XCTAssertEqual(themeManager.availableThemes.count, 9) // Built-in themes
        XCTAssertEqual(themeManager.currentTheme.name, "default_light")
    }
    
    func testThemeManagerSetTheme() {
        let cyberpunkTheme = AppTheme.builtInThemes.first { $0.name == "cyberpunk" }!
        
        themeManager.setTheme(cyberpunkTheme)
        
        XCTAssertEqual(themeManager.currentTheme.id, cyberpunkTheme.id)
        XCTAssertEqual(themeManager.currentTheme.name, "cyberpunk")
    }
    
    func testThemeManagerAddCustomTheme() {
        let customTheme = AppTheme(
            name: "custom_test",
            displayName: "Custom Test",
            isDark: true,
            primaryColor: "FF0000",
            secondaryColor: "00FF00",
            accentColor: "0000FF",
            backgroundColor: "000000",
            surfaceColor: "111111",
            textPrimaryColor: "FFFFFF",
            textSecondaryColor: "CCCCCC"
        )
        
        let initialCount = themeManager.availableThemes.count
        
        themeManager.addCustomTheme(customTheme)
        
        XCTAssertEqual(themeManager.availableThemes.count, initialCount + 1)
        XCTAssertTrue(themeManager.availableThemes.contains { $0.id == customTheme.id })
    }
    
    func testThemeManagerDeleteCustomTheme() {
        let customTheme = AppTheme(
            name: "custom_test",
            displayName: "Custom Test",
            isDark: true,
            primaryColor: "FF0000",
            secondaryColor: "00FF00",
            accentColor: "0000FF",
            backgroundColor: "000000",
            surfaceColor: "111111",
            textPrimaryColor: "FFFFFF",
            textSecondaryColor: "CCCCCC"
        )
        
        themeManager.addCustomTheme(customTheme)
        let countAfterAdd = themeManager.availableThemes.count
        
        themeManager.deleteCustomTheme(customTheme)
        
        XCTAssertEqual(themeManager.availableThemes.count, countAfterAdd - 1)
        XCTAssertFalse(themeManager.availableThemes.contains { $0.id == customTheme.id })
    }
    
    func testThemeManagerDeleteCurrentTheme() {
        let customTheme = AppTheme(
            name: "custom_test",
            displayName: "Custom Test",
            isDark: true,
            primaryColor: "FF0000",
            secondaryColor: "00FF00",
            accentColor: "0000FF",
            backgroundColor: "000000",
            surfaceColor: "111111",
            textPrimaryColor: "FFFFFF",
            textSecondaryColor: "CCCCCC"
        )
        
        themeManager.addCustomTheme(customTheme)
        themeManager.setTheme(customTheme)
        
        XCTAssertEqual(themeManager.currentTheme.id, customTheme.id)
        
        themeManager.deleteCustomTheme(customTheme)
        
        // Should fallback to default theme
        XCTAssertNotEqual(themeManager.currentTheme.id, customTheme.id)
        XCTAssertEqual(themeManager.currentTheme.name, "default_light")
    }
    
    // MARK: - Color Extension Tests
    
    func testColorHexConversion() {
        // Test 6-digit hex
        let blueColor = Color(hex: "007AFF")
        XCTAssertNotNil(blueColor)
        
        // Test 3-digit hex
        let redColor = Color(hex: "F00")
        XCTAssertNotNil(redColor)
        
        // Test invalid hex
        let invalidColor = Color(hex: "INVALID")
        XCTAssertNil(invalidColor)
        
        // Test empty string
        let emptyColor = Color(hex: "")
        XCTAssertNil(emptyColor)
    }
    
    // MARK: - Element Template Tests
    
    func testElementTemplateCreation() {
        let template = ElementTemplate(
            name: "Test Template",
            type: .character,
            description: "Test description",
            contentTemplate: "Name: [Name]",
            suggestedTags: ["test", "template"]
        )
        
        XCTAssertEqual(template.name, "Test Template")
        XCTAssertEqual(template.type, .character)
        XCTAssertEqual(template.description, "Test description")
        XCTAssertEqual(template.contentTemplate, "Name: [Name]")
        XCTAssertEqual(template.suggestedTags, ["test", "template"])
        XCTAssertNotNil(template.id)
    }
    
    func testBuiltInTemplates() {
        let templates = ElementTemplate.builtInTemplates
        XCTAssertGreaterThan(templates.count, 0)
        
        // Test that we have templates for different element types
        let characterTemplates = templates.filter { $0.type == .character }
        let locationTemplates = templates.filter { $0.type == .location }
        
        XCTAssertGreaterThan(characterTemplates.count, 0)
        XCTAssertGreaterThan(locationTemplates.count, 0)
        
        // Test specific templates exist
        XCTAssertTrue(templates.contains { $0.name == "Protagonist" })
        XCTAssertTrue(templates.contains { $0.name == "Fantasy City" })
    }
    
    // MARK: - Performance Tests
    
    func testWorldCreationPerformance() {
        measure {
            for i in 0..<100 {
                let world = World(title: "World \(i)", desc: "Description \(i)")
                XCTAssertNotNil(world.id)
            }
        }
    }
    
    func testElementCreationPerformance() {
        let worldId = UUID()
        
        measure {
            for i in 0..<1000 {
                let element = WorldElement(
                    worldId: worldId,
                    type: .character,
                    title: "Element \(i)",
                    content: "Content for element \(i)"
                )
                XCTAssertNotNil(element.id)
            }
        }
    }
    
    func testDataStoreOperationsPerformance() {
        let world = World(title: "Performance Test World", desc: "Testing performance")
        dataStore.addWorld(world)
        
        measure {
            for i in 0..<50 {
                let element = WorldElement(
                    worldId: world.id,
                    type: ElementType.allCases[i % ElementType.allCases.count],
                    title: "Element \(i)",
                    content: "Performance test content"
                )
                dataStore.addElement(to: world.id, element: element)
            }
        }
    }
    
    func testSearchPerformance() {
        let world = World(title: "Search Test World", desc: "Testing search")
        dataStore.addWorld(world)
        
        // Add many elements
        for i in 0..<100 {
            let element = WorldElement(
                worldId: world.id,
                type: ElementType.allCases[i % ElementType.allCases.count],
                title: "Element \(i)",
                content: "This is content for element \(i) with various keywords"
            )
            dataStore.addElement(to: world.id, element: element)
        }
        
        measure {
            let elements = dataStore.getElementsForMentions(in: world.id)
            XCTAssertEqual(elements.count, 100)
        }
    }
}