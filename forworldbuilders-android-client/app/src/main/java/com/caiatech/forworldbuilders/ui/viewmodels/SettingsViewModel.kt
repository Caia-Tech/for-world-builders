package com.caiatech.forworldbuilders.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.caiatech.forworldbuilders.data.database.entities.World
import com.caiatech.forworldbuilders.data.export.JsonExporter
import com.caiatech.forworldbuilders.data.import.ImportedData
import com.caiatech.forworldbuilders.data.import.JsonImporter
import com.caiatech.forworldbuilders.data.preferences.PreferencesManager
import com.caiatech.forworldbuilders.data.repository.WorldBuildingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val worlds: List<World> = emptyList(),
    val isExporting: Boolean = false,
    val isImporting: Boolean = false,
    val exportResult: String? = null,
    val importResult: String? = null,
    val pendingImport: ImportedData? = null,
    val conflictingWorlds: List<String> = emptyList(),
    val errorMessage: String? = null,
    val apiKey: String = ""
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val repository: WorldBuildingRepository,
    private val preferencesManager: PreferencesManager
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()
    
    init {
        loadWorlds()
        loadApiKey()
    }
    
    private fun loadApiKey() {
        val apiKey = preferencesManager.getApiKey()
        _uiState.value = _uiState.value.copy(apiKey = apiKey)
    }
    
    private fun loadWorlds() {
        viewModelScope.launch {
            repository.getAllWorlds().collect { worlds ->
                _uiState.value = _uiState.value.copy(worlds = worlds)
            }
        }
    }
    
    fun exportWorld(world: World) {
        viewModelScope.launch {
            try {
                _uiState.value = _uiState.value.copy(isExporting = true, errorMessage = null)
                
                val elements = repository.getElementsForWorldList(world.id)
                val relationships = repository.getRelationshipsForWorld(world.id)
                
                val jsonData = JsonExporter.exportWorld(world, elements, relationships)
                
                _uiState.value = _uiState.value.copy(
                    isExporting = false,
                    exportResult = jsonData
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isExporting = false,
                    errorMessage = "Export failed: ${e.message}"
                )
            }
        }
    }
    
    fun exportAllWorlds() {
        viewModelScope.launch {
            try {
                _uiState.value = _uiState.value.copy(isExporting = true, errorMessage = null)
                
                val worldsData = _uiState.value.worlds.map { world ->
                    val elements = repository.getElementsForWorldList(world.id)
                    val relationships = repository.getRelationshipsForWorld(world.id)
                    Triple(world, elements, relationships)
                }
                
                val jsonData = JsonExporter.exportAllWorlds(worldsData)
                
                _uiState.value = _uiState.value.copy(
                    isExporting = false,
                    exportResult = jsonData
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isExporting = false,
                    errorMessage = "Export failed: ${e.message}"
                )
            }
        }
    }
    
    fun importFromJson(jsonContent: String) {
        viewModelScope.launch {
            try {
                _uiState.value = _uiState.value.copy(isImporting = true, errorMessage = null)
                
                val parseResult = JsonImporter.parseImportData(jsonContent)
                if (parseResult.isFailure) {
                    _uiState.value = _uiState.value.copy(
                        isImporting = false,
                        errorMessage = "Import failed: ${parseResult.exceptionOrNull()?.message}"
                    )
                    return@launch
                }
                
                val importData = parseResult.getOrThrow()
                
                // Validate import data
                val validationErrors = JsonImporter.validateImportData(importData)
                if (validationErrors.isNotEmpty()) {
                    _uiState.value = _uiState.value.copy(
                        isImporting = false,
                        errorMessage = "Validation failed: ${validationErrors.joinToString(", ")}"
                    )
                    return@launch
                }
                
                // Check for conflicts
                val conflicts = repository.checkForConflicts(importData)
                if (conflicts.isNotEmpty()) {
                    _uiState.value = _uiState.value.copy(
                        isImporting = false,
                        pendingImport = importData,
                        conflictingWorlds = conflicts
                    )
                } else {
                    // No conflicts, proceed with import
                    performImport(importData, false)
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isImporting = false,
                    errorMessage = "Import failed: ${e.message}"
                )
            }
        }
    }
    
    fun confirmImport(overwriteExisting: Boolean) {
        viewModelScope.launch {
            _uiState.value.pendingImport?.let { importData ->
                _uiState.value = _uiState.value.copy(isImporting = true)
                performImport(importData, overwriteExisting)
            }
        }
    }
    
    private suspend fun performImport(importData: ImportedData, overwriteExisting: Boolean) {
        val result = repository.importData(importData, overwriteExisting)
        if (result.isSuccess) {
            val (worlds, elements, relationships) = result.getOrThrow()
            _uiState.value = _uiState.value.copy(
                isImporting = false,
                importResult = "Successfully imported $worlds worlds, $elements elements, and $relationships relationships",
                pendingImport = null,
                conflictingWorlds = emptyList()
            )
        } else {
            _uiState.value = _uiState.value.copy(
                isImporting = false,
                errorMessage = "Import failed: ${result.exceptionOrNull()?.message}",
                pendingImport = null,
                conflictingWorlds = emptyList()
            )
        }
    }
    
    fun cancelImport() {
        _uiState.value = _uiState.value.copy(
            pendingImport = null,
            conflictingWorlds = emptyList()
        )
    }
    
    fun updateApiKey(apiKey: String) {
        try {
            if (apiKey.trim().isBlank()) {
                preferencesManager.clearApiKey()
            } else {
                preferencesManager.setApiKey(apiKey.trim())
            }
            _uiState.value = _uiState.value.copy(apiKey = apiKey.trim())
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(
                errorMessage = "Failed to save API key: ${e.message}"
            )
        }
    }
    
    fun clearExportResult() {
        _uiState.value = _uiState.value.copy(exportResult = null, errorMessage = null)
    }
    
    fun clearImportResult() {
        _uiState.value = _uiState.value.copy(importResult = null, errorMessage = null)
    }
}