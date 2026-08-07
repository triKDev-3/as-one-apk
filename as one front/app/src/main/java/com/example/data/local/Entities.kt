package com.example.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

enum class UserRole {
    ADMIN_DIRECTION,
    COMPTABLE,
    CHEF_CHANTIER,
    MAGASINIER,
    AGENT_CLEANING
}

enum class AgentStatus {
    TEMPORAIRE,
    PERMANENT
}

enum class ShiftType(val label: String, val defaultRate: Double) {
    JOURNEE("Journée Standard", 2500.0),
    NUIT("Nuit", 4500.0),
    DIMANCHE("Dimanche", 5000.0)
}

enum class EquipmentCondition {
    BON,
    DEGRADE,
    MANQUANT
}

enum class SanctionType {
    NONE,
    INDIVIDUAL,
    COLLECTIVE
}

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val fullName: String,
    val phone: String,
    val role: String, // UserRole string
    val status: String = AgentStatus.TEMPORAIRE.name, // AgentStatus string
    val isSuspended: Boolean = false,
    val paymentOperator: String = "T-Money", // "T-Money" or "Flooz"
    val fixedMonthlySalary: Double = 85000.0
)

@Entity(tableName = "pricing_grid")
data class PricingGridEntity(
    @PrimaryKey val id: Int = 1,
    val standardDayRate: Double = 2500.0,
    val nightRate: Double = 4500.0,
    val sundayRate: Double = 5000.0
)

@Entity(tableName = "chantiers")
data class ChantierEntity(
    @PrimaryKey val id: String,
    val name: String,
    val location: String,
    val assignedChefId: String,
    val assignedChefName: String
)

@Entity(tableName = "pointages")
data class PointageEntity(
    @PrimaryKey val id: String,
    val date: String, // "YYYY-MM-DD"
    val chantierId: String,
    val chantierName: String,
    val agentId: String,
    val agentName: String,
    val agentStatus: String,
    val shiftType: String, // ShiftType name
    val rateAmount: Double,
    val photoProofUri: String = "",
    val validatedByChefId: String,
    val validatedByChefName: String,
    val isReplacement: Boolean = false,
    val replacedPermanentId: String? = null,
    val replacedPermanentName: String? = null
)

@Entity(tableName = "availabilities")
data class AvailabilityEntity(
    @PrimaryKey val id: String, // "agentId_YYYY-MM-DD"
    val agentId: String,
    val date: String,
    val isAvailable: Boolean
)

@Entity(tableName = "equipment")
data class EquipmentEntity(
    @PrimaryKey val id: String,
    val name: String,
    val category: String, // "TRACEABLE" or "CONSUMABLE"
    val totalQuantity: Int,
    val availableQuantity: Int,
    val estimatedValue: Double
)

@Entity(tableName = "equipment_transactions")
data class EquipmentTransactionEntity(
    @PrimaryKey val id: String,
    val equipmentId: String,
    val equipmentName: String,
    val chantierId: String,
    val chantierName: String,
    val agentOrChefId: String,
    val agentOrChefName: String,
    val transactionType: String, // "CHECKOUT" or "RETURN"
    val condition: String = EquipmentCondition.BON.name,
    val isIndulgenceGranted: Boolean = false,
    val sanctionType: String = SanctionType.NONE.name,
    val penaltyAmount: Double = 0.0,
    val date: String,
    val timestamp: Long = System.currentTimeMillis()
)

@Entity(tableName = "payroll_adjustments")
data class PayrollAdjustmentEntity(
    @PrimaryKey val id: String, // "agentId_period"
    val agentId: String,
    val period: String, // e.g. "2026-08-15" (15th) or "2026-08-31" (end of month)
    val primes: Double = 0.0,
    val advances: Double = 0.0,
    val penalties: Double = 0.0,
    val notes: String = ""
)

@Entity(tableName = "vehicles")
data class VehicleEntity(
    @PrimaryKey val id: String,
    val immatriculation: String,
    val modelName: String,
    val lastAssuranceDate: String,
    val assuranceValidityDays: Int = 365,
    val lastVidangeDate: String,
    val vidangeValidityDays: Int = 90
)
