//
//  WorldListView.swift
//  forworldbuilders-apple-client
//
//  Created on 6/11/25.
//

import SwiftUI
import CoreData

struct WorldListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \World.lastModified, ascending: false)],
        animation: .default)
    private var worlds: FetchedResults<World>
    
    @State private var showingCreateWorld = false
    @State private var showingLimitAlert = false
    @State private var worldToDelete: World?
    @State private var showingDeleteAlert = false
    
    private let freeWorldLimit = 3
    
    var columns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible())]
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if worlds.isEmpty {
                    EmptyWorldsView(showingCreateWorld: $showingCreateWorld)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(worlds) { world in
                            WorldCardView(world: world)
                                .onTapGesture {
                                    // Navigation handled in WorldCardView
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        worldToDelete = world
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        
                        // Add New World Card
                        if worlds.count < freeWorldLimit {
                            AddWorldCardView()
                                .onTapGesture {
                                    showingCreateWorld = true
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Worlds")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if worlds.count >= freeWorldLimit {
                            showingLimitAlert = true
                        } else {
                            showingCreateWorld = true
                        }
                    }) {
                        Label("Add World", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateWorld) {
                NewWorldView(isPresented: $showingCreateWorld)
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert("Free Tier Limit", isPresented: $showingLimitAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You've reached the limit of 3 worlds on the free tier. Upgrade to Pro for unlimited worlds!")
            }
            .alert("Delete World?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let world = worldToDelete {
                        deleteWorld(world)
                    }
                }
            } message: {
                Text("Are you sure you want to delete \"\(worldToDelete?.wrappedTitle ?? "this world")\"? This action cannot be undone.")
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func deleteWorld(_ world: World) {
        withAnimation {
            viewContext.delete(world)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - World Card View
struct WorldCardView: View {
    @ObservedObject var world: World
    
    var body: some View {
        NavigationLink(destination: WorldDetailView(world: world)) {
            VStack(alignment: .leading, spacing: 12) {
                // World Title and Icon
                HStack {
                    Image(systemName: "globe.americas.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Text(world.wrappedTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                // Description
                Text(world.wrappedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Stats
                VStack(spacing: 8) {
                    HStack {
                        Label("\(world.elementsArray.count)", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(world.wrappedLastModified, formatter: relativeDateFormatter)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Element Type Preview
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(getElementTypeCounts(for: world), id: \.type) { item in
                                ElementTypeChip(type: item.type, count: item.count)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(minHeight: 180)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getElementTypeCounts(for world: World) -> [(type: ElementType, count: Int)] {
        var counts: [ElementType: Int] = [:]
        
        for element in world.elementsArray {
            if let type = ElementType(rawValue: element.wrappedType) {
                counts[type, default: 0] += 1
            }
        }
        
        return counts.map { ($0.key, $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(4)
            .map { (type: $0.0, count: $0.1) }
    }
}

// MARK: - Element Type Chip
struct ElementTypeChip: View {
    let type: ElementType
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.iconName)
                .font(.caption2)
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .foregroundColor(.accentColor)
        .cornerRadius(12)
    }
}

// MARK: - Add World Card
struct AddWorldCardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("Create New World")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Start building your universe")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 180)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
        )
    }
}

// MARK: - Empty Worlds View
struct EmptyWorldsView: View {
    @Binding var showingCreateWorld: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "globe.central.south.asia")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Worlds Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first world to start building")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingCreateWorld = true
            }) {
                Label("Create Your First World", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Date Formatter
private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
}()

// MARK: - Preview
struct WorldListView_Previews: PreviewProvider {
    static var previews: some View {
        WorldListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}