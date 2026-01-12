export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      system_modules: {
        Row: {
          id: string
          module_key: string
          module_name: string
          description: string | null
          is_enabled: boolean
          requires_modules: string[]
          config: Json
          icon: string
          sort_order: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          module_key: string
          module_name: string
          description?: string | null
          is_enabled?: boolean
          requires_modules?: string[]
          config?: Json
          icon?: string
          sort_order?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          module_key?: string
          module_name?: string
          description?: string | null
          is_enabled?: boolean
          requires_modules?: string[]
          config?: Json
          icon?: string
          sort_order?: number
          created_at?: string
          updated_at?: string
        }
      }
      user_profiles: {
        Row: {
          id: string
          full_name: string
          phone: string | null
          role: 'admin' | 'manager' | 'operator'
          avatar_url: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          full_name: string
          phone?: string | null
          role?: 'admin' | 'manager' | 'operator'
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          full_name?: string
          phone?: string | null
          role?: 'admin' | 'manager' | 'operator'
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      flocks: {
        Row: {
          id: string
          flock_number: string
          flock_type: 'layers' | 'broilers'
          breed: string
          entry_date: string
          initial_quantity: number
          current_quantity: number
          birth_date: string | null
          expected_end_date: string | null
          status: 'active' | 'completed' | 'closed'
          notes: string | null
          created_by: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          flock_number: string
          flock_type: 'layers' | 'broilers'
          breed?: string
          entry_date: string
          initial_quantity: number
          current_quantity: number
          birth_date?: string | null
          expected_end_date?: string | null
          status?: 'active' | 'completed' | 'closed'
          notes?: string | null
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          flock_number?: string
          flock_type?: 'layers' | 'broilers'
          breed?: string
          entry_date?: string
          initial_quantity?: number
          current_quantity?: number
          birth_date?: string | null
          expected_end_date?: string | null
          status?: 'active' | 'completed' | 'closed'
          notes?: string | null
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      daily_production: {
        Row: {
          id: string
          flock_id: string
          production_date: string
          eggs_jumbo: number
          eggs_extra_large: number
          eggs_large: number
          eggs_medium: number
          eggs_small: number
          eggs_dirty: number
          eggs_broken: number
          total_eggs: number
          hen_count: number
          laying_percentage: number
          notes: string | null
          created_by: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          flock_id: string
          production_date: string
          eggs_jumbo?: number
          eggs_extra_large?: number
          eggs_large?: number
          eggs_medium?: number
          eggs_small?: number
          eggs_dirty?: number
          eggs_broken?: number
          hen_count: number
          notes?: string | null
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          flock_id?: string
          production_date?: string
          eggs_jumbo?: number
          eggs_extra_large?: number
          eggs_large?: number
          eggs_medium?: number
          eggs_small?: number
          eggs_dirty?: number
          eggs_broken?: number
          hen_count?: number
          notes?: string | null
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      inventory_items: {
        Row: {
          id: string
          sku: string
          item_name: string
          description: string | null
          category_id: string | null
          unit_of_measure: string
          min_stock: number
          max_stock: number | null
          current_stock: number
          unit_cost: number
          barcode: string | null
          is_active: boolean
          requires_batch: boolean
          notes: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          sku: string
          item_name: string
          description?: string | null
          category_id?: string | null
          unit_of_measure: string
          min_stock?: number
          max_stock?: number | null
          current_stock?: number
          unit_cost?: number
          barcode?: string | null
          is_active?: boolean
          requires_batch?: boolean
          notes?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          sku?: string
          item_name?: string
          description?: string | null
          category_id?: string | null
          unit_of_measure?: string
          min_stock?: number
          max_stock?: number | null
          current_stock?: number
          unit_cost?: number
          barcode?: string | null
          is_active?: boolean
          requires_batch?: boolean
          notes?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      chart_of_accounts: {
        Row: {
          id: string
          account_code: string
          account_name: string
          account_type: 'asset' | 'liability' | 'equity' | 'revenue' | 'expense' | 'cost'
          account_subtype: string | null
          sat_code_id: string | null
          parent_account_id: string | null
          level: number
          is_header: boolean
          is_active: boolean
          normal_balance: 'debit' | 'credit'
          allows_entries: boolean
          current_balance: number
          description: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          account_code: string
          account_name: string
          account_type: 'asset' | 'liability' | 'equity' | 'revenue' | 'expense' | 'cost'
          account_subtype?: string | null
          sat_code_id?: string | null
          parent_account_id?: string | null
          level?: number
          is_header?: boolean
          is_active?: boolean
          normal_balance: 'debit' | 'credit'
          allows_entries?: boolean
          current_balance?: number
          description?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          account_code?: string
          account_name?: string
          account_type?: 'asset' | 'liability' | 'equity' | 'revenue' | 'expense' | 'cost'
          account_subtype?: string | null
          sat_code_id?: string | null
          parent_account_id?: string | null
          level?: number
          is_header?: boolean
          is_active?: boolean
          normal_balance?: 'debit' | 'credit'
          allows_entries?: boolean
          current_balance?: number
          description?: string | null
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
  }
}
