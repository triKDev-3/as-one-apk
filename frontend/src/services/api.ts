const BASE_URL = 'http://localhost:8000/api';

export interface User {
  id: number | string;
  name: string;
  phone: string;
  email?: string;
  role: 'admin_direction' | 'comptable' | 'chef_chantier' | 'magasinier' | 'agent_cleaning';
  status: 'temporaire' | 'permanent';
  is_suspended: boolean;
  payment_operator: 'T-Money' | 'Flooz';
  fixed_monthly_salary: number;
}

export interface PricingGrid {
  id: number;
  standard_day_rate: number;
  night_rate: number;
  sunday_rate: number;
}

export interface Chantier {
  id: number | string;
  name: string;
  location: string;
  assigned_chef_id: number | string;
  chef?: User;
}

export interface Equipment {
  id: number | string;
  name: string;
  category: 'TRACEABLE' | 'CONSUMABLE';
  total_quantity: number;
  available_quantity: number;
  unit_value: number;
}

export interface PayrollSummaryItem {
  agent_id: number | string;
  name: string;
  phone: string;
  role: string;
  status: string;
  payment_operator: string;
  fixed_monthly_salary: number;
  shifts_count: number;
  gross_shifts: number;
  gross_total: number;
  primes: number;
  advances: number;
  penalties: number;
  net_salary: number;
  notes: string;
}

export interface Vehicle {
  id: number | string;
  immatriculation: string;
  model_name: string;
  last_assurance_date: string;
  assurance_validity_days: number;
  last_vidange_date: string;
  vidange_validity_days: number;
  assurance_days_remaining?: number;
  vidange_days_remaining?: number;
  has_assurance_alert?: boolean;
  has_vidange_alert?: boolean;
}

class ApiService {
  private token: string | null = localStorage.getItem('as_one_token');

  setToken(token: string | null) {
    this.token = token;
    if (token) {
      localStorage.setItem('as_one_token', token);
    } else {
      localStorage.removeItem('as_one_token');
    }
  }

  getToken() {
    return this.token;
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...(options.headers as Record<string, string>),
    };

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const response = await fetch(`${BASE_URL}/${endpoint}`, {
      ...options,
      headers,
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Une erreur est survenue lors de la requête');
    }

    return data as T;
  }

  // Auth
  async login(phone: string, password: string) {
    const res = await this.request<{ message: string; token: string; user: User }>('auth/login', {
      method: 'POST',
      body: JSON.stringify({ phone, password }),
    });
    if (res.token) {
      this.setToken(res.token);
    }
    return res;
  }

  async me() {
    return this.request<{ user: User }>('auth/me');
  }

  logout() {
    this.setToken(null);
  }

  // Users
  async getUsers() {
    return this.request<User[]>('users');
  }

  async createUser(user: Partial<User> & { password: string }) {
    return this.request<{ message: string; user: User }>('users', {
      method: 'POST',
      body: JSON.stringify(user),
    });
  }

  async toggleSuspension(userId: number | string) {
    return this.request<{ message: string; user: User }>(`users/${userId}/suspend`, {
      method: 'PATCH',
    });
  }

  // Pricing Grid
  async getPricingGrid() {
    return this.request<PricingGrid>('pricing-grid');
  }

  async updatePricingGrid(standard_day_rate: number, night_rate: number, sunday_rate: number) {
    return this.request<{ message: string; pricing_grid: PricingGrid }>('pricing-grid', {
      method: 'PUT',
      body: JSON.stringify({ standard_day_rate, night_rate, sunday_rate }),
    });
  }

  // Chantiers
  async getChantiers() {
    return this.request<Chantier[]>('chantiers');
  }

  async createChantier(name: string, location: string, assigned_chef_id: number | string) {
    return this.request<{ message: string; chantier: Chantier }>('chantiers', {
      method: 'POST',
      body: JSON.stringify({ name, location, assigned_chef_id }),
    });
  }

  // Pointages
  async submitPointage(formData: FormData) {
    const headers: Record<string, string> = {};
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const response = await fetch(`${BASE_URL}/pointages`, {
      method: 'POST',
      headers,
      body: formData,
    });

    return response.json();
  }

  // Equipment
  async getEquipment() {
    return this.request<Equipment[]>('equipment');
  }

  async recordEquipmentReturn(data: {
    equipment_id: number | string;
    chantier_id: number | string;
    agent_or_chef_id: number | string;
    quantity_returned: number;
    condition: string;
    is_indulgence_granted: boolean;
    sanction_type: string;
    date: string;
  }) {
    return this.request<{ message: string }>('equipment/return', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  // Payroll
  async getPayrollSummary(period?: string) {
    const query = period ? `?period=${period}` : '';
    return this.request<{ period: string; summary: PayrollSummaryItem[] }>(`payroll/summary${query}`);
  }

  async savePayrollAdjustment(data: {
    agent_id: number | string;
    period: string;
    primes: number;
    advances: number;
    penalties: number;
    notes: string;
  }) {
    return this.request<{ message: string }>('payroll/adjustments', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  // Vehicles
  async getVehicles() {
    return this.request<Vehicle[]>('vehicles');
  }

  async getVehicleAlerts() {
    return this.request<{ alert_count: number; vehicles: Vehicle[] }>('vehicles/alerts');
  }
}

export const api = new ApiService();
