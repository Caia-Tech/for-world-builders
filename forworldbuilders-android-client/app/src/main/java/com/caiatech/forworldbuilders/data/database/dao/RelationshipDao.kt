package com.caiatech.forworldbuilders.data.database.dao

import androidx.room.*
import com.caiatech.forworldbuilders.data.database.entities.Relationship
import kotlinx.coroutines.flow.Flow

@Dao
interface RelationshipDao {
    @Query("SELECT * FROM relationships WHERE sourceElementId = :elementId OR targetElementId = :elementId")
    fun getRelationshipsForElement(elementId: String): Flow<List<Relationship>>

    @Query("SELECT * FROM relationships WHERE sourceElementId = :sourceId AND targetElementId = :targetId")
    suspend fun getRelationshipBetween(sourceId: String, targetId: String): Relationship?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRelationship(relationship: Relationship)

    @Update
    suspend fun updateRelationship(relationship: Relationship)

    @Delete
    suspend fun deleteRelationship(relationship: Relationship)

    @Query("DELETE FROM relationships WHERE id = :relationshipId")
    suspend fun deleteRelationshipById(relationshipId: String)

    @Query("DELETE FROM relationships WHERE sourceElementId = :elementId OR targetElementId = :elementId")
    suspend fun deleteRelationshipsForElement(elementId: String)
    
    @Query("""
        SELECT DISTINCT r.* FROM relationships r 
        INNER JOIN world_elements e1 ON r.sourceElementId = e1.id 
        INNER JOIN world_elements e2 ON r.targetElementId = e2.id 
        WHERE e1.worldId = :worldId OR e2.worldId = :worldId
    """)
    suspend fun getRelationshipsForWorld(worldId: String): List<Relationship>
}