package com.caiatech.forworldbuilders.di

import android.content.Context
import com.caiatech.forworldbuilders.data.database.WorldBuildingDatabase
import com.caiatech.forworldbuilders.data.database.dao.RelationshipDao
import com.caiatech.forworldbuilders.data.database.dao.WorldDao
import com.caiatech.forworldbuilders.data.database.dao.WorldElementDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    
    @Provides
    @Singleton
    fun provideWorldBuildingDatabase(
        @ApplicationContext context: Context
    ): WorldBuildingDatabase {
        return WorldBuildingDatabase.getDatabase(context)
    }
    
    @Provides
    fun provideWorldDao(database: WorldBuildingDatabase): WorldDao {
        return database.worldDao()
    }
    
    @Provides
    fun provideWorldElementDao(database: WorldBuildingDatabase): WorldElementDao {
        return database.worldElementDao()
    }
    
    @Provides
    fun provideRelationshipDao(database: WorldBuildingDatabase): RelationshipDao {
        return database.relationshipDao()
    }
}