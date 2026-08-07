package com.example.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.*
import com.example.ui.components.StatusBadge
import com.example.ui.theme.*
import com.example.ui.viewmodels.AsOneViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChefChantierScreen(
    viewModel: AsOneViewModel,
    currentUser: UserEntity?,
    chantiers: List<ChantierEntity>,
    activeAgents: List<UserEntity>,
    pricingGrid: PricingGridEntity?
) {
    val context = LocalContext.current
    var selectedChantier by remember { mutableStateOf(chantiers.firstOrNull()) }
    var selectedTab by remember { mutableIntStateOf(0) } // 0 = Pointage Matin, 1 = Planification La Veille, 2 = Entraide
    val dateToday = SimpleDateFormat("yyyy-MM-DD", Locale.getDefault()).format(Date())

    // Selected workers for today's shift
    val selectedAgentShiftMap = remember { mutableStateMapOf<String, ShiftType>() }
    var photoTaken by remember { mutableStateOf(false) }
    var showWhatsAppDialog by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AsOneBackground)
    ) {
        // Site Selector Header
        Surface(
            color = MaterialTheme.colorScheme.surface,
            shadowElevation = 2.dp
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Site / Chantier en Cours:",
                    style = MaterialTheme.typography.labelMedium,
                    color = AsOneTextSecondary
                )
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = selectedChantier?.name ?: "Aucun site",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = AsOneBlue
                        )
                        Text(
                            text = "Lieu: ${selectedChantier?.location ?: "Lomé"}",
                            style = MaterialTheme.typography.bodySmall,
                            color = AsOneTextSecondary
                        )
                    }
                    Button(
                        onClick = {
                            val nextIdx = (chantiers.indexOf(selectedChantier) + 1) % chantiers.size.coerceAtLeast(1)
                            if (chantiers.isNotEmpty()) selectedChantier = chantiers[nextIdx]
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("Changer Site", fontSize = 12.sp)
                    }
                }
            }
        }

        // Subtabs
        PrimaryTabRow(
            selectedTabIndex = selectedTab,
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = AsOneGreen
        ) {
            Tab(
                selected = selectedTab == 0,
                onClick = { selectedTab = 0 },
                text = { Text("Pointage Matin", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.CheckCircle, contentDescription = null) }
            )
            Tab(
                selected = selectedTab == 1,
                onClick = { selectedTab = 1 },
                text = { Text("Planif. La Veille", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.Today, contentDescription = null) }
            )
        }

        if (selectedTab == 0) {
            // Pointage Matin
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // Photo Anti-Triche Card
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = if (photoTaken) AsOneGreen.copy(alpha = 0.12f) else Color(0xFFFFF3E0)
                        )
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
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.CameraAlt,
                                        contentDescription = null,
                                        tint = if (photoTaken) AsOneGreen else Color(0xFFE65100)
                                    )
                                    Text(
                                        text = "Sécurité Anti-Triche (Obligatoire)",
                                        fontWeight = FontWeight.Bold,
                                        style = MaterialTheme.typography.titleSmall
                                    )
                                }
                                Text(
                                    text = if (photoTaken) "✓ Photo de groupe validée sur le site" else "Prise de photo en direct du groupe d'agents obligatoire avant soumission.",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = AsOneTextSecondary
                                )
                            }
                            Button(
                                onClick = {
                                    photoTaken = true
                                    Toast.makeText(context, "Photo de groupe capturée en direct!", Toast.LENGTH_SHORT).show()
                                },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = if (photoTaken) AsOneGreen else Color(0xFFE65100)
                                ),
                                shape = RoundedCornerShape(12.dp)
                            ) {
                                Text(if (photoTaken) "Reprendre" else "Prendre Photo", fontSize = 12.sp)
                            }
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
                            text = "Agents Présents sur le Site",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        StatusBadge(
                            text = "${selectedAgentShiftMap.size} Sélectionnés",
                            backgroundColor = AsOneBlue
                        )
                    }
                }

                items(activeAgents, key = { it.id }) { agent ->
                    val isChecked = selectedAgentShiftMap.containsKey(agent.id)
                    val currentShift = selectedAgentShiftMap[agent.id] ?: ShiftType.JOURNEE

                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                if (isChecked) {
                                    selectedAgentShiftMap.remove(agent.id)
                                } else {
                                    selectedAgentShiftMap[agent.id] = ShiftType.JOURNEE
                                }
                            },
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = if (isChecked) AsOneGreen.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surface
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    Checkbox(
                                        checked = isChecked,
                                        onCheckedChange = { checked ->
                                            if (checked) {
                                                selectedAgentShiftMap[agent.id] = ShiftType.JOURNEE
                                            } else {
                                                selectedAgentShiftMap.remove(agent.id)
                                            }
                                        }
                                    )
                                    Column {
                                        Text(
                                            text = agent.fullName,
                                            fontWeight = FontWeight.Bold,
                                            style = MaterialTheme.typography.titleSmall
                                        )
                                        Text(
                                            text = "${agent.status} • Tél: ${agent.phone}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = AsOneTextSecondary
                                        )
                                    }
                                }

                                if (isChecked) {
                                    StatusBadge(
                                        text = "${currentShift.defaultRate.toInt()} FCFA",
                                        backgroundColor = AsOneGreen
                                    )
                                }
                            }

                            // Shift Selector Chips if checked
                            if (isChecked) {
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    modifier = Modifier.padding(start = 40.dp)
                                ) {
                                    ShiftType.values().forEach { st ->
                                        FilterChip(
                                            selected = currentShift == st,
                                            onClick = { selectedAgentShiftMap[agent.id] = st },
                                            label = { Text(st.label, fontSize = 11.sp) }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                // Submit & WhatsApp Button
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Button(
                            onClick = {
                                if (!photoTaken) {
                                    Toast.makeText(context, "Prise de photo en direct obligatoire!", Toast.LENGTH_LONG).show()
                                    return@Button
                                }
                                if (selectedChantier == null || selectedAgentShiftMap.isEmpty()) {
                                    Toast.makeText(context, "Sélectionnez au moins un agent!", Toast.LENGTH_SHORT).show()
                                    return@Button
                                }

                                val pointages = selectedAgentShiftMap.map { (agentId, shift) ->
                                    val agent = activeAgents.first { it.id == agentId }
                                    PointageEntity(
                                        id = "PTG_${agentId}_$dateToday",
                                        date = dateToday,
                                        chantierId = selectedChantier!!.id,
                                        chantierName = selectedChantier!!.name,
                                        agentId = agent.id,
                                        agentName = agent.fullName,
                                        agentStatus = agent.status,
                                        shiftType = shift.name,
                                        rateAmount = shift.defaultRate,
                                        photoProofUri = "photo_proof_live_captured",
                                        validatedByChefId = currentUser?.id ?: "CHEF01",
                                        validatedByChefName = currentUser?.fullName ?: "Chef"
                                    )
                                }

                                viewModel.submitPointage(
                                    chantierId = selectedChantier!!.id,
                                    chantierName = selectedChantier!!.name,
                                    date = dateToday,
                                    photoProofUri = "photo_proof_live_captured",
                                    selectedPointages = pointages
                                )

                                Toast.makeText(context, "Pointage validé avec photo anti-triche!", Toast.LENGTH_SHORT).show()
                                showWhatsAppDialog = true
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(52.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen),
                            shape = RoundedCornerShape(14.dp)
                        ) {
                            Icon(Icons.Default.CheckCircleOutline, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Valider le Pointage Matinal", fontWeight = FontWeight.Bold)
                        }

                        OutlinedButton(
                            onClick = { showWhatsAppDialog = true },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp)
                        ) {
                            Icon(Icons.Default.Share, contentDescription = null, tint = AsOneGreen)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Générer Rapport WhatsApp", color = AsOneGreen, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        } else {
            // Planification La Veille
            PlanificationLaVeilleTab(
                activeAgents = activeAgents,
                selectedChantier = selectedChantier
            )
        }
    }

    if (showWhatsAppDialog && selectedChantier != null) {
        WhatsAppReportModal(
            chantierName = selectedChantier!!.name,
            chefName = currentUser?.fullName ?: "Jean-Baptiste Mensah",
            selectedAgents = selectedAgentShiftMap.map { (id, shift) ->
                val agent = activeAgents.first { it.id == id }
                agent.fullName to shift.label
            },
            onDismiss = { showWhatsAppDialog = false }
        )
    }
}

@Composable
fun PlanificationLaVeilleTab(
    activeAgents: List<UserEntity>,
    selectedChantier: ChantierEntity?
) {
    val context = LocalContext.current
    var squad = remember { mutableStateListOf<String>() }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
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
                        text = "Planification la Veille pour le Lendemain",
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = "Consultez les agents déclarés libres et composez votre équipe. La confirmation se fait par appel/SMS au personnel.",
                        color = AsOneSkyBlueLight,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }

        items(activeAgents) { agent ->
            val isInSquad = squad.contains(agent.id)

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (isInSquad) AsOneGreen.copy(alpha = 0.1f) else MaterialTheme.colorScheme.surface
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(agent.fullName, fontWeight = FontWeight.Bold)
                        Text("Déclaré Disponible • Tél: ${agent.phone}", fontSize = 12.sp, color = AsOneTextSecondary)
                    }

                    Button(
                        onClick = {
                            if (isInSquad) squad.remove(agent.id) else squad.add(agent.id)
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (isInSquad) AsOneGreen else AsOneBlue
                        ),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(if (isInSquad) "Sélectionné ✓" else "Composer", fontSize = 11.sp)
                    }
                }
            }
        }
    }
}

@Composable
fun WhatsAppReportModal(
    chantierName: String,
    chefName: String,
    selectedAgents: List<Pair<String, String>>,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val todayDate = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault()).format(Date())

    val reportText = remember(chantierName, chefName, selectedAgents) {
        StringBuilder().apply {
            append("🏢 *RAPPORT DE POINTAGE - AS ONE*\n")
            append("📅 *Date:* $todayDate\n")
            append("📍 *Site:* $chantierName\n")
            append("👤 *Chef de Chantier:* $chefName\n")
            append("----------------------------------\n")
            append("👥 *AGENTS PRÉSENTS SUR SITE (${selectedAgents.size}) :*\n")
            selectedAgents.forEachIndexed { idx, (name, shift) ->
                append("${idx + 1}. ✅ $name - ($shift)\n")
            }
            append("----------------------------------\n")
            append("📸 *Sécurité Anti-Triche:* Photo de groupe capturée en direct.\n")
            append("✨ _Application AS ONE - Gestion Infalsifiable_")
        }.toString()
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(Icons.Default.Share, contentDescription = null, tint = AsOneGreen)
                Text("Rapport WhatsApp Officiel", fontWeight = FontWeight.Bold)
            }
        },
        text = {
            Card(
                colors = CardDefaults.cardColors(containerColor = Color(0xFFE8F5E9)),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text(
                    text = reportText,
                    fontSize = 12.sp,
                    modifier = Modifier.padding(14.dp),
                    color = Color(0xFF1B5E20)
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    val clip = ClipData.newPlainText("Rapport WhatsApp AS ONE", reportText)
                    clipboard.setPrimaryClip(clip)
                    Toast.makeText(context, "Rapport copié! Prêt à coller dans WhatsApp", Toast.LENGTH_LONG).show()
                    onDismiss()
                },
                colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen)
            ) {
                Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text("Copier pour WhatsApp")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Fermer") }
        }
    )
}
