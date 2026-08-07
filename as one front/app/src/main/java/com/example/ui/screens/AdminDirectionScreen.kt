package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.*
import com.example.ui.components.MetricStatCard
import com.example.ui.components.StatusBadge
import com.example.ui.components.getRoleLabel
import com.example.ui.theme.*
import com.example.ui.viewmodels.AsOneViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminDirectionScreen(
    viewModel: AsOneViewModel,
    allUsers: List<UserEntity>,
    pricingGrid: PricingGridEntity?,
    chantiers: List<ChantierEntity>,
    vehicles: List<VehicleEntity>
) {
    var selectedTab by remember { mutableIntStateOf(0) }
    var showCreateUserDialog by remember { mutableStateOf(false) }
    var showPricingDialog by remember { mutableStateOf(false) }
    var showAddChantierDialog by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AsOneBackground)
    ) {
        // Tab Navigation for Direction
        PrimaryTabRow(
            selectedTabIndex = selectedTab,
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = AsOneGreen
        ) {
            Tab(
                selected = selectedTab == 0,
                onClick = { selectedTab = 0 },
                text = { Text("Vue d'Ensemble", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.Dashboard, contentDescription = null) }
            )
            Tab(
                selected = selectedTab == 1,
                onClick = { selectedTab = 1 },
                text = { Text("Gestion Personnel", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.People, contentDescription = null) }
            )
            Tab(
                selected = selectedTab == 2,
                onClick = { selectedTab = 2 },
                text = { Text("Tarifs & Sites", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.RequestQuote, contentDescription = null) }
            )
        }

        when (selectedTab) {
            0 -> AdminOverviewTab(
                allUsers = allUsers,
                chantiers = chantiers,
                pricingGrid = pricingGrid,
                vehicles = vehicles,
                onConfigurePricing = { showPricingDialog = true }
            )
            1 -> AdminPersonnelTab(
                allUsers = allUsers,
                onCreateUserClick = { showCreateUserDialog = true },
                onToggleSuspension = { userId, currentSuspended ->
                    viewModel.toggleUserSuspension(userId, currentSuspended)
                }
            )
            2 -> AdminTarifsAndSitesTab(
                pricingGrid = pricingGrid,
                chantiers = chantiers,
                allUsers = allUsers,
                onEditPricing = { showPricingDialog = true },
                onAddChantier = { showAddChantierDialog = true }
            )
        }
    }

    // Dialogs
    if (showCreateUserDialog) {
        CreateUserDialog(
            onDismiss = { showCreateUserDialog = false },
            onCreate = { name, phone, role, status, salary, operator ->
                viewModel.createEmployeeAccount(name, phone, role, status, salary, operator)
                showCreateUserDialog = false
            }
        )
    }

    if (showPricingDialog) {
        EditPricingGridDialog(
            currentGrid = pricingGrid ?: PricingGridEntity(),
            onDismiss = { showPricingDialog = false },
            onSave = { std, night, sun ->
                viewModel.updatePricingGrid(std, night, sun)
                showPricingDialog = false
            }
        )
    }

    if (showAddChantierDialog) {
        AddChantierDialog(
            chefs = allUsers.filter { it.role == UserRole.CHEF_CHANTIER.name },
            onDismiss = { showAddChantierDialog = false },
            onAdd = { name, location, chefId, chefName ->
                viewModel.addChantier(name, location, chefId, chefName)
                showAddChantierDialog = false
            }
        )
    }
}

@Composable
fun AdminOverviewTab(
    allUsers: List<UserEntity>,
    chantiers: List<ChantierEntity>,
    pricingGrid: PricingGridEntity?,
    vehicles: List<VehicleEntity>,
    onConfigurePricing: () -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = AsOneBlueDark),
                shape = RoundedCornerShape(20.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Icon(Icons.Default.Security, contentDescription = null, tint = AsOneGreenLight)
                        Text(
                            text = "Direction Générale AS ONE",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                    Text(
                        text = "Sécurité administrative absolue : Seul l'administrateur crée et distribue les accès. Aucune auto-inscription possible.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = AsOneSkyBlueLight
                    )
                }
            }
        }

        // Metrics Row
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                MetricStatCard(
                    title = "Effectif Total",
                    value = "${allUsers.size} Agents",
                    subtitle = "${allUsers.count { it.isSuspended }} Suspendus",
                    icon = Icons.Default.Badge,
                    color = AsOneGreen,
                    modifier = Modifier.weight(1f)
                )
                MetricStatCard(
                    title = "Chantiers Actifs",
                    value = "${chantiers.size} Sites",
                    subtitle = "Assignés aux chefs",
                    icon = Icons.Default.LocationOn,
                    color = AsOneBlue,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        // Vehicle Safety Alerts Section
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(Icons.Default.DirectionsCar, contentDescription = null, tint = AsOneBlue)
                            Text(
                                text = "Alertes Flotte & Sécurité Véhicules",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        StatusBadge(
                            text = "${vehicles.size} Véhicules",
                            backgroundColor = AsOneBlue
                        )
                    }

                    vehicles.forEach { v ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(AsOneBackground, RoundedCornerShape(12.dp))
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = "${v.immatriculation} - ${v.modelName}",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                Text(
                                    text = "Dernière Assurance: ${v.lastAssuranceDate} | Vidange: ${v.lastVidangeDate}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = AsOneTextSecondary
                                )
                            }
                            StatusBadge(
                                text = "Rappel -7 jours actif",
                                backgroundColor = Color(0xFFE65100),
                                textColor = Color.White
                            )
                        }
                    }
                }
            }
        }

        // Current Rate Grid Summary
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Grille Tarifaire Réglementaire",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        IconButton(onClick = onConfigurePricing) {
                            Icon(Icons.Default.Edit, contentDescription = "Modifier", tint = AsOneGreen)
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        RateChip("Journée Standard", "${pricingGrid?.standardDayRate?.toInt() ?: 2500} F", AsOneGreen)
                        RateChip("Shift Nuit", "${pricingGrid?.nightRate?.toInt() ?: 4500} F", AsOneBlue)
                        RateChip("Dimanche", "${pricingGrid?.sundayRate?.toInt() ?: 5000} F", AsOneSkyBlue)
                    }
                }
            }
        }
    }
}

@Composable
fun RateChip(title: String, amount: String, color: Color) {
    Surface(
        color = color.copy(alpha = 0.12f),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(text = title, style = MaterialTheme.typography.labelSmall, color = AsOneTextSecondary)
            Text(text = amount, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = color)
        }
    }
}

@Composable
fun AdminPersonnelTab(
    allUsers: List<UserEntity>,
    onCreateUserClick: () -> Unit,
    onToggleSuspension: (String, Boolean) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Comptes Employés Distribution",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Button(
                onClick = onCreateUserClick,
                colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = null)
                Spacer(modifier = Modifier.width(4.dp))
                Text("Créer Compte")
            }
        }

        LazyLazyUserList(
            users = allUsers,
            onToggleSuspension = onToggleSuspension
        )
    }
}

@Composable
fun LazyLazyUserList(
    users: List<UserEntity>,
    onToggleSuspension: (String, Boolean) -> Unit
) {
    LazyColumn(
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        items(users, key = { it.id }) { user ->
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(CircleShape)
                                .background(if (user.isSuspended) Color.Gray else AsOneBlue),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = user.fullName.take(1),
                                color = Color.White,
                                fontWeight = FontWeight.Bold,
                                fontSize = 18.sp
                            )
                        }
                        Column {
                            Text(
                                text = user.fullName,
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "${getRoleLabel(user.role)} • ${user.status}",
                                style = MaterialTheme.typography.bodySmall,
                                color = AsOneTextSecondary
                            )
                            Text(
                                text = "Tél: ${user.phone} (${user.paymentOperator})",
                                style = MaterialTheme.typography.labelSmall,
                                color = AsOneBlue
                            )
                        }
                    }

                    Column(horizontalAlignment = Alignment.End) {
                        if (user.isSuspended) {
                            StatusBadge(text = "SUSPENDU", backgroundColor = Color.Red)
                        } else {
                            StatusBadge(text = "ACTIF", backgroundColor = AsOneGreen)
                        }
                        Spacer(modifier = Modifier.height(6.dp))
                        OutlinedButton(
                            onClick = { onToggleSuspension(user.id, user.isSuspended) },
                            modifier = Modifier.height(32.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp)
                        ) {
                            Text(
                                text = if (user.isSuspended) "Réactiver" else "Suspendre",
                                fontSize = 11.sp,
                                color = if (user.isSuspended) AsOneGreen else Color.Red
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun AdminTarifsAndSitesTab(
    pricingGrid: PricingGridEntity?,
    chantiers: List<ChantierEntity>,
    allUsers: List<UserEntity>,
    onEditPricing: () -> Unit,
    onAddChantier: () -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Grille Tarifaire des Vacations",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Button(
                            onClick = onEditPricing,
                            colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen)
                        ) {
                            Icon(Icons.Default.Edit, contentDescription = null)
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Modifier Grille")
                        }
                    }

                    Text("Standard (Journée): ${pricingGrid?.standardDayRate?.toInt() ?: 2500} FCFA")
                    Text("Vacation Nuit: ${pricingGrid?.nightRate?.toInt() ?: 4500} FCFA")
                    Text("Vacation Dimanche: ${pricingGrid?.sundayRate?.toInt() ?: 5000} FCFA")
                }
            }
        }

        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Chantiers & Affectations Chefs",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Button(
                    onClick = onAddChantier,
                    colors = ButtonDefaults.buttonColors(containerColor = AsOneBlue)
                ) {
                    Icon(Icons.Default.AddLocation, contentDescription = null)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Nouveau Site")
                }
            }
        }

        items(chantiers) { site ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = site.name,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Lieu: ${site.location}",
                            style = MaterialTheme.typography.bodySmall,
                            color = AsOneTextSecondary
                        )
                        Text(
                            text = "Chef Responsable: ${site.assignedChefName}",
                            style = MaterialTheme.typography.labelSmall,
                            color = AsOneBlue
                        )
                    }
                    StatusBadge(text = site.id, backgroundColor = AsOneSkyBlue)
                }
            }
        }
    }
}

// Dialogs
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateUserDialog(
    onDismiss: () -> Unit,
    onCreate: (String, String, UserRole, AgentStatus, Double, String) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var selectedRole by remember { mutableStateOf(UserRole.AGENT_CLEANING) }
    var selectedStatus by remember { mutableStateOf(AgentStatus.TEMPORAIRE) }
    var salaryStr by remember { mutableStateOf("85000") }
    var selectedOperator by remember { mutableStateOf("T-Money") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Créer Compte Employé (Direction)", fontWeight = FontWeight.Bold) },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Nom complet") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = phone,
                    onValueChange = { phone = it },
                    label = { Text("Numéro Téléphone (+228)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Text("Rôle Délégué:", fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    FilterChip(
                        selected = selectedRole == UserRole.AGENT_CLEANING,
                        onClick = { selectedRole = UserRole.AGENT_CLEANING },
                        label = { Text("Agent") }
                    )
                    FilterChip(
                        selected = selectedRole == UserRole.CHEF_CHANTIER,
                        onClick = { selectedRole = UserRole.CHEF_CHANTIER },
                        label = { Text("Chef") }
                    )
                    FilterChip(
                        selected = selectedRole == UserRole.MAGASINIER,
                        onClick = { selectedRole = UserRole.MAGASINIER },
                        label = { Text("Magasinier") }
                    )
                }

                Text("Statut Contrat:", fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    FilterChip(
                        selected = selectedStatus == AgentStatus.TEMPORAIRE,
                        onClick = { selectedStatus = AgentStatus.TEMPORAIRE },
                        label = { Text("Temporaire (15 du mois)") }
                    )
                    FilterChip(
                        selected = selectedStatus == AgentStatus.PERMANENT,
                        onClick = { selectedStatus = AgentStatus.PERMANENT },
                        label = { Text("Permanent (Fixe)") }
                    )
                }

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        selected = selectedOperator == "T-Money",
                        onClick = { selectedOperator = "T-Money" },
                        label = { Text("T-Money") }
                    )
                    FilterChip(
                        selected = selectedOperator == "Flooz",
                        onClick = { selectedOperator = "Flooz" },
                        label = { Text("Flooz") }
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (name.isNotBlank() && phone.isNotBlank()) {
                        val sal = salaryStr.toDoubleOrNull() ?: 85000.0
                        onCreate(name, phone, selectedRole, selectedStatus, sal, selectedOperator)
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen)
            ) {
                Text("Valider Compte")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Annuler") }
        }
    )
}

@Composable
fun EditPricingGridDialog(
    currentGrid: PricingGridEntity,
    onDismiss: () -> Unit,
    onSave: (Double, Double, Double) -> Unit
) {
    var stdStr by remember { mutableStateOf(currentGrid.standardDayRate.toInt().toString()) }
    var nightStr by remember { mutableStateOf(currentGrid.nightRate.toInt().toString()) }
    var sunStr by remember { mutableStateOf(currentGrid.sundayRate.toInt().toString()) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Modifier Grille Tarifaire FCFA", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = stdStr,
                    onValueChange = { stdStr = it },
                    label = { Text("Journée Standard (défaut 2 500 F)") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = nightStr,
                    onValueChange = { nightStr = it },
                    label = { Text("Shift Nuit (défaut 4 500 F)") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = sunStr,
                    onValueChange = { sunStr = it },
                    label = { Text("Dimanche (défaut 5 000 F)") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val std = stdStr.toDoubleOrNull() ?: 2500.0
                    val night = nightStr.toDoubleOrNull() ?: 4500.0
                    val sun = sunStr.toDoubleOrNull() ?: 5000.0
                    onSave(std, night, sun)
                },
                colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen)
            ) {
                Text("Enregistrer Grille")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Annuler") }
        }
    )
}

@Composable
fun AddChantierDialog(
    chefs: List<UserEntity>,
    onDismiss: () -> Unit,
    onAdd: (String, String, String, String) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var selectedChef by remember { mutableStateOf(chefs.firstOrNull()) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Ajouter Nouveau Chantier / Site", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Nom du site / Client") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = location,
                    onValueChange = { location = it },
                    label = { Text("Emplacement / Adresse") },
                    modifier = Modifier.fillMaxWidth()
                )
                Text("Chef Responsable:", fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                chefs.forEach { chef ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        RadioButton(
                            selected = selectedChef?.id == chef.id,
                            onClick = { selectedChef = chef }
                        )
                        Text(chef.fullName)
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (name.isNotBlank() && selectedChef != null) {
                        onAdd(name, location, selectedChef!!.id, selectedChef!!.fullName)
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = AsOneBlue)
            ) {
                Text("Créer Site")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Annuler") }
        }
    )
}
