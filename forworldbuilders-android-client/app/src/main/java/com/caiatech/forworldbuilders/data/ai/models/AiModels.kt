package com.caiatech.forworldbuilders.data.ai.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ChatMessage(
    val role: String, // "user", "assistant", "system"
    val content: String
)

@Serializable
data class ChatRequest(
    val model: String = "gpt-3.5-turbo",
    val messages: List<ChatMessage>,
    @SerialName("max_tokens") val maxTokens: Int = 500,
    val temperature: Double = 0.7,
    val functions: List<FunctionDefinition>? = null,
    @SerialName("function_call") val functionCall: String? = null
)

@Serializable
data class ChatResponse(
    val id: String,
    val `object`: String,
    val created: Long,
    val model: String,
    val choices: List<Choice>,
    val usage: Usage
)

@Serializable
data class Choice(
    val index: Int,
    val message: ChatMessage,
    @SerialName("finish_reason") val finishReason: String
)

@Serializable
data class Usage(
    @SerialName("prompt_tokens") val promptTokens: Int,
    @SerialName("completion_tokens") val completionTokens: Int,
    @SerialName("total_tokens") val totalTokens: Int
)

@Serializable
data class FunctionDefinition(
    val name: String,
    val description: String,
    val parameters: FunctionParameters
)

@Serializable
data class FunctionParameters(
    val type: String = "object",
    val properties: Map<String, ParameterProperty>,
    val required: List<String> = emptyList()
)

@Serializable
data class ParameterProperty(
    val type: String,
    val description: String,
    val enum: List<String>? = null
)

// AI Privacy Modes from specification
enum class AiPrivacyMode {
    MAXIMUM_PRIVACY,    // Local AI only, no cloud
    CONTROLLED_SHARING, // Limited cloud AI with consent
    FULL_ACCESS        // Full cloud AI access
}

// AI Assistant Types
enum class AiAssistantType {
    WORLDBUILDING_COACH,    // General worldbuilding guidance
    CHARACTER_DEVELOPER,    // Character creation and development
    PLOT_ASSISTANT,        // Story and plot development
    CONSISTENCY_CHECKER,   // World consistency analysis
    CONTENT_GENERATOR      // Generate descriptions, names, etc.
}

// Conversation Context
@Serializable
data class AiConversation(
    val id: String,
    val worldId: String,
    val assistantType: String, // AiAssistantType serialized as string
    val messages: List<ChatMessage>,
    val created: Long,
    val lastModified: Long
)

// Function Call Results
@Serializable
data class WorldQueryResult(
    val elements: List<ElementSummary>? = null,
    val relationships: List<RelationshipSummary>? = null,
    val worldInfo: WorldSummary? = null
)

@Serializable
data class ElementSummary(
    val id: String,
    val title: String,
    val type: String,
    val content: String,
    val tags: String
)

@Serializable
data class RelationshipSummary(
    val sourceElement: String,
    val targetElement: String,
    val type: String,
    val strength: Int,
    val description: String
)

@Serializable
data class WorldSummary(
    val title: String,
    val description: String,
    val elementCount: Int,
    val relationshipCount: Int
)