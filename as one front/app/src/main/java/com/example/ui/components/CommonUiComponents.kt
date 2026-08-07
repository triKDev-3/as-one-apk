package com.example.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.UserEntity
import com.example.data.local.UserRole
import com.example.ui.theme.*

/**
 * Official AS ONE Swirl / Vortex Icon matching as-one.services
 */
@Composable
fun AsOneSwirlIcon(
    modifier: Modifier = Modifier.size(36.dp)
) {
    Canvas(modifier = modifier) {
        val diameter = size.minDimension
        val strokeWidth = diameter * 0.15f
        val topLeft = Offset((size.width - diameter) / 2f + strokeWidth / 2f, (size.height - diameter) / 2f + strokeWidth / 2f)
        val arcSize = Size(diameter - strokeWidth, diameter - strokeWidth)

        // Outer Emerald Green Arc (#008559)
        drawArc(
            color = Color(0xFF008559),
            startAngle = 160f,
            sweepAngle = 150f,
            useCenter = false,
            topLeft = topLeft,
            size = arcSize,
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
        )

        // Outer Dark Petrol Blue Arc (#004F71)
        drawArc(
            color = Color(0xFF004F71),
            startAngle = 330f,
            sweepAngle = 150f,
            useCenter = false,
            topLeft = topLeft,
            size = arcSize,
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
        )

        // Inner Cyan / Sky Blue Swirl Arc (#0096C7)
        val innerStroke = strokeWidth * 0.9f
        val innerDiameter = diameter * 0.58f
        val innerOffset = Offset((size.width - innerDiameter) / 2f, (size.height - innerDiameter) / 2f)
        val innerSize = Size(innerDiameter, innerDiameter)

        drawArc(
            color = Color(0xFF0096C7),
            startAngle = 75f,
            sweepAngle = 170f,
            useCenter = false,
            topLeft = innerOffset,
            size = innerSize,
            style = Stroke(width = innerStroke, cap = StrokeCap.Round)
        )
    }
}

/**
 * Official AS ONE Logo with Text
 */
@Composable
fun AsOneLogoBadge(
    modifier: Modifier = Modifier,
    iconSize: Dp = 34.dp,
    titleSize: TextUnit = 18.sp,
    subtitleSize: TextUnit = 8.sp,
    darkText: Boolean = true
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        AsOneSwirlIcon(modifier = Modifier.size(iconSize))
        Column {
            Text(
                text = "AS ONE",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.ExtraBold,
                color = if (darkText) AsOneBlue else Color.White,
                fontSize = titleSize,
                letterSpacing = 0.5.sp
            )
            Text(
                text = "FACILITY MANAGEMENT",
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = if (darkText) AsOneGreen else AsOneSkyBlueLight,
                fontSize = subtitleSize,
                letterSpacing = 0.8.sp
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AsOneTopBar(
    currentUser: UserEntity?,
    allUsers: List<UserEntity>,
    onSelectUser: (UserEntity) -> Unit,
    onLogout: () -> Unit = {},
    title: String = "AS ONE"
) {
    var showUserMenu by remember { mutableStateOf(false) }

    Surface(
        color = AsOneGreen,
        contentColor = Color.White,
        shadowElevation = 4.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(end = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // White Logo Block on top-left corner
            Surface(
                color = Color.White,
                shape = RoundedCornerShape(bottomEnd = 16.dp),
                shadowElevation = 3.dp
            ) {
                AsOneLogoBadge(
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                    iconSize = 34.dp,
                    titleSize = 18.sp,
                    subtitleSize = 8.sp,
                    darkText = true
                )
            }

            if (currentUser != null) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Column(
                        horizontalAlignment = Alignment.End,
                        modifier = Modifier.padding(end = 4.dp)
                    ) {
                        Text(
                            text = title,
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = "RH & Paie Infalsifiable",
                            style = MaterialTheme.typography.labelSmall,
                            color = AsOneSkyBlueLight,
                            fontSize = 9.sp
                        )
                    }

                    // User Profile Badge
                    Box {
                        Surface(
                            modifier = Modifier
                                .clip(RoundedCornerShape(20.dp))
                                .clickable { showUserMenu = true },
                            color = AsOneBlue,
                            shape = RoundedCornerShape(20.dp)
                        ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(
                                        imageVector = getRoleIcon(currentUser.role),
                                        contentDescription = "Profile",
                                        tint = AsOneSkyBlueLight,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Text(
                                        text = currentUser.fullName.split(" ").firstOrNull() ?: currentUser.fullName,
                                        style = MaterialTheme.typography.bodySmall,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White
                                    )
                                    Icon(
                                        imageVector = Icons.Default.ArrowDropDown,
                                        contentDescription = "Expand",
                                        tint = Color.White,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }

                            DropdownMenu(
                                expanded = showUserMenu,
                                onDismissRequest = { showUserMenu = false },
                                modifier = Modifier.width(260.dp)
                            ) {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    color = AsOneBlue.copy(alpha = 0.1f)
                                ) {
                                    Column(modifier = Modifier.padding(12.dp)) {
                                        Text(
                                            text = currentUser.fullName,
                                            fontWeight = FontWeight.Bold,
                                            style = MaterialTheme.typography.titleSmall
                                        )
                                        Text(
                                            text = getRoleLabel(currentUser.role),
                                            style = MaterialTheme.typography.bodySmall,
                                            color = AsOneGreenDark,
                                            fontWeight = FontWeight.SemiBold
                                        )
                                        Text(
                                            text = "Tel: ${currentUser.phone}",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = AsOneTextSecondary
                                        )
                                    }
                                }

                                HorizontalDivider()

                                Text(
                                    text = "CHANGER DE RÔLE (AVEC AUTHENTIFICATION)",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = AsOneTextSecondary,
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                                    fontSize = 10.sp
                                )

                                allUsers.forEach { user ->
                                    DropdownMenuItem(
                                        text = {
                                            Column {
                                                Text(
                                                    text = user.fullName,
                                                    fontWeight = FontWeight.SemiBold,
                                                    fontSize = 13.sp
                                                )
                                                Text(
                                                    text = getRoleLabel(user.role),
                                                    fontSize = 11.sp,
                                                    color = AsOneTextSecondary
                                                )
                                            }
                                        },
                                        leadingIcon = {
                                            Icon(
                                                imageVector = getRoleIcon(user.role),
                                                contentDescription = null,
                                                tint = if (currentUser.id == user.id) AsOneGreen else AsOneBlue,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        },
                                        onClick = {
                                            onSelectUser(user)
                                            showUserMenu = false
                                        }
                                    )
                                }

                                HorizontalDivider()

                                DropdownMenuItem(
                                    text = {
                                        Text(
                                            text = "Déconnexion",
                                            color = MaterialTheme.colorScheme.error,
                                            fontWeight = FontWeight.Bold
                                        )
                                    },
                                    leadingIcon = {
                                        Icon(
                                            imageVector = Icons.Default.Logout,
                                            contentDescription = "Logout",
                                            tint = MaterialTheme.colorScheme.error
                                        )
                                    },
                                    onClick = {
                                        showUserMenu = false
                                        onLogout()
                                    }
                                )
                            }
                        }

                        // Direct Logout Button
                        IconButton(
                            onClick = onLogout,
                            modifier = Modifier.size(36.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Logout,
                                contentDescription = "Déconnexion",
                                tint = AsOneSkyBlueLight,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }
                }
            }
        }
    }

@Composable
fun MetricStatCard(
    title: String,
    value: String,
    subtitle: String,
    icon: ImageVector,
    color: Color = AsOneGreen,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
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
                    text = title,
                    style = MaterialTheme.typography.labelMedium,
                    color = AsOneTextSecondary
                )
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(color.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = color,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
            Text(
                text = value,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = AsOneTextPrimary
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = AsOneTextSecondary
            )
        }
    }
}

@Composable
fun StatusBadge(
    text: String,
    backgroundColor: Color,
    textColor: Color = Color.White
) {
    Surface(
        color = backgroundColor,
        shape = RoundedCornerShape(12.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            color = textColor,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

fun getRoleLabel(roleStr: String): String {
    return when (roleStr) {
        UserRole.ADMIN_DIRECTION.name -> "1. Direction Générale"
        UserRole.COMPTABLE.name -> "2. Comptable"
        UserRole.CHEF_CHANTIER.name -> "3. Chef de Chantier"
        UserRole.MAGASINIER.name -> "4. Magasinier"
        UserRole.AGENT_CLEANING.name -> "5. Agent / Ouvrier"
        else -> roleStr
    }
}

fun getRoleIcon(roleStr: String): ImageVector {
    return when (roleStr) {
        UserRole.ADMIN_DIRECTION.name -> Icons.Default.AdminPanelSettings
        UserRole.COMPTABLE.name -> Icons.Default.AccountBalanceWallet
        UserRole.CHEF_CHANTIER.name -> Icons.Default.Engineering
        UserRole.MAGASINIER.name -> Icons.Default.Inventory
        UserRole.AGENT_CLEANING.name -> Icons.Default.CleaningServices
        else -> Icons.Default.Person
    }
}
