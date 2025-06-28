package com.caiatech.forworldbuilders.data.preferences

import android.content.Context
import android.content.SharedPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PreferencesManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    private val prefs: SharedPreferences = context.getSharedPreferences(
        "forworldbuilders_prefs",
        Context.MODE_PRIVATE
    )
    
    companion object {
        private const val KEY_OPENAI_API_KEY = "openai_api_key"
        private const val KEY_IS_PRO_USER = "is_pro_user"
    }
    
    fun getApiKey(): String {
        return prefs.getString(KEY_OPENAI_API_KEY, "") ?: ""
    }
    
    fun setApiKey(apiKey: String) {
        prefs.edit()
            .putString(KEY_OPENAI_API_KEY, apiKey)
            .apply()
    }
    
    fun getIsProUser(): Boolean {
        return prefs.getBoolean(KEY_IS_PRO_USER, false)
    }
    
    fun setIsProUser(isProUser: Boolean) {
        prefs.edit()
            .putBoolean(KEY_IS_PRO_USER, isProUser)
            .apply()
    }
    
    fun clearApiKey() {
        prefs.edit()
            .remove(KEY_OPENAI_API_KEY)
            .apply()
    }
}