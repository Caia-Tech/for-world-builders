//
//  forworldbuilders_apple_clientApp.swift
//  forworldbuilders-apple-client
//
//  Created by Owner on 6/11/25.
//

import SwiftUI
import Combine
import StoreKit
import CryptoKit

// MARK: - AI Provider Management
enum AIProvider: String, CaseIterable, Codable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case google = "Google (Gemini)"
    case grok = "Grok (X.AI)"
    
    var icon: String {
        switch self {
        case .openai: return "brain"
        case .anthropic: return "person.crop.circle"
        case .google: return "sparkle"
        case .grok: return "x.circle"
        }
    }
    
    var baseURL: String {
        switch self {
        case .openai: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .google: return "https://generativelanguage.googleapis.com/v1"
        case .grok: return "https://api.x.ai/v1"
        }
    }
    
    var keyPrefix: String {
        switch self {
        case .openai: return "sk-"
        case .anthropic: return "sk-ant-"
        case .google: return "AIza"
        case .grok: return "xai-"
        }
    }
    
    var modelOptions: [String] {
        switch self {
        case .openai: return ["gpt-4-turbo-preview", "gpt-4", "gpt-3.5-turbo"]
        case .anthropic: return ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"]
        case .google: return ["gemini-pro", "gemini-pro-vision"]
        case .grok: return ["grok-1", "grok-1.5"]
        }
    }
}

class APIKeyManager: ObservableObject {
    @Published var apiKeys: [AIProvider: String] = [:]
    @Published var selectedProvider: AIProvider?
    @Published var selectedModel: [AIProvider: String] = [:]
    
    private let keychain = KeychainManager()
    private let keychainPrefix = "ForWorldBuilders_APIKey_"
    
    static let shared = APIKeyManager()
    
    init() {
        loadAPIKeys()
    }
    
    func setAPIKey(_ key: String, for provider: AIProvider) {
        apiKeys[provider] = key
        saveAPIKey(key, for: provider)
    }
    
    func removeAPIKey(for provider: AIProvider) {
        apiKeys.removeValue(forKey: provider)
        deleteAPIKey(for: provider)
    }
    
    func hasAPIKey(for provider: AIProvider) -> Bool {
        return apiKeys[provider] != nil && !apiKeys[provider]!.isEmpty
    }
    
    func validateAPIKey(_ key: String, for provider: AIProvider) -> Bool {
        // Basic validation - check prefix and length
        if !key.hasPrefix(provider.keyPrefix) {
            return false
        }
        
        // Provider-specific validation
        switch provider {
        case .openai:
            return key.count > 20
        case .anthropic:
            return key.count > 30
        case .google:
            return key.count == 39
        case .grok:
            return key.count > 20
        }
    }
    
    private func saveAPIKey(_ key: String, for provider: AIProvider) {
        let keychainKey = keychainPrefix + provider.rawValue
        keychain.save(key, for: keychainKey)
        
        // Also save selected model
        if let model = selectedModel[provider] {
            UserDefaults.standard.set(model, forKey: "SelectedModel_\(provider.rawValue)")
        }
    }
    
    private func loadAPIKeys() {
        for provider in AIProvider.allCases {
            let keychainKey = keychainPrefix + provider.rawValue
            if let key = keychain.load(for: keychainKey) {
                apiKeys[provider] = key
            }
            
            // Load selected model
            if let model = UserDefaults.standard.string(forKey: "SelectedModel_\(provider.rawValue)") {
                selectedModel[provider] = model
            }
        }
        
        // Set default selected provider if any has a key
        if selectedProvider == nil {
            selectedProvider = AIProvider.allCases.first { hasAPIKey(for: $0) }
        }
    }
    
    private func deleteAPIKey(for provider: AIProvider) {
        let keychainKey = keychainPrefix + provider.rawValue
        keychain.delete(for: keychainKey)
        UserDefaults.standard.removeObject(forKey: "SelectedModel_\(provider.rawValue)")
    }
}

// Simple Keychain wrapper for secure storage
class KeychainManager {
    func save(_ value: String, for key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary) // Delete existing item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func load(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        
        return nil
    }
    
    func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Subscription Management
enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "Free"
    case premium = "Premium"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
    
    var icon: String {
        switch self {
        case .free: return "person"
        case .premium: return "crown.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .free: return .gray
        case .premium: return .yellow
        }
    }
}

enum PremiumFeature: String, CaseIterable {
    case unlimitedWorlds = "Unlimited Worlds"
    case advancedExports = "Advanced Export Formats"
    case customThemes = "Custom Themes"
    case aiSuggestions = "AI-Powered Suggestions"
    case collaborativeEditing = "Collaborative Editing"
    case cloudSync = "Cloud Sync & Backup"
    case relationshipGraph = "Visual Relationship Graph"
    case advancedSearch = "Advanced Search & Filters"
    case prioritySupport = "Priority Support"
    case elementTemplates = "Premium Element Templates"
    
    var description: String {
        switch self {
        case .unlimitedWorlds: return "Create unlimited worlds (Free: 3 worlds)"
        case .advancedExports: return "Export to PDF, XML, and CSV formats"
        case .customThemes: return "Create and save custom color themes"
        case .aiSuggestions: return "Get AI-powered content suggestions"
        case .collaborativeEditing: return "Share and collaborate on worlds"
        case .cloudSync: return "Sync across all your devices"
        case .relationshipGraph: return "Visualize element connections"
        case .advancedSearch: return "Search with advanced filters"
        case .prioritySupport: return "Get help faster"
        case .elementTemplates: return "Access premium templates"
        }
    }
    
    var icon: String {
        switch self {
        case .unlimitedWorlds: return "infinity"
        case .advancedExports: return "doc.badge.arrow.up.fill"
        case .customThemes: return "paintbrush.fill"
        case .aiSuggestions: return "sparkles"
        case .collaborativeEditing: return "person.2.fill"
        case .cloudSync: return "icloud.fill"
        case .relationshipGraph: return "point.3.connected.trianglepath.dotted"
        case .advancedSearch: return "magnifyingglass.circle.fill"
        case .prioritySupport: return "star.fill"
        case .elementTemplates: return "doc.text.fill"
        }
    }
}

class SubscriptionManager: ObservableObject {
    @Published var currentTier: SubscriptionTier = .free
    @Published var isSubscribed: Bool = false
    @Published var expirationDate: Date?
    
    private let subscriptionKey = "ForWorldBuildersSubscription"
    private let worldLimitFree = 3
    
    static let shared = SubscriptionManager()
    
    init() {
        loadSubscriptionStatus()
    }
    
    func hasAccess(to feature: PremiumFeature) -> Bool {
        return currentTier == .premium
    }
    
    func canCreateMoreWorlds(currentCount: Int) -> Bool {
        if currentTier == .premium {
            return true
        }
        return currentCount < worldLimitFree
    }
    
    func getRemainingWorldsCount(currentCount: Int) -> Int? {
        if currentTier == .premium {
            return nil // Unlimited
        }
        return max(0, worldLimitFree - currentCount)
    }
    
    func upgradeToPremium() {
        // This would integrate with StoreKit for actual purchases
        // For now, we'll simulate the upgrade
        currentTier = .premium
        isSubscribed = true
        expirationDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year
        saveSubscriptionStatus()
    }
    
    func restorePurchases() {
        // This would restore purchases from StoreKit
        // For now, check saved status
        loadSubscriptionStatus()
    }
    
    private func saveSubscriptionStatus() {
        let status = SubscriptionStatus(
            tier: currentTier,
            isSubscribed: isSubscribed,
            expirationDate: expirationDate
        )
        
        if let encoded = try? JSONEncoder().encode(status) {
            UserDefaults.standard.set(encoded, forKey: subscriptionKey)
        }
    }
    
    private func loadSubscriptionStatus() {
        if let data = UserDefaults.standard.data(forKey: subscriptionKey),
           let status = try? JSONDecoder().decode(SubscriptionStatus.self, from: data) {
            currentTier = status.tier
            isSubscribed = status.isSubscribed
            expirationDate = status.expirationDate
            
            // Check if subscription expired
            if let expDate = expirationDate, expDate < Date() {
                currentTier = .free
                isSubscribed = false
                expirationDate = nil
                saveSubscriptionStatus()
            }
        }
    }
    
    struct SubscriptionStatus: Codable {
        let tier: SubscriptionTier
        let isSubscribed: Bool
        let expirationDate: Date?
    }
}

// MARK: - Models
enum ElementType: String, CaseIterable, Codable {
    case character = "Character"
    case location = "Location"
    case event = "Event"
    case culture = "Culture"
    case language = "Language"
    case timeline = "Timeline"
    case plot = "Plot"
    case organization = "Organization"
    case item = "Item"
    case concept = "Concept"
    
    var icon: String {
        switch self {
        case .character: return "person.fill"
        case .location: return "map.fill"
        case .event: return "calendar"
        case .culture: return "globe.americas.fill"
        case .language: return "text.bubble.fill"
        case .timeline: return "clock.fill"
        case .plot: return "book.fill"
        case .organization: return "building.2.fill"
        case .item: return "cube.fill"
        case .concept: return "lightbulb.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .character: return .blue
        case .location: return .green
        case .event: return .orange
        case .culture: return .purple
        case .language: return .pink
        case .timeline: return .red
        case .plot: return .indigo
        case .organization: return .brown
        case .item: return .yellow
        case .concept: return .teal
        }
    }
}

enum RelationshipType: String, CaseIterable, Codable {
    case relatedTo = "Related To"
    case childOf = "Child Of"
    case parentOf = "Parent Of"
    case locatedIn = "Located In"
    case memberOf = "Member Of"
    case ownedBy = "Owned By"
    case enemyOf = "Enemy Of"
    case allyOf = "Ally Of"
    case createdBy = "Created By"
    case connectedTo = "Connected To"
    
    var icon: String {
        switch self {
        case .relatedTo: return "link"
        case .childOf: return "arrow.up"
        case .parentOf: return "arrow.down"
        case .locatedIn: return "mappin"
        case .memberOf: return "person.3"
        case .ownedBy: return "person.crop.circle"
        case .enemyOf: return "xmark.shield"
        case .allyOf: return "checkmark.shield"
        case .createdBy: return "hammer"
        case .connectedTo: return "point.3.connected.trianglepath.dotted"
        }
    }
}

struct ElementRelationship: Identifiable, Codable {
    let id: UUID
    let fromElementId: UUID
    let toElementId: UUID
    let type: RelationshipType
    var description: String
    var created: Date
    
    init(fromElementId: UUID, toElementId: UUID, type: RelationshipType, description: String = "") {
        self.id = UUID()
        self.fromElementId = fromElementId
        self.toElementId = toElementId
        self.type = type
        self.description = description
        self.created = Date()
    }
}

struct ElementMention: Identifiable, Codable, Hashable {
    let id: UUID
    let elementId: UUID
    let elementTitle: String
    let startIndex: Int
    let length: Int
    
    init(elementId: UUID, elementTitle: String, startIndex: Int, length: Int) {
        self.id = UUID()
        self.elementId = elementId
        self.elementTitle = elementTitle
        self.startIndex = startIndex
        self.length = length
    }
    
    var range: NSRange {
        NSRange(location: startIndex, length: length)
    }
}

struct ActivityItem: Identifiable, Codable {
    let id: UUID
    let type: ActivityType
    let worldId: UUID
    let worldTitle: String
    let elementId: UUID?
    let elementTitle: String?
    let elementType: ElementType?
    let relationshipId: UUID?
    let timestamp: Date
    let details: String
    
    init(type: ActivityType, worldId: UUID, worldTitle: String, elementId: UUID? = nil, elementTitle: String? = nil, elementType: ElementType? = nil, relationshipId: UUID? = nil, details: String = "") {
        self.id = UUID()
        self.type = type
        self.worldId = worldId
        self.worldTitle = worldTitle
        self.elementId = elementId
        self.elementTitle = elementTitle
        self.elementType = elementType
        self.relationshipId = relationshipId
        self.timestamp = Date()
        self.details = details
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case worldCreated = "World Created"
    case worldModified = "World Modified"
    case elementCreated = "Element Created"
    case elementModified = "Element Modified"
    case elementDeleted = "Element Deleted"
    case relationshipCreated = "Relationship Created"
    case relationshipDeleted = "Relationship Deleted"
    
    var icon: String {
        switch self {
        case .worldCreated: return "globe.americas.fill"
        case .worldModified: return "pencil.circle"
        case .elementCreated: return "plus.circle"
        case .elementModified: return "pencil.circle.fill"
        case .elementDeleted: return "trash.circle"
        case .relationshipCreated: return "link.circle"
        case .relationshipDeleted: return "link.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .worldCreated: return .blue
        case .worldModified: return .orange
        case .elementCreated: return .green
        case .elementModified: return .yellow
        case .elementDeleted: return .red
        case .relationshipCreated: return .purple
        case .relationshipDeleted: return .pink
        }
    }
}

struct ElementTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: ElementType
    let description: String
    let contentTemplate: String
    let suggestedTags: [String]
    
    init(name: String, type: ElementType, description: String, contentTemplate: String, suggestedTags: [String] = []) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.description = description
        self.contentTemplate = contentTemplate
        self.suggestedTags = suggestedTags
    }
    
    static let builtInTemplates: [ElementTemplate] = [
        // Character templates
        ElementTemplate(
            name: "Protagonist",
            type: .character,
            description: "Main character template",
            contentTemplate: "Name: [Character Name]\n\nAge: [Age]\n\nAppearance: [Physical description]\n\nPersonality: [Key traits]\n\nBackground: [History and origin]\n\nGoals: [What they want to achieve]\n\nFears: [What they're afraid of]\n\nSkills: [Abilities and talents]",
            suggestedTags: ["protagonist", "main character", "hero"]
        ),
        ElementTemplate(
            name: "Antagonist",
            type: .character,
            description: "Opposition character template",
            contentTemplate: "Name: [Character Name]\n\nMotivation: [Why they oppose the protagonist]\n\nMethods: [How they achieve their goals]\n\nWeaknesses: [Flaws and vulnerabilities]\n\nBackground: [What made them this way]\n\nResources: [What they have at their disposal]",
            suggestedTags: ["antagonist", "villain", "opposition"]
        ),
        
        // Location templates
        ElementTemplate(
            name: "Fantasy City",
            type: .location,
            description: "Medieval fantasy city template",
            contentTemplate: "Name: [City Name]\n\nPopulation: [Number of inhabitants]\n\nGovernment: [Ruling system]\n\nEconomy: [Main trade and resources]\n\nDistricts:\n- Market Quarter: [Description]\n- Noble District: [Description]\n- Craftsman Ward: [Description]\n\nNotable Features: [Landmarks and points of interest]\n\nDefenses: [Walls, guards, magical protections]",
            suggestedTags: ["city", "fantasy", "settlement"]
        ),
        ElementTemplate(
            name: "Mystical Forest",
            type: .location,
            description: "Enchanted woodland template",
            contentTemplate: "Name: [Forest Name]\n\nSize: [Area coverage]\n\nClimate: [Weather patterns]\n\nFlora: [Unique plants and trees]\n\nFauna: [Creatures that inhabit it]\n\nMagical Properties: [Supernatural aspects]\n\nDangers: [Threats and hazards]\n\nSecrets: [Hidden locations or mysteries]",
            suggestedTags: ["forest", "mystical", "nature", "magic"]
        ),
        
        // Organization templates
        ElementTemplate(
            name: "Secret Society",
            type: .organization,
            description: "Clandestine group template",
            contentTemplate: "Name: [Organization Name]\n\nPurpose: [Goals and objectives]\n\nMembership: [Who can join and how]\n\nStructure: [Hierarchy and ranks]\n\nMethods: [How they operate]\n\nSecrets: [What they're hiding]\n\nInfluence: [Reach and power]\n\nRivals: [Opposing groups]",
            suggestedTags: ["secret", "society", "organization", "conspiracy"]
        ),
        
        // Culture templates
        ElementTemplate(
            name: "Warrior Culture",
            type: .culture,
            description: "Honor-based society template",
            contentTemplate: "Name: [Culture Name]\n\nCore Values: [Honor, courage, strength]\n\nSocial Structure: [Classes and hierarchy]\n\nRites of Passage: [Coming of age ceremonies]\n\nWarrior Code: [Rules and principles]\n\nWeapons & Combat: [Preferred fighting styles]\n\nTraditions: [Festivals and customs]\n\nBeliefs: [Religion and mythology]",
            suggestedTags: ["warrior", "honor", "military", "tradition"]
        ),
        
        // Item templates
        ElementTemplate(
            name: "Legendary Weapon",
            type: .item,
            description: "Powerful artifact template",
            contentTemplate: "Name: [Weapon Name]\n\nType: [Sword, staff, bow, etc.]\n\nAppearance: [Physical description]\n\nPowers: [Magical abilities]\n\nHistory: [Origin and previous owners]\n\nRequirements: [Who can wield it]\n\nLimitations: [Drawbacks or costs]\n\nLocation: [Where it can be found]",
            suggestedTags: ["legendary", "weapon", "artifact", "magic"]
        ),
        
        // Event templates
        ElementTemplate(
            name: "Major Battle",
            type: .event,
            description: "Large-scale conflict template",
            contentTemplate: "Name: [Battle Name]\n\nDate: [When it occurred]\n\nLocation: [Where it took place]\n\nParticipants: [Factions involved]\n\nCause: [Why the battle started]\n\nCourse of Events: [How the battle unfolded]\n\nOutcome: [Who won and consequences]\n\nCasualties: [Losses on each side]\n\nSignificance: [Long-term impact]",
            suggestedTags: ["battle", "war", "conflict", "historical"]
        ),
        ElementTemplate(
            name: "Religious Festival",
            type: .event,
            description: "Spiritual celebration template",
            contentTemplate: "Name: [Festival Name]\n\nDate: [When it occurs]\n\nDuration: [How long it lasts]\n\nLocation: [Where it's celebrated]\n\nPurpose: [Religious significance]\n\nTraditions: [Customs and rituals]\n\nParticipants: [Who takes part]\n\nFood & Drink: [Special meals]\n\nActivities: [What people do]",
            suggestedTags: ["festival", "religion", "celebration", "tradition"]
        ),
        
        // Language templates
        ElementTemplate(
            name: "Ancient Language",
            type: .language,
            description: "Dead or forgotten language template",
            contentTemplate: "Name: [Language Name]\n\nOrigin: [Who created/spoke it]\n\nScript: [Writing system]\n\nPhonology: [Sound system]\n\nGrammar: [Basic structure]\n\nVocabulary: [Key words and phrases]\n\nUsage: [Where it's still found]\n\nRelated Languages: [Linguistic family]\n\nCultural Significance: [Importance to world]",
            suggestedTags: ["ancient", "dead language", "script", "linguistics"]
        ),
        ElementTemplate(
            name: "Trade Tongue",
            type: .language,
            description: "Common commercial language template",
            contentTemplate: "Name: [Language Name]\n\nRegion: [Where it's used]\n\nSpeakers: [Who uses it]\n\nOrigin: [How it developed]\n\nVocabulary: [Commercial terms]\n\nSimplifications: [Grammatical shortcuts]\n\nWriting: [Written form if any]\n\nVariations: [Regional differences]\n\nStatus: [Official recognition]",
            suggestedTags: ["trade", "common", "commercial", "pidgin"]
        ),
        
        // Timeline templates
        ElementTemplate(
            name: "Dynasty Timeline",
            type: .timeline,
            description: "Royal lineage chronology template",
            contentTemplate: "Dynasty: [Dynasty Name]\n\nFounder: [First ruler]\n\nEstablished: [Starting date]\n\nCapital: [Seat of power]\n\n[Ruler 1]: [Reign dates] - [Major events]\n[Ruler 2]: [Reign dates] - [Major events]\n[Ruler 3]: [Reign dates] - [Major events]\n\nEnd: [How dynasty ended]\n\nLegacy: [Lasting impact]",
            suggestedTags: ["dynasty", "royalty", "chronology", "rulers"]
        ),
        ElementTemplate(
            name: "War Timeline",
            type: .timeline,
            description: "Conflict chronology template",
            contentTemplate: "Conflict: [War Name]\n\nCause: [Why it started]\n\nDuration: [Start - End dates]\n\n[Year 1]: [Major events]\n[Year 2]: [Major events]\n[Year 3]: [Major events]\n\nTurning Point: [When tide changed]\n\nConclusion: [How it ended]\n\nAftermath: [Consequences]\n\nCasualties: [Human cost]",
            suggestedTags: ["war", "conflict", "chronology", "military"]
        ),
        
        // Plot templates
        ElementTemplate(
            name: "Hero's Journey",
            type: .plot,
            description: "Classic adventure story structure",
            contentTemplate: "Hero: [Protagonist name]\n\nOrdinary World: [Starting situation]\n\nCall to Adventure: [Inciting incident]\n\nRefusal: [Initial hesitation]\n\nMentor: [Guide figure]\n\nCrossing Threshold: [Point of no return]\n\nTests & Allies: [Challenges faced]\n\nOrdeal: [Greatest challenge]\n\nReward: [What's gained]\n\nReturn: [Journey home]\n\nTransformation: [How hero changed]",
            suggestedTags: ["hero's journey", "adventure", "quest", "structure"]
        ),
        ElementTemplate(
            name: "Mystery Plot",
            type: .plot,
            description: "Investigation story structure",
            contentTemplate: "Mystery: [Central question]\n\nDetective: [Investigator]\n\nCrime/Problem: [What happened]\n\nClues: [Evidence discovered]\n\nSuspects: [Potential culprits]\n\nRed Herrings: [False leads]\n\nRevelation: [Truth discovered]\n\nExplanation: [How it's solved]\n\nResolution: [Aftermath]",
            suggestedTags: ["mystery", "investigation", "detective", "crime"]
        ),
        
        // Concept templates
        ElementTemplate(
            name: "Magic System",
            type: .concept,
            description: "Supernatural power framework",
            contentTemplate: "Name: [Magic System Name]\n\nSource: [Where power comes from]\n\nUsers: [Who can use it]\n\nMethods: [How it's practiced]\n\nLimitations: [What restricts it]\n\nCosts: [Price of using magic]\n\nEffects: [What it can do]\n\nTaboos: [Forbidden practices]\n\nHistory: [How it developed]\n\nSocial Impact: [Effect on society]",
            suggestedTags: ["magic", "supernatural", "system", "power"]
        ),
        ElementTemplate(
            name: "Philosophical Concept",
            type: .concept,
            description: "Abstract idea or belief system",
            contentTemplate: "Concept: [Name of idea]\n\nDefinition: [What it means]\n\nOrigin: [Where it came from]\n\nCore Principles: [Key beliefs]\n\nProponents: [Who believes it]\n\nOpposition: [Who disagrees]\n\nApplications: [How it's used]\n\nEvidence: [Supporting arguments]\n\nConsequences: [What it leads to]\n\nModern Relevance: [Current importance]",
            suggestedTags: ["philosophy", "belief", "idea", "theory"]
        )
    ]
}

struct WorldElement: Identifiable, Codable, Hashable {
    let id: UUID
    let worldId: UUID
    var type: ElementType
    var title: String
    var content: String
    var tags: [String]
    var mentions: [ElementMention]
    var created: Date
    var lastModified: Date
    
    init(worldId: UUID, type: ElementType, title: String, content: String = "", tags: [String] = []) {
        self.id = UUID()
        self.worldId = worldId
        self.type = type
        self.title = title
        self.content = content
        self.tags = tags
        self.mentions = []
        self.created = Date()
        self.lastModified = Date()
    }
}

struct World: Identifiable, Codable {
    let id: UUID
    var title: String
    var desc: String
    var created: Date
    var lastModified: Date
    var elements: [WorldElement]
    var relationships: [ElementRelationship]
    
    init(title: String, desc: String) {
        self.id = UUID()
        self.title = title
        self.desc = desc
        self.created = Date()
        self.lastModified = Date()
        self.elements = []
        self.relationships = []
    }
    
    var elementCount: Int { elements.count }
    
    func elementCount(for type: ElementType) -> Int {
        elements.filter { $0.type == type }.count
    }
}

// MARK: - Theme System
struct AppTheme: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let displayName: String
    let isDark: Bool
    let primaryColor: String
    let secondaryColor: String
    let accentColor: String
    let backgroundColor: String
    let surfaceColor: String
    let textPrimaryColor: String
    let textSecondaryColor: String
    
    init(name: String, displayName: String, isDark: Bool, primaryColor: String, secondaryColor: String, accentColor: String, backgroundColor: String, surfaceColor: String, textPrimaryColor: String, textSecondaryColor: String) {
        self.id = UUID()
        self.name = name
        self.displayName = displayName
        self.isDark = isDark
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.surfaceColor = surfaceColor
        self.textPrimaryColor = textPrimaryColor
        self.textSecondaryColor = textSecondaryColor
    }
    
    var primaryUIColor: Color {
        Color(hex: primaryColor) ?? .blue
    }
    
    var secondaryUIColor: Color {
        Color(hex: secondaryColor) ?? .gray
    }
    
    var accentUIColor: Color {
        Color(hex: accentColor) ?? .purple
    }
    
    var backgroundUIColor: Color {
        Color(hex: backgroundColor) ?? (isDark ? .black : .white)
    }
    
    var surfaceUIColor: Color {
        Color(hex: surfaceColor) ?? (isDark ? Color(.systemGray6) : .white)
    }
    
    var textPrimaryUIColor: Color {
        Color(hex: textPrimaryColor) ?? (isDark ? .white : .black)
    }
    
    var textSecondaryUIColor: Color {
        Color(hex: textSecondaryColor) ?? .gray
    }
    
    static let builtInThemes: [AppTheme] = [
        // Light themes
        AppTheme(
            name: "default_light",
            displayName: "Default Light",
            isDark: false,
            primaryColor: "007AFF",
            secondaryColor: "8E8E93",
            accentColor: "AF52DE",
            backgroundColor: "FFFFFF",
            surfaceColor: "F2F2F7",
            textPrimaryColor: "000000",
            textSecondaryColor: "3C3C43"
        ),
        AppTheme(
            name: "forest_light",
            displayName: "Forest Light",
            isDark: false,
            primaryColor: "228B22",
            secondaryColor: "6B8E23",
            accentColor: "32CD32",
            backgroundColor: "F5F5DC",
            surfaceColor: "F0F8E8",
            textPrimaryColor: "2F4F2F",
            textSecondaryColor: "556B2F"
        ),
        AppTheme(
            name: "ocean_light",
            displayName: "Ocean Light",
            isDark: false,
            primaryColor: "1E90FF",
            secondaryColor: "4682B4",
            accentColor: "00CED1",
            backgroundColor: "F0F8FF",
            surfaceColor: "E6F3FF",
            textPrimaryColor: "191970",
            textSecondaryColor: "4682B4"
        ),
        AppTheme(
            name: "sunset_light",
            displayName: "Sunset Light",
            isDark: false,
            primaryColor: "FF6347",
            secondaryColor: "CD853F",
            accentColor: "FF69B4",
            backgroundColor: "FFF8DC",
            surfaceColor: "FFEFD5",
            textPrimaryColor: "8B4513",
            textSecondaryColor: "A0522D"
        ),
        
        // Dark themes
        AppTheme(
            name: "default_dark",
            displayName: "Default Dark",
            isDark: true,
            primaryColor: "0A84FF",
            secondaryColor: "8E8E93",
            accentColor: "BF5AF2",
            backgroundColor: "000000",
            surfaceColor: "1C1C1E",
            textPrimaryColor: "FFFFFF",
            textSecondaryColor: "EBEBF5"
        ),
        AppTheme(
            name: "midnight",
            displayName: "Midnight",
            isDark: true,
            primaryColor: "6366F1",
            secondaryColor: "64748B",
            accentColor: "8B5CF6",
            backgroundColor: "0F172A",
            surfaceColor: "1E293B",
            textPrimaryColor: "F1F5F9",
            textSecondaryColor: "CBD5E1"
        ),
        AppTheme(
            name: "cyberpunk",
            displayName: "Cyberpunk",
            isDark: true,
            primaryColor: "00FFFF",
            secondaryColor: "FF1493",
            accentColor: "ADFF2F",
            backgroundColor: "0D0D0D",
            surfaceColor: "1A1A1A",
            textPrimaryColor: "00FFFF",
            textSecondaryColor: "FF69B4"
        ),
        AppTheme(
            name: "nature_dark",
            displayName: "Nature Dark",
            isDark: true,
            primaryColor: "90EE90",
            secondaryColor: "8FBC8F",
            accentColor: "98FB98",
            backgroundColor: "1B2F1B",
            surfaceColor: "2F4F2F",
            textPrimaryColor: "F0FFF0",
            textSecondaryColor: "90EE90"
        ),
        AppTheme(
            name: "royal_purple",
            displayName: "Royal Purple",
            isDark: true,
            primaryColor: "9370DB",
            secondaryColor: "8A2BE2",
            accentColor: "DA70D6",
            backgroundColor: "2E1065",
            surfaceColor: "3730A3",
            textPrimaryColor: "F3E8FF",
            textSecondaryColor: "C4B5FD"
        )
    ]
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme
    @Published var availableThemes: [AppTheme]
    
    private let themeKey = "ForWorldBuildersTheme"
    private let customThemesKey = "ForWorldBuildersCustomThemes"
    
    init() {
        // Load custom themes
        var customThemes: [AppTheme] = []
        if let data = UserDefaults.standard.data(forKey: customThemesKey),
           let decoded = try? JSONDecoder().decode([AppTheme].self, from: data) {
            customThemes = decoded
        }
        
        self.availableThemes = AppTheme.builtInThemes + customThemes
        
        // Load current theme
        if let data = UserDefaults.standard.data(forKey: themeKey),
           let decoded = try? JSONDecoder().decode(AppTheme.self, from: data) {
            self.currentTheme = decoded
        } else {
            self.currentTheme = AppTheme.builtInThemes.first { $0.name == "default_light" } ?? AppTheme.builtInThemes[0]
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveCurrentTheme()
    }
    
    func addCustomTheme(_ theme: AppTheme) {
        availableThemes.append(theme)
        saveCustomThemes()
    }
    
    func deleteCustomTheme(_ theme: AppTheme) {
        availableThemes.removeAll { $0.id == theme.id }
        saveCustomThemes()
        
        // If deleted theme was current, switch to default
        if currentTheme.id == theme.id {
            setTheme(AppTheme.builtInThemes[0])
        }
    }
    
    private func saveCurrentTheme() {
        if let encoded = try? JSONEncoder().encode(currentTheme) {
            UserDefaults.standard.set(encoded, forKey: themeKey)
        }
    }
    
    private func saveCustomThemes() {
        let customThemes = availableThemes.filter { theme in
            !AppTheme.builtInThemes.contains { $0.id == theme.id }
        }
        if let encoded = try? JSONEncoder().encode(customThemes) {
            UserDefaults.standard.set(encoded, forKey: customThemesKey)
        }
    }
}

// MARK: - Data Store
class DataStore: ObservableObject {
    @Published var worlds: [World] = []
    @Published var recentActivity: [ActivityItem] = []
    
    static let shared = DataStore()
    
    private let saveKey = "ForWorldBuildersData"
    private let activityKey = "ForWorldBuildersActivity"
    private let maxActivityItems = 100 // Keep last 100 activities
    
    init() {
        load()
        loadActivity()
    }
    
    func addWorld(_ world: World) {
        worlds.append(world)
        logActivity(ActivityItem(type: .worldCreated, worldId: world.id, worldTitle: world.title))
        save()
    }
    
    func deleteWorld(_ world: World) {
        worlds.removeAll { $0.id == world.id }
        save()
    }
    
    func updateWorld(_ world: World) {
        if let index = worlds.firstIndex(where: { $0.id == world.id }) {
            worlds[index] = world
            worlds[index].lastModified = Date()
            logActivity(ActivityItem(type: .worldModified, worldId: world.id, worldTitle: world.title))
            save()
        }
    }
    
    func addElement(to worldId: UUID, element: WorldElement) {
        if let index = worlds.firstIndex(where: { $0.id == worldId }) {
            worlds[index].elements.append(element)
            worlds[index].lastModified = Date()
            logActivity(ActivityItem(type: .elementCreated, worldId: worldId, worldTitle: worlds[index].title, elementId: element.id, elementTitle: element.title, elementType: element.type))
            save()
        }
    }
    
    func updateElement(in worldId: UUID, element: WorldElement) {
        if let worldIndex = worlds.firstIndex(where: { $0.id == worldId }),
           let elementIndex = worlds[worldIndex].elements.firstIndex(where: { $0.id == element.id }) {
            worlds[worldIndex].elements[elementIndex] = element
            worlds[worldIndex].lastModified = Date()
            logActivity(ActivityItem(type: .elementModified, worldId: worldId, worldTitle: worlds[worldIndex].title, elementId: element.id, elementTitle: element.title, elementType: element.type))
            save()
        }
    }
    
    func deleteElement(from worldId: UUID, elementId: UUID) {
        if let worldIndex = worlds.firstIndex(where: { $0.id == worldId }) {
            if let element = worlds[worldIndex].elements.first(where: { $0.id == elementId }) {
                logActivity(ActivityItem(type: .elementDeleted, worldId: worldId, worldTitle: worlds[worldIndex].title, elementId: element.id, elementTitle: element.title, elementType: element.type))
            }
            worlds[worldIndex].elements.removeAll { $0.id == elementId }
            // Also remove any relationships involving this element
            worlds[worldIndex].relationships.removeAll { 
                $0.fromElementId == elementId || $0.toElementId == elementId 
            }
            worlds[worldIndex].lastModified = Date()
            save()
        }
    }
    
    func addRelationship(to worldId: UUID, relationship: ElementRelationship) {
        if let index = worlds.firstIndex(where: { $0.id == worldId }) {
            worlds[index].relationships.append(relationship)
            worlds[index].lastModified = Date()
            logActivity(ActivityItem(type: .relationshipCreated, worldId: worldId, worldTitle: worlds[index].title, relationshipId: relationship.id, details: relationship.type.rawValue))
            save()
        }
    }
    
    func deleteRelationship(from worldId: UUID, relationshipId: UUID) {
        if let worldIndex = worlds.firstIndex(where: { $0.id == worldId }) {
            if let relationship = worlds[worldIndex].relationships.first(where: { $0.id == relationshipId }) {
                logActivity(ActivityItem(type: .relationshipDeleted, worldId: worldId, worldTitle: worlds[worldIndex].title, relationshipId: relationship.id, details: relationship.type.rawValue))
            }
            worlds[worldIndex].relationships.removeAll { $0.id == relationshipId }
            worlds[worldIndex].lastModified = Date()
            save()
        }
    }
    
    func getRelationships(for elementId: UUID, in worldId: UUID) -> [ElementRelationship] {
        guard let world = worlds.first(where: { $0.id == worldId }) else { return [] }
        return world.relationships.filter { 
            $0.fromElementId == elementId || $0.toElementId == elementId 
        }
    }
    
    func updateElementMentions(in worldId: UUID, elementId: UUID, mentions: [ElementMention]) {
        if let worldIndex = worlds.firstIndex(where: { $0.id == worldId }),
           let elementIndex = worlds[worldIndex].elements.firstIndex(where: { $0.id == elementId }) {
            worlds[worldIndex].elements[elementIndex].mentions = mentions
            worlds[worldIndex].lastModified = Date()
            save()
        }
    }
    
    func getElementsForMentions(in worldId: UUID, excluding elementId: UUID? = nil) -> [WorldElement] {
        guard let world = worlds.first(where: { $0.id == worldId }) else { return [] }
        return world.elements.filter { element in
            if let excludeId = elementId, element.id == excludeId {
                return false
            }
            return true
        }
    }
    
    func findElement(by id: UUID, in worldId: UUID) -> WorldElement? {
        guard let world = worlds.first(where: { $0.id == worldId }) else { return nil }
        return world.elements.first(where: { $0.id == id })
    }
    
    private func logActivity(_ activity: ActivityItem) {
        recentActivity.insert(activity, at: 0)
        if recentActivity.count > maxActivityItems {
            recentActivity = Array(recentActivity.prefix(maxActivityItems))
        }
        saveActivity()
    }
    
    func getRecentActivity(limit: Int = 20) -> [ActivityItem] {
        return Array(recentActivity.prefix(limit))
    }
    
    func getRecentActivity(for worldId: UUID, limit: Int = 10) -> [ActivityItem] {
        return Array(recentActivity.filter { $0.worldId == worldId }.prefix(limit))
    }
    
    private func saveActivity() {
        if let encoded = try? JSONEncoder().encode(recentActivity) {
            UserDefaults.standard.set(encoded, forKey: activityKey)
        }
    }
    
    private func loadActivity() {
        if let data = UserDefaults.standard.data(forKey: activityKey),
           let decoded = try? JSONDecoder().decode([ActivityItem].self, from: data) {
            recentActivity = decoded
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(worlds) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([World].self, from: data) {
            worlds = decoded
        }
    }
}

@main
struct forworldbuilders_apple_clientApp: App {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var apiKeyManager = APIKeyManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(themeManager)
                .environmentObject(subscriptionManager)
                .environmentObject(apiKeyManager)
                .preferredColorScheme(themeManager.currentTheme.isDark ? .dark : .light)
        }
    }
}
