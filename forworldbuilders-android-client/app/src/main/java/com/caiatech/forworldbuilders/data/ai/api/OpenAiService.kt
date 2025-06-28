package com.caiatech.forworldbuilders.data.ai.api

import com.caiatech.forworldbuilders.data.ai.models.ChatRequest
import com.caiatech.forworldbuilders.data.ai.models.ChatResponse
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.Header
import retrofit2.http.POST

interface OpenAiService {
    @POST("v1/chat/completions")
    suspend fun createChatCompletion(
        @Header("Authorization") authorization: String,
        @Header("Content-Type") contentType: String = "application/json",
        @Body request: ChatRequest
    ): Response<ChatResponse>
}

object OpenAiConfig {
    const val BASE_URL = "https://api.openai.com/"
    const val API_VERSION = "v1"
    
    // For demo purposes - in production this should be secured
    const val DEMO_API_KEY = "demo-key-replace-with-real-key"
    
    fun formatApiKey(apiKey: String): String {
        return "Bearer $apiKey"
    }
}