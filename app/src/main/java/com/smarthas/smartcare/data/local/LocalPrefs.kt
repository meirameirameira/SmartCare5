package com.smarthas.smartcare.data.local

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * Lightweight SharedPreferences wrapper for SmartCare local persistence.
 *
 * Stores:
 *  - Health notes (user-written observations keyed by date)
 *  - Chat history (last N messages as JSON)
 *  - User display name
 */
class LocalPrefs(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("smartcare_prefs", Context.MODE_PRIVATE)

    private val gson = Gson()

    // ── Health Notes ─────────────────────────────────────────────────────────

    /** Save a health note for today (keyed by ISO date string). */
    fun saveHealthNote(date: String, note: String) {
        val map = getHealthNotes().toMutableMap()
        map[date] = note
        prefs.edit().putString(KEY_HEALTH_NOTES, gson.toJson(map)).apply()
    }

    /** Return all stored health notes as a Map<date, note>. */
    fun getHealthNotes(): Map<String, String> {
        val json = prefs.getString(KEY_HEALTH_NOTES, null) ?: return emptyMap()
        val type = object : TypeToken<Map<String, String>>() {}.type
        return gson.fromJson(json, type) ?: emptyMap()
    }

    /** Return the note for a specific date, or null if absent. */
    fun getHealthNote(date: String): String? = getHealthNotes()[date]

    /** Delete a specific health note. */
    fun deleteHealthNote(date: String) {
        val map = getHealthNotes().toMutableMap()
        map.remove(date)
        prefs.edit().putString(KEY_HEALTH_NOTES, gson.toJson(map)).apply()
    }

    // ── Chat History ─────────────────────────────────────────────────────────

    /** Persist a list of serialised chat message strings. */
    fun saveChatHistory(messages: List<String>) {
        val trimmed = if (messages.size > MAX_CHAT_MESSAGES) {
            messages.takeLast(MAX_CHAT_MESSAGES)
        } else messages
        prefs.edit().putString(KEY_CHAT_HISTORY, gson.toJson(trimmed)).apply()
    }

    /** Load persisted chat history (empty list if none). */
    fun loadChatHistory(): List<String> {
        val json = prefs.getString(KEY_CHAT_HISTORY, null) ?: return emptyList()
        val type = object : TypeToken<List<String>>() {}.type
        return gson.fromJson(json, type) ?: emptyList()
    }

    /** Clear all chat history. */
    fun clearChatHistory() {
        prefs.edit().remove(KEY_CHAT_HISTORY).apply()
    }

    // ── User Preferences ─────────────────────────────────────────────────────

    fun saveUserName(name: String) {
        prefs.edit().putString(KEY_USER_NAME, name).apply()
    }

    fun loadUserName(): String? = prefs.getString(KEY_USER_NAME, null)

    fun saveOnboardingDone(done: Boolean) {
        prefs.edit().putBoolean(KEY_ONBOARDING_DONE, done).apply()
    }

    fun isOnboardingDone(): Boolean = prefs.getBoolean(KEY_ONBOARDING_DONE, false)

    // ─────────────────────────────────────────────────────────────────────────

    companion object {
        private const val KEY_HEALTH_NOTES    = "health_notes"
        private const val KEY_CHAT_HISTORY    = "chat_history"
        private const val KEY_USER_NAME       = "user_name"
        private const val KEY_ONBOARDING_DONE = "onboarding_done"
        private const val MAX_CHAT_MESSAGES   = 50
    }
}
