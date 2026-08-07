package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.local.UserRole
import com.example.ui.components.AsOneTopBar
import com.example.ui.components.getRoleLabel
import com.example.ui.screens.*
import com.example.ui.theme.MyApplicationTheme
import com.example.ui.viewmodels.AsOneViewModel

class MainActivity : ComponentActivity() {

    private val viewModel: AsOneViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            MyApplicationTheme {
                val currentUser by viewModel.currentUser.collectAsStateWithLifecycle()
                val allUsers by viewModel.allUsers.collectAsStateWithLifecycle()
                val pricingGrid by viewModel.pricingGrid.collectAsStateWithLifecycle()
                val chantiers by viewModel.allChantiers.collectAsStateWithLifecycle()
                val pointages by viewModel.allPointages.collectAsStateWithLifecycle()
                val equipmentList by viewModel.allEquipment.collectAsStateWithLifecycle()
                val transactions by viewModel.allTransactions.collectAsStateWithLifecycle()
                val vehicles by viewModel.allVehicles.collectAsStateWithLifecycle()
                val activeAgents by viewModel.activeAgents.collectAsStateWithLifecycle()

                if (currentUser == null) {
                    LoginScreen(
                        allUsers = allUsers,
                        onLoginSuccess = { user ->
                            viewModel.setCurrentUser(user)
                        }
                    )
                } else {
                    Scaffold(
                        modifier = Modifier.fillMaxSize(),
                        topBar = {
                            AsOneTopBar(
                                currentUser = currentUser,
                                allUsers = allUsers,
                                onSelectUser = { user ->
                                    viewModel.setCurrentUser(user)
                                },
                                onLogout = {
                                    viewModel.logout()
                                },
                                title = "AS ONE - ${getRoleLabel(currentUser?.role ?: UserRole.ADMIN_DIRECTION.name)}"
                            )
                        }
                    ) { innerPadding ->
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(innerPadding)
                        ) {
                            when (currentUser?.role) {
                                UserRole.ADMIN_DIRECTION.name -> {
                                    AdminDirectionScreen(
                                        viewModel = viewModel,
                                        allUsers = allUsers,
                                        pricingGrid = pricingGrid,
                                        chantiers = chantiers,
                                        vehicles = vehicles
                                    )
                                }
                                UserRole.COMPTABLE.name -> {
                                    ComptableScreen(
                                        viewModel = viewModel,
                                        allUsers = allUsers,
                                        pointages = pointages,
                                        transactions = transactions
                                    )
                                }
                                UserRole.CHEF_CHANTIER.name -> {
                                    ChefChantierScreen(
                                        viewModel = viewModel,
                                        currentUser = currentUser,
                                        chantiers = chantiers,
                                        activeAgents = activeAgents,
                                        pricingGrid = pricingGrid
                                    )
                                }
                                UserRole.MAGASINIER.name -> {
                                    MagasinierScreen(
                                        viewModel = viewModel,
                                        equipmentList = equipmentList,
                                        transactions = transactions,
                                        vehicles = vehicles,
                                        chantiers = chantiers,
                                        allUsers = allUsers
                                    )
                                }
                                UserRole.AGENT_CLEANING.name -> {
                                    AgentScreen(
                                        viewModel = viewModel,
                                        currentUser = currentUser,
                                        pointages = pointages,
                                        transactions = transactions
                                    )
                                }
                                else -> {
                                    AdminDirectionScreen(
                                        viewModel = viewModel,
                                        allUsers = allUsers,
                                        pricingGrid = pricingGrid,
                                        chantiers = chantiers,
                                        vehicles = vehicles
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
