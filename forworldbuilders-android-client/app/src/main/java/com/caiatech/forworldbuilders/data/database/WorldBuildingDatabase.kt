package com.caiatech.forworldbuilders.data.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import android.content.Context
import com.caiatech.forworldbuilders.data.database.dao.RelationshipDao
import com.caiatech.forworldbuilders.data.database.dao.WorldDao
import com.caiatech.forworldbuilders.data.database.dao.WorldElementDao
import com.caiatech.forworldbuilders.data.database.entities.Relationship
import com.caiatech.forworldbuilders.data.database.entities.World
import com.caiatech.forworldbuilders.data.database.entities.WorldElement

@Database(
    entities = [World::class, WorldElement::class, Relationship::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class WorldBuildingDatabase : RoomDatabase() {
    abstract fun worldDao(): WorldDao
    abstract fun worldElementDao(): WorldElementDao
    abstract fun relationshipDao(): RelationshipDao

    companion object {
        @Volatile
        private var INSTANCE: WorldBuildingDatabase? = null

        fun getDatabase(context: Context): WorldBuildingDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    WorldBuildingDatabase::class.java,
                    "world_building_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}