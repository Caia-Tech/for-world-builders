package com.caiatech.forworldbuilders.ui.viewmodels

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.caiatech.forworldbuilders.data.ai.models.AiAssistantType
import com.caiatech.forworldbuilders.data.ai.models.ChatMessage
import com.caiatech.forworldbuilders.data.ai.repository.AiRepository
import com.caiatech.forworldbuilders.data.ai.repository.AiResult
import com.caiatech.forworldbuilders.data.preferences.PreferencesManager
import com.caiatech.forworldbuilders.data.repository.WorldBuildingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

data class AiChatUiState(
    val messages: List<ChatMessage> = emptyList(),
    val isLoading: Boolean = false,
    val assistantType: AiAssistantType = AiAssistantType.WORLDBUILDING_COACH,
    val worldTitle: String? = null,
    val isProUser: Boolean = false,
    val apiKeyRequired: Boolean = false,
    val errorMessage: String? = null,
    val currentInput: String = ""
)

@HiltViewModel
class AiChatViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val aiRepository: AiRepository,
    private val worldRepository: WorldBuildingRepository,
    private val preferencesManager: PreferencesManager
) : ViewModel() {
    
    private val worldId: String? = savedStateHandle.get<String>("worldId")
    
    private val _uiState = MutableStateFlow(AiChatUiState())
    val uiState: StateFlow<AiChatUiState> = _uiState.asStateFlow()
    
    init {
        loadWorldInfo()
        initializeChat()
    }
    
    private fun loadWorldInfo() {
        worldId?.let { id ->
            viewModelScope.launch {
                val world = worldRepository.getWorldById(id)
                _uiState.value = _uiState.value.copy(worldTitle = world?.title)
            }
        }
    }
    
    private fun initializeChat() {
        val welcomeMessage = ChatMessage(
            role = "assistant",
            content = getWelcomeMessage(_uiState.value.assistantType)
        )
        _uiState.value = _uiState.value.copy(messages = listOf(welcomeMessage))
    }
    
    private fun getWelcomeMessage(assistantType: AiAssistantType): String {
        return when (assistantType) {
            AiAssistantType.WORLDBUILDING_COACH -> 
                "👋 Hi! I'm your worldbuilding coach. I'm here to help you create rich, immersive worlds. What aspect of your world would you like to explore today?"
            
            AiAssistantType.CHARACTER_DEVELOPER ->
                "🎭 Hello! I specialize in character development. Whether you're creating new characters or deepening existing ones, I'm here to help. Tell me about a character you're working on!"
            
            AiAssistantType.PLOT_ASSISTANT ->
                "📖 Greetings! I'm your plot development assistant. I can help you craft compelling storylines, develop conflicts, and weave narratives that fit your world. What story elements are you exploring?"
            
            AiAssistantType.CONSISTENCY_CHECKER ->
                "🔍 Hello! I'm here to help maintain consistency in your world. I can analyze your world elements for logical consistency, timeline issues, and potential contradictions. What would you like me to review?"
            
            AiAssistantType.CONTENT_GENERATOR ->
                "✨ Hi there! I'm your creative content generator. I can help you create names, descriptions, cultural details, and other world elements. What kind of content do you need?"
        }
    }
    
    fun updateInput(input: String) {
        _uiState.value = _uiState.value.copy(currentInput = input)
    }
    
    fun sendMessage() {
        val currentInput = _uiState.value.currentInput.trim()
        if (currentInput.isBlank()) return
        
        val userMessage = ChatMessage(role = "user", content = currentInput)
        val updatedMessages = _uiState.value.messages + userMessage
        
        _uiState.value = _uiState.value.copy(
            messages = updatedMessages,
            currentInput = "",
            isLoading = true,
            errorMessage = null
        )
        
        viewModelScope.launch {
            // For demo purposes, we'll use mock responses
            // In production, check if user is Pro and has API key
            if (_uiState.value.isProUser) {
                handleProUserMessage(updatedMessages)
            } else {
                handleFreeUserMessage(currentInput)
            }
        }
    }
    
    private suspend fun handleProUserMessage(messages: List<ChatMessage>) {
        val apiKey = preferencesManager.getApiKey()
        
        when (val result = aiRepository.chatWithAi(
            messages = messages.filter { it.role != "system" },
            worldId = worldId,
            assistantType = _uiState.value.assistantType,
            apiKey = apiKey
        )) {
            is AiResult.Success -> {
                val updatedMessages = _uiState.value.messages + result.data
                _uiState.value = _uiState.value.copy(
                    messages = updatedMessages,
                    isLoading = false
                )
            }
            
            is AiResult.ApiKeyRequired -> {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    apiKeyRequired = true,
                    errorMessage = result.message
                )
            }
            
            is AiResult.Error -> {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = result.message
                )
            }
        }
    }
    
    private fun handleFreeUserMessage(userInput: String) {
        // Use mock responses for free users
        val mockResponse = aiRepository.getMockAiResponse(userInput, _uiState.value.assistantType)
        val updatedMessages = _uiState.value.messages + mockResponse
        
        _uiState.value = _uiState.value.copy(
            messages = updatedMessages,
            isLoading = false
        )
    }
    
    fun changeAssistantType(newType: AiAssistantType) {
        val typeChangeMessage = ChatMessage(
            role = "assistant",
            content = "🔄 Switching to ${getAssistantTypeName(newType)} mode.\n\n${getWelcomeMessage(newType)}"
        )
        
        val updatedMessages = _uiState.value.messages + typeChangeMessage
        
        _uiState.value = _uiState.value.copy(
            assistantType = newType,
            messages = updatedMessages
        )
    }
    
    private fun getAssistantTypeName(type: AiAssistantType): String {
        return when (type) {
            AiAssistantType.WORLDBUILDING_COACH -> "Worldbuilding Coach"
            AiAssistantType.CHARACTER_DEVELOPER -> "Character Developer"
            AiAssistantType.PLOT_ASSISTANT -> "Plot Assistant"
            AiAssistantType.CONSISTENCY_CHECKER -> "Consistency Checker"
            AiAssistantType.CONTENT_GENERATOR -> "Content Generator"
        }
    }
    
    fun clearChat() {
        initializeChat()
        _uiState.value = _uiState.value.copy(
            errorMessage = null,
            apiKeyRequired = false
        )
    }
    
    fun dismissError() {
        _uiState.value = _uiState.value.copy(
            errorMessage = null,
            apiKeyRequired = false
        )
    }
    
    fun toggleProMode() {
        // For demo purposes - in production this would be determined by actual Pro status
        _uiState.value = _uiState.value.copy(
            isProUser = !_uiState.value.isProUser
        )
    }
}