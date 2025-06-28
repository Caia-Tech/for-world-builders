package com.caiatech.forworldbuilders.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.caiatech.forworldbuilders.data.database.entities.World
import com.caiatech.forworldbuilders.data.repository.WorldBuildingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class WorldsUiState(
    val worlds: List<World> = emptyList(),
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null,
    val worldCount: Int = 0,
    val canCreateWorld: Boolean = true
)

@HiltViewModel
class WorldsViewModel @Inject constructor(
    private val repository: WorldBuildingRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(WorldsUiState())
    val uiState: StateFlow<WorldsUiState> = _uiState.asStateFlow()
    
    init {
        loadWorlds()
    }
    
    private fun loadWorlds() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            
            // Observe worlds
            repository.getAllWorlds().collect { worldsList ->
                val worldCount = worldsList.size
                _uiState.update { 
                    it.copy(
                        worlds = worldsList,
                        worldCount = worldCount,
                        canCreateWorld = worldCount < 3,
                        isLoading = false
                    )
                }
            }
        }
    }
    
    fun createWorld(title: String, description: String): Boolean {
        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true, errorMessage = null) }
            
            repository.createWorld(title, description)
                .onSuccess {
                    // World created successfully
                    _uiState.update { 
                        it.copy(
                            isSaving = false,
                            successMessage = "World \"$title\" created successfully!",
                            errorMessage = null
                        ) 
                    }
                }
                .onFailure { exception ->
                    _uiState.update { 
                        it.copy(
                            isSaving = false,
                            errorMessage = exception.message
                        ) 
                    }
                }
        }
        return true
    }
    
    fun deleteWorld(world: World) {
        viewModelScope.launch {
            repository.deleteWorld(world)
        }
    }
    
    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
    
    fun clearSuccess() {
        _uiState.update { it.copy(successMessage = null) }
    }
}