package com.example.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

private val LightColorScheme = lightColorScheme(
    primary = AsOneGreen,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFE0F2EC),
    onPrimaryContainer = AsOneGreenDark,
    secondary = AsOneBlue,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFE0EDF2),
    onSecondaryContainer = AsOneBlueDark,
    tertiary = AsOneSkyBlue,
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFE0F7FC),
    onTertiaryContainer = AsOneBlueDark,
    background = AsOneBackground,
    surface = AsOneSurface,
    onBackground = AsOneTextPrimary,
    onSurface = AsOneTextPrimary,
    outline = AsOneCardBorder
)

private val DarkColorScheme = darkColorScheme(
    primary = AsOneGreenLight,
    onPrimary = AsOneGreenDark,
    primaryContainer = Color(0xFF1B5E20),
    onPrimaryContainer = Color(0xFFE8F5E9),
    secondary = Color(0xFF90CAF9),
    onSecondary = AsOneBlueDark,
    secondaryContainer = Color(0xFF0D47A1),
    onSecondaryContainer = Color(0xFFE3F2FD),
    tertiary = AsOneSkyBlueLight,
    onTertiary = Color(0xFF004D40),
    background = Color(0xFF0F172A),
    surface = Color(0xFF1E293B),
    onBackground = Color(0xFFF8FAFC),
    onSurface = Color(0xFFF8FAFC)
)

@Composable
fun MyApplicationTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false, // Set false to prioritize brand green, blue & sky blue
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}

