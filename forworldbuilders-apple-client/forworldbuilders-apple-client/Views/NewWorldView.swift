//
//  NewWorldView.swift
//  forworldbuilders-apple-client
//
//  Created on 6/11/25.
//

import SwiftUI
import CoreData

struct NewWorldView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var description = ""
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title
        case description
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("World Title", systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter world name", text: $title)
                            .font(.title3)
                            .focused($focusedField, equals: .title)
                            .onSubmit {
                                focusedField = .description
                            }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $description)
                            .font(.body)
                            .frame(minHeight: 100)
                            .focused($focusedField, equals: .description)
                            .overlay(
                                Group {
                                    if description.isEmpty {
                                        Text("Describe your world's setting, theme, or story...")
                                            .foregroundColor(.secondary.opacity(0.5))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 8)
                                            .allowsHitTesting(false)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    }
                                }
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("World Details")
                } footer: {
                    Text("Give your world a memorable name and description to help you organize your creative universe.")
                        .font(.caption)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("Tips for World Building")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Start with a clear concept or theme")
                            BulletPoint(text: "Consider the scope - planet, galaxy, or multiverse?")
                            BulletPoint(text: "Think about the rules that govern your world")
                            BulletPoint(text: "Don't worry about having everything figured out yet!")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Create New World")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createWorld()
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
    
    private func createWorld() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Please enter a title for your world."
            showingValidationAlert = true
            return
        }
        
        guard trimmedTitle.count <= 100 else {
            validationMessage = "World title must be 100 characters or less."
            showingValidationAlert = true
            return
        }
        
        // Create the world
        let _ = World.create(in: viewContext, title: trimmedTitle, description: trimmedDescription)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            validationMessage = "Failed to create world. Please try again."
            showingValidationAlert = true
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview
struct NewWorldView_Previews: PreviewProvider {
    static var previews: some View {
        NewWorldView(isPresented: .constant(true))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}