package com.caiatech.forworldbuilders.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.caiatech.forworldbuilders.data.database.entities.ElementType
import com.caiatech.forworldbuilders.ui.screens.*
import androidx.compose.material3.*
import androidx.compose.runtime.getValue
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.Modifier
import androidx.navigation.compose.currentBackStackEntryAsState
import com.caiatech.forworldbuilders.ui.composables.ForWorldBuildersBottomBar

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ForWorldBuildersNavigation(
    navController: NavHostController = rememberNavController()
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route
    
    val showBottomBar = when (currentRoute?.substringBefore("/")) {
        "worlds_list", "settings" -> true
        else -> false
    }
    
    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                ForWorldBuildersBottomBar(
                    currentRoute = currentRoute,
                    onNavigate = { route ->
                        navController.navigate(route) {
                            popUpTo(navController.graph.startDestinationId) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState = true
                        }
                    }
                )
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = "worlds_list",
            modifier = Modifier.padding(paddingValues)
        ) {
        composable("worlds_list") {
            WorldsListScreen(
                onWorldClick = { world ->
                    navController.navigate("world_detail/${world.id}")
                },
                onCreateWorld = {
                    navController.navigate("create_world")
                },
                onNavigateToAi = {
                    navController.navigate("ai_chat_general")
                }
            )
        }
        
        composable("create_world") {
            CreateWorldScreen(
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
        
        composable(
            route = "world_detail/{worldId}",
            arguments = listOf(navArgument("worldId") { type = NavType.StringType })
        ) { backStackEntry ->
            val worldId = backStackEntry.arguments?.getString("worldId") ?: ""
            WorldDetailScreen(
                onNavigateBack = { navController.popBackStack() },
                onElementClick = { element ->
                    navController.navigate("element_detail/${element.id}")
                },
                onCreateElement = { elementType ->
                    navController.navigate("create_element/$worldId/${elementType.name}")
                },
                onNavigateToNetwork = {
                    navController.navigate("network_view/$worldId")
                },
                onNavigateToAi = {
                    navController.navigate("ai_chat/$worldId")
                }
            )
        }
        
        composable(
            route = "create_element/{worldId}/{elementType}",
            arguments = listOf(
                navArgument("worldId") { type = NavType.StringType },
                navArgument("elementType") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val elementTypeString = backStackEntry.arguments?.getString("elementType") ?: "CUSTOM"
            val elementType = try {
                ElementType.valueOf(elementTypeString)
            } catch (e: IllegalArgumentException) {
                ElementType.CUSTOM
            }
            
            CreateElementScreen(
                elementType = elementType,
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(
            route = "element_detail/{elementId}",
            arguments = listOf(navArgument("elementId") { type = NavType.StringType })
        ) {
            ElementDetailScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToElement = { elementId ->
                    navController.navigate("element_detail/$elementId")
                }
            )
        }
        
        composable(
            route = "network_view/{worldId}",
            arguments = listOf(navArgument("worldId") { type = NavType.StringType })
        ) {
            NetworkScreen(
                onNavigateBack = { navController.popBackStack() },
                onElementClick = { element ->
                    navController.navigate("element_detail/${element.id}")
                }
            )
        }
        
        composable("settings") {
            SettingsScreen(
                onNavigateBack = { navController.popBackStack() },
                onUpgradeClick = { /* TODO: Implement upgrade */ }
            )
        }
        
        composable(
            route = "ai_chat/{worldId}",
            arguments = listOf(navArgument("worldId") { type = NavType.StringType })
        ) {
            AiChatScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable("ai_chat_general") {
            AiChatScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
        }
    }
}