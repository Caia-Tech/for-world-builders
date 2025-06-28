//
//  MinimalApp.swift
//  forworldbuilders-apple-client
//
//  Minimal working version for testing
//

import SwiftUI
import CoreData

// MARK: - Core Data Stack
class PersistenceController {
    static let shared = PersistenceController()
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data
        for i in 0..<3 {
            let newWorld = World(context: viewContext)
            newWorld.id = UUID()
            newWorld.title = "Sample World \(i + 1)"
            newWorld.desc = "This is a sample world for testing"
            newWorld.created = Date()
            newWorld.lastModified = Date()
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ForWorldBuilders")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// MARK: - Core Data Models
@objc(World)
public class World: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var created: Date?
    @NSManaged public var lastModified: Date?
}

// MARK: - Views
struct WorldListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \World.lastModified, ascending: false)],
        animation: .default)
    private var worlds: FetchedResults<World>
    
    @State private var showingNewWorld = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if worlds.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        Text("No Worlds Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Create your first world to begin your journey")
                            .foregroundColor(.secondary)
                        Button(action: { showingNewWorld = true }) {
                            Label("Create World", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 100)
                } else {
                    VStack(spacing: 16) {
                        ForEach(worlds) { world in
                            WorldCard(world: world)
                        }
                        
                        if worlds.count < 3 {
                            Button(action: { showingNewWorld = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.largeTitle)
                                    Text("Create New World")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 150)
                                .background(Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        .foregroundColor(.gray)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Worlds")
            .toolbar {
                if worlds.count < 3 {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingNewWorld = true }) {
                            Label("Add World", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewWorld) {
                NewWorldView()
            }
        }
    }
}

struct WorldCard: View {
    let world: World
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe.americas.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text(world.title ?? "Untitled World")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let desc = world.desc, !desc.isEmpty {
                Text(desc)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label("0 Elements", systemImage: "square.stack.3d.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let date = world.lastModified {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete World", systemImage: "trash")
            }
        }
        .alert("Delete World?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation {
                    viewContext.delete(world)
                    try? viewContext.save()
                }
            }
        } message: {
            Text("This will permanently delete \"\(world.title ?? "Untitled World")\" and all its elements.")
        }
    }
}

struct NewWorldView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("World Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("World Details")
                }
                
                Section {
                    Text("• Give your world a memorable name")
                    Text("• Add a brief description of your world's concept")
                    Text("• You can always change these later")
                } header: {
                    Text("Tips")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .navigationTitle("New World")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createWorld()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text("Failed to create world. Please try again.")
            }
        }
    }
    
    private func createWorld() {
        let newWorld = World(context: viewContext)
        newWorld.id = UUID()
        newWorld.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        newWorld.desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        newWorld.created = Date()
        newWorld.lastModified = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            showingError = true
        }
    }
}