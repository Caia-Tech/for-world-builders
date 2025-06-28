//
//  AddElementView.swift
//  forworldbuilders-apple-client
//
//  Created on 6/11/25.
//

import SwiftUI
import CoreData

struct AddElementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let world: World
    @State private var selectedType: ElementType
    @State private var title = ""
    @State private var content = ""
    @State private var tags = ""
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title
        case content
        case tags
    }
    
    init(world: World, preselectedType: ElementType = .character) {
        self.world = world
        _selectedType = State(initialValue: preselectedType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Element Type Selection
                Section {
                    Picker("Element Type", selection: $selectedType) {
                        ForEach(ElementType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Type")
                } footer: {
                    Text("Choose the type of element you're creating")
                }
                
                // Basic Information
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Title", systemImage: "textformat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter \(selectedType.rawValue.lowercased()) name", text: $title)
                            .font(.body)
                            .focused($focusedField, equals: .title)
                            .onSubmit {
                                focusedField = .content
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $content)
                            .font(.body)
                            .frame(minHeight: 100)
                            .focused($focusedField, equals: .content)
                            .overlay(
                                Group {
                                    if content.isEmpty {
                                        Text("Add details about this \(selectedType.rawValue.lowercased())...")
                                            .foregroundColor(.secondary.opacity(0.5))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 8)
                                            .allowsHitTesting(false)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    }
                                }
                            )
                    }
                } header: {
                    Text("Details")
                }
                
                // Tags
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tags", systemImage: "tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter tags separated by commas", text: $tags)
                            .font(.body)
                            .focused($focusedField, equals: .tags)
                            .onSubmit {
                                createElement()
                            }
                    }
                    
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(parsedTags, id: \.self) { tag in
                                    TagPreview(tag: tag)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Organization")
                } footer: {
                    Text("Tags help you organize and find related elements")
                }
                
                // Quick Tips
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.yellow)
                            Text("Quick Tips for \(selectedType.rawValue)s")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(tipsForType(selectedType), id: \.self) { tip in
                                BulletPoint(text: tip)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New \(selectedType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createElement()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                focusedField = .title
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK") {
                    focusedField = .title
                }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private var parsedTags: [String] {
        tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func createElement() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Please enter a title for your \(selectedType.rawValue.lowercased())."
            showingValidationAlert = true
            return
        }
        
        // Create element
        let _ = WorldElement.create(
            in: viewContext,
            world: world,
            type: selectedType.rawValue,
            title: trimmedTitle,
            content: trimmedContent,
            tags: parsedTags
        )
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            validationMessage = "Failed to create element. Please try again."
            showingValidationAlert = true
        }
    }
    
    private func tipsForType(_ type: ElementType) -> [String] {
        switch type {
        case .character:
            return [
                "Include personality traits and motivations",
                "Note important relationships with other characters",
                "Add physical descriptions if relevant",
                "Consider their role in your world's story"
            ]
        case .location:
            return [
                "Describe the atmosphere and mood",
                "Note important features or landmarks",
                "Consider who lives or works there",
                "Think about its history and significance"
            ]
        case .item:
            return [
                "Describe its appearance and properties",
                "Note who owns or uses it",
                "Consider its origin and creation",
                "Think about its importance to the story"
            ]
        case .event:
            return [
                "Include when and where it occurs",
                "Note who is involved or affected",
                "Describe the cause and consequences",
                "Consider its impact on your world"
            ]
        case .concept:
            return [
                "Explain the core idea clearly",
                "Note how it affects your world",
                "Consider related concepts or systems",
                "Think about who knows or uses it"
            ]
        case .organization:
            return [
                "Describe its purpose and goals",
                "Note key members or leaders",
                "Include structure and hierarchy",
                "Consider its influence and reach"
            ]
        case .general:
            return [
                "Use for anything that doesn't fit other categories",
                "Be descriptive in your title",
                "Consider adding relevant tags",
                "Link to related elements when possible"
            ]
        }
    }
}

struct TagPreview: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(12)
    }
}

// MARK: - Preview
struct AddElementView_Previews: PreviewProvider {
    static var previews: some View {
        AddElementView(world: World())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}