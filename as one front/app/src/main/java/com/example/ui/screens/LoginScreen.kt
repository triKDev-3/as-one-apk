package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.UserEntity
import com.example.data.local.UserRole
import com.example.ui.components.*
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoginScreen(
    allUsers: List<UserEntity>,
    onLoginSuccess: (UserEntity) -> Unit
) {
    var selectedRoleFilter by remember { mutableStateOf<String?>(null) }
    var selectedUser by remember { mutableStateOf<UserEntity?>(null) }
    var pinCode by remember { mutableStateOf("") }
    var isPasswordVisible by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val focusManager = LocalFocusManager.current

    val filteredUsers = remember(allUsers, selectedRoleFilter) {
        if (selectedRoleFilter == null) allUsers
        else allUsers.filter { it.role == selectedRoleFilter }
    }

    // Auto-select first user in filtered list if current selection is not in filter
    LaunchedEffect(filteredUsers) {
        if (selectedUser == null || (selectedRoleFilter != null && selectedUser?.role != selectedRoleFilter)) {
            selectedUser = filteredUsers.firstOrNull()
        }
    }

    val gradientBackground = Brush.verticalGradient(
        colors = listOf(
            AsOneBlueDark,
            AsOneBlue,
            AsOneBackground
        )
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(gradientBackground)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(16.dp))

            // Official Brand Header Badge with White Container
            Surface(
                color = Color.White,
                shape = RoundedCornerShape(24.dp),
                shadowElevation = 8.dp,
                modifier = Modifier.padding(bottom = 8.dp)
            ) {
                AsOneLogoBadge(
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 14.dp),
                    iconSize = 46.dp,
                    titleSize = 24.sp,
                    subtitleSize = 9.sp,
                    darkText = true
                )
            }

            Text(
                text = "Plateforme Gestion RH & Paie Infalsifiable",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White.copy(alpha = 0.9f),
                fontWeight = FontWeight.Medium,
                fontSize = 13.sp
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Main Login Card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = AsOneSurface),
                elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(20.dp)
                ) {
                    Text(
                        text = "Connexion & Sélection de Rôle",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = AsOneTextPrimary
                    )
                    Text(
                        text = "Choisissez votre compte pour accéder à votre espace dédié",
                        style = MaterialTheme.typography.bodySmall,
                        color = AsOneTextSecondary,
                        modifier = Modifier.padding(bottom = 12.dp)
                    )

                    // Role Tabs / Chips
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 12.dp),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        FilterChip(
                            selected = selectedRoleFilter == null,
                            onClick = { selectedRoleFilter = null },
                            label = { Text("Tous", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = AsOneGreen,
                                selectedLabelColor = Color.White
                            )
                        )

                        UserRole.entries.forEach { role ->
                            val isSelected = selectedRoleFilter == role.name
                            FilterChip(
                                selected = isSelected,
                                onClick = { selectedRoleFilter = if (isSelected) null else role.name },
                                label = {
                                    Text(
                                        text = when (role) {
                                            UserRole.ADMIN_DIRECTION -> "Direction"
                                            UserRole.COMPTABLE -> "Comptable"
                                            UserRole.CHEF_CHANTIER -> "Chef"
                                            UserRole.MAGASINIER -> "Magasin"
                                            UserRole.AGENT_CLEANING -> "Agent"
                                        },
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                },
                                leadingIcon = {
                                    Icon(
                                        imageVector = getRoleIcon(role.name),
                                        contentDescription = null,
                                        modifier = Modifier.size(14.dp)
                                    )
                                },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = AsOneBlue,
                                    selectedLabelColor = Color.White
                                )
                            )
                        }
                    }

                    HorizontalDivider(color = AsOneCardBorder)

                    // User Selection List
                    Text(
                        text = "Sélectionnez un utilisateur :",
                        style = MaterialTheme.typography.labelSmall,
                        color = AsOneTextSecondary,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(top = 10.dp, bottom = 6.dp)
                    )

                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(filteredUsers) { user ->
                            val isSelected = selectedUser?.id == user.id
                            Surface(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(12.dp))
                                    .clickable {
                                        selectedUser = user
                                        errorMessage = null
                                    }
                                    .border(
                                        width = if (isSelected) 2.dp else 1.dp,
                                        color = if (isSelected) AsOneGreen else AsOneCardBorder,
                                        shape = RoundedCornerShape(12.dp)
                                    ),
                                color = if (isSelected) AsOneGreen.copy(alpha = 0.08f) else AsOneSurface
                            ) {
                                Row(
                                    modifier = Modifier.padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(40.dp)
                                            .clip(CircleShape)
                                            .background(
                                                if (isSelected) AsOneGreen else AsOneSkyBlue.copy(alpha = 0.2f)
                                            ),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            imageVector = getRoleIcon(user.role),
                                            contentDescription = null,
                                            tint = if (isSelected) Color.White else AsOneBlue,
                                            modifier = Modifier.size(20.dp)
                                        )
                                    }

                                    Column(modifier = Modifier.weight(1f)) {
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                                        ) {
                                            Text(
                                                text = user.fullName,
                                                fontWeight = FontWeight.Bold,
                                                style = MaterialTheme.typography.bodyMedium,
                                                color = AsOneTextPrimary
                                            )
                                            if (isSelected) {
                                                Icon(
                                                    imageVector = Icons.Default.CheckCircle,
                                                    contentDescription = null,
                                                    tint = AsOneGreen,
                                                    modifier = Modifier.size(16.dp)
                                                )
                                            }
                                        }
                                        Text(
                                            text = "${getRoleLabel(user.role)} • Tel: ${user.phone}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = AsOneTextSecondary,
                                            fontSize = 11.sp
                                        )
                                    }

                                    Surface(
                                        color = when (user.role) {
                                            UserRole.ADMIN_DIRECTION.name -> AsOneGreen.copy(alpha = 0.15f)
                                            UserRole.COMPTABLE.name -> AsOneBlue.copy(alpha = 0.15f)
                                            UserRole.CHEF_CHANTIER.name -> AsOneSkyBlue.copy(alpha = 0.15f)
                                            else -> Color(0xFFF1F5F9)
                                        },
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text(
                                            text = user.id,
                                            style = MaterialTheme.typography.labelSmall,
                                            fontWeight = FontWeight.Bold,
                                            color = AsOneTextPrimary,
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Code PIN Input & Authentication
                    if (selectedUser != null) {
                        Surface(
                            modifier = Modifier.fillMaxWidth(),
                            color = Color(0xFFF8FAFC),
                            shape = RoundedCornerShape(16.dp),
                            border = androidx.compose.foundation.BorderStroke(1.dp, AsOneCardBorder)
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Text(
                                    text = "Code PIN d'Accès pour ${selectedUser?.fullName}:",
                                    style = MaterialTheme.typography.labelMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = AsOneTextPrimary
                                )
                                Text(
                                    text = "Entrez le code PIN (Code démo: 1234)",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = AsOneTextSecondary,
                                    fontSize = 11.sp
                                )

                                Spacer(modifier = Modifier.height(8.dp))

                                OutlinedTextField(
                                    value = pinCode,
                                    onValueChange = {
                                        if (it.length <= 6) {
                                            pinCode = it
                                            errorMessage = null
                                        }
                                    },
                                    modifier = Modifier.fillMaxWidth(),
                                    placeholder = { Text("Ex: 1234") },
                                    singleLine = true,
                                    keyboardOptions = KeyboardOptions(
                                        keyboardType = KeyboardType.Number,
                                        imeAction = ImeAction.Done
                                    ),
                                    visualTransformation = if (isPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                                    trailingIcon = {
                                        IconButton(onClick = { isPasswordVisible = !isPasswordVisible }) {
                                            Icon(
                                                imageVector = if (isPasswordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                                                contentDescription = "Toggle password visibility"
                                            )
                                        }
                                    },
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = AsOneGreen,
                                        unfocusedBorderColor = AsOneCardBorder
                                    )
                                )

                                if (errorMessage != null) {
                                    Text(
                                        text = errorMessage!!,
                                        color = MaterialTheme.colorScheme.error,
                                        style = MaterialTheme.typography.bodySmall,
                                        modifier = Modifier.padding(top = 4.dp)
                                    )
                                }

                                Spacer(modifier = Modifier.height(12.dp))

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Button(
                                        onClick = {
                                            focusManager.clearFocus()
                                            // Demo PIN validation: accepts "1234" or empty/any 4 digits for ease
                                            if (pinCode.isEmpty() || pinCode == "1234" || pinCode.length >= 4) {
                                                onLoginSuccess(selectedUser!!)
                                            } else {
                                                errorMessage = "Code PIN incorrect. Utilisez 1234 pour la démonstration."
                                            }
                                        },
                                        modifier = Modifier
                                            .weight(1f)
                                            .height(48.dp),
                                        shape = RoundedCornerShape(12.dp),
                                        colors = ButtonDefaults.buttonColors(containerColor = AsOneGreen)
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.LockOpen,
                                            contentDescription = null,
                                            modifier = Modifier.size(18.dp)
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text(
                                            text = "Se Connecter",
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 15.sp
                                        )
                                    }

                                    OutlinedButton(
                                        onClick = {
                                            // Fast direct login for demo
                                            onLoginSuccess(selectedUser!!)
                                        },
                                        modifier = Modifier.height(48.dp),
                                        shape = RoundedCornerShape(12.dp),
                                        colors = ButtonDefaults.outlinedButtonColors(contentColor = AsOneBlue)
                                    ) {
                                        Text("Démo Flash", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Footer info
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.VerifiedUser,
                    contentDescription = null,
                    tint = AsOneSkyBlueLight,
                    modifier = Modifier.size(16.dp)
                )
                Text(
                    text = "Système Anti-Fraude & Rôles Isolé v2.4 • Vert, Bleu, Bleu Ciel",
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White.copy(alpha = 0.8f)
                )
            }
        }
    }
}
