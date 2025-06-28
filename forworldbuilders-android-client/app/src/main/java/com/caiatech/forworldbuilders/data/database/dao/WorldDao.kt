package com.caiatech.forworldbuilders.data.database.dao

import androidx.room.*
import com.caiatech.forworldbuilders.data.database.entities.World
import kotlinx.coroutines.flow.Flow

@Dao
interface WorldDao {
    @Query("SELECT * FROM worlds ORDER BY lastModified DESC")
    fun getAllWorlds(): Flow<List<World>>

    @Query("SELECT * FROM worlds WHERE id = :worldId")
    suspend fun getWorldById(worldId: String): World?

    @Query("SELECT COUNT(*) FROM worlds")
    suspend fun getWorldCount(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertWorld(world: World)

    @Update
    suspend fun updateWorld(world: World)

    @Delete
    suspend fun deleteWorld(world: World)

    @Query("DELETE FROM worlds WHERE id = :worldId")
    suspend fun deleteWorldById(worldId: String)
}