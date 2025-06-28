//
//  WorldDetailView.swift
//  forworldbuilders-apple-client
//
//  Created on 6/11/25.
//

import SwiftUI
import CoreData

struct WorldDetailView: View {
    @ObservedObject var world: World
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab: ElementType = .character
    @State private var searchText = ""
    @State private var showingAddElement = false
    @State private var showingWorldSettings = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Tab Selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(ElementType.allCases, id: \.self) { elementType in
                            TabButton(
                                elementType: elementType,
                                isSelected: selectedTab == elementType,
                                count: getElementCount(for: elementType)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = elementType
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Content
                ElementListView(
                    world: world,
                    elementType: selectedTab,
                    searchText: searchText
                )
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingAddElement = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(world.wrappedTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingWorldSettings = true
                }) {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddElement) {
            AddElementView(world: world, preselectedType: selectedTab)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingWorldSettings) {
            WorldSettingsView(world: world)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func getElementCount(for type: ElementType) -> Int {
        world.elementsArray.filter { $0.wrappedType == type.rawValue }.count
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search elements...", text: $text)
                    .onTapGesture {
                        withAnimation {
                            isEditing = true
                        }
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            
            if isEditing {
                Button("Cancel") {
                    withAnimation {
                        isEditing = false
                        text = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let elementType: ElementType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: elementType.iconName)
                        .font(.caption)
                    
                    Text(elementType.rawValue)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isSelected ? Color.white.opacity(0.2) : Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                )
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(height: 3)
                        .frame(maxWidth: 40)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Element List View
struct ElementListView: View {
    @ObservedObject var world: World
    let elementType: ElementType
    let searchText: String
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var elementToDelete: WorldElement?
    @State private var showingDeleteAlert = false
    
    var filteredElements: [WorldElement] {
        world.elementsArray.filter { element in
            element.wrappedType == elementType.rawValue &&
            (searchText.isEmpty || element.wrappedTitle.localizedCaseInsensitiveContains(searchText) ||
             element.wrappedContent.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        Group {
            if filteredElements.isEmpty {
                EmptyElementView(elementType: elementType, hasSearch: !searchText.isEmpty)
            } else {
                List {
                    ForEach(filteredElements, id: \.wrappedId) { element in
                        NavigationLink(destination: ElementDetailView(element: element)) {
                            ElementRowView(element: element)
                        }
                    }
                    .onDelete(perform: deleteElements)
                }
                .listStyle(PlainListStyle())
            }
        }
        .alert("Delete Element?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let element = elementToDelete {
                    deleteElement(element)
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(elementToDelete?.wrappedTitle ?? "this element")\"? This action cannot be undone.")
        }
    }
    
    private func deleteElements(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredElements[$0] }.forEach { element in
                elementToDelete = element
                showingDeleteAlert = true
            }
        }
    }
    
    private func deleteElement(_ element: WorldElement) {
        withAnimation {
            viewContext.delete(element)
            world.updateModificationDate()
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting element: \(error)")
            }
        }
    }
}

// MARK: - Element Row View
struct ElementRowView: View {
    @ObservedObject var element: WorldElement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(element.wrappedTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if !element.wrappedTags.isEmpty {
                    Image(systemName: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !element.wrappedContent.isEmpty {
                Text(element.wrappedContent)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if !element.wrappedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(element.wrappedTags, id: \.self) { tag in
                            TagView(tag: tag)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tag View
struct TagView: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(8)
    }
}

// MARK: - Empty Element View
struct EmptyElementView: View {
    let elementType: ElementType
    let hasSearch: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: hasSearch ? "magnifyingglass" : elementType.iconName)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(hasSearch ? "No Results" : "No \(elementType.rawValue)s Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(hasSearch ? "Try adjusting your search" : "Add your first \(elementType.rawValue.lowercased())")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Placeholder Views (to be implemented)
struct WorldSettingsView: View {
    let world: World
    
    var body: some View {
        Text("World Settings - To be implemented")
    }
}

struct ElementDetailView: View {
    let element: WorldElement
    
    var body: some View {
        Text("Element Detail View - To be implemented")
            .navigationTitle(element.wrappedTitle)
    }
}

// MARK: - Preview
struct WorldDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorldDetailView(world: World())
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}