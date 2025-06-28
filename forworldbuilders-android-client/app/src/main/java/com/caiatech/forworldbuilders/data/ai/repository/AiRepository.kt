package com.caiatech.forworldbuilders.data.ai.repository

import com.caiatech.forworldbuilders.data.ai.api.OpenAiConfig
import com.caiatech.forworldbuilders.data.ai.api.OpenAiService
import com.caiatech.forworldbuilders.data.ai.models.*
import com.caiatech.forworldbuilders.data.repository.WorldBuildingRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

sealed class AiResult<T> {
    data class Success<T>(val data: T) : AiResult<T>()
    data class Error<T>(val message: String, val cause: Throwable? = null) : AiResult<T>()
    data class ApiKeyRequired<T>(val message: String = "OpenAI API key required for AI features") : AiResult<T>()
}

@Singleton
class AiRepository @Inject constructor(
    private val openAiService: OpenAiService,
    private val worldRepository: WorldBuildingRepository
) {
    
    suspend fun chatWithAi(
        messages: List<ChatMessage>,
        worldId: String? = null,
        assistantType: AiAssistantType = AiAssistantType.WORLDBUILDING_COACH,
        apiKey: String? = null
    ): AiResult<ChatMessage> = withContext(Dispatchers.IO) {
        
        val effectiveApiKey = apiKey ?: OpenAiConfig.DEMO_API_KEY
        if (effectiveApiKey == OpenAiConfig.DEMO_API_KEY) {
            return@withContext AiResult.ApiKeyRequired()
        }
        
        try {
            val systemPrompt = createSystemPrompt(assistantType, worldId)
            val fullMessages = listOf(systemPrompt) + messages
            
            val functions = if (worldId != null) createWorldFunctions() else emptyList()
            
            val request = ChatRequest(
                model = "gpt-3.5-turbo",
                messages = fullMessages,
                maxTokens = 500,
                temperature = 0.7,
                functions = functions.takeIf { it.isNotEmpty() }
            )
            
            val response = openAiService.createChatCompletion(
                authorization = OpenAiConfig.formatApiKey(effectiveApiKey),
                request = request
            )
            
            if (response.isSuccessful) {
                val chatResponse = response.body()
                val aiMessage = chatResponse?.choices?.firstOrNull()?.message
                if (aiMessage != null) {
                    AiResult.Success(aiMessage)
                } else {
                    AiResult.Error("No response from AI")
                }
            } else {
                AiResult.Error("AI API Error: ${response.code()} ${response.message()}")
            }
            
        } catch (e: Exception) {
            AiResult.Error("Network error: ${e.message}", e)
        }
    }
    
    private suspend fun createSystemPrompt(assistantType: AiAssistantType, worldId: String?): ChatMessage {
        val basePrompt = when (assistantType) {
            AiAssistantType.WORLDBUILDING_COACH -> """
                You are an expert worldbuilding assistant for the ForWorldBuilders app. Help users create rich, consistent fictional worlds.
                
                Your role:
                - Provide creative worldbuilding guidance and suggestions
                - Ask thoughtful questions to help users develop their ideas
                - Offer constructive feedback on world elements
                - Suggest connections between different world elements
                - Help maintain consistency across the world
                
                Guidelines:
                - Be encouraging and supportive
                - Ask follow-up questions to understand the user's vision
                - Suggest specific details that enhance immersion
                - Respect the user's creative choices
                - Keep responses concise but helpful
            """.trimIndent()
            
            AiAssistantType.CHARACTER_DEVELOPER -> """
                You are a character development specialist for ForWorldBuilders. Help users create compelling, well-rounded characters.
                
                Focus on:
                - Character motivations and backstories
                - Personality traits and flaws
                - Character relationships and dynamics
                - Character arcs and development
                - Making characters feel authentic and memorable
                
                Ask about goals, fears, secrets, and what drives the character.
            """.trimIndent()
            
            AiAssistantType.PLOT_ASSISTANT -> """
                You are a plot and story development assistant for ForWorldBuilders. Help users craft engaging narratives.
                
                Expertise in:
                - Story structure and pacing
                - Plot hooks and conflicts
                - Character-driven storylines
                - World-appropriate plot elements
                - Connecting story beats to world elements
            """.trimIndent()
            
            AiAssistantType.CONSISTENCY_CHECKER -> """
                You are a world consistency analyst for ForWorldBuilders. Help users maintain logical consistency in their worlds.
                
                Focus on:
                - Identifying potential contradictions
                - Logical consistency of world rules
                - Timeline and causality issues
                - Character behavior consistency
                - World physics and magic systems
            """.trimIndent()
            
            AiAssistantType.CONTENT_GENERATOR -> """
                You are a creative content generator for ForWorldBuilders. Help users generate names, descriptions, and world details.
                
                Provide:
                - Creative names for people, places, organizations
                - Vivid descriptions of locations and items
                - Cultural details and customs
                - Historical events and legends
                - Flora, fauna, and natural phenomena
            """.trimIndent()
        }
        
        val worldContext = if (worldId != null) {
            val worldInfo = getWorldContext(worldId)
            "\n\nCurrent World Context:\n$worldInfo"
        } else {
            ""
        }
        
        return ChatMessage(
            role = "system",
            content = basePrompt + worldContext
        )
    }
    
    private suspend fun getWorldContext(worldId: String): String {
        return try {
            val world = worldRepository.getWorldById(worldId)
            val elements = worldRepository.getElementsForWorldList(worldId)
            val relationships = worldRepository.getRelationshipsForWorld(worldId)
            
            buildString {
                world?.let {
                    appendLine("World: ${it.title}")
                    appendLine("Description: ${it.description}")
                    appendLine()
                }
                
                if (elements.isNotEmpty()) {
                    appendLine("Elements (${elements.size}):")
                    elements.take(10).forEach { element ->
                        appendLine("- ${element.type.name}: ${element.title}")
                        if (element.content.isNotBlank()) {
                            appendLine("  ${element.content.take(100)}${if (element.content.length > 100) "..." else ""}")
                        }
                    }
                    if (elements.size > 10) {
                        appendLine("... and ${elements.size - 10} more elements")
                    }
                    appendLine()
                }
                
                if (relationships.isNotEmpty()) {
                    appendLine("Key Relationships (${relationships.size}):")
                    relationships.take(5).forEach { rel ->
                        val source = elements.find { it.id == rel.sourceElementId }?.title ?: "Unknown"
                        val target = elements.find { it.id == rel.targetElementId }?.title ?: "Unknown"
                        appendLine("- $source ${rel.type} $target (strength: ${rel.strength}/10)")
                    }
                    if (relationships.size > 5) {
                        appendLine("... and ${relationships.size - 5} more relationships")
                    }
                }
            }
        } catch (e: Exception) {
            "Unable to load world context: ${e.message}"
        }
    }
    
    private fun createWorldFunctions(): List<FunctionDefinition> {
        return listOf(
            FunctionDefinition(
                name = "query_world_elements",
                description = "Search for elements in the current world by type or name",
                parameters = FunctionParameters(
                    properties = mapOf(
                        "element_type" to ParameterProperty(
                            type = "string",
                            description = "Type of element to search for",
                            enum = listOf("CHARACTER", "LOCATION", "EVENT", "ORGANIZATION", "ITEM", "CULTURE", "LANGUAGE", "TIMELINE", "PLOT", "CONCEPT", "CUSTOM")
                        ),
                        "search_term" to ParameterProperty(
                            type = "string",
                            description = "Search term to find elements by name or content"
                        )
                    )
                )
            ),
            FunctionDefinition(
                name = "get_element_relationships",
                description = "Get all relationships for a specific element",
                parameters = FunctionParameters(
                    properties = mapOf(
                        "element_name" to ParameterProperty(
                            type = "string",
                            description = "Name of the element to get relationships for"
                        )
                    ),
                    required = listOf("element_name")
                )
            ),
            FunctionDefinition(
                name = "analyze_world_consistency",
                description = "Analyze the world for potential consistency issues",
                parameters = FunctionParameters(
                    properties = mapOf(
                        "focus_area" to ParameterProperty(
                            type = "string",
                            description = "Specific area to focus consistency check on",
                            enum = listOf("timeline", "geography", "characters", "magic_system", "technology", "culture")
                        )
                    )
                )
            )
        )
    }
    
    // Mock AI response for demo/free users
    fun getMockAiResponse(userMessage: String, assistantType: AiAssistantType): ChatMessage {
        val mockResponses = when (assistantType) {
            AiAssistantType.WORLDBUILDING_COACH -> listOf(
                "That's an interesting world concept! Have you considered how the geography might influence the culture and politics of your world?",
                "Great start! What's the central conflict or tension that drives events in this world?",
                "I love that idea! How do the different groups or factions in your world interact with each other?",
                "That element could create fascinating dynamics. What are the consequences or implications of this in your world?"
            )
            AiAssistantType.CHARACTER_DEVELOPER -> listOf(
                "This character sounds intriguing! What is their greatest fear or weakness?",
                "Nice character concept! What drives them to take action? What are their core motivations?",
                "I can see potential here. How do they relate to other characters in your world?",
                "Interesting! What's a secret this character keeps, and how might it affect the story?"
            )
            AiAssistantType.CONTENT_GENERATOR -> listOf(
                "Here are some name suggestions: Aethermoor, Crystalhaven, Shadowpeak, Driftlands, Ironwatch",
                "Consider these elements: floating gardens, crystal formations, ancient ruins, mystical forests, underground cities",
                "Some cultural aspects to explore: unique festivals, traditional crafts, social hierarchies, belief systems, customs",
                "Potential conflicts: resource scarcity, territorial disputes, ideological differences, ancient grudges, environmental threats"
            )
            else -> listOf(
                "That's a great question for worldbuilding! Consider exploring the deeper implications of this element.",
                "Interesting concept! How does this fit with the overall theme and tone of your world?",
                "Good thinking! What are the broader consequences of this choice in your world?"
            )
        }
        
        return ChatMessage(
            role = "assistant",
            content = mockResponses.random() + "\n\n💡 *This is a demo response. Connect your OpenAI API key for full AI assistance.*"
        )
    }
}