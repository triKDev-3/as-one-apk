package com.example.ui.screens

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
fun ComptableScreen(
    viewModel: AsOneViewModel,
    allUsers: List<UserEntity>,
    pointages: List<PointageEntity>,
    transactions: List<EquipmentTransactionEntity>
) {
    var selectedPeriodTab by remember { mutableIntStateOf(0) } // 0 = Temporaires (Clôture 15), 1 = Permanents (Fin de mois)
    var selectedAgentForAdjustment by remember { mutableStateOf<UserEntity?>(null) }
    var showReplacementProtocolDialog by remember { mutableStateOf(false) }

    val agents = allUsers.filter { it.role == UserRole.AGENT_CLEANING.name }
    val temporaires = agents.filter { it.status == AgentStatus.TEMPORAIRE.name }
    val permanents = agents.filter { it.status == AgentStatus.PERMANENT.name }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AsOneBackground)
    ) {
        // Period selector
        PrimaryTabRow(
            selectedTabIndex = selectedPeriodTab,
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = AsOneBlue
        ) {
            Tab(
                selected = selectedPeriodTab == 0,
                onClick = { selectedPeriodTab = 0 },
                text = { Text("Temporaires (Clôture 15)", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.DateRange, contentDescription = null) }
            )
            Tab(
                selected = selectedPeriodTab == 1,
                onClick = { selectedPeriodTab = 1 },
                text = { Text("Permanents (Fin de Mois)", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.AccountBalance, contentDescription = null) }
            )
        }

        // Formula Header Banner
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            colors = CardDefaults.cardColors(containerColor = AsOneBlueDark),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = "Formule Infalsifiable du Solde Net",
                    style = MaterialTheme.typography.titleSmall,
                    color = AsOneGreenLight,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Salaire Net = Brut (Shifts ou Fixe) - Avances - Pénalités (Matériel/Absence) + Primes",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White
                )
            }
        }

        if (selectedPeriodTab == 0) {
            PayrollTemporairesList(
                temporaires = temporaires,
                pointages = pointages,
                transactions = transactions,
                onInjectPrimeOrPenalite = { selectedAgentForAdjustment = it }
            )
        } else {
            PayrollPermanentsList(
                permanents = permanents,
                pointages = pointages,
                transactions = transactions,
                onInjectPrimeOrPenalite = { selectedAgentForAdjustment = it },
                onActivateReplacementProtocol = { showReplacementProtocolDialog = true }
            )
        }
    }

    // Dialogs
    selectedAgentForAdjustment?.let { agent ->
        InjectAdjustmentDialog(
            agent = agent,
            onDismiss = { selectedAgentForAdjustment = null },
            onSave = { primes, advances, penalties, notes ->
                val period = if (agent.status == AgentStatus.TEMPORAIRE.name) "2026-08-15" else "2026-08-31"
                viewModel.savePayrollAdjustment(agent.id, period, primes, advances, penalties, notes)
                selectedAgentForAdjustment = null
            }
        )
    }

    if (showReplacementProtocolDialog) {
        ReplacementProtocolDialog(
            permanents = permanents,
            temporaires = temporaires,
            onDismiss = { showReplacementProtocolDialog = false },
            onApplyOption2 = { perm, temp ->
                // Deduct 1 day prorata from permanent fixed salary and assign shift credit to temporary
                val period = "2026-08-31"
                val dayShare = (perm.fixedMonthlySalary / 26.0).coerceAtLeast(3200.0)
                viewModel.savePayrollAdjustment(
                    agentId = perm.id,
                    period = period,
                    primes = 0.0,
                    advances = 0.0,
                    penalties = dayShare,
                    notes = "Déduction Option 2 Remplacement par ${temp.fullName}"
                )
                viewModel.savePayrollAdjustment(
                    agentId = temp.id,
                    period = "2026-08-15",
                    primes = dayShare,
                    advances = 0.0,
                    penalties = 0.0,
                    notes = "Prise de poste Remplacement Permanent de ${perm.fullName}"
                )
                showReplacementProtocolDialog = false
            }
        )
    }
}

@Composable
fun PayrollTemporairesList(
    temporaires: List<UserEntity>,
    pointages: List<PointageEntity>,
    transactions: List<EquipmentTransactionEntity>,
    onInjectPrimeOrPenalite: (UserEntity) -> Unit
) {
    val totalPayout = temporaires.sumOf { agent ->
        val agentShifts = pointages.filter { it.agentId == agent.id }
        agentShifts.sumOf { it.rateAmount }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
    ) {
        MetricStatCard(
            title = "Total Paie Quinzaine (15 du Mois)",
            value = "${totalPayout.toInt()} FCFA",
            subtitle = "${temporaires.size} Agents Temporaires",
            icon = Icons.Default.Payments,
            color = AsOneGreen,
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 12.dp)
        )

        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(temporaires, key = { it.id }) { agent ->
                val agentShifts = pointages.filter { it.agentId == agent.id }
                val shiftTotal = agentShifts.sumOf { it.rateAmount }
                val penalties = transactions
                    .filter { it.agentOrChefId == agent.id && it.sanctionType != SanctionType.NONE.name }
                    .sumOf { it.penaltyAmount }

                val netSalary = (shiftTotal - penalties).coerceAtLeast(0.0)

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
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
                            Column {
                                Text(
                                    text = agent.fullName,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "Virement: ${agent.phone} (${agent.paymentOperator})",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = AsOneBlue
                                )
                            }
                            StatusBadge(
                                text = "${netSalary.toInt()} FCFA",
                                backgroundColor = AsOneGreen
                            )
                        }

                        HorizontalDivider()

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Shifts Validés (${agentShifts.size}):", fontSize = 12.sp)
                            Text("${shiftTotal.toInt()} F", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        }

                        if (penalties > 0) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Retenues Matériel:", fontSize = 12.sp, color = Color.Red)
                                Text("-${penalties.toInt()} F", fontWeight = FontWeight.Bold, fontSize = 12.sp, color = Color.Red)
                            }
                        }

                        Button(
                            onClick = { onInjectPrimeOrPenalite(agent) },
                            modifier = Modifier.align(Alignment.End),
                            colors = ButtonDefaults.buttonColors(containerColor = AsOneBlue),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Icon(Icons.Default.Tune, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Injecter Prime / Retenue", fontSize = 12.sp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun PayrollPermanentsList(
    permanents: List<UserEntity>,
    pointages: List<PointageEntity>,
    transactions: List<EquipmentTransactionEntity>,
    onInjectPrimeOrPenalite: (UserEntity) -> Unit,
    onActivateReplacementProtocol: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Salaires Fixes Fin de Mois",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            OutlinedButton(
                onClick = onActivateReplacementProtocol,
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.SwapHoriz, contentDescription = null, tint = AsOneGreen)
                Spacer(modifier = Modifier.width(4.dp))
                Text("Protocole Remplacement", fontSize = 12.sp, color = AsOneGreen)
            }
        }

        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(permanents, key = { it.id }) { agent ->
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
                            Column {
                                Text(
                                    text = agent.fullName,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "Salaire Fixe Contractuel: ${agent.fixedMonthlySalary.toInt()} FCFA",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = AsOneTextSecondary
                                )
                            }
                            StatusBadge(
                                text = "${agent.fixedMonthlySalary.toInt()} FCFA",
                                backgroundColor = AsOneBlue
                            )
                        }

                        Button(
                            onClick = { onInjectPrimeOrPenalite(agent) },
                            modifier = Modifier.align(Alignment.End),
                            colors = ButtonDefaults.buttonColors(containerColor = AsOneBlue),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Icon(Icons.Default.Tune, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Ajuster Fiche Paie", fontSize = 12.sp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun InjectAdjustmentDialog(
    agent: UserEntity,
    onDismiss: () -> Unit,
    onSave: (Double, Double, Double, String) -> Unit
) {
    var primeStr by remember { mutableStateOf("0") }
    var advanceStr by remember { mutableStateOf("0") }
    var penaltyStr by remember { mutableStateOf("0") }
    var notes by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Injecter Prime / Retenue - ${agent.fullName}", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = primeStr,
                    onValueChange = { primeStr = it },
                    label = { Text("Prime Forfaitaire (FCFA)") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = advanceStr,
                    onValueChange = { advanceStr = it },
                    label = { Text("Acompte perçu (FCFA)") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = penaltyStr,
                    onValueChange = { penaltyStr = it },
                    label = { Text("Retenue pour litige/absence (FCFA)") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    label = { Text("Motif / Justificatif") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val p = primeStr.toDoubleOrNull() ?: 0.0
                    val a = advanceStr.toDoubleOrNull() ?: 0.0
                    val pen = penaltyStr.toDoubleOrNull() ?: 0.0
                    onSave(p, a, pen, notes)
                },
                colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen)
            ) {
                Text("Valider la Fiche")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Annuler") }
        }
    )
}

@Composable
fun ReplacementProtocolDialog(
    permanents: List<UserEntity>,
    temporaires: List<UserEntity>,
    onDismiss: () -> Unit,
    onApplyOption2: (UserEntity, UserEntity) -> Unit
) {
    var selectedPerm by remember { mutableStateOf(permanents.firstOrNull()) }
    var selectedTemp by remember { mutableStateOf(temporaires.firstOrNull()) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Protocole de Remplacement Permanent", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = "Option 2 (Bascule Directe) : La valeur financière de cette journée est retirée du salaire fixe du permanent absent et versée directement au temporaire.",
                    style = MaterialTheme.typography.bodySmall,
                    color = AsOneTextSecondary
                )

                Text("1. Permanent Absent:", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                permanents.forEach { perm ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        RadioButton(
                            selected = selectedPerm?.id == perm.id,
                            onClick = { selectedPerm = perm }
                        )
                        Text(perm.fullName)
                    }
                }

                Text("2. Temporaire Remplaçant:", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                temporaires.forEach { temp ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        RadioButton(
                            selected = selectedTemp?.id == temp.id,
                            onClick = { selectedTemp = temp }
                        )
                        Text(temp.fullName)
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (selectedPerm != null && selectedTemp != null) {
                        onApplyOption2(selectedPerm!!, selectedTemp!!)
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen)
            ) {
                Text("Bascule Option 2")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Annuler") }
        }
    )
}
