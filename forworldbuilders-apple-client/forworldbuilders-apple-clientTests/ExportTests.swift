//
//  ExportTests.swift
//  forworldbuilders-apple-clientTests
//
//  Created by Owner on 6/11/25.
//

import XCTest
@testable import forworldbuilders_apple_client

final class ExportTests: XCTestCase {
    
    var dataStore: DataStore!
    var sampleWorld: World!
    var sampleElements: [WorldElement]!
    
    override func setUpWithError() throws {
        dataStore = DataStore()
        
        // Create sample data for testing
        sampleWorld = World(title: "Test World", desc: "A world for testing exports")
        dataStore.addWorld(sampleWorld)
        
        let character = WorldElement(worldId: sampleWorld.id, type: .character, title: "Hero", content: "A brave warrior with a sword", tags: ["hero", "warrior"])
        let location = WorldElement(worldId: sampleWorld.id, type: .location, title: "Castle", content: "A mighty fortress", tags: ["fortress", "stone"])
        let item = WorldElement(worldId: sampleWorld.id, type: .item, title: "Magic Sword", content: "A glowing blade", tags: ["magic", "weapon"])
        
        dataStore.addElement(to: sampleWorld.id, element: character)
        dataStore.addElement(to: sampleWorld.id, element: location)
        dataStore.addElement(to: sampleWorld.id, element: item)
        
        sampleElements = [character, location, item]
        
        // Add relationships
        let relationship1 = ElementRelationship(fromElementId: character.id, toElementId: location.id, type: .locatedIn, description: "Hero lives in the castle")
        let relationship2 = ElementRelationship(fromElementId: character.id, toElementId: item.id, type: .ownedBy, description: "Hero owns the magic sword")
        
        dataStore.addRelationship(to: sampleWorld.id, relationship: relationship1)
        dataStore.addRelationship(to: sampleWorld.id, relationship: relationship2)
    }
    
    override func tearDownWithError() throws {
        dataStore = nil
        sampleWorld = nil
        sampleElements = nil
    }
    
    // MARK: - ExportData Model Tests
    
    func testExportDataCreation() {
        let exportData = ExportData(
            worlds: dataStore.worlds,
            recentActivity: dataStore.recentActivity,
            exportDate: Date(),
            version: "1.0.0"
        )
        
        XCTAssertEqual(exportData.worlds.count, 1)
        XCTAssertEqual(exportData.worlds.first?.title, "Test World")
        XCTAssertGreaterThan(exportData.recentActivity.count, 0)
        XCTAssertEqual(exportData.version, "1.0.0")
        XCTAssertNotNil(exportData.exportDate)
    }
    
    func testExportDataCodable() throws {
        let exportData = ExportData(
            worlds: dataStore.worlds,
            recentActivity: dataStore.recentActivity,
            exportDate: Date(),
            version: "1.0.0"
        )
        
        // Test JSON encoding/decoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(exportData)
        XCTAssertGreaterThan(jsonData.count, 0)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decodedData = try decoder.decode(ExportData.self, from: jsonData)
        
        XCTAssertEqual(decodedData.worlds.count, exportData.worlds.count)
        XCTAssertEqual(decodedData.recentActivity.count, exportData.recentActivity.count)
        XCTAssertEqual(decodedData.version, exportData.version)
        XCTAssertEqual(decodedData.worlds.first?.title, exportData.worlds.first?.title)
    }
    
    // MARK: - Export Format Tests
    
    func testExportFormatProperties() {
        let formats = [
            (ExportFormat.json, "json", "Complete data structure with full fidelity", "doc.text"),
            (ExportFormat.text, "txt", "Simple human-readable format", "doc.plaintext"),
            (ExportFormat.markdown, "md", "Formatted text with headers and links", "doc.richtext"),
            (ExportFormat.pdf, "pdf", "Professional document format", "doc.fill"),
            (ExportFormat.csv, "csv", "Spreadsheet-compatible data", "tablecells"),
            (ExportFormat.xml, "xml", "Structured markup format", "chevron.left.forwardslash.chevron.right")
        ]
        
        for (format, expectedExtension, expectedDescription, expectedIcon) in formats {
            XCTAssertEqual(format.fileExtension, expectedExtension)
            XCTAssertEqual(format.description, expectedDescription)
            XCTAssertEqual(format.icon, expectedIcon)
        }
        
        XCTAssertEqual(ExportFormat.allCases.count, 6)
    }
    
    // MARK: - JSON Export Tests
    
    func testJSONExportContent() throws {
        let exportData = ExportData(
            worlds: dataStore.worlds,
            recentActivity: dataStore.recentActivity,
            exportDate: Date(),
            version: "1.0.0"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(exportData)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Verify JSON contains expected content
        XCTAssertTrue(jsonString.contains("Test World"))
        XCTAssertTrue(jsonString.contains("Hero"))
        XCTAssertTrue(jsonString.contains("Castle"))
        XCTAssertTrue(jsonString.contains("Magic Sword"))
        XCTAssertTrue(jsonString.contains("locatedIn"))
        XCTAssertTrue(jsonString.contains("ownedBy"))
        XCTAssertTrue(jsonString.contains("version"))
        XCTAssertTrue(jsonString.contains("exportDate"))
    }
    
    // MARK: - Text Export Tests
    
    func testTextExportGeneration() {
        let exportData = ExportData(
            worlds: dataStore.worlds,
            recentActivity: [],
            exportDate: Date(),
            version: "1.0.0"
        )
        
        var textOutput = "For World Builders Export\n"
        textOutput += "========================\n"
        textOutput += "Export Date: \(exportData.exportDate)\n"
        textOutput += "Version: \(exportData.version)\n\n"
        
        for world in exportData.worlds {
            textOutput += "WORLD: \(world.title)\n"
            textOutput += "Description: \(world.desc)\n"
            textOutput += "Created: \(world.created)\n"
            textOutput += "Elements: \(world.elements.count)\n"
            textOutput += "Relationships: \(world.relationships.count)\n\n"
            
            for element in world.elements {
                textOutput += "  ELEMENT: \(element.title) (\(element.type.rawValue))\n"
                textOutput += "  Content: \(element.content)\n"
                textOutput += "  Tags: \(element.tags.joined(separator: ", "))\n\n"
            }
            
            textOutput += "---\n\n"
        }
        
        // Verify text export contains expected content
        XCTAssertTrue(textOutput.contains("For World Builders Export"))
        XCTAssertTrue(textOutput.contains("Test World"))
        XCTAssertTrue(textOutput.contains("Hero"))
        XCTAssertTrue(textOutput.contains("Castle"))
        XCTAssertTrue(textOutput.contains("Elements: 3"))
        XCTAssertTrue(textOutput.contains("Relationships: 2"))
    }
    
    // MARK: - Markdown Export Tests
    
    func testMarkdownExportGeneration() {
        let exportData = ExportData(
            worlds: dataStore.worlds,
            recentActivity: [],
            exportDate: Date(),
            version: "1.0.0"
        )
        
        var markdown = "# For World Builders Export\n\n"
        markdown += "**Export Date:** \(exportData.exportDate.formatted())\n"
        markdown += "**Version:** \(exportData.version)\n\n"
        markdown += "---\n\n"
        
        for world in exportData.worlds {
            markdown += "## 🌍 \(world.title)\n\n"
            markdown += "**Description:** \(world.desc)\n\n"
            
            // Group elements by type
            let groupedElements = Dictionary(grouping: world.elements) { $0.type }
            
            for elementType in ElementType.allCases {
                if let elements = groupedElements[elementType], !elements.isEmpty {
                    markdown += "### \(elementType.icon) \(elementType.rawValue)s\n\n"
                    
                    for element in elements.sorted(by: { $0.title < $1.title }) {
                        markdown += "#### \(element.title)\n\n"
                        
                        if !element.content.isEmpty {
                            markdown += "\(element.content)\n\n"
                        }
                        
                        if !element.tags.isEmpty {
                            markdown += "**Tags:** `\(element.tags.joined(separator: "`, `"))`\n\n"
                        }
                    }
                }
            }
        }
        
        // Verify markdown export contains expected content
        XCTAssertTrue(markdown.contains("# For World Builders Export"))
        XCTAssertTrue(markdown.contains("## 🌍 Test World"))
        XCTAssertTrue(markdown.contains("#### Hero"))
        XCTAssertTrue(markdown.contains("#### Castle"))
        XCTAssertTrue(markdown.contains("**Tags:**"))
        XCTAssertTrue(markdown.contains("### 👤 Characters"))
        XCTAssertTrue(markdown.contains("### 🗺️ Locations"))
    }
    
    // MARK: - CSV Export Tests
    
    func testCSVExportGeneration() {
        var csvContent = ""
        
        // Header
        csvContent += "World,Element Type,Element Title,Element Content,Tags,Created,Last Modified,Relationships\n"
        
        for world in dataStore.worlds {
            for element in world.elements {
                let relationships = world.relationships.filter { 
                    $0.fromElementId == element.id || $0.toElementId == element.id 
                }
                
                let relationshipDesc = relationships.map { rel in
                    if rel.fromElementId == element.id {
                        if let toElement = world.elements.first(where: { $0.id == rel.toElementId }) {
                            return "\(rel.type.rawValue) → \(toElement.title)"
                        }
                    } else {
                        if let fromElement = world.elements.first(where: { $0.id == rel.fromElementId }) {
                            return "\(fromElement.title) → \(rel.type.rawValue)"
                        }
                    }
                    return ""
                }.filter { !$0.isEmpty }.joined(separator: "; ")
                
                // Escape CSV fields
                let worldTitle = "\"\(world.title.replacingOccurrences(of: "\"", with: "\"\""))\""
                let elementType = "\"\(element.type.rawValue)\""
                let elementTitle = "\"\(element.title.replacingOccurrences(of: "\"", with: "\"\""))\""
                let elementContent = "\"\(element.content.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: " "))\""
                let tags = "\"\(element.tags.joined(separator: "; "))\""
                let created = "\"\(element.created.formatted())\""
                let modified = "\"\(element.lastModified.formatted())\""
                let relationships = "\"\(relationshipDesc)\""
                
                csvContent += "\(worldTitle),\(elementType),\(elementTitle),\(elementContent),\(tags),\(created),\(modified),\(relationships)\n"
            }
        }
        
        // Verify CSV export contains expected content
        XCTAssertTrue(csvContent.contains("World,Element Type,Element Title"))
        XCTAssertTrue(csvContent.contains("\"Test World\""))
        XCTAssertTrue(csvContent.contains("\"Character\""))
        XCTAssertTrue(csvContent.contains("\"Hero\""))
        XCTAssertTrue(csvContent.contains("\"Located In → Castle\""))
        XCTAssertTrue(csvContent.contains("\"hero; warrior\""))
    }
    
    // MARK: - XML Export Tests
    
    func testXMLExportGeneration() {
        let exportData = ExportData(
            worlds: dataStore.worlds,
            recentActivity: [],
            exportDate: Date(),
            version: "1.0.0"
        )
        
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<ForWorldBuildersExport>\n"
        xml += "  <metadata>\n"
        xml += "    <exportDate>\(exportData.exportDate.ISO8601Format())</exportDate>\n"
        xml += "    <version>\(exportData.version)</version>\n"
        xml += "  </metadata>\n"
        xml += "  <worlds>\n"
        
        for world in exportData.worlds {
            xml += "    <world id=\"\(world.id)\">\n"
            xml += "      <title><![CDATA[\(world.title)]]></title>\n"
            xml += "      <description><![CDATA[\(world.desc)]]></description>\n"
            xml += "      <elements>\n"
            
            for element in world.elements {
                xml += "        <element id=\"\(element.id)\">\n"
                xml += "          <type>\(element.type.rawValue)</type>\n"
                xml += "          <title><![CDATA[\(element.title)]]></title>\n"
                xml += "          <content><![CDATA[\(element.content)]]></content>\n"
                xml += "          <tags>\n"
                for tag in element.tags {
                    xml += "            <tag><![CDATA[\(tag)]]></tag>\n"
                }
                xml += "          </tags>\n"
                xml += "        </element>\n"
            }
            
            xml += "      </elements>\n"
            xml += "      <relationships>\n"
            
            for relationship in world.relationships {
                xml += "        <relationship id=\"\(relationship.id)\">\n"
                xml += "          <fromElementId>\(relationship.fromElementId)</fromElementId>\n"
                xml += "          <toElementId>\(relationship.toElementId)</toElementId>\n"
                xml += "          <type>\(relationship.type.rawValue)</type>\n"
                xml += "        </relationship>\n"
            }
            
            xml += "      </relationships>\n"
            xml += "    </world>\n"
        }
        
        xml += "  </worlds>\n"
        xml += "</ForWorldBuildersExport>\n"
        
        // Verify XML export contains expected content
        XCTAssertTrue(xml.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        XCTAssertTrue(xml.contains("<ForWorldBuildersExport>"))
        XCTAssertTrue(xml.contains("<title><![CDATA[Test World]]></title>"))
        XCTAssertTrue(xml.contains("<title><![CDATA[Hero]]></title>"))
        XCTAssertTrue(xml.contains("<type>Character</type>"))
        XCTAssertTrue(xml.contains("<type>Located In</type>"))
        XCTAssertTrue(xml.contains("<tag><![CDATA[hero]]></tag>"))
    }
    
    // MARK: - Edge Cases Tests
    
    func testExportWithEmptyData() {
        let emptyDataStore = DataStore()
        let exportData = ExportData(
            worlds: emptyDataStore.worlds,
            recentActivity: emptyDataStore.recentActivity,
            exportDate: Date(),
            version: "1.0.0"
        )
        
        XCTAssertTrue(exportData.worlds.isEmpty)
        XCTAssertTrue(exportData.recentActivity.isEmpty)
        
        // Should still be encodable
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(exportData))
    }
    
    func testExportWithSpecialCharacters() {
        let specialWorld = World(title: "Test \"Quotes\" & <Tags>", desc: "Special chars: !@#$%^&*()")
        let dataStore = DataStore()
        dataStore.addWorld(specialWorld)
        
        let specialElement = WorldElement(
            worldId: specialWorld.id,
            type: .character,
            title: "Hero with \"quotes\"",
            content: "Content with <xml> & special chars\nand newlines",
            tags: ["tag with spaces", "tag,with,commas"]
        )
        dataStore.addElement(to: specialWorld.id, element: specialElement)
        
        let exportData = ExportData(
            worlds: dataStore.worlds,
            recentActivity: [],
            exportDate: Date(),
            version: "1.0.0"
        )
        
        // Should handle special characters in JSON
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(exportData))
        
        // Test CSV escaping
        var csvContent = ""
        csvContent += "World,Element Type,Element Title,Element Content,Tags,Created,Last Modified,Relationships\n"
        
        for world in dataStore.worlds {
            for element in world.elements {
                let worldTitle = "\"\(world.title.replacingOccurrences(of: "\"", with: "\"\""))\""
                let elementTitle = "\"\(element.title.replacingOccurrences(of: "\"", with: "\"\""))\""
                let elementContent = "\"\(element.content.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: " "))\""
                
                csvContent += "\(worldTitle),\"Character\",\(elementTitle),\(elementContent),\"\",\"\",\"\",\"\"\n"
            }
        }
        
        XCTAssertTrue(csvContent.contains("\"Test \"\"Quotes\"\" & <Tags>\""))
        XCTAssertTrue(csvContent.contains("\"Hero with \"\"quotes\"\"\""))
        XCTAssertTrue(csvContent.contains("\"Content with <xml> & special chars and newlines\""))
    }
    
    func testExportWithLargeDataset() {
        let largeDataStore = DataStore()
        let world = World(title: "Large Test World", desc: "Testing with many elements")
        largeDataStore.addWorld(world)
        
        // Add 100 elements
        for i in 0..<100 {
            let element = WorldElement(
                worldId: world.id,
                type: ElementType.allCases[i % ElementType.allCases.count],
                title: "Element \(i)",
                content: "This is content for element \(i) with some longer text to test performance",
                tags: ["tag\(i)", "category\(i % 5)"]
            )
            largeDataStore.addElement(to: world.id, element: element)
        }
        
        // Add relationships
        let elements = largeDataStore.worlds.first!.elements
        for i in 0..<50 {
            let relationship = ElementRelationship(
                fromElementId: elements[i].id,
                toElementId: elements[(i + 1) % elements.count].id,
                type: RelationshipType.allCases[i % RelationshipType.allCases.count]
            )
            largeDataStore.addRelationship(to: world.id, relationship: relationship)
        }
        
        let exportData = ExportData(
            worlds: largeDataStore.worlds,
            recentActivity: largeDataStore.recentActivity,
            exportDate: Date(),
            version: "1.0.0"
        )
        
        // Should handle large datasets
        measure {
            let encoder = JSONEncoder()
            _ = try? encoder.encode(exportData)
        }
        
        XCTAssertEqual(exportData.worlds.first?.elements.count, 100)
        XCTAssertEqual(exportData.worlds.first?.relationships.count, 50)
        XCTAssertGreaterThan(exportData.recentActivity.count, 100) // World + 100 elements + 50 relationships
    }
    
    func testExportDataIntegrity() throws {
        let originalData = ExportData(
            worlds: dataStore.worlds,
            recentActivity: dataStore.recentActivity,
            exportDate: Date(),
            version: "1.0.0"
        )
        
        // Encode and decode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(originalData)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedData = try decoder.decode(ExportData.self, from: jsonData)
        
        // Verify all data is preserved
        XCTAssertEqual(decodedData.worlds.count, originalData.worlds.count)
        XCTAssertEqual(decodedData.worlds.first?.elements.count, originalData.worlds.first?.elements.count)
        XCTAssertEqual(decodedData.worlds.first?.relationships.count, originalData.worlds.first?.relationships.count)
        
        // Verify specific element data
        let originalHero = originalData.worlds.first?.elements.first { $0.title == "Hero" }
        let decodedHero = decodedData.worlds.first?.elements.first { $0.title == "Hero" }
        
        XCTAssertEqual(originalHero?.id, decodedHero?.id)
        XCTAssertEqual(originalHero?.title, decodedHero?.title)
        XCTAssertEqual(originalHero?.content, decodedHero?.content)
        XCTAssertEqual(originalHero?.tags, decodedHero?.tags)
        XCTAssertEqual(originalHero?.type, decodedHero?.type)
    }
}