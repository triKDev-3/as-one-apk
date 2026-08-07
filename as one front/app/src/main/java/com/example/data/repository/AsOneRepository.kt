package com.example.data.repository

import com.example.data.local.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import java.text.SimpleDateFormat
import java.util.*

class AsOneRepository(private val db: AppDatabase) {

    // Users & Roles
    val allUsers: Flow<List<UserEntity>> = db.userDao().getAllUsers()
    val activeAgents: Flow<List<UserEntity>> = db.userDao().getActiveAgents()

    suspend fun getUserById(id: String): UserEntity? = db.userDao().getUserById(id)

    suspend fun createOrUpdateUser(user: UserEntity) {
        db.userDao().insertOrUpdateUser(user)
    }

    suspend fun setUserSuspended(userId: String, suspended: Boolean) {
        db.userDao().updateUserStatus(userId, suspended)
    }

    suspend fun updateAgentProfile(userId: String, fullName: String, phone: String, operator: String) {
        db.userDao().updateAgentProfile(userId, fullName, phone, operator)
    }

    // Pricing Grid
    val pricingGrid: Flow<PricingGridEntity?> = db.pricingGridDao().getPricingGrid()

    suspend fun updatePricingGrid(standardDay: Double, night: Double, sunday: Double) {
        db.pricingGridDao().setPricingGrid(
            PricingGridEntity(id = 1, standardDayRate = standardDay, nightRate = night, sundayRate = sunday)
        )
    }

    // Chantiers / Sites
    val allChantiers: Flow<List<ChantierEntity>> = db.chantierDao().getAllChantiers()

    fun getChantiersForChef(chefId: String): Flow<List<ChantierEntity>> =
        db.chantierDao().getChantiersForChef(chefId)

    suspend fun addChantier(chantier: ChantierEntity) {
        db.chantierDao().insertChantier(chantier)
    }

    // Pointages (Attendance)
    val allPointages: Flow<List<PointageEntity>> = db.pointageDao().getAllPointages()

    fun getPointagesForDate(date: String): Flow<List<PointageEntity>> =
        db.pointageDao().getPointagesForDate(date)

    fun getPointagesForChantierAndDate(chantierId: String, date: String): Flow<List<PointageEntity>> =
        db.pointageDao().getPointagesForChantierAndDate(chantierId, date)

    fun getPointagesForAgent(agentId: String): Flow<List<PointageEntity>> =
        db.pointageDao().getPointagesForAgent(agentId)

    suspend fun submitPointageForSite(
        chantierId: String,
        chantierName: String,
        date: String,
        chefId: String,
        chefName: String,
        photoProofUri: String,
        selectedPointages: List<PointageEntity>
    ) {
        // Replace existing pointages for this site & date with new validated ones
        db.pointageDao().deletePointagesForChantierAndDate(chantierId, date)
        val updated = selectedPointages.map { p ->
            p.copy(
                chantierId = chantierId,
                chantierName = chantierName,
                date = date,
                validatedByChefId = chefId,
                validatedByChefName = chefName,
                photoProofUri = photoProofUri
            )
        }
        db.pointageDao().insertPointages(updated)
    }

    // Availabilities
    fun getAvailabilitiesForAgent(agentId: String): Flow<List<AvailabilityEntity>> =
        db.availabilityDao().getAvailabilitiesForAgent(agentId)

    fun getAvailableAgentsForDate(date: String): Flow<List<AvailabilityEntity>> =
        db.availabilityDao().getAvailableAgentsForDate(date)

    suspend fun setAgentAvailability(agentId: String, date: String, isAvailable: Boolean) {
        val id = "${agentId}_$date"
        db.availabilityDao().setAvailability(
            AvailabilityEntity(id = id, agentId = agentId, date = date, isAvailable = isAvailable)
        )
    }

    // Equipment & Transactions
    val allEquipment: Flow<List<EquipmentEntity>> = db.equipmentDao().getAllEquipment()
    val allEquipmentTransactions: Flow<List<EquipmentTransactionEntity>> =
        db.equipmentTransactionDao().getAllTransactions()

    fun getTransactionsForAgent(agentId: String): Flow<List<EquipmentTransactionEntity>> =
        db.equipmentTransactionDao().getTransactionsForAgent(agentId)

    suspend fun addEquipment(equipment: EquipmentEntity) {
        db.equipmentDao().insertEquipment(equipment)
    }

    suspend fun recordEquipmentReturn(
        transaction: EquipmentTransactionEntity,
        newAvailableQty: Int
    ) {
        db.equipmentTransactionDao().insertTransaction(transaction)
        db.equipmentDao().updateQuantity(transaction.equipmentId, newAvailableQty)

        // If sanction applied, automatically log penalty for the responsible agent
        if (transaction.sanctionType == SanctionType.INDIVIDUAL.name && transaction.penaltyAmount > 0) {
            val period = transaction.date.substring(0, 7) + "-30"
            val existing = db.payrollAdjustmentDao().getAdjustmentsForAgent(transaction.agentOrChefId).first().firstOrNull { it.period == period }
            val updatedPenalties = (existing?.penalties ?: 0.0) + transaction.penaltyAmount
            val updatedNote = (existing?.notes ?: "") + " | Retenue Matériel (${transaction.equipmentName}): ${transaction.penaltyAmount.toInt()} FCFA"
            
            db.payrollAdjustmentDao().setAdjustment(
                PayrollAdjustmentEntity(
                    id = "${transaction.agentOrChefId}_$period",
                    agentId = transaction.agentOrChefId,
                    period = period,
                    primes = existing?.primes ?: 0.0,
                    advances = existing?.advances ?: 0.0,
                    penalties = updatedPenalties,
                    notes = updatedNote
                )
            )
        }
    }

    // Payroll Adjustments (Primes, Retenues, Acomptes)
    fun getAdjustmentsForPeriod(period: String): Flow<List<PayrollAdjustmentEntity>> =
        db.payrollAdjustmentDao().getAdjustmentsForPeriod(period)

    fun getAdjustmentsForAgent(agentId: String): Flow<List<PayrollAdjustmentEntity>> =
        db.payrollAdjustmentDao().getAdjustmentsForAgent(agentId)

    suspend fun updatePayrollAdjustment(adjustment: PayrollAdjustmentEntity) {
        db.payrollAdjustmentDao().setAdjustment(adjustment)
    }

    // Vehicle Fleet Management
    val allVehicles: Flow<List<VehicleEntity>> = db.vehicleDao().getAllVehicles()

    suspend fun addVehicle(vehicle: VehicleEntity) {
        db.vehicleDao().insertVehicle(vehicle)
    }
}
