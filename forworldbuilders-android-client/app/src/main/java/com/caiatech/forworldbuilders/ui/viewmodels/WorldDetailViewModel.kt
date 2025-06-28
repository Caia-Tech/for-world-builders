package com.caiatech.forworldbuilders.ui.viewmodels

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.caiatech.forworldbuilders.data.database.entities.ElementType
import com.caiatech.forworldbuilders.data.database.entities.World
import com.caiatech.forworldbuilders.data.database.entities.WorldElement
import com.caiatech.forworldbuilders.data.repository.WorldBuildingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class SortBy { NAME, CREATED, MODIFIED }
enum class SortOrder { ASC, DESC }

data class WorldDetailUiState(
    val world: World? = null,
    val elements: List<WorldElement> = emptyList(),
    val filteredElements: List<WorldElement> = emptyList(),
    val elementsByType: Map<ElementType, List<WorldElement>> = emptyMap(),
    val selectedType: ElementType? = null,
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val elementCount: Int = 0,
    val canCreateElement: Boolean = true,
    val searchQuery: String = "",
    val sortBy: SortBy = SortBy.MODIFIED,
    val sortOrder: SortOrder = SortOrder.DESC,
    val showRecentOnly: Boolean = false
)

@HiltViewModel
class WorldDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: WorldBuildingRepository
) : ViewModel() {
    
    private val worldId: String = savedStateHandle.get<String>("worldId") ?: ""
    
    private val _uiState = MutableStateFlow(WorldDetailUiState())
    val uiState: StateFlow<WorldDetailUiState> = _uiState.asStateFlow()
    
    init {
        loadWorld()
        loadElements()
    }
    
    private fun loadWorld() {
        viewModelScope.launch {
            repository.getWorldById(worldId)?.let { world ->
                _uiState.update { it.copy(world = world) }
            }
        }
    }
    
    private fun loadElements() {
        viewModelScope.launch {
            repository.getElementsForWorld(worldId).collect { elementsList ->
                val elementCount = elementsList.size
                val sortedAndFilteredElements = applySortingAndFiltering(elementsList)
                val elementsByType = sortedAndFilteredElements.groupBy { it.type }
                
                _uiState.update { 
                    it.copy(
                        elements = elementsList,
                        filteredElements = sortedAndFilteredElements,
                        elementsByType = elementsByType,
                        elementCount = elementCount,
                        canCreateElement = elementCount < 100,
                        isLoading = false
                    )
                }
            }
        }
    }
    
    private fun applySortingAndFiltering(elements: List<WorldElement>): List<WorldElement> {
        val state = _uiState.value
        var result = elements
        
        // Apply recent filter
        if (state.showRecentOnly) {
            val weekAgo = System.currentTimeMillis() - (7 * 24 * 60 * 60 * 1000)
            result = result.filter { it.lastModified.time > weekAgo }
        }
        
        // Apply type filter
        state.selectedType?.let { selectedType ->
            result = result.filter { it.type == selectedType }
        }
        
        // Apply sorting
        result = when (state.sortBy) {
            SortBy.NAME -> result.sortedBy { it.title.lowercase() }
            SortBy.CREATED -> result.sortedBy { it.created }
            SortBy.MODIFIED -> result.sortedBy { it.lastModified }
        }
        
        // Apply sort order
        if (state.sortOrder == SortOrder.DESC) {
            result = result.reversed()
        }
        
        return result
    }
    
    fun selectType(type: ElementType?) {
        _uiState.update { it.copy(selectedType = type) }
        refreshElements()
    }
    
    fun setSorting(sortBy: SortBy, sortOrder: SortOrder = _uiState.value.sortOrder) {
        _uiState.update { it.copy(sortBy = sortBy, sortOrder = sortOrder) }
        refreshElements()
    }
    
    fun toggleSortOrder() {
        val newOrder = if (_uiState.value.sortOrder == SortOrder.ASC) SortOrder.DESC else SortOrder.ASC
        _uiState.update { it.copy(sortOrder = newOrder) }
        refreshElements()
    }
    
    fun toggleRecentFilter() {
        _uiState.update { it.copy(showRecentOnly = !it.showRecentOnly) }
        refreshElements()
    }
    
    private fun refreshElements() {
        val currentElements = _uiState.value.elements
        val sortedAndFilteredElements = applySortingAndFiltering(currentElements)
        val elementsByType = sortedAndFilteredElements.groupBy { it.type }
        
        _uiState.update { 
            it.copy(
                filteredElements = sortedAndFilteredElements,
                elementsByType = elementsByType
            )
        }
    }
    
    fun updateSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }
        if (query.isNotBlank()) {
            searchElements(query)
        } else {
            loadElements()
        }
    }
    
    private fun searchElements(query: String) {
        viewModelScope.launch {
            repository.searchElements(worldId, query).collect { searchResults ->
                val sortedAndFilteredResults = applySortingAndFiltering(searchResults)
                val elementsByType = sortedAndFilteredResults.groupBy { it.type }
                _uiState.update { 
                    it.copy(
                        elements = searchResults,
                        filteredElements = sortedAndFilteredResults,
                        elementsByType = elementsByType
                    )
                }
            }
        }
    }
    
    fun createElement(type: ElementType, title: String, content: String, tags: String = "") {
        viewModelScope.launch {
            repository.createElement(
                worldId = worldId,
                type = type,
                title = title,
                content = content,
                tags = tags
            ).onSuccess {
                _uiState.update { it.copy(errorMessage = null) }
            }.onFailure { exception ->
                _uiState.update { it.copy(errorMessage = exception.message) }
            }
        }
    }
    
    fun deleteElement(element: WorldElement) {
        viewModelScope.launch {
            repository.deleteElement(element)
        }
    }
    
    fun updateWorld(title: String, description: String) {
        viewModelScope.launch {
            _uiState.value.world?.let { world ->
                repository.updateWorld(
                    world.copy(
                        title = title,
                        description = description
                    )
                )
            }
        }
    }
    
    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}