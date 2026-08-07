package com.example.data.local

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface UserDao {
    @Query("SELECT * FROM users ORDER BY fullName ASC")
    fun getAllUsers(): Flow<List<UserEntity>>

    @Query("SELECT * FROM users WHERE role = 'AGENT_CLEANING' AND isSuspended = 0 ORDER BY fullName ASC")
    fun getActiveAgents(): Flow<List<UserEntity>>

    @Query("SELECT * FROM users WHERE id = :id")
    suspend fun getUserById(id: String): UserEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdateUser(user: UserEntity)

    @Query("UPDATE users SET isSuspended = :isSuspended WHERE id = :id")
    suspend fun updateUserStatus(id: String, isSuspended: Boolean)

    @Query("UPDATE users SET fullName = :fullName, phone = :phone, paymentOperator = :operator WHERE id = :id")
    suspend fun updateAgentProfile(id: String, fullName: String, phone: String, operator: String)
}

@Dao
interface PricingGridDao {
    @Query("SELECT * FROM pricing_grid WHERE id = 1")
    fun getPricingGrid(): Flow<PricingGridEntity?>

    @Query("SELECT * FROM pricing_grid WHERE id = 1")
    suspend fun getPricingGridOnce(): PricingGridEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun setPricingGrid(grid: PricingGridEntity)
}

@Dao
interface ChantierDao {
    @Query("SELECT * FROM chantiers ORDER BY name ASC")
    fun getAllChantiers(): Flow<List<ChantierEntity>>

    @Query("SELECT * FROM chantiers WHERE assignedChefId = :chefId ORDER BY name ASC")
    fun getChantiersForChef(chefId: String): Flow<List<ChantierEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertChantier(chantier: ChantierEntity)
}

@Dao
interface PointageDao {
    @Query("SELECT * FROM pointages ORDER BY date DESC")
    fun getAllPointages(): Flow<List<PointageEntity>>

    @Query("SELECT * FROM pointages WHERE date = :date")
    fun getPointagesForDate(date: String): Flow<List<PointageEntity>>

    @Query("SELECT * FROM pointages WHERE chantierId = :chantierId AND date = :date")
    fun getPointagesForChantierAndDate(chantierId: String, date: String): Flow<List<PointageEntity>>

    @Query("SELECT * FROM pointages WHERE agentId = :agentId ORDER BY date DESC")
    fun getPointagesForAgent(agentId: String): Flow<List<PointageEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPointages(pointages: List<PointageEntity>)

    @Query("DELETE FROM pointages WHERE chantierId = :chantierId AND date = :date")
    suspend fun deletePointagesForChantierAndDate(chantierId: String, date: String)
}

@Dao
interface AvailabilityDao {
    @Query("SELECT * FROM availabilities WHERE agentId = :agentId")
    fun getAvailabilitiesForAgent(agentId: String): Flow<List<AvailabilityEntity>>

    @Query("SELECT * FROM availabilities WHERE date = :date AND isAvailable = 1")
    fun getAvailableAgentsForDate(date: String): Flow<List<AvailabilityEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun setAvailability(availability: AvailabilityEntity)
}

@Dao
interface EquipmentDao {
    @Query("SELECT * FROM equipment ORDER BY name ASC")
    fun getAllEquipment(): Flow<List<EquipmentEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEquipment(equipment: EquipmentEntity)

    @Query("UPDATE equipment SET availableQuantity = :qty WHERE id = :id")
    suspend fun updateQuantity(id: String, qty: Int)
}

@Dao
interface EquipmentTransactionDao {
    @Query("SELECT * FROM equipment_transactions ORDER BY timestamp DESC")
    fun getAllTransactions(): Flow<List<EquipmentTransactionEntity>>

    @Query("SELECT * FROM equipment_transactions WHERE agentOrChefId = :agentId")
    fun getTransactionsForAgent(agentId: String): Flow<List<EquipmentTransactionEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTransaction(transaction: EquipmentTransactionEntity)
}

@Dao
interface PayrollAdjustmentDao {
    @Query("SELECT * FROM payroll_adjustments WHERE period = :period")
    fun getAdjustmentsForPeriod(period: String): Flow<List<PayrollAdjustmentEntity>>

    @Query("SELECT * FROM payroll_adjustments WHERE agentId = :agentId")
    fun getAdjustmentsForAgent(agentId: String): Flow<List<PayrollAdjustmentEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun setAdjustment(adjustment: PayrollAdjustmentEntity)
}

@Dao
interface VehicleDao {
    @Query("SELECT * FROM vehicles ORDER BY immatriculation ASC")
    fun getAllVehicles(): Flow<List<VehicleEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertVehicle(vehicle: VehicleEntity)
}
