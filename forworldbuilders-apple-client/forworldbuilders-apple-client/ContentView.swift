//
//  ContentView.swift
//  forworldbuilders-apple-client
//
//  Created by Owner on 6/11/25.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    var body: some View {
        WorldListView()
    }
}

// MARK: - Views
struct WorldListView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingNewWorld = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var showingGlobalSearch = false
    @State private var showingRecentActivity = false
    @State private var showingSettings = false
    @State private var showingUpgradeAlert = false
    
    func importWorld() {
        #if os(macOS)
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.json]
        openPanel.message = "Choose a world or worlds export file to import"
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let jsonData = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                // Try to decode single world first
                if let world = try? decoder.decode(World.self, from: jsonData) {
                    // Check if we're at the world limit
                    if !subscriptionManager.canCreateMoreWorlds(currentCount: dataStore.worlds.count) {
                        importErrorMessage = "Free tier limit reached. You can only have 3 worlds. Upgrade to Premium for unlimited worlds."
                        showingImportError = true
                        showingUpgradeAlert = true
                        return
                    }
                    
                    // Check if world with same ID already exists
                    if dataStore.worlds.contains(where: { $0.id == world.id }) {
                        // Create new world with same data but new ID
                        var newWorld = world
                        let worldData = try JSONEncoder().encode(world)
                        newWorld = try decoder.decode(World.self, from: worldData)
                        
                        // Generate new title for imported world
                        let newTitle = "\(newWorld.title) (Imported)"
                        
                        // Create completely new world with new IDs
                        let importedWorld = World(title: newTitle, desc: newWorld.desc)
                        
                        // Copy elements with new IDs
                        for element in newWorld.elements {
                            let newElement = WorldElement(
                                worldId: importedWorld.id,
                                type: element.type,
                                title: element.title,
                                content: element.content,
                                tags: element.tags
                            )
                            dataStore.addElement(to: importedWorld.id, element: newElement)
                        }
                        
                        dataStore.addWorld(importedWorld)
                    } else {
                        dataStore.addWorld(world)
                    }
                    return
                }
                
                // Try to decode multiple worlds
                struct ExportData: Codable {
                    let version: String
                    let exportDate: Date
                    let worlds: [World]
                }
                
                if let exportData = try? decoder.decode(ExportData.self, from: jsonData) {
                    var importedCount = 0
                    var skippedCount = 0
                    
                    for world in exportData.worlds {
                        if !subscriptionManager.canCreateMoreWorlds(currentCount: dataStore.worlds.count) {
                            skippedCount += 1
                            continue
                        }
                        
                        if dataStore.worlds.contains(where: { $0.id == world.id }) {
                            // Import with new ID
                            let newTitle = "\(world.title) (Imported)"
                            let importedWorld = World(title: newTitle, desc: world.desc)
                            
                            for element in world.elements {
                                let newElement = WorldElement(
                                    worldId: importedWorld.id,
                                    type: element.type,
                                    title: element.title,
                                    content: element.content,
                                    tags: element.tags
                                )
                                dataStore.addElement(to: importedWorld.id, element: newElement)
                            }
                            
                            dataStore.addWorld(importedWorld)
                        } else {
                            dataStore.addWorld(world)
                        }
                        importedCount += 1
                    }
                    
                    if skippedCount > 0 {
                        importErrorMessage = "Imported \(importedCount) world(s). Skipped \(skippedCount) due to free tier limit."
                        showingImportError = true
                    }
                    return
                }
                
                importErrorMessage = "Invalid file format. Please select a valid world export file."
                showingImportError = true
                
            } catch {
                importErrorMessage = "Failed to import file: \(error.localizedDescription)"
                showingImportError = true
            }
        }
        #endif
    }
    
    func exportAllWorlds() {
        struct ExportData: Codable {
            let version: String
            let exportDate: Date
            let worlds: [World]
        }
        
        let exportData = ExportData(
            version: "1.0",
            exportDate: Date(),
            worlds: dataStore.worlds
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let jsonData = try? encoder.encode(exportData) {
            #if os(macOS)
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "ForWorldBuilders_AllWorlds_\(Date().timeIntervalSince1970).json"
            savePanel.message = "Choose where to save all worlds export"
            
            if savePanel.runModal() == .OK, let url = savePanel.url {
                try? jsonData.write(to: url)
            }
            #endif
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if dataStore.worlds.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        Text("No Worlds Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Create your first world to begin your journey")
                            .foregroundColor(.secondary)
                        Button(action: { 
                            if subscriptionManager.canCreateMoreWorlds(currentCount: dataStore.worlds.count) {
                                showingNewWorld = true
                            } else {
                                showingUpgradeAlert = true
                            }
                        }) {
                            Label("Create World", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.top, 100)
                } else {
                    VStack(spacing: 16) {
                        ForEach(dataStore.worlds.sorted(by: { $0.lastModified > $1.lastModified })) { world in
                            NavigationLink(destination: WorldDetailView(world: world)) {
                                WorldCard(world: world)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Show create button or upgrade prompt
                        if subscriptionManager.canCreateMoreWorlds(currentCount: dataStore.worlds.count) {
                            Button(action: { showingNewWorld = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.largeTitle)
                                    Text("Create New World")
                                        .font(.headline)
                                    if subscriptionManager.currentTier == .free,
                                       let remaining = subscriptionManager.getRemainingWorldsCount(currentCount: dataStore.worlds.count) {
                                        Text("\(remaining) remaining")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
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
                        } else {
                            // Free tier limit reached
                            Button(action: { showingUpgradeAlert = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "crown.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.yellow)
                                    Text("Upgrade to Premium")
                                        .font(.headline)
                                    Text("Create unlimited worlds")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 150)
                                .background(LinearGradient(
                                    colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow, lineWidth: 2)
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
                if subscriptionManager.canCreateMoreWorlds(currentCount: dataStore.worlds.count) {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { 
                            if subscriptionManager.canCreateMoreWorlds(currentCount: dataStore.worlds.count) {
                                showingNewWorld = true
                            } else {
                                showingUpgradeAlert = true
                            }
                        }) {
                            Label("Add World", systemImage: "plus")
                        }
                    }
                }
                
                if !dataStore.worlds.isEmpty {
                    ToolbarItem(placement: .automatic) {
                        Button(action: { showingGlobalSearch = true }) {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                    }
                    
                    ToolbarItem(placement: .automatic) {
                        Button(action: { showingRecentActivity = true }) {
                            Label("Recent Activity", systemImage: "clock")
                        }
                    }
                    
                    ToolbarItem(placement: .automatic) {
                        Menu {
                            Button(action: { exportAllWorlds() }) {
                                Label("Export All Worlds", systemImage: "square.and.arrow.up.on.square")
                            }
                            
                            Divider()
                            
                            Button(action: { importWorld() }) {
                                Label("Import World", systemImage: "square.and.arrow.down")
                            }
                        } label: {
                            Label("Export/Import", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingNewWorld) {
                NewWorldView()
            }
            .sheet(isPresented: $showingGlobalSearch) {
                GlobalSearchView()
                    .environmentObject(dataStore)
            }
            .sheet(isPresented: $showingRecentActivity) {
                RecentActivityView()
                    .environmentObject(dataStore)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(dataStore)
            }
            .alert("Import Error", isPresented: $showingImportError) {
                Button("OK") { }
            } message: {
                Text(importErrorMessage)
            }
            .sheet(isPresented: $showingUpgradeAlert) {
                UpgradeView()
                    .environmentObject(subscriptionManager)
            }
        }
    }
}

struct WorldCard: View {
    let world: World
    @EnvironmentObject var dataStore: DataStore
    @State private var showingDeleteAlert = false
    
    func exportWorld(_ world: World) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let jsonData = try? encoder.encode(world) {
            #if os(macOS)
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "\(world.title.replacingOccurrences(of: " ", with: "_")).json"
            savePanel.message = "Choose where to save your world export"
            
            if savePanel.runModal() == .OK, let url = savePanel.url {
                try? jsonData.write(to: url)
            }
            #endif
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe.americas.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text(world.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if !world.desc.isEmpty {
                Text(world.desc)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(world.elementCount) Elements", systemImage: "square.stack.3d.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if true {
                    Text(world.lastModified, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .contextMenu {
            Button {
                exportWorld(world)
            } label: {
                Label("Export World", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
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
                    dataStore.deleteWorld(world)
                }
            }
        } message: {
            Text("This will permanently delete \"\(world.title)\" and all its elements.")
        }
    }
}

struct NewWorldView: View {
    @EnvironmentObject var dataStore: DataStore
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
        let newWorld = World(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            desc: description.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        dataStore.addWorld(newWorld)
        dismiss()
    }
}

#Preview {
    ContentView()
        .environmentObject(DataStore.shared)
}

// MARK: - World Detail View
struct WorldDetailView: View {
    let world: World
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTab: ElementType = .character
    @State private var searchText = ""
    @State private var showingAddElement = false
    @State private var showingEditWorld = false
    @State private var showingAIAssistant = false
    @State private var showingStatistics = false
    @State private var showingRelationshipGraph = false
    
    var filteredElements: [WorldElement] {
        let elements = dataStore.worlds.first(where: { $0.id == world.id })?.elements ?? []
        let typeFiltered = elements.filter { $0.type == selectedTab }
        
        if searchText.isEmpty {
            return typeFiltered
        } else {
            return typeFiltered.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var currentWorld: World {
        dataStore.worlds.first(where: { $0.id == world.id }) ?? world
    }
    
    func exportCurrentWorld() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let jsonData = try? encoder.encode(currentWorld) {
            #if os(macOS)
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "\(currentWorld.title.replacingOccurrences(of: " ", with: "_")).json"
            savePanel.message = "Choose where to save your world export"
            
            if savePanel.runModal() == .OK, let url = savePanel.url {
                try? jsonData.write(to: url)
            }
            #endif
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(ElementType.allCases, id: \.self) { type in
                        TabButton(
                            type: type,
                            isSelected: selectedTab == type,
                            count: currentWorld.elementCount(for: type)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = type
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search \(selectedTab.rawValue)s...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding()
            
            // Element list
            ScrollView {
                if filteredElements.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: selectedTab.icon)
                            .font(.system(size: 60))
                            .foregroundColor(selectedTab.color.opacity(0.5))
                        Text("No \(selectedTab.rawValue)s Yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Add your first \(selectedTab.rawValue.lowercased()) to get started")
                            .foregroundColor(.secondary)
                        Button(action: { showingAddElement = true }) {
                            Label("Add \(selectedTab.rawValue)", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredElements) { element in
                            ElementRow(element: element, worldId: world.id)
                                .environmentObject(dataStore)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(currentWorld.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddElement = true }) {
                    Label("Add Element", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: { showingAIAssistant = true }) {
                    Label("AI Assistant", systemImage: "brain.head.profile")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: { showingRelationshipGraph = true }) {
                    Label("Relationship Graph", systemImage: "point.3.connected.trianglepath.dotted")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button(action: { showingEditWorld = true }) {
                        Label("Edit World", systemImage: "pencil")
                    }
                    
                    Button(action: { showingStatistics = true }) {
                        Label("Statistics", systemImage: "chart.bar.fill")
                    }
                    
                    Divider()
                    
                    Button(action: { exportCurrentWorld() }) {
                        Label("Export World", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddElement) {
            AddElementView(worldId: world.id, selectedType: selectedTab)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showingEditWorld) {
            EditWorldView(world: currentWorld)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showingAIAssistant) {
            AIAssistantView(world: currentWorld)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showingStatistics) {
            WorldStatisticsView(world: currentWorld)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showingRelationshipGraph) {
            RelationshipGraphView(world: currentWorld)
                .environmentObject(dataStore)
        }
    }
}

struct TabButton: View {
    let type: ElementType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: type.icon)
                        .font(.system(size: 16))
                    Text(type.rawValue)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
                .foregroundColor(isSelected ? type.color : .secondary)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? type.color : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(type.color.opacity(isSelected ? 0.2 : 0.1))
                        )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? type.color.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ElementRow: View {
    let element: WorldElement
    let worldId: UUID
    @EnvironmentObject var dataStore: DataStore
    @State private var showingDeleteAlert = false
    @State private var showingEditElement = false
    @State private var showingRelationships = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: element.type.icon)
                    .foregroundColor(element.type.color)
                Text(element.title)
                    .font(.headline)
                Spacer()
                Text(element.lastModified, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !element.content.isEmpty {
                LinkableTextView(
                    text: element.content,
                    mentions: element.mentions,
                    worldId: worldId
                )
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            }
            
            if !element.tags.isEmpty {
                HStack {
                    ForEach(element.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(element.type.color.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .contextMenu {
            Button {
                showingEditElement = true
            } label: {
                Label("Edit \(element.type.rawValue)", systemImage: "pencil")
            }
            
            Button {
                showingRelationships = true
            } label: {
                Label("Relationships", systemImage: "point.3.connected.trianglepath.dotted")
            }
            
            Divider()
            
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete \(element.type.rawValue)", systemImage: "trash")
            }
        }
        .alert("Delete \(element.type.rawValue)?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation {
                    dataStore.deleteElement(from: worldId, elementId: element.id)
                }
            }
        } message: {
            Text("This will permanently delete \"\(element.title)\".")
        }
        .sheet(isPresented: $showingEditElement) {
            EditElementView(worldId: worldId, element: element)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showingRelationships) {
            ElementRelationshipsView(worldId: worldId, element: element)
                .environmentObject(dataStore)
        }
    }
}

struct AddElementView: View {
    let worldId: UUID
    let selectedType: ElementType
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var elementType: ElementType
    @State private var title = ""
    @State private var content = ""
    @State private var tagInput = ""
    @State private var showingError = false
    @State private var errorMessage = "Failed to create element. Please try again."
    @State private var showingTemplates = false
    @State private var selectedTemplate: ElementTemplate?
    
    init(worldId: UUID, selectedType: ElementType) {
        self.worldId = worldId
        self.selectedType = selectedType
        self._elementType = State(initialValue: selectedType)
    }
    
    var parsedTags: [String] {
        tagInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Element Type", selection: $elementType) {
                        ForEach(ElementType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button(action: { showingTemplates = true }) {
                        Label("Use Template", systemImage: "doc.text.fill")
                    }
                    
                    TextField("Title", text: $title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        MentionTextEditor(
                            worldId: worldId,
                            elementId: nil,
                            text: $content
                        )
                    }
                    
                    TextField("Tags (comma separated)", text: $tagInput)
                } header: {
                    Text("Element Details")
                }
                
                if !parsedTags.isEmpty {
                    Section {
                        HStack {
                            ForEach(parsedTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(elementType.color.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    } header: {
                        Text("Tags Preview")
                    }
                }
                
                Section {
                    Text("• Give your \(elementType.rawValue.lowercased()) a descriptive name")
                    Text("• Add details about their role in your world")
                    Text("• Use tags to organize and categorize")
                } header: {
                    Text("Tips")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .navigationTitle("New \(elementType.rawValue)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createElement()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingTemplates) {
                ElementTemplateSelectionView(
                    elementType: elementType,
                    onTemplateSelected: applyTemplate
                )
            }
        }
    }
    
    private func createElement() {
        // Check element limit for free tier
        if let world = dataStore.worlds.first(where: { $0.id == worldId }),
           world.elementCount >= 100 {
            errorMessage = "Free tier limit reached. You can have up to 100 elements per world."
            showingError = true
            return
        }
        
        let newElement = WorldElement(
            worldId: worldId,
            type: elementType,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: parsedTags
        )
        
        dataStore.addElement(to: worldId, element: newElement)
        dismiss()
    }
    
    private func applyTemplate(_ template: ElementTemplate) {
        elementType = template.type
        title = ""
        content = template.contentTemplate
        tagInput = template.suggestedTags.joined(separator: ", ")
        selectedTemplate = template
        showingTemplates = false
    }
}

extension AddElementView {
    var availableTemplates: [ElementTemplate] {
        ElementTemplate.builtInTemplates.filter { $0.type == elementType }
    }
}

struct EditElementView: View {
    let worldId: UUID
    let element: WorldElement
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var elementType: ElementType
    @State private var title: String
    @State private var content: String
    @State private var tagInput: String
    @State private var showingError = false
    @State private var errorMessage = "Failed to update element. Please try again."
    @State private var showingTemplates = false
    
    init(worldId: UUID, element: WorldElement) {
        self.worldId = worldId
        self.element = element
        self._elementType = State(initialValue: element.type)
        self._title = State(initialValue: element.title)
        self._content = State(initialValue: element.content)
        self._tagInput = State(initialValue: element.tags.joined(separator: ", "))
    }
    
    var parsedTags: [String] {
        tagInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Element Type", selection: $elementType) {
                        ForEach(ElementType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button(action: { showingTemplates = true }) {
                        Label("Use Template", systemImage: "doc.text.fill")
                    }
                    
                    TextField("Title", text: $title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        MentionTextEditor(
                            worldId: worldId,
                            elementId: element.id,
                            text: $content
                        )
                    }
                    
                    TextField("Tags (comma separated)", text: $tagInput)
                } header: {
                    Text("Element Details")
                }
                
                if !parsedTags.isEmpty {
                    Section {
                        HStack {
                            ForEach(parsedTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(elementType.color.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    } header: {
                        Text("Tags Preview")
                    }
                }
                
                Section {
                    Text("• Update your \(elementType.rawValue.lowercased()) details")
                    Text("• Changes are saved automatically")
                    Text("• Use tags to organize and categorize")
                } header: {
                    Text("Tips")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .navigationTitle("Edit \(element.type.rawValue)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateElement()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingTemplates) {
                ElementTemplateSelectionView(
                    elementType: elementType,
                    onTemplateSelected: applyTemplate
                )
            }
        }
    }
    
    private func updateElement() {
        var updatedElement = element
        updatedElement.type = elementType
        updatedElement.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedElement.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedElement.tags = parsedTags
        updatedElement.lastModified = Date()
        
        dataStore.updateElement(in: worldId, element: updatedElement)
        dismiss()
    }
    
    private func applyTemplate(_ template: ElementTemplate) {
        elementType = template.type
        content = template.contentTemplate
        tagInput = template.suggestedTags.joined(separator: ", ")
        showingTemplates = false
    }
}

struct EditWorldView: View {
    let world: World
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var showingError = false
    
    init(world: World) {
        self.world = world
        self._title = State(initialValue: world.title)
        self._description = State(initialValue: world.desc)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("World Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("World Details")
                }
                
                Section {
                    HStack {
                        Label("Elements", systemImage: "square.stack.3d.up")
                        Spacer()
                        Text("\(world.elementCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Created", systemImage: "calendar.badge.plus")
                        Spacer()
                        Text(world.created, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Last Modified", systemImage: "calendar")
                        Spacer()
                        Text(world.lastModified, style: .relative)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Information")
                }
                
                Section {
                    Text("• Update your world's name and description")
                    Text("• Changes are saved automatically")
                    Text("• World elements are preserved")
                } header: {
                    Text("Tips")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .navigationTitle("Edit World")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateWorld()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text("Failed to update world. Please try again.")
            }
        }
    }
    
    private func updateWorld() {
        var updatedWorld = world
        updatedWorld.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedWorld.desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedWorld.lastModified = Date()
        
        dataStore.updateWorld(updatedWorld)
        dismiss()
    }
}

struct AIAssistantView: View {
    let world: World
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText = ""
    @State private var conversation: [ChatMessage] = []
    @State private var isProcessing = false
    @State private var showingProUpgrade = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with world context
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("AI Assistant")
                            .font(.headline)
                        Spacer()
                        Text(world.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text("Get AI-powered suggestions for your world elements")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                
                Divider()
                
                // Chat area
                ScrollView {
                    if conversation.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60))
                                .foregroundColor(.blue.opacity(0.3))
                            
                            Text("AI Assistant Ready")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Ask me to help with character development, plot ideas, world lore, or anything related to your world!")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Try asking:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                SuggestionBubble(text: "Create a mysterious character for my fantasy world")
                                SuggestionBubble(text: "What are some unique locations I could add?")
                                SuggestionBubble(text: "Help me develop the culture of my world")
                            }
                            .padding()
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(conversation, id: \.id) { message in
                                ChatBubble(message: message)
                            }
                        }
                        .padding()
                    }
                }
                
                Divider()
                
                // Input area
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Ask your AI assistant...", text: $inputText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...4)
                        
                        Button(action: sendMessage) {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 36, height: 36)
                        .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(18)
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                    }
                    
                    // Free tier notice
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Text("AI features require Pro subscription")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Upgrade") {
                            showingProUpgrade = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 4)
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingProUpgrade) {
                ProUpgradeView()
            }
        }
    }
    
    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        // Add user message
        conversation.append(ChatMessage(text: userMessage, isUser: true))
        inputText = ""
        isProcessing = true
        
        // Simulate AI response (placeholder)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let responses = [
                "I'd love to help with that! However, AI features are available in the Pro version. Upgrade to unlock powerful AI assistance for your worldbuilding.",
                "That's a great question! AI-powered suggestions and character development are available with a Pro subscription.",
                "I can provide detailed worldbuilding assistance with the Pro version. Would you like to upgrade to access these features?"
            ]
            
            let response = responses.randomElement() ?? responses[0]
            conversation.append(ChatMessage(text: response, isUser: false))
            isProcessing = false
        }
    }
}

struct ChatMessage {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct SuggestionBubble: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
    }
}

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("Upgrade to Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Unlock powerful AI assistance and unlimited worlds")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "infinity", title: "Unlimited Worlds", description: "Create as many worlds as you want")
                    FeatureRow(icon: "infinity", title: "Unlimited Elements", description: "No limit on elements per world")
                    FeatureRow(icon: "brain.head.profile", title: "AI Assistant", description: "Get AI-powered worldbuilding suggestions")
                    FeatureRow(icon: "cpu", title: "Local AI", description: "Privacy-first offline AI models")
                    FeatureRow(icon: "cloud", title: "Cloud AI", description: "Use your own API keys for advanced AI")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Sync & Backup", description: "Keep your worlds safe across devices")
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        // TODO: Implement purchase logic
                    }) {
                        VStack(spacing: 4) {
                            Text("Start Pro - $19.99/month")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Cancel anytime")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button("Restore Purchases") {
                        // TODO: Implement restore logic
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationTitle("Upgrade")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ElementRelationshipsView: View {
    let worldId: UUID
    let element: WorldElement
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddRelationship = false
    
    var currentWorld: World? {
        dataStore.worlds.first(where: { $0.id == worldId })
    }
    
    var relationships: [ElementRelationship] {
        dataStore.getRelationships(for: element.id, in: worldId)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: element.type.icon)
                            .foregroundColor(element.type.color)
                        Text(element.title)
                            .font(.headline)
                        Spacer()
                    }
                    Text("Manage relationships between elements")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                
                Divider()
                
                // Relationships list
                ScrollView {
                    if relationships.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No Relationships")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Create connections between your world elements")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            
                            Button(action: { showingAddRelationship = true }) {
                                Label("Add Relationship", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(relationships, id: \.id) { relationship in
                                RelationshipRow(
                                    relationship: relationship,
                                    currentElement: element,
                                    worldId: worldId
                                )
                                .environmentObject(dataStore)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Relationships")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                if !relationships.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingAddRelationship = true }) {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddRelationship) {
                AddRelationshipView(worldId: worldId, fromElement: element)
                    .environmentObject(dataStore)
            }
        }
    }
}

struct RelationshipRow: View {
    let relationship: ElementRelationship
    let currentElement: WorldElement
    let worldId: UUID
    @EnvironmentObject var dataStore: DataStore
    @State private var showingDeleteAlert = false
    
    var otherElement: WorldElement? {
        guard let world = dataStore.worlds.first(where: { $0.id == worldId }) else { return nil }
        let otherId = relationship.fromElementId == currentElement.id 
            ? relationship.toElementId 
            : relationship.fromElementId
        return world.elements.first(where: { $0.id == otherId })
    }
    
    var relationshipDirection: String {
        if relationship.fromElementId == currentElement.id {
            return relationship.type.rawValue
        } else {
            // Show inverse relationship
            switch relationship.type {
            case .childOf: return "Parent Of"
            case .parentOf: return "Child Of"
            case .locatedIn: return "Contains"
            case .memberOf: return "Has Member"
            case .ownedBy: return "Owns"
            case .enemyOf: return "Enemy Of"
            case .allyOf: return "Ally Of"
            case .createdBy: return "Created"
            default: return relationship.type.rawValue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let other = otherElement {
                Image(systemName: other.type.icon)
                    .foregroundColor(other.type.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(relationshipDirection)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(relationship.created, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(other.title)
                        .font(.headline)
                    
                    if !relationship.description.isEmpty {
                        Text(relationship.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete Relationship", systemImage: "trash")
            }
        }
        .alert("Delete Relationship?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataStore.deleteRelationship(from: worldId, relationshipId: relationship.id)
            }
        } message: {
            if let other = otherElement {
                Text("This will remove the relationship between \"\(currentElement.title)\" and \"\(other.title)\".")
            }
        }
    }
}

struct AddRelationshipView: View {
    let worldId: UUID
    let fromElement: WorldElement
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedToElement: WorldElement?
    @State private var relationshipType: RelationshipType = .relatedTo
    @State private var description = ""
    
    var availableElements: [WorldElement] {
        guard let world = dataStore.worlds.first(where: { $0.id == worldId }) else { return [] }
        return world.elements.filter { $0.id != fromElement.id }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: fromElement.type.icon)
                            .foregroundColor(fromElement.type.color)
                        Text(fromElement.title)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("From")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Source Element")
                }
                
                Section {
                    Picker("Relationship Type", selection: $relationshipType) {
                        ForEach(RelationshipType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Relationship Type")
                }
                
                Section {
                    if availableElements.isEmpty {
                        Text("No other elements to connect")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Select Element", selection: $selectedToElement) {
                            Text("Select an element").tag(nil as WorldElement?)
                            ForEach(availableElements, id: \.id) { element in
                                Label(element.title, systemImage: element.type.icon)
                                    .tag(element as WorldElement?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Target Element")
                }
                
                Section {
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                } header: {
                    Text("Description")
                }
                
                Section {
                    Text("• Choose how elements are connected")
                    Text("• Relationships help organize your world")
                    Text("• You can add multiple relationships")
                } header: {
                    Text("Tips")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .navigationTitle("Add Relationship")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addRelationship()
                    }
                    .disabled(selectedToElement == nil)
                }
            }
        }
    }
    
    private func addRelationship() {
        guard let toElement = selectedToElement else { return }
        
        let relationship = ElementRelationship(
            fromElementId: fromElement.id,
            toElementId: toElement.id,
            type: relationshipType,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        dataStore.addRelationship(to: worldId, relationship: relationship)
        dismiss()
    }
}

struct WorldStatisticsView: View {
    let world: World
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    var totalElements: Int {
        world.elements.count
    }
    
    var totalRelationships: Int {
        world.relationships.count
    }
    
    var elementsByType: [(ElementType, Int)] {
        ElementType.allCases.map { type in
            (type, world.elements.filter { $0.type == type }.count)
        }.sorted { $0.1 > $1.1 }
    }
    
    var mostConnectedElement: (WorldElement, Int)? {
        let connectionCounts = world.elements.map { element in
            let connections = world.relationships.filter { 
                $0.fromElementId == element.id || $0.toElementId == element.id 
            }.count
            return (element, connections)
        }
        return connectionCounts.max { $0.1 < $1.1 }
    }
    
    var averageTagsPerElement: Double {
        guard totalElements > 0 else { return 0 }
        let totalTags = world.elements.reduce(0) { $0 + $1.tags.count }
        return Double(totalTags) / Double(totalElements)
    }
    
    var creationTrend: [Date] {
        world.elements.map { $0.created }.sorted()
    }
    
    var daysSinceLastActivity: Int {
        let lastModified = max(world.lastModified, world.elements.map { $0.lastModified }.max() ?? world.lastModified)
        return Calendar.current.dateComponents([.day], from: lastModified, to: Date()).day ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text(world.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("World Statistics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Quick Stats
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(
                            icon: "square.stack.3d.up.fill",
                            title: "Total Elements",
                            value: "\(totalElements)",
                            color: .blue
                        )
                        
                        StatCard(
                            icon: "point.3.connected.trianglepath.dotted",
                            title: "Relationships",
                            value: "\(totalRelationships)",
                            color: .green
                        )
                        
                        StatCard(
                            icon: "tag.fill",
                            title: "Avg Tags",
                            value: String(format: "%.1f", averageTagsPerElement),
                            color: .orange
                        )
                        
                        StatCard(
                            icon: "clock.fill",
                            title: "Days Since Activity",
                            value: "\(daysSinceLastActivity)",
                            color: daysSinceLastActivity > 7 ? .red : .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Element Type Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Element Breakdown")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ForEach(elementsByType, id: \.0) { type, count in
                                HStack {
                                    Image(systemName: type.icon)
                                        .foregroundColor(type.color)
                                        .frame(width: 24)
                                    
                                    Text(type.rawValue)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Text("\(count)")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    
                                    // Progress bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(type.color.opacity(0.2))
                                        .frame(width: 60, height: 8)
                                        .overlay(
                                            GeometryReader { geometry in
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(type.color)
                                                    .frame(width: totalElements > 0 ? geometry.size.width * (CGFloat(count) / CGFloat(totalElements)) : 0)
                                            }
                                        )
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Most Connected Element
                    if let (element, connectionCount) = mostConnectedElement, connectionCount > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Most Connected Element")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                Image(systemName: element.type.icon)
                                    .font(.title2)
                                    .foregroundColor(element.type.color)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(element.title)
                                        .font(.headline)
                                    Text("\(connectionCount) connection\(connectionCount == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    // World Timeline
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Development Timeline")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TimelineItem(
                                icon: "plus.circle.fill",
                                title: "World Created",
                                date: world.created,
                                color: .blue
                            )
                            
                            if let firstElement = creationTrend.first {
                                TimelineItem(
                                    icon: "square.fill",
                                    title: "First Element Added",
                                    date: firstElement,
                                    color: .green
                                )
                            }
                            
                            TimelineItem(
                                icon: "pencil.circle.fill",
                                title: "Last Modified",
                                date: world.lastModified,
                                color: .orange
                            )
                        }
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Statistics")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TimelineItem: View {
    let icon: String
    let title: String
    let date: Date
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(date, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

struct ElementTemplateSelectionView: View {
    let elementType: ElementType
    let onTemplateSelected: (ElementTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var availableTemplates: [ElementTemplate] {
        ElementTemplate.builtInTemplates.filter { $0.type == elementType }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if availableTemplates.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: elementType.icon)
                            .font(.system(size: 60))
                            .foregroundColor(elementType.color.opacity(0.5))
                        
                        Text("No Templates Available")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("No built-in templates for \(elementType.rawValue.lowercased())s yet. Create your element from scratch!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(availableTemplates, id: \.id) { template in
                            TemplateCard(
                                template: template,
                                onSelect: {
                                    onTemplateSelected(template)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("\(elementType.rawValue) Templates")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct TemplateCard: View {
    let template: ElementTemplate
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: template.type.icon)
                    .foregroundColor(template.type.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Use") {
                    onSelect()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            // Preview of template content
            VStack(alignment: .leading, spacing: 8) {
                Text("Template Preview:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(template.contentTemplate)
                    .font(.caption)
                    .lineLimit(4)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Suggested tags
            if !template.suggestedTags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Suggested Tags:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(template.suggestedTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(template.type.color.opacity(0.2))
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Mention Text Editor
struct MentionTextEditor: View {
    let worldId: UUID
    let elementId: UUID?
    @Binding var text: String
    @EnvironmentObject var dataStore: DataStore
    
    @State private var showingMentionPicker = false
    @State private var mentionQuery = ""
    @State private var mentionPosition: CGPoint = .zero
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    var availableElements: [WorldElement] {
        dataStore.getElementsForMentions(in: worldId, excluding: elementId)
            .filter { element in
                if mentionQuery.isEmpty {
                    return true
                }
                return element.title.localizedCaseInsensitiveContains(mentionQuery)
            }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .lineLimit(5...10)
                .onChange(of: text) { _, newValue in
                    detectMentions(in: newValue)
                }
            
            if showingMentionPicker && !availableElements.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(availableElements, id: \.id) { element in
                        Button(action: {
                            insertMention(element)
                        }) {
                            HStack {
                                Image(systemName: element.type.icon)
                                    .foregroundColor(element.type.color)
                                    .frame(width: 20)
                                Text(element.title)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .background(Color.gray.opacity(0.05))
                        
                        if element.id != availableElements.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 4)
                .frame(maxWidth: 250)
                .offset(x: mentionPosition.x, y: mentionPosition.y + 25)
            }
        }
    }
    
    private func detectMentions(in text: String) {
        let lastAtIndex = text.lastIndex(of: "@")
        
        if let atIndex = lastAtIndex {
            let afterAt = text[text.index(after: atIndex)...]
            let query = String(afterAt)
            
            // Check if we're still typing a mention (no spaces after @)
            if !query.contains(" ") && !query.contains("\n") {
                mentionQuery = query
                showingMentionPicker = true
                // In a real implementation, you'd calculate the actual position
                mentionPosition = CGPoint(x: 20, y: 20)
            } else {
                showingMentionPicker = false
            }
        } else {
            showingMentionPicker = false
        }
    }
    
    private func insertMention(_ element: WorldElement) {
        // Find the last @ symbol
        if let lastAtIndex = text.lastIndex(of: "@") {
            let beforeAt = text[..<lastAtIndex]
            let mentionText = "@\(element.title)"
            text = String(beforeAt) + mentionText + " "
            
            // Save mention information
            let mention = ElementMention(
                elementId: element.id,
                elementTitle: element.title,
                startIndex: beforeAt.count,
                length: mentionText.count
            )
            
            if let currentElementId = elementId {
                var currentMentions = dataStore.findElement(by: currentElementId, in: worldId)?.mentions ?? []
                currentMentions.append(mention)
                dataStore.updateElementMentions(in: worldId, elementId: currentElementId, mentions: currentMentions)
            }
        }
        
        showingMentionPicker = false
        mentionQuery = ""
    }
}

// MARK: - Linkable Text View
struct LinkableTextView: View {
    let text: String
    let mentions: [ElementMention]
    let worldId: UUID
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedElementId: UUID?
    @State private var showingElementDetail = false
    
    var body: some View {
        Text(attributedText)
            .onTapGesture { location in
                handleTap(at: location)
            }
            .sheet(isPresented: $showingElementDetail) {
                if let elementId = selectedElementId,
                   let element = dataStore.findElement(by: elementId, in: worldId) {
                    NavigationStack {
                        ElementDetailView(element: element, worldId: worldId)
                            .navigationTitle(element.title)
                            #if os(iOS)
                            .navigationBarTitleDisplayMode(.inline)
                            #endif
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Close") {
                                        showingElementDetail = false
                                    }
                                }
                            }
                    }
                }
            }
    }
    
    private var attributedText: AttributedString {
        var attributed = AttributedString(text)
        
        for mention in mentions {
            let range = mention.range
            if range.location + range.length <= text.count {
                let start = attributed.index(attributed.startIndex, offsetByCharacters: range.location)
                let end = attributed.index(start, offsetByCharacters: range.length)
                
                attributed[start..<end].foregroundColor = .blue
                attributed[start..<end].underlineStyle = .single
            }
        }
        
        return attributed
    }
    
    private func handleTap(at location: CGPoint) {
        // In a more sophisticated implementation, you'd convert the tap location
        // to a text position and check if it falls within a mention range
        // For now, we'll just show the first mention if any exist
        if let firstMention = mentions.first {
            selectedElementId = firstMention.elementId
            showingElementDetail = true
        }
    }
}

// MARK: - Element Detail View
struct ElementDetailView: View {
    let element: WorldElement
    let worldId: UUID
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: element.type.icon)
                        .font(.title)
                        .foregroundColor(element.type.color)
                    
                    VStack(alignment: .leading) {
                        Text(element.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(element.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Content
                if !element.content.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.headline)
                        
                        LinkableTextView(
                            text: element.content,
                            mentions: element.mentions,
                            worldId: worldId
                        )
                    }
                }
                
                // Tags
                if !element.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                        
                        HStack {
                            ForEach(element.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(element.type.color.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Information")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Created: \(element.created, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Modified: \(element.lastModified, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Global Search
struct GlobalSearchView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedWorldFilter: UUID?
    @State private var selectedTypeFilter: ElementType?
    @State private var selectedDateFilter: DateFilter = .all
    @State private var searchInContent = true
    @State private var searchInTags = true
    @State private var caseSensitive = false
    
    enum DateFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week" 
        case month = "This Month"
        case year = "This Year"
    }
    
    var filteredResults: [SearchResult] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        var results: [SearchResult] = []
        let query = caseSensitive ? searchText : searchText.lowercased()
        
        for world in dataStore.worlds {
            // Filter by world if specified
            if let worldFilter = selectedWorldFilter, world.id != worldFilter {
                continue
            }
            
            for element in world.elements {
                // Filter by element type if specified
                if let typeFilter = selectedTypeFilter, element.type != typeFilter {
                    continue
                }
                
                // Filter by date if specified
                if !matchesDateFilter(element.lastModified) {
                    continue
                }
                
                var matches: [SearchMatch] = []
                
                // Search in title
                let titleText = caseSensitive ? element.title : element.title.lowercased()
                if titleText.contains(query) {
                    matches.append(SearchMatch(type: .title, text: element.title, range: titleText.range(of: query)))
                }
                
                // Search in content
                if searchInContent {
                    let contentText = caseSensitive ? element.content : element.content.lowercased()
                    if contentText.contains(query) {
                        matches.append(SearchMatch(type: .content, text: element.content, range: contentText.range(of: query)))
                    }
                }
                
                // Search in tags
                if searchInTags {
                    for tag in element.tags {
                        let tagText = caseSensitive ? tag : tag.lowercased()
                        if tagText.contains(query) {
                            matches.append(SearchMatch(type: .tag, text: tag, range: tagText.range(of: query)))
                        }
                    }
                }
                
                if !matches.isEmpty {
                    results.append(SearchResult(
                        world: world,
                        element: element,
                        matches: matches
                    ))
                }
            }
        }
        
        return results.sorted { $0.element.lastModified > $1.element.lastModified }
    }
    
    private func matchesDateFilter(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateFilter {
        case .all:
            return true
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) ?? false
        case .month:
            return calendar.dateInterval(of: .month, for: now)?.contains(date) ?? false
        case .year:
            return calendar.dateInterval(of: .year, for: now)?.contains(date) ?? false
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search across all worlds...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Quick stats
                    if !searchText.isEmpty {
                        HStack {
                            Text("\(filteredResults.count) result\(filteredResults.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // World filter
                        Menu {
                            Button("All Worlds") {
                                selectedWorldFilter = nil
                            }
                            Divider()
                            ForEach(dataStore.worlds, id: \.id) { world in
                                Button(world.title) {
                                    selectedWorldFilter = world.id
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "globe.americas.fill")
                                Text(selectedWorldFilter != nil ? 
                                     dataStore.worlds.first(where: { $0.id == selectedWorldFilter })?.title ?? "All Worlds" :
                                     "All Worlds")
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedWorldFilter != nil ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                        
                        // Type filter
                        Menu {
                            Button("All Types") {
                                selectedTypeFilter = nil
                            }
                            Divider()
                            ForEach(ElementType.allCases, id: \.self) { type in
                                Button(action: { selectedTypeFilter = type }) {
                                    Label(type.rawValue, systemImage: type.icon)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedTypeFilter?.icon ?? "square.stack.3d.up")
                                Text(selectedTypeFilter?.rawValue ?? "All Types")
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTypeFilter != nil ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                        
                        // Date filter
                        Menu {
                            ForEach(DateFilter.allCases, id: \.self) { filter in
                                Button(filter.rawValue) {
                                    selectedDateFilter = filter
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                Text(selectedDateFilter.rawValue)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedDateFilter != .all ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                Divider()
                
                // Results
                ScrollView {
                    if searchText.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Global Search")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Search across all your worlds for elements, content, and tags")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        .padding(.top, 100)
                    } else if filteredResults.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No Results")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Try adjusting your search terms or filters")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredResults, id: \.element.id) { result in
                                SearchResultRow(result: result, searchQuery: searchText, caseSensitive: caseSensitive)
                                    .environmentObject(dataStore)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Section("Search Options") {
                            Button(action: { searchInContent.toggle() }) {
                                Label("Search in Content", systemImage: searchInContent ? "checkmark" : "")
                            }
                            
                            Button(action: { searchInTags.toggle() }) {
                                Label("Search in Tags", systemImage: searchInTags ? "checkmark" : "")
                            }
                            
                            Button(action: { caseSensitive.toggle() }) {
                                Label("Case Sensitive", systemImage: caseSensitive ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label("Options", systemImage: "slider.horizontal.3")
                    }
                }
            }
        }
    }
}

struct SearchResult {
    let world: World
    let element: WorldElement
    let matches: [SearchMatch]
}

struct SearchMatch {
    enum MatchType {
        case title, content, tag
    }
    
    let type: MatchType
    let text: String
    let range: Range<String.Index>?
}

struct SearchResultRow: View {
    let result: SearchResult
    let searchQuery: String
    let caseSensitive: Bool
    @EnvironmentObject var dataStore: DataStore
    @State private var showingElementDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: result.element.type.icon)
                    .foregroundColor(result.element.type.color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(highlightedText(result.element.title, query: searchQuery))
                        .font(.headline)
                    
                    HStack {
                        Text(result.world.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(result.element.lastModified, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { showingElementDetail = true }) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            
            // Content preview
            if !result.element.content.isEmpty {
                Text(highlightedText(String(result.element.content.prefix(150)), query: searchQuery))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Tags
            if !result.element.tags.isEmpty {
                HStack {
                    ForEach(result.element.tags.prefix(3), id: \.self) { tag in
                        Text(highlightedText(tag, query: searchQuery))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(result.element.type.color.opacity(0.2))
                            .cornerRadius(4)
                    }
                    if result.element.tags.count > 3 {
                        Text("+\(result.element.tags.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Match summary
            HStack {
                ForEach(Array(Set(result.matches.map { $0.type })), id: \.self) { matchType in
                    HStack(spacing: 4) {
                        Image(systemName: iconForMatchType(matchType))
                            .font(.caption2)
                        Text(labelForMatchType(matchType))
                            .font(.caption2)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(3)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .onTapGesture {
            showingElementDetail = true
        }
        .sheet(isPresented: $showingElementDetail) {
            NavigationStack {
                ElementDetailView(element: result.element, worldId: result.world.id)
                    .navigationTitle(result.element.title)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showingElementDetail = false
                            }
                        }
                    }
            }
        }
    }
    
    private func highlightedText(_ text: String, query: String) -> AttributedString {
        var attributed = AttributedString(text)
        let searchText = caseSensitive ? query : query.lowercased()
        let targetText = caseSensitive ? text : text.lowercased()
        
        if let range = targetText.range(of: searchText) {
            let start = attributed.index(attributed.startIndex, offsetByCharacters: targetText.distance(from: targetText.startIndex, to: range.lowerBound))
            let end = attributed.index(start, offsetByCharacters: searchText.count)
            
            attributed[start..<end].backgroundColor = .yellow.opacity(0.3)
            attributed[start..<end].font = .body.weight(.semibold)
        }
        
        return attributed
    }
    
    private func iconForMatchType(_ type: SearchMatch.MatchType) -> String {
        switch type {
        case .title: return "textformat"
        case .content: return "doc.text"
        case .tag: return "tag"
        }
    }
    
    private func labelForMatchType(_ type: SearchMatch.MatchType) -> String {
        switch type {
        case .title: return "Title"
        case .content: return "Content"
        case .tag: return "Tag"
        }
    }
}

// MARK: - Recent Activity
struct RecentActivityView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTimeFilter: TimeFilter = .all
    @State private var selectedWorldFilter: UUID?
    @State private var selectedActivityFilter: ActivityType?
    
    enum TimeFilter: String, CaseIterable {
        case hour = "Last Hour"
        case day = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
        
        var dateFilter: Date? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .hour:
                return calendar.date(byAdding: .hour, value: -1, to: now)
            case .day:
                return calendar.startOfDay(for: now)
            case .week:
                return calendar.dateInterval(of: .weekOfYear, for: now)?.start
            case .month:
                return calendar.dateInterval(of: .month, for: now)?.start
            case .all:
                return nil
            }
        }
    }
    
    private var filteredActivities: [ActivityItem] {
        var activities = dataStore.recentActivity
        
        // Filter by time
        if let dateFilter = selectedTimeFilter.dateFilter {
            activities = activities.filter { $0.timestamp >= dateFilter }
        }
        
        // Filter by world
        if let worldFilter = selectedWorldFilter {
            activities = activities.filter { $0.worldId == worldFilter }
        }
        
        // Filter by activity type
        if let activityFilter = selectedActivityFilter {
            activities = activities.filter { $0.type == activityFilter }
        }
        
        return activities
    }
    
    private var availableWorlds: [World] {
        dataStore.worlds.filter { world in
            dataStore.recentActivity.contains { $0.worldId == world.id }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Time Filter
                        Menu {
                            ForEach(TimeFilter.allCases, id: \.self) { filter in
                                Button(filter.rawValue) {
                                    selectedTimeFilter = filter
                                }
                            }
                        } label: {
                            Label(selectedTimeFilter.rawValue, systemImage: "clock")
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(16)
                        }
                        
                        // World Filter
                        if !availableWorlds.isEmpty {
                            Menu {
                                Button("All Worlds") {
                                    selectedWorldFilter = nil
                                }
                                Divider()
                                ForEach(availableWorlds) { world in
                                    Button(world.title) {
                                        selectedWorldFilter = world.id
                                    }
                                }
                            } label: {
                                Label(selectedWorldFilter != nil ? 
                                      (availableWorlds.first { $0.id == selectedWorldFilter }?.title ?? "World") : 
                                      "All Worlds", 
                                      systemImage: "globe")
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(16)
                            }
                        }
                        
                        // Activity Type Filter
                        Menu {
                            Button("All Activities") {
                                selectedActivityFilter = nil
                            }
                            Divider()
                            ForEach(ActivityType.allCases, id: \.self) { type in
                                Button(type.rawValue) {
                                    selectedActivityFilter = type
                                }
                            }
                        } label: {
                            Label(selectedActivityFilter?.rawValue ?? "All Activities", 
                                  systemImage: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(16)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Activity List
                if filteredActivities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Recent Activity")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Start creating worlds and elements to see your activity here.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredActivities) { activity in
                            ActivityRowView(activity: activity)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Recent Activity")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ActivityRowView: View {
    let activity: ActivityItem
    @EnvironmentObject var dataStore: DataStore
    @State private var showingElementDetail = false
    @State private var showingWorldDetail = false
    
    private var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: activity.timestamp, relativeTo: Date())
    }
    
    private var detailText: String {
        switch activity.type {
        case .worldCreated:
            return "Created world"
        case .worldModified:
            return "Modified world"
        case .elementCreated:
            return "Created \(activity.elementType?.rawValue.lowercased() ?? "element")"
        case .elementModified:
            return "Modified \(activity.elementType?.rawValue.lowercased() ?? "element")"
        case .elementDeleted:
            return "Deleted \(activity.elementType?.rawValue.lowercased() ?? "element")"
        case .relationshipCreated:
            return "Created relationship: \(activity.details)"
        case .relationshipDeleted:
            return "Deleted relationship: \(activity.details)"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Type Icon
            Image(systemName: activity.type.icon)
                .font(.title2)
                .foregroundColor(activity.type.color)
                .frame(width: 32, height: 32)
                .background(activity.type.color.opacity(0.1))
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 4) {
                // Primary action description
                HStack {
                    Text(detailText)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // World name (always shown)
                Button(action: {
                    showingWorldDetail = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.caption)
                        Text(activity.worldTitle)
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Element name (if applicable)
                if let elementTitle = activity.elementTitle {
                    Button(action: {
                        showingElementDetail = true
                    }) {
                        HStack(spacing: 4) {
                            if let elementType = activity.elementType {
                                Image(systemName: elementType.icon)
                                    .font(.caption)
                            }
                            Text(elementTitle)
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingWorldDetail) {
            if let world = dataStore.worlds.first(where: { $0.id == activity.worldId }) {
                NavigationStack {
                    WorldDetailView(world: world)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showingWorldDetail = false
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showingElementDetail) {
            if let elementId = activity.elementId,
               let element = dataStore.findElement(by: elementId, in: activity.worldId) {
                NavigationStack {
                    ElementDetailView(element: element, worldId: activity.worldId)
                        .navigationTitle(element.title)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showingElementDetail = false
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Visual Relationship Graph
struct RelationshipGraphView: View {
    let world: World
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedElement: WorldElement?
    @State private var showingElementDetail = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var filteredElementTypes: Set<ElementType> = Set(ElementType.allCases)
    @State private var showingFilters = false
    
    private var filteredElements: [WorldElement] {
        world.elements.filter { filteredElementTypes.contains($0.type) }
    }
    
    private var filteredRelationships: [ElementRelationship] {
        world.relationships.filter { relationship in
            filteredElements.contains { $0.id == relationship.fromElementId } &&
            filteredElements.contains { $0.id == relationship.toElementId }
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color.black.opacity(0.05)
                        .ignoresSafeArea()
                    
                    // Graph Canvas
                    Canvas { context, size in
                        drawRelationshipGraph(context: context, size: size)
                    }
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(0.5, min(2.0, value))
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = value.translation
                                }
                        )
                    )
                    
                    // Overlay elements for interaction
                    ForEach(filteredElements) { element in
                        ElementNodeView(
                            element: element,
                            position: nodePosition(for: element, in: geometry.size),
                            scale: scale,
                            offset: offset
                        ) {
                            selectedElement = element
                            showingElementDetail = true
                        }
                    }
                    
                    // Control Panel
                    VStack {
                        HStack {
                            Button(action: { showingFilters.toggle() }) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .padding(8)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Button(action: {
                                    scale = min(2.0, scale + 0.2)
                                }) {
                                    Image(systemName: "plus.magnifyingglass")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(8)
                                        .shadow(radius: 2)
                                }
                                
                                Button(action: {
                                    scale = max(0.5, scale - 0.2)
                                }) {
                                    Image(systemName: "minus.magnifyingglass")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(8)
                                        .shadow(radius: 2)
                                }
                                
                                Button(action: {
                                    scale = 1.0
                                    offset = .zero
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(8)
                                        .shadow(radius: 2)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Legend
                        if !filteredElementTypes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Element Types")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
                                    ForEach(Array(filteredElementTypes).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                                        HStack(spacing: 4) {
                                            Image(systemName: type.icon)
                                                .font(.caption)
                                                .foregroundColor(type.color)
                                            Text(type.rawValue)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(4)
                                    }
                                }
                                .padding(8)
                            }
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .padding(.leading, 8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Relationship Graph")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                ElementTypeFilterView(
                    selectedTypes: $filteredElementTypes,
                    availableTypes: Set(world.elements.map { $0.type })
                )
            }
            .sheet(isPresented: $showingElementDetail) {
                if let element = selectedElement {
                    NavigationStack {
                        ElementDetailView(element: element, worldId: world.id)
                            .navigationTitle(element.title)
                            #if os(iOS)
                            .navigationBarTitleDisplayMode(.inline)
                            #endif
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Close") {
                                        showingElementDetail = false
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func drawRelationshipGraph(context: GraphicsContext, size: CGSize) {
        // Draw relationship lines
        for relationship in filteredRelationships {
            guard let fromElement = filteredElements.first(where: { $0.id == relationship.fromElementId }),
                  let toElement = filteredElements.first(where: { $0.id == relationship.toElementId }) else {
                continue
            }
            
            let fromPos = nodePosition(for: fromElement, in: size)
            let toPos = nodePosition(for: toElement, in: size)
            
            // Draw line
            let path = Path { path in
                path.move(to: fromPos)
                path.addLine(to: toPos)
            }
            
            context.stroke(path, with: .color(.gray.opacity(0.6)), lineWidth: 2)
            
            // Draw relationship type label
            let midPoint = CGPoint(
                x: (fromPos.x + toPos.x) / 2,
                y: (fromPos.y + toPos.y) / 2
            )
            
            context.draw(
                Text(relationship.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary),
                at: midPoint
            )
        }
    }
    
    private func nodePosition(for element: WorldElement, in size: CGSize) -> CGPoint {
        // Use a simple circle layout based on element ID hash
        let hash = abs(element.id.hashValue)
        let angle = Double(hash % 360) * .pi / 180
        let radius = min(size.width, size.height) * 0.3
        
        let x = size.width / 2 + cos(angle) * radius
        let y = size.height / 2 + sin(angle) * radius
        
        return CGPoint(x: x, y: y)
    }
}

struct ElementNodeView: View {
    let element: WorldElement
    let position: CGPoint
    let scale: CGFloat
    let offset: CGSize
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Image(systemName: element.type.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(element.type.color)
                    .cornerRadius(20)
                    .shadow(radius: 2)
                
                Text(element.title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(4)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .position(
            x: position.x * scale + offset.width,
            y: position.y * scale + offset.height
        )
    }
}

struct ElementTypeFilterView: View {
    @Binding var selectedTypes: Set<ElementType>
    let availableTypes: Set<ElementType>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Element Types") {
                    ForEach(Array(availableTypes).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(type.color)
                            
                            Text(type.rawValue)
                            
                            Spacer()
                            
                            if selectedTypes.contains(type) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedTypes.contains(type) {
                                selectedTypes.remove(type)
                            } else {
                                selectedTypes.insert(type)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Select All") {
                        selectedTypes = availableTypes
                    }
                    
                    Button("Deselect All") {
                        selectedTypes.removeAll()
                    }
                }
            }
            .navigationTitle("Filter Elements")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Settings Screen
struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var apiKeyManager: APIKeyManager
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("keepActivityHistory") private var keepActivityHistory = true
    @AppStorage("enableTemplates") private var enableTemplates = true
    @AppStorage("autoBackup") private var autoBackup = false
    @AppStorage("defaultElementType") private var defaultElementType = ElementType.character.rawValue
    @AppStorage("showElementIcons") private var showElementIcons = true
    @AppStorage("compactMode") private var compactMode = false
    @AppStorage("enableMentions") private var enableMentions = true
    
    @State private var showingResetAlert = false
    @State private var showingDataExport = false
    @State private var showingDataImport = false
    @State private var showingAbout = false
    @State private var showingThemeSettings = false
    @State private var showingUpgradeAlert = false
    @State private var showingAPIKeySettings = false
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription Status
                Section("Subscription") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: subscriptionManager.currentTier.icon)
                                    .foregroundColor(subscriptionManager.currentTier.color)
                                Text(subscriptionManager.currentTier.displayName)
                                    .font(.headline)
                            }
                            
                            if subscriptionManager.currentTier == .free {
                                Text("Worlds: \(dataStore.worlds.count)/3")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if let expDate = subscriptionManager.expirationDate {
                                Text("Expires: \(expDate, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if subscriptionManager.currentTier == .free {
                            Button("Upgrade") {
                                showingUpgradeAlert = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // General Settings
                Section("General") {
                    Toggle("Auto-save changes", isOn: $autoSave)
                    Toggle("Show element icons", isOn: $showElementIcons)
                    Toggle("Compact mode", isOn: $compactMode)
                    
                    Picker("Default element type", selection: $defaultElementType) {
                        ForEach(ElementType.allCases, id: \.rawValue) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type.rawValue)
                        }
                    }
                }
                
                // Features
                Section("Features") {
                    Toggle("Enable templates", isOn: $enableTemplates)
                    Toggle("Enable @mentions", isOn: $enableMentions)
                    Toggle("Keep activity history", isOn: $keepActivityHistory)
                }
                
                // Notifications & Backup
                Section("Backup & Sync") {
                    Toggle("Auto backup", isOn: $autoBackup)
                    Toggle("Enable notifications", isOn: $enableNotifications)
                }
                
                // Data Management
                Section("Data Management") {
                    Button("Export All Data") {
                        showingDataExport = true
                    }
                    
                    Button("Import Data") {
                        showingDataImport = true
                    }
                    
                    Button("Clear Activity History") {
                        clearActivityHistory()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Reset All Settings") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                // Statistics
                Section("Statistics") {
                    HStack {
                        Text("Total Worlds")
                        Spacer()
                        Text("\(dataStore.worlds.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Elements")
                        Spacer()
                        Text("\(dataStore.worlds.flatMap { $0.elements }.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Relationships")
                        Spacer()
                        Text("\(dataStore.worlds.flatMap { $0.relationships }.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Recent Activities")
                        Spacer()
                        Text("\(dataStore.recentActivity.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // AI Settings
                Section("AI Providers") {
                    Button("API Keys") {
                        showingAPIKeySettings = true
                    }
                    
                    if let provider = apiKeyManager.selectedProvider,
                       apiKeyManager.hasAPIKey(for: provider) {
                        HStack {
                            Text("Active Provider")
                            Spacer()
                            Label(provider.rawValue, systemImage: provider.icon)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Themes
                Section("Appearance") {
                    Button("Themes") {
                        showingThemeSettings = true
                    }
                }
                
                // About
                Section("About") {
                    Button("About For World Builders") {
                        showingAbout = true
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllSettings()
                }
            } message: {
                Text("This will reset all settings to their default values. This action cannot be undone.")
            }
            .sheet(isPresented: $showingDataExport) {
                DataExportView()
                    .environmentObject(dataStore)
            }
            .sheet(isPresented: $showingDataImport) {
                DataImportView()
                    .environmentObject(dataStore)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingThemeSettings) {
                ThemeSettingsView()
            }
            .sheet(isPresented: $showingUpgradeAlert) {
                UpgradeView()
                    .environmentObject(subscriptionManager)
            }
            .sheet(isPresented: $showingAPIKeySettings) {
                APIKeySettingsView()
                    .environmentObject(apiKeyManager)
            }
        }
    }
    
    private func clearActivityHistory() {
        dataStore.recentActivity.removeAll()
    }
    
    private func resetAllSettings() {
        enableNotifications = true
        autoSave = true
        keepActivityHistory = true
        enableTemplates = true
        autoBackup = false
        defaultElementType = ElementType.character.rawValue
        showElementIcons = true
        compactMode = false
        enableMentions = true
    }
}

// MARK: - Data Export View
struct DataExportView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var exportFormat: ExportFormat = .json
    @State private var includeActivity = true
    @State private var exportInProgress = false
    @State private var showingUpgradeAlert = false
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case text = "Text"
        case markdown = "Markdown"
        case pdf = "PDF"
        case csv = "CSV"
        case xml = "XML"
        
        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .text: return "txt"
            case .markdown: return "md"
            case .pdf: return "pdf"
            case .csv: return "csv"
            case .xml: return "xml"
            }
        }
        
        var description: String {
            switch self {
            case .json: return "Complete data structure with full fidelity"
            case .text: return "Simple human-readable format"
            case .markdown: return "Formatted text with headers and links"
            case .pdf: return "Professional document format"
            case .csv: return "Spreadsheet-compatible data"
            case .xml: return "Structured markup format"
            }
        }
        
        var icon: String {
            switch self {
            case .json: return "doc.text"
            case .text: return "doc.plaintext"
            case .markdown: return "doc.richtext"
            case .pdf: return "doc.fill"
            case .csv: return "tablecells"
            case .xml: return "chevron.left.forwardslash.chevron.right"
            }
        }
        
        var isPremium: Bool {
            switch self {
            case .json, .text: return false
            case .markdown, .pdf, .csv, .xml: return true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        HStack {
                            Image(systemName: format.icon)
                                .foregroundColor(format.isPremium && !subscriptionManager.hasAccess(to: .advancedExports) ? .gray : .blue)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(format.rawValue)
                                        .font(.headline)
                                    
                                    if format.isPremium {
                                        Image(systemName: "crown.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }
                                }
                                
                                Text(format.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if exportFormat == format {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .opacity(format.isPremium && !subscriptionManager.hasAccess(to: .advancedExports) ? 0.6 : 1.0)
                        .onTapGesture {
                            if format.isPremium && !subscriptionManager.hasAccess(to: .advancedExports) {
                                showingUpgradeAlert = true
                            } else {
                                exportFormat = format
                            }
                        }
                    }
                }
                
                Section("Options") {
                    Toggle("Include activity history", isOn: $includeActivity)
                }
                
                Section("Export Data") {
                    Button("Export All Data") {
                        exportAllData()
                    }
                    .disabled(exportInProgress)
                }
            }
            .navigationTitle("Export Data")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingUpgradeAlert) {
                UpgradeView()
                    .environmentObject(subscriptionManager)
            }
        }
    }
    
    private func exportAllData() {
        exportInProgress = true
        
        let exportData = ExportData(
            worlds: dataStore.worlds,
            recentActivity: includeActivity ? dataStore.recentActivity : [],
            exportDate: Date(),
            version: "1.0.0"
        )
        
        switch exportFormat {
        case .json:
            exportAsJSON(exportData)
        case .text:
            exportAsText(exportData)
        case .markdown:
            exportAsMarkdown(exportData)
        case .pdf:
            exportAsPDF(exportData)
        case .csv:
            exportAsCSV(exportData)
        case .xml:
            exportAsXML(exportData)
        }
        
        exportInProgress = false
        dismiss()
    }
    
    private func exportAsJSON(_ data: ExportData) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let jsonData = try? encoder.encode(data) {
            #if os(macOS)
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "ForWorldBuilders_Export_\(Date().ISO8601Format()).json"
            savePanel.message = "Choose where to save your data export"
            
            if savePanel.runModal() == .OK, let url = savePanel.url {
                try? jsonData.write(to: url)
            }
            #endif
        }
    }
    
    private func exportAsText(_ data: ExportData) {
        var textOutput = "For World Builders Export\n"
        textOutput += "========================\n"
        textOutput += "Export Date: \(data.exportDate)\n"
        textOutput += "Version: \(data.version)\n\n"
        
        for world in data.worlds {
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
        
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "ForWorldBuilders_Export_\(Date().ISO8601Format()).txt"
        savePanel.message = "Choose where to save your text export"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? textOutput.write(to: url, atomically: true, encoding: .utf8)
        }
        #endif
    }
    
    private func exportAsMarkdown(_ data: ExportData) {
        var markdown = "# For World Builders Export\n\n"
        markdown += "**Export Date:** \(data.exportDate.formatted())\n"
        markdown += "**Version:** \(data.version)\n\n"
        markdown += "---\n\n"
        
        for world in data.worlds {
            markdown += "## 🌍 \(world.title)\n\n"
            markdown += "**Description:** \(world.desc)\n\n"
            markdown += "**Created:** \(world.created.formatted())\n"
            markdown += "**Last Modified:** \(world.lastModified.formatted())\n"
            markdown += "**Elements:** \(world.elements.count) | **Relationships:** \(world.relationships.count)\n\n"
            
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
                        
                        markdown += "**Created:** \(element.created.formatted()) | **Modified:** \(element.lastModified.formatted())\n\n"
                        markdown += "---\n\n"
                    }
                }
            }
            
            // Relationships
            if !world.relationships.isEmpty {
                markdown += "### 🔗 Relationships\n\n"
                for relationship in world.relationships {
                    if let fromElement = world.elements.first(where: { $0.id == relationship.fromElementId }),
                       let toElement = world.elements.first(where: { $0.id == relationship.toElementId }) {
                        markdown += "- **\(fromElement.title)** → *\(relationship.type.rawValue)* → **\(toElement.title)**"
                        if !relationship.description.isEmpty {
                            markdown += ": \(relationship.description)"
                        }
                        markdown += "\n"
                    }
                }
                markdown += "\n"
            }
            
            markdown += "\n---\n\n"
        }
        
        // Activity History
        if includeActivity && !data.recentActivity.isEmpty {
            markdown += "## 📋 Recent Activity\n\n"
            let sortedActivity = data.recentActivity.sorted { $0.timestamp > $1.timestamp }
            
            for activity in sortedActivity.prefix(50) {
                markdown += "- **\(activity.timestamp.formatted())** - \(activity.type.rawValue)"
                if let elementTitle = activity.elementTitle {
                    markdown += " - \(elementTitle)"
                }
                markdown += " in \(activity.worldTitle)\n"
            }
        }
        
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "md")!]
        savePanel.nameFieldStringValue = "ForWorldBuilders_Export_\(Date().ISO8601Format()).md"
        savePanel.message = "Choose where to save your Markdown export"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? markdown.write(to: url, atomically: true, encoding: .utf8)
        }
        #endif
    }
    
    private func exportAsPDF(_ data: ExportData) {
        // Create formatted text for PDF
        var pdfContent = "For World Builders Export\n"
        pdfContent += "=" + String(repeating: "=", count: 30) + "\n\n"
        pdfContent += "Export Date: \(data.exportDate.formatted())\n"
        pdfContent += "Version: \(data.version)\n\n"
        
        for world in data.worlds {
            pdfContent += "WORLD: \(world.title)\n"
            pdfContent += String(repeating: "-", count: world.title.count + 7) + "\n\n"
            pdfContent += "Description: \(world.desc)\n"
            pdfContent += "Created: \(world.created.formatted())\n"
            pdfContent += "Elements: \(world.elements.count) | Relationships: \(world.relationships.count)\n\n"
            
            // Group elements by type
            let groupedElements = Dictionary(grouping: world.elements) { $0.type }
            
            for elementType in ElementType.allCases {
                if let elements = groupedElements[elementType], !elements.isEmpty {
                    pdfContent += "\(elementType.rawValue.uppercased())S:\n"
                    
                    for element in elements.sorted(by: { $0.title < $1.title }) {
                        pdfContent += "\n  • \(element.title)\n"
                        if !element.content.isEmpty {
                            pdfContent += "    \(element.content.replacingOccurrences(of: "\n", with: "\n    "))\n"
                        }
                        if !element.tags.isEmpty {
                            pdfContent += "    Tags: \(element.tags.joined(separator: ", "))\n"
                        }
                    }
                    pdfContent += "\n"
                }
            }
            
            pdfContent += "\n" + String(repeating: "=", count: 50) + "\n\n"
        }
        
        #if os(macOS)
        // Convert to PDF using NSAttributedString and PDFDocument
        let font = NSFont.systemFont(ofSize: 12)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.textColor
        ]
        
        let attributedString = NSAttributedString(string: pdfContent, attributes: attributes)
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "ForWorldBuilders_Export_\(Date().ISO8601Format()).pdf"
        savePanel.message = "Choose where to save your PDF export"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            // Create PDF data
            let pdfData = NSMutableData()
            let consumer = CGDataConsumer(data: pdfData)!
            let mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
            let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
            
            let textRect = CGRect(x: 50, y: 50, width: 512, height: 692)
            
            pdfContext.beginPDFPage(nil)
            attributedString.draw(in: textRect)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
            
            try? pdfData.write(to: url)
        }
        #endif
    }
    
    private func exportAsCSV(_ data: ExportData) {
        var csvContent = ""
        
        // Header
        csvContent += "World,Element Type,Element Title,Element Content,Tags,Created,Last Modified,Relationships\n"
        
        for world in data.worlds {
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
                let relationshipsColumn = "\"\(relationshipDesc)\""
                
                csvContent += "\(worldTitle),\(elementType),\(elementTitle),\(elementContent),\(tags),\(created),\(modified),\(relationshipsColumn)\n"
            }
        }
        
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "ForWorldBuilders_Export_\(Date().ISO8601Format()).csv"
        savePanel.message = "Choose where to save your CSV export"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? csvContent.write(to: url, atomically: true, encoding: .utf8)
        }
        #endif
    }
    
    private func exportAsXML(_ data: ExportData) {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<ForWorldBuildersExport>\n"
        xml += "  <metadata>\n"
        xml += "    <exportDate>\(data.exportDate.ISO8601Format())</exportDate>\n"
        xml += "    <version>\(data.version)</version>\n"
        xml += "  </metadata>\n"
        xml += "  <worlds>\n"
        
        for world in data.worlds {
            xml += "    <world id=\"\(world.id)\">\n"
            xml += "      <title><![CDATA[\(world.title)]]></title>\n"
            xml += "      <description><![CDATA[\(world.desc)]]></description>\n"
            xml += "      <created>\(world.created.ISO8601Format())</created>\n"
            xml += "      <lastModified>\(world.lastModified.ISO8601Format())</lastModified>\n"
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
                xml += "          <created>\(element.created.ISO8601Format())</created>\n"
                xml += "          <lastModified>\(element.lastModified.ISO8601Format())</lastModified>\n"
                xml += "        </element>\n"
            }
            
            xml += "      </elements>\n"
            xml += "      <relationships>\n"
            
            for relationship in world.relationships {
                xml += "        <relationship id=\"\(relationship.id)\">\n"
                xml += "          <fromElementId>\(relationship.fromElementId)</fromElementId>\n"
                xml += "          <toElementId>\(relationship.toElementId)</toElementId>\n"
                xml += "          <type>\(relationship.type.rawValue)</type>\n"
                xml += "          <description><![CDATA[\(relationship.description)]]></description>\n"
                xml += "          <created>\(relationship.created.ISO8601Format())</created>\n"
                xml += "        </relationship>\n"
            }
            
            xml += "      </relationships>\n"
            xml += "    </world>\n"
        }
        
        xml += "  </worlds>\n"
        
        if includeActivity && !data.recentActivity.isEmpty {
            xml += "  <recentActivity>\n"
            for activity in data.recentActivity {
                xml += "    <activity id=\"\(activity.id)\">\n"
                xml += "      <type>\(activity.type.rawValue)</type>\n"
                xml += "      <worldId>\(activity.worldId)</worldId>\n"
                xml += "      <worldTitle><![CDATA[\(activity.worldTitle)]]></worldTitle>\n"
                if let elementId = activity.elementId {
                    xml += "      <elementId>\(elementId)</elementId>\n"
                }
                if let elementTitle = activity.elementTitle {
                    xml += "      <elementTitle><![CDATA[\(elementTitle)]]></elementTitle>\n"
                }
                if let elementType = activity.elementType {
                    xml += "      <elementType>\(elementType.rawValue)</elementType>\n"
                }
                xml += "      <timestamp>\(activity.timestamp.ISO8601Format())</timestamp>\n"
                xml += "      <details><![CDATA[\(activity.details)]]></details>\n"
                xml += "    </activity>\n"
            }
            xml += "  </recentActivity>\n"
        }
        
        xml += "</ForWorldBuildersExport>\n"
        
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.xml]
        savePanel.nameFieldStringValue = "ForWorldBuilders_Export_\(Date().ISO8601Format()).xml"
        savePanel.message = "Choose where to save your XML export"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? xml.write(to: url, atomically: true, encoding: .utf8)
        }
        #endif
    }
}

// MARK: - Data Import View
struct DataImportView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFilePicker = false
    @State private var importInProgress = false
    @State private var importError: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Import Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Import your previously exported For World Builders data. This will merge with your existing data.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Button("Choose File") {
                    showingFilePicker = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(importInProgress)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import Data")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Import Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(importError ?? "Unknown error occurred")
            }
        }
    }
    
    private func importData(from url: URL) {
        importInProgress = true
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let exportData = try decoder.decode(ExportData.self, from: data)
            
            // Merge worlds
            for importedWorld in exportData.worlds {
                // Check if world with same ID already exists
                if !dataStore.worlds.contains(where: { $0.id == importedWorld.id }) {
                    dataStore.addWorld(importedWorld)
                }
            }
            
            importInProgress = false
            dismiss()
        } catch {
            importError = error.localizedDescription
            showingError = true
            importInProgress = false
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("For World Builders")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Privacy-first worldbuilding for creators")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Create rich, interconnected worlds")
                    Text("• Track characters, locations, and events")
                    Text("• Build relationships between elements")
                    Text("• All data stored locally on your device")
                    Text("• Export and backup your creations")
                }
                .font(.body)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                Text("Made with ❤️ for world builders everywhere")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("About")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Export Data Model
struct ExportData: Codable {
    let worlds: [World]
    let recentActivity: [ActivityItem]
    let exportDate: Date
    let version: String
}

// MARK: - Theme Settings
struct ThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCustomThemeCreator = false
    @State private var showingDeleteAlert = false
    @State private var themeToDelete: AppTheme?
    @State private var showingUpgradeAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Current Theme Preview
                Section("Current Theme") {
                    ThemePreviewCard(theme: themeManager.currentTheme, isSelected: true)
                }
                
                // Built-in Themes
                Section("Built-in Themes") {
                    ForEach(AppTheme.builtInThemes) { theme in
                        ThemePreviewCard(
                            theme: theme,
                            isSelected: theme.id == themeManager.currentTheme.id
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                themeManager.setTheme(theme)
                            }
                        }
                    }
                }
                
                // Custom Themes
                let customThemes = themeManager.availableThemes.filter { theme in
                    !AppTheme.builtInThemes.contains { $0.id == theme.id }
                }
                
                if !customThemes.isEmpty {
                    Section("Custom Themes") {
                        ForEach(customThemes) { theme in
                            ThemePreviewCard(
                                theme: theme,
                                isSelected: theme.id == themeManager.currentTheme.id,
                                canDelete: true
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    themeManager.setTheme(theme)
                                }
                            } onDelete: {
                                themeToDelete = theme
                                showingDeleteAlert = true
                            }
                        }
                    }
                }
                
                // Create Custom Theme
                Section {
                    Button(action: { 
                        if subscriptionManager.hasAccess(to: .customThemes) {
                            showingCustomThemeCreator = true
                        } else {
                            showingUpgradeAlert = true
                        }
                    }) {
                        HStack {
                            Label("Create Custom Theme", systemImage: "plus.circle.fill")
                                .foregroundColor(.blue)
                            
                            if !subscriptionManager.hasAccess(to: .customThemes) {
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Themes")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Theme", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let theme = themeToDelete {
                        themeManager.deleteCustomTheme(theme)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this custom theme? This action cannot be undone.")
            }
            .sheet(isPresented: $showingCustomThemeCreator) {
                CustomThemeCreatorView()
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingUpgradeAlert) {
                UpgradeView()
                    .environmentObject(subscriptionManager)
            }
        }
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let canDelete: Bool
    let onSelect: (() -> Void)?
    let onDelete: (() -> Void)?
    
    init(theme: AppTheme, isSelected: Bool, canDelete: Bool = false, onSelect: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.theme = theme
        self.isSelected = isSelected
        self.canDelete = canDelete
        self.onSelect = onSelect
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Theme Preview
            HStack(spacing: 4) {
                Rectangle()
                    .fill(theme.primaryUIColor)
                    .frame(width: 12, height: 40)
                    .cornerRadius(2)
                
                Rectangle()
                    .fill(theme.accentUIColor)
                    .frame(width: 12, height: 40)
                    .cornerRadius(2)
                
                Rectangle()
                    .fill(theme.surfaceUIColor)
                    .frame(width: 12, height: 40)
                    .cornerRadius(2)
                    .overlay(
                        Rectangle()
                            .stroke(theme.textSecondaryUIColor.opacity(0.3), lineWidth: 0.5)
                            .cornerRadius(2)
                    )
            }
            .padding(8)
            .background(theme.backgroundUIColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.textSecondaryUIColor.opacity(0.2), lineWidth: 0.5)
            )
            
            // Theme Info
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(theme.isDark ? "Dark" : "Light")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Selection Indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            
            // Delete Button
            if canDelete {
                Button(action: { onDelete?() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect?()
        }
    }
}

// MARK: - Custom Theme Creator
struct CustomThemeCreatorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var themeName = ""
    @State private var isDark = false
    @State private var primaryColor = Color.blue
    @State private var secondaryColor = Color.gray
    @State private var accentColor = Color.purple
    @State private var backgroundColor = Color.white
    @State private var surfaceColor = Color.gray.opacity(0.1)
    @State private var textPrimaryColor = Color.black
    @State private var textSecondaryColor = Color.gray
    
    @State private var showingNameError = false
    
    var previewTheme: AppTheme {
        AppTheme(
            name: "custom_\(UUID().uuidString)",
            displayName: themeName.isEmpty ? "Custom Theme" : themeName,
            isDark: isDark,
            primaryColor: primaryColor.toHex() ?? "007AFF",
            secondaryColor: secondaryColor.toHex() ?? "8E8E93",
            accentColor: accentColor.toHex() ?? "AF52DE",
            backgroundColor: backgroundColor.toHex() ?? (isDark ? "000000" : "FFFFFF"),
            surfaceColor: surfaceColor.toHex() ?? (isDark ? "1C1C1E" : "F2F2F7"),
            textPrimaryColor: textPrimaryColor.toHex() ?? (isDark ? "FFFFFF" : "000000"),
            textSecondaryColor: textSecondaryColor.toHex() ?? "8E8E93"
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Theme Preview
                Section("Preview") {
                    ThemePreviewCard(theme: previewTheme, isSelected: false)
                    
                    // Sample UI Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sample World")
                            .font(.headline)
                            .foregroundColor(previewTheme.textPrimaryUIColor)
                        
                        Text("This is how your content will look with this theme.")
                            .font(.body)
                            .foregroundColor(previewTheme.textSecondaryUIColor)
                        
                        HStack {
                            Button("Primary") { }
                                .buttonStyle(.borderedProminent)
                                .tint(previewTheme.primaryUIColor)
                            
                            Button("Accent") { }
                                .buttonStyle(.bordered)
                                .tint(previewTheme.accentUIColor)
                        }
                    }
                    .padding()
                    .background(previewTheme.surfaceUIColor)
                    .cornerRadius(8)
                    .background(previewTheme.backgroundUIColor)
                }
                
                // Theme Details
                Section("Theme Details") {
                    TextField("Theme Name", text: $themeName)
                    
                    Toggle("Dark Theme", isOn: $isDark)
                        .onChange(of: isDark) { _, newValue in
                            // Auto-adjust colors when switching dark/light
                            if newValue {
                                backgroundColor = Color.black
                                surfaceColor = Color.gray.opacity(0.2)
                                textPrimaryColor = Color.white
                                textSecondaryColor = Color.gray
                            } else {
                                backgroundColor = Color.white
                                surfaceColor = Color.gray.opacity(0.1)
                                textPrimaryColor = Color.black
                                textSecondaryColor = Color.gray
                            }
                        }
                }
                
                // Colors
                Section("Colors") {
                    ColorPickerRow(title: "Primary", color: $primaryColor)
                    ColorPickerRow(title: "Secondary", color: $secondaryColor)
                    ColorPickerRow(title: "Accent", color: $accentColor)
                    ColorPickerRow(title: "Background", color: $backgroundColor)
                    ColorPickerRow(title: "Surface", color: $surfaceColor)
                    ColorPickerRow(title: "Text Primary", color: $textPrimaryColor)
                    ColorPickerRow(title: "Text Secondary", color: $textSecondaryColor)
                }
                
                // Actions
                Section {
                    Button("Save Theme") {
                        saveTheme()
                    }
                    .disabled(themeName.isEmpty)
                }
            }
            .navigationTitle("Create Theme")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Theme Name Required", isPresented: $showingNameError) {
                Button("OK") { }
            } message: {
                Text("Please enter a name for your theme.")
            }
        }
    }
    
    private func saveTheme() {
        guard !themeName.isEmpty else {
            showingNameError = true
            return
        }
        
        let theme = AppTheme(
            name: "custom_\(UUID().uuidString)",
            displayName: themeName,
            isDark: isDark,
            primaryColor: primaryColor.toHex() ?? "007AFF",
            secondaryColor: secondaryColor.toHex() ?? "8E8E93",
            accentColor: accentColor.toHex() ?? "AF52DE",
            backgroundColor: backgroundColor.toHex() ?? (isDark ? "000000" : "FFFFFF"),
            surfaceColor: surfaceColor.toHex() ?? (isDark ? "1C1C1E" : "F2F2F7"),
            textPrimaryColor: textPrimaryColor.toHex() ?? (isDark ? "FFFFFF" : "000000"),
            textSecondaryColor: textSecondaryColor.toHex() ?? "8E8E93"
        )
        
        themeManager.addCustomTheme(theme)
        themeManager.setTheme(theme)
        dismiss()
    }
}

struct ColorPickerRow: View {
    let title: String
    @Binding var color: Color
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            ColorPicker("", selection: $color)
                .labelsHidden()
        }
    }
}

// MARK: - Upgrade View
struct UpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedPlan = "yearly"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Upgrade to Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock the full power of world building")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(PremiumFeature.allCases, id: \.self) { feature in
                            HStack(spacing: 12) {
                                Image(systemName: feature.icon)
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feature.rawValue)
                                        .font(.headline)
                                    Text(feature.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Pricing Plans
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Yearly Plan
                        Button(action: { selectedPlan = "yearly" }) {
                            VStack(spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Yearly")
                                            .font(.headline)
                                        Text("Save 25%")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("$29.99/year")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                        Text("~$2.50/month")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(selectedPlan == "yearly" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedPlan == "yearly" ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Monthly Plan
                        Button(action: { selectedPlan = "monthly" }) {
                            VStack(spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Monthly")
                                            .font(.headline)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("$3.99/month")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding()
                                .background(selectedPlan == "monthly" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedPlan == "monthly" ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
                    // Subscribe Button
                    Button(action: {
                        // In a real app, this would initiate the StoreKit purchase
                        subscriptionManager.upgradeToPremium()
                        dismiss()
                    }) {
                        Text(selectedPlan == "yearly" ? "Subscribe for $29.99/year" : "Subscribe for $3.99/month")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Legal Text
                    VStack(spacing: 8) {
                        Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Restore Purchases") {
                            subscriptionManager.restorePurchases()
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - API Key Settings Views
struct APIKeySettingsView: View {
    @EnvironmentObject var apiKeyManager: APIKeyManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var showingEditView = false
    @State private var selectedProvider: AIProvider?
    @State private var showingDeleteConfirmation = false
    @State private var providerToDelete: AIProvider?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Configured Providers")) {
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        HStack {
                            Image(systemName: provider.icon)
                                .frame(width: 30)
                                .foregroundColor(apiKeyManager.hasAPIKey(for: provider) ? .green : .gray)
                            
                            VStack(alignment: .leading) {
                                Text(provider.rawValue)
                                    .font(.headline)
                                if apiKeyManager.hasAPIKey(for: provider) {
                                    Text("API key configured")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    if let model = apiKeyManager.selectedModel[provider] {
                                        Text("Model: \(model)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("No API key")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedProvider = provider
                                showingEditView = true
                            }) {
                                Image(systemName: apiKeyManager.hasAPIKey(for: provider) ? "pencil" : "plus.circle")
                                    .foregroundColor(.blue)
                            }
                            
                            if apiKeyManager.hasAPIKey(for: provider) {
                                Button(action: {
                                    providerToDelete = provider
                                    showingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Active Provider")) {
                    if let activeProvider = apiKeyManager.selectedProvider {
                        HStack {
                            Image(systemName: activeProvider.icon)
                                .foregroundColor(.blue)
                            Text(activeProvider.rawValue)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("No active provider selected")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bring Your Own API Keys")
                            .font(.headline)
                        Text("Configure your own API keys from OpenAI, Anthropic, Google, or Grok to enable AI-powered features.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !subscriptionManager.hasAccess(to: .aiSuggestions) {
                            Label("AI features require Premium subscription", systemImage: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("AI Providers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                if let provider = selectedProvider {
                    APIKeyEditView(provider: provider)
                        .environmentObject(apiKeyManager)
                }
            }
            .alert("Remove API Key", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    if let provider = providerToDelete {
                        apiKeyManager.removeAPIKey(for: provider)
                    }
                }
            } message: {
                Text("Are you sure you want to remove the API key for \(providerToDelete?.rawValue ?? "")?")
            }
        }
    }
}

struct APIKeyEditView: View {
    let provider: AIProvider
    @EnvironmentObject var apiKeyManager: APIKeyManager
    @Environment(\.dismiss) var dismiss
    @State private var apiKey: String = ""
    @State private var selectedModel: String = ""
    @State private var isValidating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Key")) {
                    VStack(alignment: .leading) {
                        Text("Enter your \(provider.rawValue) API key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("API Key", text: $apiKey)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !apiKey.isEmpty {
                            HStack {
                                Image(systemName: apiKeyManager.validateAPIKey(apiKey, for: provider) ? "checkmark.circle" : "xmark.circle")
                                    .foregroundColor(apiKeyManager.validateAPIKey(apiKey, for: provider) ? .green : .red)
                                Text(apiKeyManager.validateAPIKey(apiKey, for: provider) ? "Valid format" : "Invalid format")
                                    .font(.caption)
                                    .foregroundColor(apiKeyManager.validateAPIKey(apiKey, for: provider) ? .green : .red)
                            }
                        }
                    }
                }
                
                Section(header: Text("Model Selection")) {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(provider.modelOptions, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Provider Information")) {
                    HStack {
                        Text("Base URL")
                        Spacer()
                        Text(provider.baseURL)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Key Prefix")
                        Spacer()
                        Text(provider.keyPrefix + "...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Link("Get API Key from \(provider.rawValue)", destination: URL(string: getProviderSignupURL())!)
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle(provider.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty || !apiKeyManager.validateAPIKey(apiKey, for: provider))
                }
            }
            .onAppear {
                if let existingKey = apiKeyManager.apiKeys[provider] {
                    apiKey = existingKey
                }
                if let existingModel = apiKeyManager.selectedModel[provider] {
                    selectedModel = existingModel
                } else {
                    selectedModel = provider.modelOptions.first ?? ""
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func getProviderSignupURL() -> String {
        switch provider {
        case .openai:
            return "https://platform.openai.com/api-keys"
        case .anthropic:
            return "https://console.anthropic.com/settings/keys"
        case .google:
            return "https://makersuite.google.com/app/apikey"
        case .grok:
            return "https://console.x.ai/"
        }
    }
    
    private func saveAPIKey() {
        guard apiKeyManager.validateAPIKey(apiKey, for: provider) else {
            errorMessage = "Invalid API key format"
            showingError = true
            return
        }
        
        apiKeyManager.setAPIKey(apiKey, for: provider)
        apiKeyManager.selectedModel[provider] = selectedModel
        
        // Set as active provider if it's the first one
        if apiKeyManager.selectedProvider == nil {
            apiKeyManager.selectedProvider = provider
        }
        
        dismiss()
    }
}