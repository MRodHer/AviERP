/*
  # Módulo de Contabilidad
  
  ## Tablas Creadas
  
  ### 1. Catálogo de Cuentas
  - `chart_of_accounts` - Plan de cuentas contable
    - Código SAT (Anexo 24)
    - Niveles jerárquicos
  
  ### 2. Códigos SAT
  - `sat_account_codes` - Catálogo oficial SAT
    - 800+ códigos agrupadores
  
  ### 3. Pólizas Contables
  - `journal_entries` - Libro diario
    - Pólizas de diario, ingresos, egresos
  
  ### 4. Líneas de Póliza
  - `journal_entry_lines` - Movimientos de partida doble
    - Debe y haber
  
  ### 5. Períodos Contables
  - `accounting_periods` - Control de períodos
    - Apertura/cierre mensual
  
  ## Seguridad
  - RLS habilitado
  - Validación de partida doble
*/

-- Tabla de códigos SAT (Anexo 24)
CREATE TABLE IF NOT EXISTS sat_account_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  level INTEGER NOT NULL,
  parent_code VARCHAR(20),
  nature VARCHAR(10) CHECK (nature IN ('deudora', 'acreedora')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sat_codes_code ON sat_account_codes(code);
CREATE INDEX idx_sat_codes_level ON sat_account_codes(level);

ALTER TABLE sat_account_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all SAT codes"
  ON sat_account_codes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage SAT codes"
  ON sat_account_codes FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Insertar códigos SAT básicos (muestra - se agregarían los 800+ del anexo 24)
INSERT INTO sat_account_codes (code, name, level, nature) VALUES
('100', 'ACTIVO', 1, 'deudora'),
('100.01', 'ACTIVO CIRCULANTE', 2, 'deudora'),
('101', 'CAJA', 3, 'deudora'),
('102', 'BANCOS', 3, 'deudora'),
('103', 'CLIENTES', 3, 'deudora'),
('115', 'INVENTARIOS', 3, 'deudora'),
('200', 'PASIVO', 1, 'acreedora'),
('200.01', 'PASIVO A CORTO PLAZO', 2, 'acreedora'),
('201', 'PROVEEDORES', 3, 'acreedora'),
('300', 'CAPITAL CONTABLE', 1, 'acreedora'),
('301', 'CAPITAL SOCIAL', 3, 'acreedora'),
('400', 'INGRESOS', 1, 'acreedora'),
('401', 'VENTAS', 3, 'acreedora'),
('500', 'COSTOS Y GASTOS', 1, 'deudora'),
('501', 'COSTO DE VENTAS', 3, 'deudora'),
('601', 'GASTOS DE OPERACIÓN', 3, 'deudora')
ON CONFLICT (code) DO NOTHING;

-- Tabla de catálogo de cuentas
CREATE TABLE IF NOT EXISTS chart_of_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_code VARCHAR(50) UNIQUE NOT NULL,
  account_name VARCHAR(255) NOT NULL,
  account_type VARCHAR(30) NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'revenue', 'expense', 'cost')),
  account_subtype VARCHAR(50),
  sat_code_id UUID REFERENCES sat_account_codes(id),
  parent_account_id UUID REFERENCES chart_of_accounts(id),
  level INTEGER NOT NULL DEFAULT 1,
  is_header BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  normal_balance VARCHAR(10) CHECK (normal_balance IN ('debit', 'credit')),
  allows_entries BOOLEAN DEFAULT true,
  current_balance DECIMAL(15,2) DEFAULT 0,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_coa_code ON chart_of_accounts(account_code);
CREATE INDEX idx_coa_type ON chart_of_accounts(account_type);
CREATE INDEX idx_coa_sat_code ON chart_of_accounts(sat_code_id);
CREATE INDEX idx_coa_active ON chart_of_accounts(is_active);

ALTER TABLE chart_of_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all accounts"
  ON chart_of_accounts FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can manage accounts"
  ON chart_of_accounts FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Tabla de períodos contables
CREATE TABLE IF NOT EXISTS accounting_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  period_year INTEGER NOT NULL,
  period_month INTEGER NOT NULL CHECK (period_month BETWEEN 1 AND 12),
  period_name VARCHAR(50) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'closed', 'locked')),
  closed_by UUID REFERENCES auth.users(id),
  closed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(period_year, period_month)
);

CREATE INDEX idx_periods_year_month ON accounting_periods(period_year, period_month);
CREATE INDEX idx_periods_status ON accounting_periods(status);

ALTER TABLE accounting_periods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all periods"
  ON accounting_periods FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage periods"
  ON accounting_periods FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

-- Tabla de pólizas contables (journal entries)
CREATE TABLE IF NOT EXISTS journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_number VARCHAR(50) UNIQUE NOT NULL,
  entry_type VARCHAR(20) NOT NULL CHECK (entry_type IN ('standard', 'opening', 'closing', 'adjustment')),
  entry_date DATE NOT NULL,
  period_id UUID REFERENCES accounting_periods(id),
  description TEXT NOT NULL,
  reference_type VARCHAR(50),
  reference_id UUID,
  reference_number VARCHAR(100),
  total_debit DECIMAL(15,2) DEFAULT 0,
  total_credit DECIMAL(15,2) DEFAULT 0,
  is_balanced BOOLEAN GENERATED ALWAYS AS (total_debit = total_credit) STORED,
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'posted', 'void')),
  posted_by UUID REFERENCES auth.users(id),
  posted_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_journal_entries_number ON journal_entries(entry_number);
CREATE INDEX idx_journal_entries_date ON journal_entries(entry_date);
CREATE INDEX idx_journal_entries_type ON journal_entries(entry_type);
CREATE INDEX idx_journal_entries_status ON journal_entries(status);
CREATE INDEX idx_journal_entries_period ON journal_entries(period_id);

ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all journal entries"
  ON journal_entries FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create journal entries"
  ON journal_entries FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update draft entries"
  ON journal_entries FOR UPDATE
  TO authenticated
  USING (status = 'draft')
  WITH CHECK (true);

-- Tabla de líneas de póliza
CREATE TABLE IF NOT EXISTS journal_entry_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
  line_number INTEGER NOT NULL,
  account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
  description TEXT,
  debit_amount DECIMAL(15,2) DEFAULT 0 CHECK (debit_amount >= 0),
  credit_amount DECIMAL(15,2) DEFAULT 0 CHECK (credit_amount >= 0),
  reference_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(journal_entry_id, line_number),
  CHECK (NOT (debit_amount > 0 AND credit_amount > 0))
);

CREATE INDEX idx_journal_lines_entry ON journal_entry_lines(journal_entry_id);
CREATE INDEX idx_journal_lines_account ON journal_entry_lines(account_id);

ALTER TABLE journal_entry_lines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all journal entry lines"
  ON journal_entry_lines FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can manage journal entry lines"
  ON journal_entry_lines FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Vista de libro mayor (general ledger)
CREATE OR REPLACE VIEW general_ledger AS
SELECT 
  jel.account_id,
  coa.account_code,
  coa.account_name,
  je.entry_date,
  je.entry_number,
  je.description as entry_description,
  jel.description as line_description,
  jel.debit_amount,
  jel.credit_amount,
  CASE 
    WHEN coa.normal_balance = 'debit' THEN 
      SUM(jel.debit_amount - jel.credit_amount) OVER (PARTITION BY jel.account_id ORDER BY je.entry_date, je.entry_number, jel.line_number)
    ELSE 
      SUM(jel.credit_amount - jel.debit_amount) OVER (PARTITION BY jel.account_id ORDER BY je.entry_date, je.entry_number, jel.line_number)
  END as running_balance
FROM journal_entry_lines jel
JOIN journal_entries je ON jel.journal_entry_id = je.id
JOIN chart_of_accounts coa ON jel.account_id = coa.id
WHERE je.status = 'posted'
ORDER BY jel.account_id, je.entry_date, je.entry_number, jel.line_number;

-- Vista de balanza de comprobación (trial balance)
CREATE OR REPLACE VIEW trial_balance AS
SELECT 
  coa.id as account_id,
  coa.account_code,
  coa.account_name,
  coa.account_type,
  coa.normal_balance,
  COALESCE(SUM(jel.debit_amount), 0) as total_debit,
  COALESCE(SUM(jel.credit_amount), 0) as total_credit,
  CASE 
    WHEN coa.normal_balance = 'debit' THEN 
      COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0)
    ELSE 
      COALESCE(SUM(jel.credit_amount - jel.debit_amount), 0)
  END as balance
FROM chart_of_accounts coa
LEFT JOIN journal_entry_lines jel ON coa.id = jel.account_id
LEFT JOIN journal_entries je ON jel.journal_entry_id = je.id AND je.status = 'posted'
WHERE coa.is_active = true AND coa.allows_entries = true
GROUP BY coa.id, coa.account_code, coa.account_name, coa.account_type, coa.normal_balance
HAVING COALESCE(SUM(jel.debit_amount), 0) != 0 OR COALESCE(SUM(jel.credit_amount), 0) != 0
ORDER BY coa.account_code;

-- Triggers para updated_at
CREATE TRIGGER update_chart_of_accounts_updated_at BEFORE UPDATE ON chart_of_accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_journal_entries_updated_at BEFORE UPDATE ON journal_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para calcular totales de póliza
CREATE OR REPLACE FUNCTION calculate_journal_entry_totals()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE journal_entries
  SET 
    total_debit = (SELECT COALESCE(SUM(debit_amount), 0) FROM journal_entry_lines WHERE journal_entry_id = NEW.journal_entry_id),
    total_credit = (SELECT COALESCE(SUM(credit_amount), 0) FROM journal_entry_lines WHERE journal_entry_id = NEW.journal_entry_id)
  WHERE id = NEW.journal_entry_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_totals
  AFTER INSERT OR UPDATE ON journal_entry_lines
  FOR EACH ROW
  EXECUTE FUNCTION calculate_journal_entry_totals();