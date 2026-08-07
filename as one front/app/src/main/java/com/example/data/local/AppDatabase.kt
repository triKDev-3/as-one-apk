package com.example.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Database(
    entities = [
        UserEntity::class,
        PricingGridEntity::class,
        ChantierEntity::class,
        PointageEntity::class,
        AvailabilityEntity::class,
        EquipmentEntity::class,
        EquipmentTransactionEntity::class,
        PayrollAdjustmentEntity::class,
        VehicleEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun pricingGridDao(): PricingGridDao
    abstract fun chantierDao(): ChantierDao
    abstract fun pointageDao(): PointageDao
    abstract fun availabilityDao(): AvailabilityDao
    abstract fun equipmentDao(): EquipmentDao
    abstract fun equipmentTransactionDao(): EquipmentTransactionDao
    abstract fun payrollAdjustmentDao(): PayrollAdjustmentDao
    abstract fun vehicleDao(): VehicleDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "as_one_database"
                )
                    .addCallback(DatabaseCallback(context))
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }

    private class DatabaseCallback(
        private val context: Context
    ) : RoomDatabase.Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)
            CoroutineScope(Dispatchers.IO).launch {
                val database = getDatabase(context)
                populateInitialData(database)
            }
        }

        private suspend fun populateInitialData(db: AppDatabase) {
            // Initial pricing grid
            db.pricingGridDao().setPricingGrid(
                PricingGridEntity(
                    id = 1,
                    standardDayRate = 2500.0,
                    nightRate = 4500.0,
                    sundayRate = 5000.0
                )
            )

            // Initial Accounts
            val users = listOf(
                UserEntity("DIR01", "Kofi Lawson (Direction)", "+228 90 00 11 22", UserRole.ADMIN_DIRECTION.name, AgentStatus.PERMANENT.name, false, "T-Money", 250000.0),
                UserEntity("COMP01", "Amina Badarou (Comptabilité)", "+228 91 22 33 44", UserRole.COMPTABLE.name, AgentStatus.PERMANENT.name, false, "Flooz", 180000.0),
                UserEntity("CHEF01", "Jean-Baptiste Mensah (Chef de Chantier)", "+228 92 33 44 55", UserRole.CHEF_CHANTIER.name, AgentStatus.PERMANENT.name, false, "T-Money", 120000.0),
                UserEntity("MAG01", "Ekoué Tossou (Magasinier)", "+228 93 44 55 66", UserRole.MAGASINIER.name, AgentStatus.PERMANENT.name, false, "T-Money", 100000.0),
                
                // Agents de nettoyage / Ouvriers (Temporaires & Permanents)
                UserEntity("AGT01", "Kossi Agbeko", "+228 96 11 22 33", UserRole.AGENT_CLEANING.name, AgentStatus.TEMPORAIRE.name, false, "T-Money"),
                UserEntity("AGT02", "Ablavi Dogbé", "+228 97 22 33 44", UserRole.AGENT_CLEANING.name, AgentStatus.TEMPORAIRE.name, false, "Flooz"),
                UserEntity("AGT03", "Yawovi Amédée", "+228 98 33 44 55", UserRole.AGENT_CLEANING.name, AgentStatus.TEMPORAIRE.name, false, "T-Money"),
                UserEntity("AGT04", "Akouba Sossou", "+228 99 44 55 66", UserRole.AGENT_CLEANING.name, AgentStatus.PERMANENT.name, false, "Flooz", 85000.0),
                UserEntity("AGT05", "Kodjo Fiagbé", "+228 90 55 66 77", UserRole.AGENT_CLEANING.name, AgentStatus.PERMANENT.name, false, "T-Money", 85000.0)
            )
            users.forEach { db.userDao().insertOrUpdateUser(it) }

            // Initial Sites
            val chantiers = listOf(
                ChantierEntity("CHT01", "Banque Oragroup - Siège", "Lomé, Bd du 13 Janvier", "CHEF01", "Jean-Baptiste Mensah"),
                ChantierEntity("CHT02", "Hôtel 2 Février - Salles Polyvalentes", "Lomé Centre", "CHEF01", "Jean-Baptiste Mensah"),
                ChantierEntity("CHT03", "Port Autonome - Magasin Hangar 4", "Zone Portuaire", "CHEF01", "Jean-Baptiste Mensah")
            )
            chantiers.forEach { db.chantierDao().insertChantier(it) }

            // Initial Equipment
            val equipmentList = listOf(
                EquipmentEntity("EQ01", "Aspirateur Industriel Wet&Dry #1", "TRACEABLE", 3, 2, 185000.0),
                EquipmentEntity("EQ02", "Monobrosse Haute Vitesse Kärcher", "TRACEABLE", 2, 1, 320000.0),
                EquipmentEntity("EQ03", "Injecteur/Extracteur Moquette", "TRACEABLE", 2, 2, 240000.0),
                EquipmentEntity("EQ04", "Lot Microfibres & Raclettes Vitres", "CONSUMABLE", 50, 42, 15000.0),
                EquipmentEntity("EQ05", "Bidons Décapant Sols 5L", "CONSUMABLE", 20, 14, 28000.0)
            )
            equipmentList.forEach { db.equipmentDao().insertEquipment(it) }

            // Initial Vehicles
            val vehicles = listOf(
                VehicleEntity("VEH01", "TG-4521-BN", "Toyota HiAce Van Dépôt", "2025-08-12", 365, "2026-05-10", 90),
                VehicleEntity("VEH02", "TG-8832-AP", "Pickup Isuzu Chantiers", "2026-08-01", 365, "2026-07-28", 90)
            )
            vehicles.forEach { db.vehicleDao().insertVehicle(it) }

            // Initial availabilities for demo
            val today = "2026-08-07"
            val tomorrow = "2026-08-08"
            val availabilities = listOf(
                AvailabilityEntity("AGT01_$today", "AGT01", today, true),
                AvailabilityEntity("AGT01_$tomorrow", "AGT01", tomorrow, true),
                AvailabilityEntity("AGT02_$today", "AGT02", today, true),
                AvailabilityEntity("AGT02_$tomorrow", "AGT02", tomorrow, true),
                AvailabilityEntity("AGT03_$today", "AGT03", today, true),
                AvailabilityEntity("AGT03_$tomorrow", "AGT03", tomorrow, true)
            )
            availabilities.forEach { db.availabilityDao().setAvailability(it) }

            // Initial Pointages for demo
            val initialPointages = listOf(
                PointageEntity(
                    id = "PTG_AGT01_$today",
                    date = today,
                    chantierId = "CHT01",
                    chantierName = "Banque Oragroup - Siège",
                    agentId = "AGT01",
                    agentName = "Kossi Agbeko",
                    agentStatus = "TEMPORAIRE",
                    shiftType = ShiftType.JOURNEE.name,
                    rateAmount = 2500.0,
                    photoProofUri = "photo_proof_oragroup_group1",
                    validatedByChefId = "CHEF01",
                    validatedByChefName = "Jean-Baptiste Mensah"
                ),
                PointageEntity(
                    id = "PTG_AGT02_$today",
                    date = today,
                    chantierId = "CHT01",
                    chantierName = "Banque Oragroup - Siège",
                    agentId = "AGT02",
                    agentName = "Ablavi Dogbé",
                    agentStatus = "TEMPORAIRE",
                    shiftType = ShiftType.JOURNEE.name,
                    rateAmount = 2500.0,
                    photoProofUri = "photo_proof_oragroup_group1",
                    validatedByChefId = "CHEF01",
                    validatedByChefName = "Jean-Baptiste Mensah"
                )
            )
            db.pointageDao().insertPointages(initialPointages)
        }
    }
}
