/*
  # Sistema ERP Avícola - Esquema Base
  
  ## Tablas Creadas
  
  ### 1. Sistema de Módulos
  - `system_modules` - Control de activación/desactivación de módulos
  
  ### 2. Usuarios y Perfiles
  - `user_profiles` - Perfiles extendidos de usuarios
  
  ### 3. Configuración del Sistema
  - `system_config` - Configuraciones globales
  
  ## Seguridad
  - RLS habilitado en todas las tablas
  - Políticas restrictivas por rol
*/

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tabla de perfiles de usuario (crear primero)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  role VARCHAR(20) DEFAULT 'operator' CHECK (role IN ('admin', 'manager', 'operator')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid()
      AND up.role = 'admin'
    )
  );

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Tabla de módulos del sistema
CREATE TABLE IF NOT EXISTS system_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_key VARCHAR(50) UNIQUE NOT NULL,
  module_name VARCHAR(100) NOT NULL,
  description TEXT,
  is_enabled BOOLEAN DEFAULT false,
  requires_modules TEXT[] DEFAULT '{}',
  config JSONB DEFAULT '{}',
  icon VARCHAR(50) DEFAULT 'Circle',
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE system_modules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view enabled modules"
  ON system_modules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can modify modules"
  ON system_modules FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

CREATE TRIGGER update_system_modules_updated_at BEFORE UPDATE ON system_modules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Tabla de configuración del sistema
CREATE TABLE IF NOT EXISTS system_config (
  key VARCHAR(100) PRIMARY KEY,
  value JSONB NOT NULL DEFAULT '{}',
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view config"
  ON system_config FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can modify config"
  ON system_config FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

CREATE TRIGGER update_system_config_updated_at BEFORE UPDATE ON system_config
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insertar módulos del sistema
INSERT INTO system_modules (module_key, module_name, description, is_enabled, requires_modules, icon, sort_order) VALUES
('dashboard', 'Dashboard', 'Panel principal con KPIs y métricas', true, '{}', 'LayoutDashboard', 1),
('production', 'Producción Avícola', 'Control de parvadas, producción de huevo y pollo', true, '{}', 'Egg', 2),
('inventory', 'Inventario', 'Gestión de alimentos, insumos y productos', true, '{}', 'Package', 3),
('suppliers', 'Proveedores', 'Catálogo y gestión de proveedores', true, '{}', 'Truck', 4),
('customers', 'Clientes', 'Catálogo y cartera de clientes', true, '{}', 'Users', 5),
('purchases', 'Compras', 'Órdenes de compra y cuentas por pagar', true, '{suppliers,inventory}', 'ShoppingCart', 6),
('sales', 'Ventas', 'Cotizaciones, pedidos y facturación', true, '{customers,inventory}', 'ShoppingBag', 7),
('treasury', 'Tesorería', 'Bancos, conciliación y flujo de efectivo', true, '{}', 'Landmark', 8),
('accounting', 'Contabilidad', 'Catálogo de cuentas, pólizas y mayor', true, '{}', 'Calculator', 9),
('ai_classification', 'Clasificación IA', 'Clasificación automática con RAG', false, '{accounting}', 'Brain', 10),
('financial_statements', 'Estados Financieros', 'Balance, Estado de Resultados, Flujo', true, '{accounting}', 'FileText', 11),
('fiscal_emulator', 'Emulador Fiscal', 'Proyecciones ISR/IVA', false, '{accounting}', 'DollarSign', 12),
('ledger', 'Ledger Inmutable', 'Registro inmutable de operaciones', true, '{}', 'Lock', 13),
('legal', 'Legal', 'Contratos y documentos legales', false, '{}', 'Scale', 14),
('reports', 'Reportes', 'Generación de reportes', true, '{}', 'FileSpreadsheet', 15),
('settings', 'Configuración', 'Configuración del sistema', true, '{}', 'Settings', 99)
ON CONFLICT (module_key) DO UPDATE SET
  module_name = EXCLUDED.module_name,
  description = EXCLUDED.description,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order;

-- Configuraciones iniciales del sistema
INSERT INTO system_config (key, value, description) VALUES
('company_info', '{"name": "Avícola Metepec", "rfc": "", "address": "Metepec, Estado de México", "phone": "", "email": ""}', 'Información de la empresa'),
('currency', '{"code": "MXN", "symbol": "$", "decimals": 2}', 'Configuración de moneda'),
('fiscal_year_start', '{"month": 1, "day": 1}', 'Inicio del año fiscal'),
('production_standards', '{"ross_308": true, "target_fcr": 1.85, "target_mortality": 5.0}', 'Estándares de producción avícola')
ON CONFLICT (key) DO NOTHING;