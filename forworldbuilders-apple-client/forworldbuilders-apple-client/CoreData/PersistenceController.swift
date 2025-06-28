//
//  PersistenceController.swift
//  forworldbuilders-apple-client
//
//  Created on 6/11/25.
//

import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()
    
    // Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleWorld = World(context: viewContext)
        sampleWorld.id = UUID()
        sampleWorld.title = "Sample World"
        sampleWorld.desc = "A sample world for preview"
        sampleWorld.created = Date()
        sampleWorld.lastModified = Date()
        
        let sampleElement = WorldElement(context: viewContext)
        sampleElement.id = UUID()
        sampleElement.worldId = sampleWorld.id
        sampleElement.type = "Character"
        sampleElement.title = "Sample Character"
        sampleElement.content = "A brave hero on a quest"
        sampleElement.tags = ["hero", "protagonist"]
        sampleElement.world = sampleWorld
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ForWorldBuilders")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure for CloudKit sync
        container.persistentStoreDescriptions.forEach { storeDescription in
            // Enable persistent history tracking
            storeDescription.setOption(true as NSNumber,
                                     forKey: NSPersistentHistoryTrackingKey)
            
            // Enable remote change notifications
            storeDescription.setOption(true as NSNumber,
                                     forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Set CloudKit container options
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.forworldbuilders.app"
            )
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// MARK: - Core Data Saving support
extension PersistenceController {
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}