<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\PricingGrid;
use App\Models\Chantier;
use App\Models\Equipment;
use App\Models\Vehicle;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Pricing Grid
        PricingGrid::updateOrCreate(
            ['id' => 1],
            [
                'standard_day_rate' => 2500.00,
                'night_rate' => 4500.00,
                'sunday_rate' => 5000.00,
            ]
        );

        // 2. Admin Direction
        $admin = User::create([
            'name' => 'Directeur Général AS ONE',
            'phone' => '90000001',
            'email' => 'direction@asone.tg',
            'password' => Hash::make('password'),
            'role' => 'admin_direction',
            'status' => 'permanent',
            'fixed_monthly_salary' => 350000.00,
        ]);

        // 3. Comptable
        $comptable = User::create([
            'name' => 'Chef Comptable',
            'phone' => '90000002',
            'email' => 'compta@asone.tg',
            'password' => Hash::make('password'),
            'role' => 'comptable',
            'status' => 'permanent',
            'fixed_monthly_salary' => 200000.00,
        ]);

        // 4. Chef de Chantier
        $chef1 = User::create([
            'name' => 'Koffi Chef Chantier',
            'phone' => '90000003',
            'email' => 'koffi@asone.tg',
            'password' => Hash::make('password'),
            'role' => 'chef_chantier',
            'status' => 'permanent',
            'fixed_monthly_salary' => 150000.00,
        ]);

        $chef2 = User::create([
            'name' => 'Ablavi Chef Chantier',
            'phone' => '90000004',
            'email' => 'ablavi@asone.tg',
            'password' => Hash::make('password'),
            'role' => 'chef_chantier',
            'status' => 'permanent',
            'fixed_monthly_salary' => 150000.00,
        ]);

        // 5. Magasinier
        $magasinier = User::create([
            'name' => 'Yao Magasinier',
            'phone' => '90000005',
            'email' => 'magasin@asone.tg',
            'password' => Hash::make('password'),
            'role' => 'magasinier',
            'status' => 'permanent',
            'fixed_monthly_salary' => 120000.00,
        ]);

        // 6. Agents de Nettoyage (Temporaires & Permanents)
        $agent1 = User::create([
            'name' => 'Kodjo Agbonou',
            'phone' => '90000006',
            'password' => Hash::make('password'),
            'role' => 'agent_cleaning',
            'status' => 'temporaire',
            'payment_operator' => 'T-Money',
        ]);

        $agent2 = User::create([
            'name' => 'Akossiwa Mensah',
            'phone' => '90000007',
            'password' => Hash::make('password'),
            'role' => 'agent_cleaning',
            'status' => 'temporaire',
            'payment_operator' => 'Flooz',
        ]);

        $agent3 = User::create([
            'name' => 'Fofo Lawson',
            'phone' => '90000008',
            'password' => Hash::make('password'),
            'role' => 'agent_cleaning',
            'status' => 'permanent',
            'fixed_monthly_salary' => 85000.00,
            'payment_operator' => 'T-Money',
        ]);

        // 7. Chantiers
        Chantier::create([
            'name' => 'Chantier Port Autonome de Lomé',
            'location' => 'Lomé Port',
            'assigned_chef_id' => $chef1->id,
        ]);

        Chantier::create([
            'name' => 'Chantier Siège Banque BCEAO',
            'location' => 'Lomé Centre',
            'assigned_chef_id' => $chef2->id,
        ]);

        // 8. Equipment
        Equipment::create([
            'name' => 'Aspirateur Industriel Kärcher 30L',
            'category' => 'TRACEABLE',
            'total_quantity' => 5,
            'available_quantity' => 5,
            'unit_value' => 120000.00,
        ]);

        Equipment::create([
            'name' => 'Monobrosse Haute Vitesse',
            'category' => 'TRACEABLE',
            'total_quantity' => 3,
            'available_quantity' => 3,
            'unit_value' => 250000.00,
        ]);

        Equipment::create([
            'name' => 'Pack Chiffons Microfibres (Lot 20)',
            'category' => 'CONSUMABLE',
            'total_quantity' => 50,
            'available_quantity' => 50,
            'unit_value' => 5000.00,
        ]);

        // 9. Vehicles
        Vehicle::create([
            'immatriculation' => 'TG-8842-CA',
            'model_name' => 'Toyota HiAce Fourgon',
            'last_assurance_date' => now()->subMonths(11)->addDays(20)->toDateString(), // Expiry in 15 days
            'assurance_validity_days' => 365,
            'last_vidange_date' => now()->subDays(85)->toDateString(), // Expiry in 5 days -> Alert!
            'vidange_validity_days' => 90,
        ]);
    }
}
