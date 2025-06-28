//
//  CoreDataExtensions.swift
//  forworldbuilders-apple-client
//
//  Created on 6/11/25.
//

import Foundation
import CoreData

// MARK: - World Extensions
extension World {
    
    var wrappedTitle: String {
        title ?? "Untitled World"
    }
    
    var wrappedDescription: String {
        desc ?? ""
    }
    
    var wrappedId: UUID {
        id ?? UUID()
    }
    
    var wrappedCreated: Date {
        created ?? Date()
    }
    
    var wrappedLastModified: Date {
        lastModified ?? Date()
    }
    
    var elementsArray: [WorldElement] {
        let set = elements as? Set<WorldElement> ?? []
        return set.sorted {
            $0.wrappedTitle < $1.wrappedTitle
        }
    }
    
    static func create(in context: NSManagedObjectContext,
                      title: String,
                      description: String) -> World {
        let world = World(context: context)
        world.id = UUID()
        world.title = title
        world.desc = description
        world.created = Date()
        world.lastModified = Date()
        return world
    }
    
    func updateModificationDate() {
        lastModified = Date()
    }
}

// MARK: - WorldElement Extensions
extension WorldElement {
    
    var wrappedTitle: String {
        title ?? "Untitled Element"
    }
    
    var wrappedContent: String {
        content ?? ""
    }
    
    var wrappedType: String {
        type ?? "General"
    }
    
    var wrappedId: UUID {
        id ?? UUID()
    }
    
    var wrappedWorldId: UUID {
        worldId ?? UUID()
    }
    
    var wrappedTags: [String] {
        tags ?? []
    }
    
    var wrappedRelationships: [String] {
        relationships ?? []
    }
    
    static func create(in context: NSManagedObjectContext,
                      world: World,
                      type: String,
                      title: String,
                      content: String,
                      tags: [String] = []) -> WorldElement {
        let element = WorldElement(context: context)
        element.id = UUID()
        element.worldId = world.id
        element.type = type
        element.title = title
        element.content = content
        element.tags = tags
        element.relationships = []
        element.world = world
        
        world.updateModificationDate()
        
        return element
    }
}

// MARK: - Relationship Extensions
extension Relationship {
    
    var wrappedId: UUID {
        id ?? UUID()
    }
    
    var wrappedSourceElementId: UUID {
        sourceElementId ?? UUID()
    }
    
    var wrappedTargetElementId: UUID {
        targetElementId ?? UUID()
    }
    
    var wrappedType: String {
        type ?? "Related To"
    }
    
    var wrappedStrength: Double {
        strength
    }
    
    var isBidirectional: Bool {
        bidirectional
    }
    
    static func create(in context: NSManagedObjectContext,
                      sourceElementId: UUID,
                      targetElementId: UUID,
                      type: String,
                      strength: Double = 1.0,
                      bidirectional: Bool = false) -> Relationship {
        let relationship = Relationship(context: context)
        relationship.id = UUID()
        relationship.sourceElementId = sourceElementId
        relationship.targetElementId = targetElementId
        relationship.type = type
        relationship.strength = strength
        relationship.bidirectional = bidirectional
        return relationship
    }
}

// MARK: - Element Type Enum
enum ElementType: String, CaseIterable {
    case character = "Character"
    case location = "Location"
    case item = "Item"
    case event = "Event"
    case concept = "Concept"
    case organization = "Organization"
    case general = "General"
    
    var iconName: String {
        switch self {
        case .character: return "person.fill"
        case .location: return "map.fill"
        case .item: return "cube.fill"
        case .event: return "calendar"
        case .concept: return "lightbulb.fill"
        case .organization: return "building.2.fill"
        case .general: return "doc.text.fill"
        }
    }
}

// MARK: - Relationship Type Enum
enum RelationshipType: String, CaseIterable {
    case relatedTo = "Related To"
    case parentOf = "Parent Of"
    case childOf = "Child Of"
    case partOf = "Part Of"
    case contains = "Contains"
    case knows = "Knows"
    case owns = "Owns"
    case createdBy = "Created By"
    case locatedIn = "Located In"
    case participatesIn = "Participates In"
    
    var inverse: RelationshipType? {
        switch self {
        case .parentOf: return .childOf
        case .childOf: return .parentOf
        case .contains: return .partOf
        case .partOf: return .contains
        default: return nil
        }
    }
}