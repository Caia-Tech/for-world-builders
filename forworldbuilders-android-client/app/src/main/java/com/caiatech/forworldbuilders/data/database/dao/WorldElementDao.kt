package com.caiatech.forworldbuilders.data.database.dao

import androidx.room.*
import com.caiatech.forworldbuilders.data.database.entities.ElementType
import com.caiatech.forworldbuilders.data.database.entities.WorldElement
import kotlinx.coroutines.flow.Flow

@Dao
interface WorldElementDao {
    @Query("SELECT * FROM world_elements WHERE worldId = :worldId ORDER BY lastModified DESC")
    fun getElementsForWorld(worldId: String): Flow<List<WorldElement>>

    @Query("SELECT * FROM world_elements WHERE worldId = :worldId AND type = :type ORDER BY title")
    fun getElementsByType(worldId: String, type: ElementType): Flow<List<WorldElement>>

    @Query("SELECT * FROM world_elements WHERE id = :elementId")
    suspend fun getElementById(elementId: String): WorldElement?

    @Query("SELECT COUNT(*) FROM world_elements WHERE worldId = :worldId")
    suspend fun getElementCountForWorld(worldId: String): Int

    @Query("SELECT * FROM world_elements WHERE worldId = :worldId AND (title LIKE '%' || :query || '%' OR content LIKE '%' || :query || '%')")
    fun searchElements(worldId: String, query: String): Flow<List<WorldElement>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertElement(element: WorldElement)

    @Update
    suspend fun updateElement(element: WorldElement)

    @Delete
    suspend fun deleteElement(element: WorldElement)

    @Query("DELETE FROM world_elements WHERE id = :elementId")
    suspend fun deleteElementById(elementId: String)
    
    @Query("SELECT * FROM world_elements WHERE worldId = :worldId ORDER BY created ASC")
    suspend fun getElementsForWorldList(worldId: String): List<WorldElement>
}