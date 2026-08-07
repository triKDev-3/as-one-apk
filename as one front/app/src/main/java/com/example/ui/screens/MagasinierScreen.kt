package com.example.ui.screens

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.*
import com.example.ui.components.MetricStatCard
import com.example.ui.components.StatusBadge
import com.example.ui.theme.*
import com.example.ui.viewmodels.AsOneViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MagasinierScreen(
    viewModel: AsOneViewModel,
    equipmentList: List<EquipmentEntity>,
    transactions: List<EquipmentTransactionEntity>,
    vehicles: List<VehicleEntity>,
    chantiers: List<ChantierEntity>,
    allUsers: List<UserEntity>
) {
    var selectedTab by remember { mutableIntStateOf(0) } // 0 = Matériel, 1 = Flotte Véhicules
    var selectedEquipmentForReturn by remember { mutableStateOf<EquipmentEntity?>(null) }
    var showAddVehicleDialog by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AsOneBackground)
    ) {
        // Subtabs
        PrimaryTabRow(
            selectedTabIndex = selectedTab,
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = AsOneBlue
        ) {
            Tab(
                selected = selectedTab == 0,
                onClick = { selectedTab = 0 },
                text = { Text("Matériel & Dépôt", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.Build, contentDescription = null) }
            )
            Tab(
                selected = selectedTab == 1,
                onClick = { selectedTab = 1 },
                text = { Text("Flotte Véhicules (Rappel 7J)", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.AirportShuttle, contentDescription = null) }
            )
        }

        if (selectedTab == 0) {
            EquipmentInventoryTab(
                equipmentList = equipmentList,
                onReturnClick = { selectedEquipmentForReturn = it }
            )
        } else {
            VehicleFleetTab(
                vehicles = vehicles,
                onAddVehicleClick = { showAddVehicleDialog = true }
            )
        }
    }

    // Return Inspection Dialog
    selectedEquipmentForReturn?.let { eq ->
        EquipmentReturnInspectionDialog(
            equipment = eq,
            chantiers = chantiers,
            agents = allUsers.filter { it.role == UserRole.AGENT_CLEANING.name || it.role == UserRole.CHEF_CHANTIER.name },
            onDismiss = { selectedEquipmentForReturn = null },
            onSaveReturn = { qty, condition, isIndulgence, sanctionType, targetAgentId, targetAgentName, chantierId, chantierName, penalty ->
                viewModel.recordEquipmentReturn(
                    equipment = eq,
                    qtyReturned = qty,
                    condition = condition,
                    isIndulgence = isIndulgence,
                    targetAgentId = targetAgentId,
                    targetAgentName = targetAgentName,
                    chantierId = chantierId,
                    chantierName = chantierName,
                    penaltyAmount = penalty,
                    sanctionType = sanctionType
                )
                selectedEquipmentForReturn = null
            }
        )
    }

    if (showAddVehicleDialog) {
        AddVehicleDialog(
            onDismiss = { showAddVehicleDialog = false },
            onAdd = { immat, model, assuranceDate, assuranceDays, vidangeDate, vidangeDays ->
                viewModel.addVehicle(immat, model, assuranceDate, assuranceDays, vidangeDate, vidangeDays)
                showAddVehicleDialog = false
            }
        )
    }
}

@Composable
fun EquipmentInventoryTab(
    equipmentList: List<EquipmentEntity>,
    onReturnClick: (EquipmentEntity) -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = AsOneBlueDark),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(
                        text = "Protection du Matériel AS ONE",
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = "Au retour au dépôt, validez obligatoirement l'état (Bon / Dégradé / Manquant). Le bouton Indulgence évite la pénalité si l'usure est légitime.",
                        color = AsOneSkyBlueLight,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }

        items(equipmentList, key = { it.id }) { eq ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                text = eq.name,
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.titleSmall
                            )
                            StatusBadge(
                                text = eq.category,
                                backgroundColor = if (eq.category == "TRACEABLE") AsOneBlue else AsOneSkyBlue
                            )
                        }
                        Text(
                            text = "En Dépôt: ${eq.availableQuantity} / ${eq.totalQuantity} unités",
                            style = MaterialTheme.typography.bodyMedium,
                            color = AsOneTextSecondary
                        )
                        Text(
                            text = "Valeur unitaire: ${eq.estimatedValue.toInt()} FCFA",
                            style = MaterialTheme.typography.labelSmall,
                            color = AsOneGreen
                        )
                    }

                    Button(
                        onClick = { onReturnClick(eq) },
                        colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Default.FactCheck, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Retour Dépôt", fontSize = 12.sp)
                    }
                }
            }
        }
    }
}

@Composable
fun VehicleFleetTab(
    vehicles: List<VehicleEntity>,
    onAddVehicleClick: () -> Unit
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
                text = "Rappels Sécurité Flotte Véhicules",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Button(
                onClick = onAddVehicleClick,
                colors = ButtonDefaults.buttonColors(containerColor = AsOneBlue),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = null)
                Spacer(modifier = Modifier.width(4.dp))
                Text("Ajouter Véhicule")
            }
        }

        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(vehicles, key = { it.id }) { v ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "${v.immatriculation} - ${v.modelName}",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            StatusBadge(
                                text = "Alerte -7J Active",
                                backgroundColor = Color(0xFFE65100)
                            )
                        }

                        HorizontalDivider()

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Dernière Assurance:", fontSize = 12.sp)
                            Text("${v.lastAssuranceDate} (Valide ${v.assuranceValidityDays}j)", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Dernière Vidange:", fontSize = 12.sp)
                            Text("${v.lastVidangeDate} (Valide ${v.vidangeValidityDays}j)", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EquipmentReturnInspectionDialog(
    equipment: EquipmentEntity,
    chantiers: List<ChantierEntity>,
    agents: List<UserEntity>,
    onDismiss: () -> Unit,
    onSaveReturn: (Int, EquipmentCondition, Boolean, SanctionType, String, String, String, String, Double) -> Unit
) {
    var selectedCondition by remember { mutableStateOf(EquipmentCondition.BON) }
    var isIndulgence by remember { mutableStateOf(true) } // Bouton Indulgence
    var selectedSanction by remember { mutableStateOf(SanctionType.INDIVIDUAL) }
    var selectedChantier by remember { mutableStateOf(chantiers.firstOrNull()) }
    var selectedAgent by remember { mutableStateOf(agents.firstOrNull()) }
    var penaltyAmountStr by remember { mutableStateOf((equipment.estimatedValue * 0.5).toInt().toString()) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Contrôle Retour: ${equipment.name}", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("État de l'outil au retour:", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    FilterChip(
                        selected = selectedCondition == EquipmentCondition.BON,
                        onClick = { selectedCondition = EquipmentCondition.BON },
                        label = { Text("BON") }
                    )
                    FilterChip(
                        selected = selectedCondition == EquipmentCondition.DEGRADE,
                        onClick = { selectedCondition = EquipmentCondition.DEGRADE },
                        label = { Text("DÉGRADÉ") }
                    )
                    FilterChip(
                        selected = selectedCondition == EquipmentCondition.MANQUANT,
                        onClick = { selectedCondition = EquipmentCondition.MANQUANT },
                        label = { Text("MANQUANT") }
                    )
                }

                if (selectedCondition != EquipmentCondition.BON) {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = Color(0xFFFFF3E0)),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(12.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Bouton Indulgence (Usure Légitime)", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                Switch(
                                    checked = isIndulgence,
                                    onCheckedChange = { isIndulgence = it }
                                )
                            }
                            Text(
                                text = if (isIndulgence) "✓ Indulgence accordée: Usure normale ou accident justifié. Pas de pénalité." else "⚠️ Anomalie non justifiée: Litige enregistré pour retenue comptable.",
                                fontSize = 11.sp,
                                color = if (isIndulgence) AsOneGreen else Color(0xFFE65100)
                            )
                        }
                    }

                    if (!isIndulgence) {
                        OutlinedTextField(
                            value = penaltyAmountStr,
                            onValueChange = { penaltyAmountStr = it },
                            label = { Text("Montant Retenue FCFA") },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val penalty = if (selectedCondition != EquipmentCondition.BON && !isIndulgence) {
                        penaltyAmountStr.toDoubleOrNull() ?: 15000.0
                    } else 0.0

                    onSaveReturn(
                        1,
                        selectedCondition,
                        isIndulgence,
                        if (selectedCondition != EquipmentCondition.BON && !isIndulgence) selectedSanction else SanctionType.NONE,
                        selectedAgent?.id ?: "AGT01",
                        selectedAgent?.fullName ?: "Agent Responsable",
                        selectedChantier?.id ?: "CHT01",
                        selectedChantier?.name ?: "Chantier",
                        penalty
                    )
                },
                colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen)
            ) {
                Text("Valider le Retour")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Annuler") }
        }
    )
}

@Composable
fun AddVehicleDialog(
    onDismiss: () -> Unit,
    onAdd: (String, String, String, Int, String, Int) -> Unit
) {
    var immat by remember { mutableStateOf("") }
    var model by remember { mutableStateOf("") }
    var assuranceDate by remember { mutableStateOf("2026-08-01") }
    var vidangeDate by remember { mutableStateOf("2026-07-28") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Enregistrer Nouveau Véhicule", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = immat,
                    onValueChange = { immat = it },
                    label = { Text("Immatriculation (ex: TG-9921-AZ)") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = model,
                    onValueChange = { model = it },
                    label = { Text("Modèle Véhicule / Destination") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = assuranceDate,
                    onValueChange = { assuranceDate = it },
                    label = { Text("Date Dernière Assurance (AAAA-MM-JJ)") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = vidangeDate,
                    onValueChange = { vidangeDate = it },
                    label = { Text("Date Dernière Vidange (AAAA-MM-JJ)") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (immat.isNotBlank()) {
                        onAdd(immat, model, assuranceDate, 365, vidangeDate, 90)
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = AsOneBlue)
            ) {
                Text("Enregistrer")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Annuler") }
        }
    )
}
