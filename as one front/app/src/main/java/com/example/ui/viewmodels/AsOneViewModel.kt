package com.example.ui.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.local.*
import com.example.data.repository.AsOneRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

class AsOneViewModel(application: Application) : AndroidViewModel(application) {

    private val repository: AsOneRepository
    val database: AppDatabase = AppDatabase.getDatabase(application)

    init {
        repository = AsOneRepository(database)
    }

    // Current active user / role
    private val _currentUser = MutableStateFlow<UserEntity?>(null)
    val currentUser: StateFlow<UserEntity?> = _currentUser.asStateFlow()

    // Database reactive flows
    val allUsers: StateFlow<List<UserEntity>> = repository.allUsers
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val activeAgents: StateFlow<List<UserEntity>> = repository.activeAgents
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val pricingGrid: StateFlow<PricingGridEntity?> = repository.pricingGrid
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), PricingGridEntity())

    val allChantiers: StateFlow<List<ChantierEntity>> = repository.allChantiers
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allPointages: StateFlow<List<PointageEntity>> = repository.allPointages
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allEquipment: StateFlow<List<EquipmentEntity>> = repository.allEquipment
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allTransactions: StateFlow<List<EquipmentTransactionEntity>> = repository.allEquipmentTransactions
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allVehicles: StateFlow<List<VehicleEntity>> = repository.allVehicles
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        // Default login as Direction on launch
        viewModelScope.launch {
            allUsers.firstOrNull { it.isNotEmpty() }?.let { users ->
                _currentUser.value = users.firstOrNull { it.role == UserRole.ADMIN_DIRECTION.name } ?: users.first()
            }
        }
    }

    fun setCurrentUser(user: UserEntity?) {
        _currentUser.value = user
    }

    fun logout() {
        _currentUser.value = null
    }

    // Direction Actions
    fun createEmployeeAccount(
        fullName: String,
        phone: String,
        role: UserRole,
        status: AgentStatus,
        fixedSalary: Double = 85000.0,
        operator: String = "T-Money"
    ) {
        viewModelScope.launch {
            val id = "EMP${System.currentTimeMillis().toString().takeLast(5)}"
            val newUser = UserEntity(
                id = id,
                fullName = fullName,
                phone = phone,
                role = role.name,
                status = status.name,
                isSuspended = false,
                paymentOperator = operator,
                fixedMonthlySalary = fixedSalary
            )
            repository.createOrUpdateUser(newUser)
        }
    }

    fun toggleUserSuspension(userId: String, currentSuspended: Boolean) {
        viewModelScope.launch {
            repository.setUserSuspended(userId, !currentSuspended)
        }
    }

    fun updatePricingGrid(standardDay: Double, night: Double, sunday: Double) {
        viewModelScope.launch {
            repository.updatePricingGrid(standardDay, night, sunday)
        }
    }

    fun addChantier(name: String, location: String, chefId: String, chefName: String) {
        viewModelScope.launch {
            val id = "CHT${System.currentTimeMillis().toString().takeLast(4)}"
            val chantier = ChantierEntity(
                id = id,
                name = name,
                location = location,
                assignedChefId = chefId,
                assignedChefName = chefName
            )
            repository.addChantier(chantier)
        }
    }

    // Chef de Chantier Actions
    fun submitPointage(
        chantierId: String,
        chantierName: String,
        date: String,
        photoProofUri: String,
        selectedPointages: List<PointageEntity>
    ) {
        viewModelScope.launch {
            val chef = currentUser.value ?: return@launch
            repository.submitPointageForSite(
                chantierId = chantierId,
                chantierName = chantierName,
                date = date,
                chefId = chef.id,
                chefName = chef.fullName,
                photoProofUri = photoProofUri,
                selectedPointages = selectedPointages
            )
        }
    }

    // Agent Availability
    fun getAgentAvailabilities(agentId: String): Flow<List<AvailabilityEntity>> {
        return repository.getAvailabilitiesForAgent(agentId)
    }

    fun toggleAvailability(agentId: String, date: String, currentlyAvailable: Boolean) {
        viewModelScope.launch {
            repository.setAgentAvailability(agentId, date, !currentlyAvailable)
        }
    }

    // Magasinier Actions
    fun recordEquipmentReturn(
        equipment: EquipmentEntity,
        qtyReturned: Int,
        condition: EquipmentCondition,
        isIndulgence: Boolean,
        targetAgentId: String,
        targetAgentName: String,
        chantierId: String,
        chantierName: String,
        penaltyAmount: Double = 0.0,
        sanctionType: SanctionType = SanctionType.NONE
    ) {
        viewModelScope.launch {
            val dateStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
            val newAvailable = (equipment.availableQuantity + qtyReturned).coerceAtMost(equipment.totalQuantity)

            val transaction = EquipmentTransactionEntity(
                id = "TX_${System.currentTimeMillis()}",
                equipmentId = equipment.id,
                equipmentName = equipment.name,
                chantierId = chantierId,
                chantierName = chantierName,
                agentOrChefId = targetAgentId,
                agentOrChefName = targetAgentName,
                transactionType = "RETURN",
                condition = condition.name,
                isIndulgenceGranted = isIndulgence,
                sanctionType = sanctionType.name,
                penaltyAmount = penaltyAmount,
                date = dateStr
            )
            repository.recordEquipmentReturn(transaction, newAvailable)
        }
    }

    fun addVehicle(
        immatriculation: String,
        modelName: String,
        lastAssuranceDate: String,
        assuranceDays: Int = 365,
        lastVidangeDate: String,
        vidangeDays: Int = 90
    ) {
        viewModelScope.launch {
            val id = "VEH${System.currentTimeMillis().toString().takeLast(4)}"
            val vehicle = VehicleEntity(
                id = id,
                immatriculation = immatriculation,
                modelName = modelName,
                lastAssuranceDate = lastAssuranceDate,
                assuranceValidityDays = assuranceDays,
                lastVidangeDate = lastVidangeDate,
                vidangeValidityDays = vidangeDays
            )
            repository.addVehicle(vehicle)
        }
    }

    // Comptable Actions
    fun savePayrollAdjustment(
        agentId: String,
        period: String,
        primes: Double,
        advances: Double,
        penalties: Double,
        notes: String
    ) {
        viewModelScope.launch {
            val id = "${agentId}_$period"
            repository.updatePayrollAdjustment(
                PayrollAdjustmentEntity(
                    id = id,
                    agentId = agentId,
                    period = period,
                    primes = primes,
                    advances = advances,
                    penalties = penalties,
                    notes = notes
                )
            )
        }
    }

    // Worker Self-Profile Update
    fun updateAgentSelfProfile(fullName: String, phone: String, operator: String) {
        viewModelScope.launch {
            val user = currentUser.value ?: return@launch
            repository.updateAgentProfile(user.id, fullName, phone, operator)
            _currentUser.value = user.copy(fullName = fullName, phone = phone, paymentOperator = operator)
        }
    }
}
