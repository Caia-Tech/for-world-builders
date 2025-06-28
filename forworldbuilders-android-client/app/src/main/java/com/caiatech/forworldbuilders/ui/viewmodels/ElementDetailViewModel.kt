package com.caiatech.forworldbuilders.ui.viewmodels

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.caiatech.forworldbuilders.data.database.entities.Relationship
import com.caiatech.forworldbuilders.data.database.entities.WorldElement
import com.caiatech.forworldbuilders.data.repository.WorldBuildingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ElementDetailUiState(
    val element: WorldElement? = null,
    val relationships: List<Relationship> = emptyList(),
    val relatedElements: Map<String, WorldElement> = emptyMap(),
    val availableElements: List<WorldElement> = emptyList(),
    val isLoading: Boolean = false,
    val isEditing: Boolean = false,
    val errorMessage: String? = null
)

@HiltViewModel
class ElementDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: WorldBuildingRepository
) : ViewModel() {
    
    private val elementId: String = savedStateHandle.get<String>("elementId") ?: ""
    
    private val _uiState = MutableStateFlow(ElementDetailUiState())
    val uiState: StateFlow<ElementDetailUiState> = _uiState.asStateFlow()
    
    init {
        loadElement()
        loadRelationships()
        loadAvailableElements()
    }
    
    private fun loadElement() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            repository.getElementById(elementId)?.let { element ->
                _uiState.update { 
                    it.copy(
                        element = element,
                        isLoading = false
                    )
                }
            }
        }
    }
    
    private fun loadRelationships() {
        viewModelScope.launch {
            repository.getRelationshipsForElement(elementId).collect { relationships ->
                _uiState.update { it.copy(relationships = relationships) }
                
                // Load related elements
                val relatedElementIds = relationships.flatMap { 
                    listOf(it.sourceElementId, it.targetElementId)
                }.filter { it != elementId }.distinct()
                
                val relatedElements = mutableMapOf<String, WorldElement>()
                relatedElementIds.forEach { id ->
                    repository.getElementById(id)?.let { element ->
                        relatedElements[id] = element
                    }
                }
                
                _uiState.update { it.copy(relatedElements = relatedElements) }
            }
        }
    }
    
    fun toggleEditMode() {
        _uiState.update { it.copy(isEditing = !it.isEditing) }
    }
    
    fun updateElement(
        title: String,
        content: String,
        tags: String
    ) {
        viewModelScope.launch {
            _uiState.value.element?.let { element ->
                val updatedElement = element.copy(
                    title = title,
                    content = content,
                    tags = tags
                )
                repository.updateElement(updatedElement)
                _uiState.update { 
                    it.copy(
                        element = updatedElement,
                        isEditing = false
                    )
                }
            }
        }
    }
    
    fun deleteElement() {
        viewModelScope.launch {
            _uiState.value.element?.let { element ->
                repository.deleteElement(element)
            }
        }
    }
    
    fun createRelationship(
        targetElementId: String,
        type: String,
        strength: Int = 5,
        description: String = "",
        bidirectional: Boolean = false
    ) {
        viewModelScope.launch {
            repository.createRelationship(
                sourceElementId = elementId,
                targetElementId = targetElementId,
                type = type,
                strength = strength,
                description = description,
                bidirectional = bidirectional
            )
        }
    }
    
    fun deleteRelationship(relationship: Relationship) {
        viewModelScope.launch {
            repository.deleteRelationship(relationship)
        }
    }
    
    private fun loadAvailableElements() {
        viewModelScope.launch {
            _uiState.value.element?.let { element ->
                repository.getElementsForWorld(element.worldId).collect { allElements ->
                    // Filter out current element and already related elements
                    val existingRelationshipIds = _uiState.value.relationships.flatMap { 
                        listOf(it.sourceElementId, it.targetElementId)
                    }.filter { it != elementId }.distinct()
                    
                    val availableElements = allElements.filter { 
                        it.id != elementId && it.id !in existingRelationshipIds
                    }
                    
                    _uiState.update { it.copy(availableElements = availableElements) }
                }
            }
        }
    }
    
    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}