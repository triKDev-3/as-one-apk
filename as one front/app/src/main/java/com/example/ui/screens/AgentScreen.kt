package com.example.ui.screens

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
import androidx.compose.ui.graphics.Brush
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
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AgentScreen(
    viewModel: AsOneViewModel,
    currentUser: UserEntity?,
    pointages: List<PointageEntity>,
    transactions: List<EquipmentTransactionEntity>
) {
    var selectedTab by remember { mutableIntStateOf(0) } // 0 = Mon Solde & Shifts, 1 = Disponibilités, 2 = Mon Profil
    val agentId = currentUser?.id ?: "AGT01"
    val agentPointages = pointages.filter { it.agentId == agentId }
    val agentPenalties = transactions.filter { it.agentOrChefId == agentId && it.penaltyAmount > 0 }

    val totalShiftsEarnings = agentPointages.sumOf { it.rateAmount }
    val totalPenalties = agentPenalties.sumOf { it.penaltyAmount }
    val netBalance = (totalShiftsEarnings - totalPenalties).coerceAtLeast(0.0)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AsOneBackground)
    ) {
        // Agent Subtabs
        PrimaryTabRow(
            selectedTabIndex = selectedTab,
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = AsOneGreen
        ) {
            Tab(
                selected = selectedTab == 0,
                onClick = { selectedTab = 0 },
                text = { Text("Mon Solde", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.AccountBalanceWallet, contentDescription = null) }
            )
            Tab(
                selected = selectedTab == 1,
                onClick = { selectedTab = 1 },
                text = { Text("Disponibilités", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.CalendarMonth, contentDescription = null) }
            )
            Tab(
                selected = selectedTab == 2,
                onClick = { selectedTab = 2 },
                text = { Text("Mon Profil", fontWeight = FontWeight.Bold) },
                icon = { Icon(Icons.Default.Person, contentDescription = null) }
            )
        }

        when (selectedTab) {
            0 -> AgentBalanceTab(
                currentUser = currentUser,
                netBalance = netBalance,
                agentPointages = agentPointages,
                agentPenalties = agentPenalties
            )
            1 -> AgentAvailabilityTab(
                viewModel = viewModel,
                agentId = agentId,
                agentPointages = agentPointages
            )
            2 -> AgentProfileTab(
                currentUser = currentUser,
                onUpdateProfile = { name, phone, operator ->
                    viewModel.updateAgentSelfProfile(name, phone, operator)
                }
            )
        }
    }
}

@Composable
fun AgentBalanceTab(
    currentUser: UserEntity?,
    netBalance: Double,
    agentPointages: List<PointageEntity>,
    agentPenalties: List<EquipmentTransactionEntity>
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = AsOneGreen),
                shape = RoundedCornerShape(20.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Transparence Totale des Gains",
                            style = MaterialTheme.typography.labelMedium,
                            color = Color.White.copy(alpha = 0.8f)
                        )
                        StatusBadge(
                            text = currentUser?.paymentOperator ?: "T-Money",
                            backgroundColor = AsOneBlue
                        )
                    }

                    Text(
                        text = "${netBalance.toInt()} FCFA",
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )

                    Text(
                        text = "Solde accumulé pour la période en cours (${currentUser?.status ?: "TEMPORAIRE"}). Aucun litige les jours de paie.",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.9f)
                    )
                }
            }
        }

        item {
            Text(
                text = "Détail de mes Vacations Validées (${agentPointages.size})",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }

        if (agentPointages.isEmpty()) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Text(
                        text = "Aucun shift pointé récemment.",
                        modifier = Modifier.padding(16.dp),
                        color = AsOneTextSecondary
                    )
                }
            }
        }

        items(agentPointages) { ptg ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
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
                            text = ptg.chantierName,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Date: ${ptg.date} • Shift: ${ptg.shiftType}",
                            style = MaterialTheme.typography.bodySmall,
                            color = AsOneTextSecondary
                        )
                        Text(
                            text = "Validé par: ${ptg.validatedByChefName}",
                            style = MaterialTheme.typography.labelSmall,
                            color = AsOneBlue
                        )
                    }
                    StatusBadge(
                        text = "+${ptg.rateAmount.toInt()} F",
                        backgroundColor = AsOneGreen
                    )
                }
            }
        }

        if (agentPenalties.isNotEmpty()) {
            item {
                Text(
                    text = "Pénalités Retenues",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.Red
                )
            }

            items(agentPenalties) { pen ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFFFEBEE))
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(pen.equipmentName, fontWeight = FontWeight.Bold, color = Color.Red)
                            Text("Pénalité Matériel (${pen.condition})", fontSize = 12.sp, color = AsOneTextSecondary)
                        }
                        Text("-${pen.penaltyAmount.toInt()} F", fontWeight = FontWeight.Bold, color = Color.Red)
                    }
                }
            }
        }
    }
}

@Composable
fun AgentAvailabilityTab(
    viewModel: AsOneViewModel,
    agentId: String,
    agentPointages: List<PointageEntity>
) {
    val context = LocalContext.current
    var isContinuousAvailability by remember { mutableStateOf(false) }
    var selectedAgendaSubTab by remember { mutableIntStateOf(0) } // 0 = Calendrier Carré (Mois), 1 = Shifts Programmés (Accepter/Décliner), 2 = Jours Pointés/Travaillés

    // Sample/demo programmed shifts assigned by chefs to this agent (Accepté par défaut)
    var programmedShifts by remember {
        mutableStateOf(
            listOf(
                ScheduledShift(
                    id = "PROG_01",
                    date = "2026-08-08",
                    chantierName = "Tour Lomé 2000 (BTP)",
                    chefName = "Koffi Mensah",
                    shiftType = "JOURNEE",
                    rateAmount = 2500.0,
                    status = ShiftAssignmentState.ACCEPTED
                ),
                ScheduledShift(
                    id = "PROG_02",
                    date = "2026-08-12",
                    chantierName = "Résidence Palm Beach",
                    chefName = "Amina Diallo",
                    shiftType = "NUIT",
                    rateAmount = 4500.0,
                    status = ShiftAssignmentState.ACCEPTED
                ),
                ScheduledShift(
                    id = "PROG_03",
                    date = "2026-08-04",
                    chantierName = "Aéroport International",
                    chefName = "Koffi Mensah",
                    shiftType = "JOURNEE",
                    rateAmount = 2500.0,
                    status = ShiftAssignmentState.ACCEPTED
                )
            )
        )
    }

    // Set of custom manually declared available dates (YYYY-MM-DD)
    var customAvailableDates by remember {
        mutableStateOf(setOf("2026-08-01", "2026-08-02", "2026-08-05", "2026-08-08", "2026-08-12", "2026-08-15", "2026-08-20"))
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // --- 1. BOUTON EN HAUT : ACTIVATION CONTINUELLE (ON / OFF) ---
        item {
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = if (isContinuousAvailability) AsOneGreen else AsOneBlueDark
                ),
                shape = RoundedCornerShape(20.dp),
                elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
                modifier = Modifier.fillMaxWidth()
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
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(42.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (isContinuousAvailability) Color.White.copy(alpha = 0.25f) else AsOneSkyBlue.copy(alpha = 0.3f)
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = if (isContinuousAvailability) Icons.Default.AllInclusive else Icons.Default.EventAvailable,
                                    contentDescription = null,
                                    tint = Color.White,
                                    modifier = Modifier.size(24.dp)
                                )
                            }

                            Column {
                                Text(
                                    text = "DISPONIBILITÉ PERMANENTE",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = AsOneSkyBlueLight,
                                    fontWeight = FontWeight.ExtraBold
                                )
                                Text(
                                    text = if (isContinuousAvailability) "Mode Continu : ACTIVÉ (7j/7)" else "Mode Continu : DÉSACTIVÉ",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White
                                )
                            }
                        }

                        // Switch ON / OFF
                        Switch(
                            checked = isContinuousAvailability,
                            onCheckedChange = { checked ->
                                isContinuousAvailability = checked
                                val msg = if (checked) {
                                    "Disponibilité continuelle ACTIVÉE 7j/7 sur tout le calendrier !"
                                } else {
                                    "Mode continuel DÉSACTIVÉ. Gestion jour par jour rétablie."
                                }
                                Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
                            },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = AsOneGreen,
                                checkedTrackColor = Color.White,
                                uncheckedThumbColor = Color.White,
                                uncheckedTrackColor = AsOneBlue
                            )
                        )
                    }

                    HorizontalDivider(color = Color.White.copy(alpha = 0.2f))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = if (isContinuousAvailability) {
                                "Vous êtes automatiquement déclaré LIBRE chaque jour du mois pour les chefs de chantier."
                            } else {
                                "Activez ce bouton pour être constamment disponible sans cocher chaque case du mois."
                            },
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.9f),
                            modifier = Modifier.weight(1f),
                            fontSize = 11.sp
                        )

                        Spacer(modifier = Modifier.width(8.dp))

                        Button(
                            onClick = {
                                isContinuousAvailability = !isContinuousAvailability
                                val msg = if (isContinuousAvailability) {
                                    "Disponibilité continuelle ACTIVÉE !"
                                } else {
                                    "Mode continuel DÉSACTIVÉ."
                                }
                                Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
                            },
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (isContinuousAvailability) Color.White else AsOneGreen,
                                contentColor = if (isContinuousAvailability) AsOneGreenDark else Color.White
                            ),
                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                        ) {
                            Icon(
                                imageVector = if (isContinuousAvailability) Icons.Default.CheckCircle else Icons.Default.PowerSettingsNew,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = if (isContinuousAvailability) "ON (Permanent)" else "Activer ON",
                                fontWeight = FontWeight.Bold,
                                fontSize = 11.sp
                            )
                        }
                    }
                }
            }
        }

        // --- 2. SUB-VIEW SELECTOR CHIPS ---
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                FilterChip(
                    selected = selectedAgendaSubTab == 0,
                    onClick = { selectedAgendaSubTab = 0 },
                    label = { Text("Calendrier Carré", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                    leadingIcon = { Icon(Icons.Default.CalendarMonth, contentDescription = null, modifier = Modifier.size(14.dp)) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = AsOneBlue,
                        selectedLabelColor = Color.White
                    )
                )

                FilterChip(
                    selected = selectedAgendaSubTab == 1,
                    onClick = { selectedAgendaSubTab = 1 },
                    label = {
                        val pendingCount = programmedShifts.count { it.status == ShiftAssignmentState.PROGRAMMED }
                        Text(if (pendingCount > 0) "Shifts ($pendingCount 🔔)" else "Shifts", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                    },
                    leadingIcon = { Icon(Icons.Default.AssignmentInd, contentDescription = null, modifier = Modifier.size(14.dp)) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = AsOneGreen,
                        selectedLabelColor = Color.White
                    )
                )

                FilterChip(
                    selected = selectedAgendaSubTab == 2,
                    onClick = { selectedAgendaSubTab = 2 },
                    label = { Text("Jours Pointés (${agentPointages.size})", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                    leadingIcon = { Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(14.dp)) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = AsOneSkyBlue,
                        selectedLabelColor = AsOneBlueDark
                    )
                )
            }
        }

        // --- 3. DYNAMIC CONTENT BASED ON SELECTED SUB-TAB ---
        when (selectedAgendaSubTab) {
            0 -> {
                // SUB-TAB 0: CARRÉ AGENDA MENSUEL (GRID)
                item {
                    MonthlySquareCalendarView(
                        isContinuousAvailability = isContinuousAvailability,
                        customAvailableDates = customAvailableDates,
                        onToggleCustomDate = { dateStr ->
                            customAvailableDates = if (customAvailableDates.contains(dateStr)) {
                                customAvailableDates - dateStr
                            } else {
                                customAvailableDates + dateStr
                            }
                        },
                        programmedShifts = programmedShifts,
                        agentPointages = agentPointages
                    )
                }
            }
            1 -> {
                // SUB-TAB 1: PROGRAMMATIONS & APPROBATION PAR L'AGENT
                item {
                    ProgrammedShiftsView(
                        programmedShifts = programmedShifts,
                        onAcceptShift = { shiftId ->
                            programmedShifts = programmedShifts.map { shift ->
                                if (shift.id == shiftId) shift.copy(status = ShiftAssignmentState.ACCEPTED) else shift
                            }
                            Toast.makeText(context, "Shift accepté ! Le chef de chantier a été notifié.", Toast.LENGTH_SHORT).show()
                        },
                        onDeclineShift = { shiftId ->
                            programmedShifts = programmedShifts.map { shift ->
                                if (shift.id == shiftId) shift.copy(status = ShiftAssignmentState.DECLINED) else shift
                            }
                            Toast.makeText(context, "Shift décliné. Vous êtes libéré pour cette journée.", Toast.LENGTH_SHORT).show()
                        }
                    )
                }
            }
            2 -> {
                // SUB-TAB 2: AGENDA DES JOURS POINTÉS ET TRAVAILLÉS
                item {
                    WorkedDaysAgendaView(
                        agentPointages = agentPointages
                    )
                }
            }
        }
    }
}

// --- COMPOSABLE: MONTHLY SQUARE CALENDAR GRID VIEW ---
@Composable
fun MonthlySquareCalendarView(
    isContinuousAvailability: Boolean,
    customAvailableDates: Set<String>,
    onToggleCustomDate: (String) -> Unit,
    programmedShifts: List<ScheduledShift>,
    agentPointages: List<PointageEntity>
) {
    val context = LocalContext.current

    // Month calendar navigation state
    var calendarMonthOffset by remember { mutableIntStateOf(0) } // 0 = current month
    val calendar = remember(calendarMonthOffset) {
        Calendar.getInstance().apply {
            add(Calendar.MONTH, calendarMonthOffset)
            set(Calendar.DAY_OF_MONTH, 1)
        }
    }

    val monthYearFormat = SimpleDateFormat("MMMM yyyy", Locale.FRANCE)
    val monthTitle = monthYearFormat.format(calendar.time).replaceFirstChar { it.uppercase() }

    val currentYear = calendar.get(Calendar.YEAR)
    val currentMonthIndex = calendar.get(Calendar.MONTH) + 1 // 1..12
    val monthString = String.format(Locale.US, "%04d-%02d", currentYear, currentMonthIndex)

    val maxDaysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
    // Convert Sunday=1..Saturday=7 to Monday=0..Sunday=6
    val firstDayOfWeek = (calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7

    var selectedDayNumber by remember { mutableStateOf<Int?>(Calendar.getInstance().get(Calendar.DAY_OF_MONTH)) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = AsOneSurface),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header: Month Navigation
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = { calendarMonthOffset-- },
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(AsOneSkyBlue.copy(alpha = 0.2f))
                ) {
                    Icon(Icons.Default.ChevronLeft, contentDescription = "Mois précédent", tint = AsOneBlue)
                }

                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = monthTitle,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.ExtraBold,
                        color = AsOneBlueDark
                    )
                    Text(
                        text = "Agenda Carré Mensuel • Cliquer sur un jour",
                        style = MaterialTheme.typography.labelSmall,
                        color = AsOneTextSecondary,
                        fontSize = 10.sp
                    )
                }

                IconButton(
                    onClick = { calendarMonthOffset++ },
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(AsOneSkyBlue.copy(alpha = 0.2f))
                ) {
                    Icon(Icons.Default.ChevronRight, contentDescription = "Mois suivant", tint = AsOneBlue)
                }
            }

            HorizontalDivider(color = AsOneCardBorder)

            // Days of week header row (LUN, MAR, MER, JEU, VEN, SAM, DIM)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                val dayHeaders = listOf("LUN", "MAR", "MER", "JEU", "VEN", "SAM", "DIM")
                dayHeaders.forEach { header ->
                    Text(
                        text = header,
                        modifier = Modifier.weight(1f),
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.ExtraBold,
                        color = AsOneBlue,
                        fontSize = 10.sp
                    )
                }
            }

            // Square Calendar Grid (6 rows x 7 cols max)
            val totalCells = firstDayOfWeek + maxDaysInMonth
            val totalRows = (totalCells + 6) / 7

            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                for (rowIndex in 0 until totalRows) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        for (colIndex in 0 until 7) {
                            val cellIndex = rowIndex * 7 + colIndex
                            val dayNumber = cellIndex - firstDayOfWeek + 1

                            if (dayNumber in 1..maxDaysInMonth) {
                                val dateStr = String.format(Locale.US, "%s-%02d", monthString, dayNumber)

                                // States for this day
                                val isPointed = agentPointages.any { it.date == dateStr }
                                val shiftProg = programmedShifts.firstOrNull { it.date == dateStr }
                                val isAvailable = isContinuousAvailability || customAvailableDates.contains(dateStr)
                                val isSelected = selectedDayNumber == dayNumber

                                // Square Box with aspectRatio(1f)
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .aspectRatio(1f)
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(
                                            when {
                                                isPointed -> AsOneGreen.copy(alpha = 0.25f)
                                                shiftProg?.status == ShiftAssignmentState.ACCEPTED -> AsOneSkyBlue.copy(alpha = 0.35f)
                                                shiftProg?.status == ShiftAssignmentState.DECLINED -> Color.Red.copy(alpha = 0.15f)
                                                shiftProg?.status == ShiftAssignmentState.PROGRAMMED -> Color(0xFFFFF3CD)
                                                isAvailable -> AsOneGreen.copy(alpha = 0.12f)
                                                else -> Color(0xFFF1F5F9)
                                            }
                                        )
                                        .border(
                                            width = if (isSelected) 2.dp else 1.dp,
                                            color = when {
                                                isSelected -> AsOneBlueDark
                                                isPointed -> AsOneGreen
                                                shiftProg?.status == ShiftAssignmentState.DECLINED -> Color.Red
                                                shiftProg?.status == ShiftAssignmentState.PROGRAMMED -> Color(0xFFFFB800)
                                                isAvailable -> AsOneGreen
                                                else -> AsOneCardBorder
                                            },
                                            shape = RoundedCornerShape(8.dp)
                                        )
                                        .clickable {
                                            selectedDayNumber = dayNumber
                                            if (!isContinuousAvailability) {
                                                onToggleCustomDate(dateStr)
                                            }
                                        },
                                    contentAlignment = Alignment.Center
                                ) {
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        verticalArrangement = Arrangement.Center
                                    ) {
                                        Text(
                                            text = dayNumber.toString(),
                                            fontWeight = if (isSelected || isPointed) FontWeight.ExtraBold else FontWeight.Bold,
                                            fontSize = 12.sp,
                                            color = when {
                                                shiftProg?.status == ShiftAssignmentState.DECLINED -> Color.Red
                                                isPointed -> AsOneGreenDark
                                                isAvailable -> AsOneBlueDark
                                                else -> AsOneTextPrimary
                                            }
                                        )

                                        // Status Dot / Icon
                                        if (isPointed) {
                                            Icon(
                                                imageVector = Icons.Default.Check,
                                                contentDescription = null,
                                                tint = AsOneGreenDark,
                                                modifier = Modifier.size(10.dp)
                                            )
                                        } else if (shiftProg != null) {
                                            when (shiftProg.status) {
                                                ShiftAssignmentState.PROGRAMMED -> {
                                                    Icon(
                                                        imageVector = Icons.Default.NotificationsActive,
                                                        contentDescription = null,
                                                        tint = Color(0xFFD97706),
                                                        modifier = Modifier.size(10.dp)
                                                    )
                                                }
                                                ShiftAssignmentState.ACCEPTED -> {
                                                    Icon(
                                                        imageVector = Icons.Default.ThumbUp,
                                                        contentDescription = null,
                                                        tint = AsOneBlue,
                                                        modifier = Modifier.size(10.dp)
                                                    )
                                                }
                                                ShiftAssignmentState.DECLINED -> {
                                                    Icon(
                                                        imageVector = Icons.Default.Close,
                                                        contentDescription = null,
                                                        tint = Color.Red,
                                                        modifier = Modifier.size(10.dp)
                                                    )
                                                }
                                            }
                                        } else if (isAvailable) {
                                            Box(
                                                modifier = Modifier
                                                    .size(5.dp)
                                                    .clip(CircleShape)
                                                    .background(AsOneGreen)
                                            )
                                        }
                                    }
                                }
                            } else {
                                // Empty square filler cell
                                Spacer(
                                    modifier = Modifier
                                        .weight(1f)
                                        .aspectRatio(1f)
                                )
                            }
                        }
                    }
                }
            }

            // Legend / Color Key
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 4.dp),
                horizontalArrangement = Arrangement.SpaceAround,
                verticalAlignment = Alignment.CenterVertically
            ) {
                LegendDotItem(color = AsOneGreen, label = "Libre")
                LegendDotItem(color = Color(0xFFFFB800), label = "Programmé")
                LegendDotItem(color = AsOneBlue, label = "Accepté")
                LegendDotItem(color = AsOneGreenDark, label = "Pointé ✓")
                LegendDotItem(color = Color.Red, label = "Décliné ✗")
            }

            // Details for Selected Day
            if (selectedDayNumber != null) {
                val selectedDateStr = String.format(Locale.US, "%s-%02d", monthString, selectedDayNumber)
                val pointageOnDate = agentPointages.firstOrNull { it.date == selectedDateStr }
                val shiftOnDate = programmedShifts.firstOrNull { it.date == selectedDateStr }
                val isLibre = isContinuousAvailability || customAvailableDates.contains(selectedDateStr)

                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = Color(0xFFF8FAFC),
                    shape = RoundedCornerShape(12.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, AsOneCardBorder)
                ) {
                    Column(
                        modifier = Modifier.padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Détails du Jour $selectedDayNumber $monthTitle :",
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.titleSmall,
                                color = AsOneBlueDark
                            )

                            StatusBadge(
                                text = when {
                                    pointageOnDate != null -> "Jour Travaillé & Pointé ✓"
                                    shiftOnDate?.status == ShiftAssignmentState.ACCEPTED -> "Programmation Acceptée"
                                    shiftOnDate?.status == ShiftAssignmentState.DECLINED -> "Décliné par Agent"
                                    shiftOnDate?.status == ShiftAssignmentState.PROGRAMMED -> "En Attente de Confirmation"
                                    isLibre -> "Disponible"
                                    else -> "Non Libre"
                                },
                                backgroundColor = when {
                                    pointageOnDate != null -> AsOneGreen
                                    shiftOnDate?.status == ShiftAssignmentState.DECLINED -> Color.Red
                                    shiftOnDate != null -> AsOneBlue
                                    isLibre -> AsOneGreen
                                    else -> Color.Gray
                                }
                            )
                        }

                        if (pointageOnDate != null) {
                            Text(
                                text = "• Chantier : ${pointageOnDate.chantierName}\n• Shift : ${pointageOnDate.shiftType} (${pointageOnDate.rateAmount.toInt()} FCFA)\n• Chef Valideur : ${pointageOnDate.validatedByChefName}",
                                style = MaterialTheme.typography.bodySmall,
                                color = AsOneTextPrimary
                            )
                        } else if (shiftOnDate != null) {
                            Text(
                                text = "• Programmation par le chef : ${shiftOnDate.chefName}\n• Chantier : ${shiftOnDate.chantierName}\n• Shift : ${shiftOnDate.shiftType} (${shiftOnDate.rateAmount.toInt()} FCFA)",
                                style = MaterialTheme.typography.bodySmall,
                                color = AsOneTextPrimary
                            )
                        } else {
                            Text(
                                text = if (isLibre) "Vous êtes déclaré libre pour être affecté sur un chantier." else "Journée non sélectionnée comme disponible.",
                                style = MaterialTheme.typography.bodySmall,
                                color = AsOneTextSecondary
                            )
                        }
                    }
                }
            }
        }
    }
}

// --- COMPOSABLE: PROGRAMMED SHIFTS VIEW (WITH ACCEPTER / DECLINER) ---
@Composable
fun ProgrammedShiftsView(
    programmedShifts: List<ScheduledShift>,
    onAcceptShift: (String) -> Unit,
    onDeclineShift: (String) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = AsOneSurface),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
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
                Column {
                    Text(
                        text = "Programmations & Affectations Chefs",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = AsOneTextPrimary
                    )
                    Text(
                        text = "Consultez vos convocations et choisissez d'accepter ou décliner",
                        style = MaterialTheme.typography.bodySmall,
                        color = AsOneTextSecondary,
                        fontSize = 11.sp
                    )
                }

                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(AsOneBlue.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.AssignmentInd,
                        contentDescription = null,
                        tint = AsOneBlue
                    )
                }
            }

            HorizontalDivider(color = AsOneCardBorder)

            if (programmedShifts.isEmpty()) {
                Text(
                    text = "Aucune programmation en cours pour le moment.",
                    style = MaterialTheme.typography.bodySmall,
                    color = AsOneTextSecondary,
                    modifier = Modifier.padding(vertical = 12.dp)
                )
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    programmedShifts.forEach { shift ->
                        Surface(
                            modifier = Modifier.fillMaxWidth(),
                            color = when (shift.status) {
                                ShiftAssignmentState.ACCEPTED -> AsOneGreen.copy(alpha = 0.08f)
                                ShiftAssignmentState.DECLINED -> Color.Red.copy(alpha = 0.06f)
                                ShiftAssignmentState.PROGRAMMED -> Color(0xFFFFFBEB)
                            },
                            shape = RoundedCornerShape(14.dp),
                            border = androidx.compose.foundation.BorderStroke(
                                width = 1.dp,
                                color = when (shift.status) {
                                    ShiftAssignmentState.ACCEPTED -> AsOneGreen
                                    ShiftAssignmentState.DECLINED -> Color.Red
                                    ShiftAssignmentState.PROGRAMMED -> Color(0xFFF59E0B)
                                }
                            )
                        ) {
                            Column(
                                modifier = Modifier.padding(14.dp),
                                verticalArrangement = Arrangement.spacedBy(10.dp)
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
                                        Icon(
                                            imageVector = Icons.Default.Event,
                                            contentDescription = null,
                                            tint = AsOneBlue,
                                            modifier = Modifier.size(18.dp)
                                        )
                                        Text(
                                            text = "Date : ${shift.date}",
                                            fontWeight = FontWeight.ExtraBold,
                                            style = MaterialTheme.typography.titleSmall,
                                            color = AsOneBlueDark
                                        )
                                    }

                                    StatusBadge(
                                        text = when (shift.status) {
                                            ShiftAssignmentState.PROGRAMMED -> "EN ATTENTE 🔔"
                                            ShiftAssignmentState.ACCEPTED -> "ACCEPTÉ ✓"
                                            ShiftAssignmentState.DECLINED -> "DÉCLINÉ ✗"
                                        },
                                        backgroundColor = when (shift.status) {
                                            ShiftAssignmentState.PROGRAMMED -> Color(0xFFF59E0B)
                                            ShiftAssignmentState.ACCEPTED -> AsOneGreen
                                            ShiftAssignmentState.DECLINED -> Color.Red
                                        }
                                    )
                                }

                                HorizontalDivider(color = AsOneCardBorder.copy(alpha = 0.5f))

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                        Text(
                                            text = "Chantier : ${shift.chantierName}",
                                            fontWeight = FontWeight.Bold,
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = AsOneTextPrimary
                                        )
                                        Text(
                                            text = "Chef convocateur : ${shift.chefName}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = AsOneTextSecondary
                                        )
                                    }

                                    Column(horizontalAlignment = Alignment.End) {
                                        Text(
                                            text = "${shift.rateAmount.toInt()} FCFA",
                                            fontWeight = FontWeight.ExtraBold,
                                            color = AsOneGreenDark,
                                            fontSize = 15.sp
                                        )
                                        Text(
                                            text = "Shift ${shift.shiftType}",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = AsOneBlue
                                        )
                                    }
                                }

                                // Action Buttons: ACCEPTER / DECLINER (Actif & Modifiable à tout moment)
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    val isAccepted = shift.status == ShiftAssignmentState.ACCEPTED || shift.status == ShiftAssignmentState.PROGRAMMED
                                    
                                    Button(
                                        onClick = { onAcceptShift(shift.id) },
                                        modifier = Modifier.weight(1f),
                                        shape = RoundedCornerShape(10.dp),
                                        colors = ButtonDefaults.buttonColors(
                                            containerColor = if (isAccepted) AsOneGreen else Color.LightGray.copy(alpha = 0.3f),
                                            contentColor = if (isAccepted) Color.White else AsOneTextPrimary
                                        )
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.CheckCircle,
                                            contentDescription = null,
                                            modifier = Modifier.size(16.dp)
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text(if (isAccepted) "Accepté ✓" else "Accepter ✓", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                    }

                                    Button(
                                        onClick = { onDeclineShift(shift.id) },
                                        modifier = Modifier.weight(1f),
                                        shape = RoundedCornerShape(10.dp),
                                        colors = ButtonDefaults.buttonColors(
                                            containerColor = if (shift.status == ShiftAssignmentState.DECLINED) Color.Red else Color.LightGray.copy(alpha = 0.3f),
                                            contentColor = if (shift.status == ShiftAssignmentState.DECLINED) Color.White else Color.Red
                                        )
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.Cancel,
                                            contentDescription = null,
                                            modifier = Modifier.size(16.dp)
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text(if (shift.status == ShiftAssignmentState.DECLINED) "Décliné ✗" else "Décliner ✗", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// --- COMPOSABLE: WORKED & CLOCKED-IN DAYS AGENDA VIEW ---
@Composable
fun WorkedDaysAgendaView(
    agentPointages: List<PointageEntity>
) {
    val totalEarnings = agentPointages.sumOf { it.rateAmount }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = AsOneSurface),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
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
                Column {
                    Text(
                        text = "Agenda des Jours Pointés & Travaillés",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = AsOneTextPrimary
                    )
                    Text(
                        text = "Historique infalsifiable des présences validées par les chefs",
                        style = MaterialTheme.typography.bodySmall,
                        color = AsOneTextSecondary,
                        fontSize = 11.sp
                    )
                }

                Surface(
                    color = AsOneGreen.copy(alpha = 0.15f),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text(
                        text = "${totalEarnings.toInt()} F Total",
                        fontWeight = FontWeight.ExtraBold,
                        color = AsOneGreenDark,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        fontSize = 12.sp
                    )
                }
            }

            HorizontalDivider(color = AsOneCardBorder)

            if (agentPointages.isEmpty()) {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = Color(0xFFF8FAFC),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Default.FactCheck,
                            contentDescription = null,
                            tint = AsOneSkyBlue,
                            modifier = Modifier.size(32.dp)
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "Aucun pointage encore enregistré pour cette période.",
                            style = MaterialTheme.typography.bodySmall,
                            color = AsOneTextSecondary,
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
                        )
                    }
                }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    agentPointages.forEach { pt ->
                        Surface(
                            modifier = Modifier.fillMaxWidth(),
                            color = MaterialTheme.colorScheme.surface,
                            shape = RoundedCornerShape(14.dp),
                            border = androidx.compose.foundation.BorderStroke(1.dp, AsOneGreen.copy(alpha = 0.4f))
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(46.dp)
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(AsOneGreen),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Verified,
                                        contentDescription = null,
                                        tint = Color.White,
                                        modifier = Modifier.size(24.dp)
                                    )
                                }

                                Column(modifier = Modifier.weight(1f)) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                                    ) {
                                        Text(
                                            text = pt.date,
                                            fontWeight = FontWeight.Bold,
                                            style = MaterialTheme.typography.titleSmall,
                                            color = AsOneTextPrimary
                                        )
                                        StatusBadge(text = "VALIDÉ", backgroundColor = AsOneGreen)
                                    }

                                    Text(
                                        text = "${pt.chantierName} • Shift ${pt.shiftType}",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = AsOneBlueDark,
                                        fontWeight = FontWeight.SemiBold
                                    )

                                    Text(
                                        text = "Chef : ${pt.validatedByChefName}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = AsOneTextSecondary,
                                        fontSize = 11.sp
                                    )
                                }

                                Column(horizontalAlignment = Alignment.End) {
                                    Text(
                                        text = "+${pt.rateAmount.toInt()} F",
                                        fontWeight = FontWeight.ExtraBold,
                                        color = AsOneGreenDark,
                                        fontSize = 15.sp
                                    )
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(2.dp)
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.CameraAlt,
                                            contentDescription = null,
                                            tint = AsOneSkyBlue,
                                            modifier = Modifier.size(12.dp)
                                        )
                                        Text(
                                            text = "Preuve Photo",
                                            fontSize = 10.sp,
                                            color = AsOneBlue
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
}

@Composable
private fun LegendDotItem(color: Color, label: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(color)
        )
        Text(
            text = label,
            fontSize = 9.sp,
            fontWeight = FontWeight.SemiBold,
            color = AsOneTextSecondary
        )
    }
}

enum class ShiftAssignmentState {
    PROGRAMMED,
    ACCEPTED,
    DECLINED
}

data class ScheduledShift(
    val id: String,
    val date: String,
    val chantierName: String,
    val chefName: String,
    val shiftType: String,
    val rateAmount: Double,
    val status: ShiftAssignmentState = ShiftAssignmentState.PROGRAMMED
)


@Composable
fun AgentProfileTab(
    currentUser: UserEntity?,
    onUpdateProfile: (String, String, String) -> Unit
) {
    val context = LocalContext.current
    var fullName by remember(currentUser) { mutableStateOf(currentUser?.fullName ?: "") }
    var phone by remember(currentUser) { mutableStateOf(currentUser?.phone ?: "") }
    var operator by remember(currentUser) { mutableStateOf(currentUser?.paymentOperator ?: "T-Money") }
    var password by remember { mutableStateOf("••••••••") }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
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
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(56.dp)
                                .clip(CircleShape)
                                .background(AsOneGreen),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = fullName.take(1),
                                color = Color.White,
                                fontWeight = FontWeight.Bold,
                                fontSize = 24.sp
                            )
                        }
                        Column {
                            Text(
                                text = "Autonomie de Profil",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "Modifiez vos informations en cas d'erreur initiale.",
                                style = MaterialTheme.typography.bodySmall,
                                color = AsOneTextSecondary
                            )
                        }
                    }

                    HorizontalDivider()

                    OutlinedTextField(
                        value = fullName,
                        onValueChange = { fullName = it },
                        label = { Text("Nom et Prénom") },
                        modifier = Modifier.fillMaxWidth()
                    )

                    OutlinedTextField(
                        value = phone,
                        onValueChange = { phone = it },
                        label = { Text("Numéro Téléphone (+228)") },
                        modifier = Modifier.fillMaxWidth()
                    )

                    Text("Opérateur Mobile Money (Virements):", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        FilterChip(
                            selected = operator == "T-Money",
                            onClick = { operator = "T-Money" },
                            label = { Text("T-Money (Togocom)") }
                        )
                        FilterChip(
                            selected = operator == "Flooz",
                            onClick = { operator = "Flooz" },
                            label = { Text("Flooz (Moov)") }
                        )
                    }

                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = { Text("Renouveler Mot de Passe") },
                        modifier = Modifier.fillMaxWidth()
                    )

                    Button(
                        onClick = {
                            onUpdateProfile(fullName, phone, operator)
                            Toast.makeText(context, "Profil mis à jour en toute sécurité!", Toast.LENGTH_SHORT).show()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(Icons.Default.Save, contentDescription = null)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Enregistrer Profil", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}
