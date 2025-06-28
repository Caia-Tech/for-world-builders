package com.caiatech.forworldbuilders.ui.composables

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.vector.ImageVector

enum class BottomNavItem(
    val route: String,
    val icon: ImageVector,
    val label: String
) {
    WORLDS("worlds_list", Icons.Filled.Home, "Worlds"),
    SETTINGS("settings", Icons.Filled.Settings, "Settings")
}

@Composable
fun ForWorldBuildersBottomBar(
    currentRoute: String?,
    onNavigate: (String) -> Unit
) {
    NavigationBar {
        BottomNavItem.values().forEach { item ->
            NavigationBarItem(
                selected = currentRoute?.startsWith(item.route) == true,
                onClick = { onNavigate(item.route) },
                icon = { Icon(item.icon, contentDescription = item.label) },
                label = { Text(item.label) }
            )
        }
    }
}