package com.example.data.remote

import retrofit2.Response
import retrofit2.http.*
import okhttp3.MultipartBody
import okhttp3.RequestBody

// Request DTOs
data class LoginRequest(
    val phone: String,
    val password: String
)

data class AuthResponse(
    val message: String,
    val token: String?,
    val user: ApiUser?
)

data class ApiUser(
    val id: String,
    val name: String,
    val phone: String,
    val email: String? = null,
    val role: String,
    val status: String,
    val is_suspended: Boolean = false,
    val payment_operator: String = "T-Money",
    val fixed_monthly_salary: Double = 85000.0
)

data class CreateUserRequest(
    val name: String,
    val phone: String,
    val password: String,
    val role: String,
    val status: String,
    val payment_operator: String = "T-Money",
    val fixed_monthly_salary: Double = 85000.0
)

data class UpdateProfileRequest(
    val name: String? = null,
    val phone: String? = null,
    val payment_operator: String? = null,
    val password: String? = null
)

data class PricingGridResponse(
    val id: Int = 1,
    val standard_day_rate: Double = 2500.0,
    val night_rate: Double = 4500.0,
    val sunday_rate: Double = 5000.0
)

data class UpdatePricingGridRequest(
    val standard_day_rate: Double,
    val night_rate: Double,
    val sunday_rate: Double
)

data class ChantierResponse(
    val id: String,
    val name: String,
    val location: String,
    val assigned_chef_id: String?,
    val chef: ApiUser?
)

data class CreateChantierRequest(
    val name: String,
    val location: String,
    val assigned_chef_id: String
)

data class PointageAgentDto(
    val agent_id: String,
    val shift_type: String,
    val is_replacement: Boolean = false,
    val replaced_permanent_id: String? = null
)

data class SubmitPointageResponse(
    val message: String,
    val count: Int,
    val photo_url: String?
)

data class EquipmentDto(
    val id: String,
    val name: String,
    val category: String,
    val total_quantity: Int,
    val available_quantity: Int,
    val unit_value: Double
)

data class EquipmentReturnRequest(
    val equipment_id: String,
    val chantier_id: String,
    val agent_or_chef_id: String,
    val quantity_returned: Int,
    val condition: String, // BON, DEGRADE, MANQUANT
    val is_indulgence_granted: Boolean,
    val sanction_type: String, // NONE, INDIVIDUAL, COLLECTIVE
    val date: String
)

data class PayrollSummaryItem(
    val agent_id: String,
    val name: String,
    val phone: String,
    val role: String,
    val status: String,
    val payment_operator: String,
    val fixed_monthly_salary: Double,
    val shifts_count: Int,
    val gross_shifts: Double,
    val gross_total: Double,
    val primes: Double,
    val advances: Double,
    val penalties: Double,
    val net_salary: Double,
    val notes: String
)

data class PayrollSummaryResponse(
    val period: String,
    val summary: List<PayrollSummaryItem>
)

data class PayrollAdjustmentRequest(
    val agent_id: String,
    val period: String,
    val primes: Double,
    val advances: Double,
    val penalties: Double,
    val notes: String
)

data class VehicleDto(
    val id: String,
    val immatriculation: String,
    val model_name: String,
    val last_assurance_date: String,
    val assurance_validity_days: Int,
    val last_vidange_date: String,
    val vidange_validity_days: Int,
    val assurance_days_remaining: Int = 0,
    val vidange_days_remaining: Int = 0,
    val has_assurance_alert: Boolean = false,
    val has_vidange_alert: Boolean = false
)

interface AsOneApiService {

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>

    @GET("auth/me")
    suspend fun me(@Header("Authorization") token: String): Response<AuthResponse>

    @POST("auth/logout")
    suspend fun logout(@Header("Authorization") token: String): Response<Map<String, String>>

    @GET("users")
    suspend fun getUsers(@Header("Authorization") token: String): Response<List<ApiUser>>

    @POST("users")
    suspend fun createUser(
        @Header("Authorization") token: String,
        @Body request: CreateUserRequest
    ): Response<AuthResponse>

    @PATCH("users/{id}/suspend")
    suspend fun toggleSuspension(
        @Header("Authorization") token: String,
        @Path("id") userId: String
    ): Response<AuthResponse>

    @PUT("users/profile")
    suspend fun updateSelfProfile(
        @Header("Authorization") token: String,
        @Body request: UpdateProfileRequest
    ): Response<AuthResponse>

    @GET("pricing-grid")
    suspend fun getPricingGrid(@Header("Authorization") token: String): Response<PricingGridResponse>

    @PUT("pricing-grid")
    suspend fun updatePricingGrid(
        @Header("Authorization") token: String,
        @Body request: UpdatePricingGridRequest
    ): Response<Map<String, Any>>

    @GET("chantiers")
    suspend fun getChantiers(@Header("Authorization") token: String): Response<List<ChantierResponse>>

    @POST("chantiers")
    suspend fun createChantier(
        @Header("Authorization") token: String,
        @Body request: CreateChantierRequest
    ): Response<Map<String, Any>>

    @GET("equipment")
    suspend fun getEquipment(@Header("Authorization") token: String): Response<List<EquipmentDto>>

    @POST("equipment/return")
    suspend fun recordEquipmentReturn(
        @Header("Authorization") token: String,
        @Body request: EquipmentReturnRequest
    ): Response<Map<String, Any>>

    @GET("payroll/summary")
    suspend fun getPayrollSummary(
        @Header("Authorization") token: String,
        @Query("period") period: String? = null
    ): Response<PayrollSummaryResponse>

    @POST("payroll/adjustments")
    suspend fun savePayrollAdjustment(
        @Header("Authorization") token: String,
        @Body request: PayrollAdjustmentRequest
    ): Response<Map<String, Any>>

    @GET("vehicles")
    suspend fun getVehicles(@Header("Authorization") token: String): Response<List<VehicleDto>>

    @GET("vehicles/alerts")
    suspend fun getVehicleAlerts(@Header("Authorization") token: String): Response<Map<String, Any>>
}
