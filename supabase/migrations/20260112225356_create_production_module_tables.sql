/*
  # Módulo de Producción Avícola
  
  ## Tablas Creadas
  
  ### 1. Parvadas (Lotes de Aves)
  - `flocks` - Registro de parvadas/lotes
    - Datos: fecha ingreso, cantidad inicial, tipo (postura/engorda)
    - Referencia a raza/línea genética
  
  ### 2. Producción Diaria
  - `daily_production` - Registro diario de producción de huevo
    - Huevos recolectados, clasificados por tamaño
    - Porcentaje de postura
  
  ### 3. Mortalidad
  - `mortality_records` - Registro de bajas y mortalidad
    - Fecha, cantidad, causa, observaciones
  
  ### 4. Consumo de Alimento
  - `feed_consumption` - Registro de consumo diario
    - Cantidad consumida, cálculo de conversión alimenticia
  
  ### 5. Muestras de Peso
  - `weight_samples` - Pesos de muestras para seguimiento
    - Para pollos de engorda
  
  ## Seguridad
  - RLS habilitado
  - Solo usuarios autenticados pueden acceder
*/

-- Tabla de parvadas/lotes
CREATE TABLE IF NOT EXISTS flocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flock_number VARCHAR(50) UNIQUE NOT NULL,
  flock_type VARCHAR(20) NOT NULL CHECK (flock_type IN ('layers', 'broilers')),
  breed VARCHAR(100) DEFAULT 'Ross 308',
  entry_date DATE NOT NULL,
  initial_quantity INTEGER NOT NULL CHECK (initial_quantity > 0),
  current_quantity INTEGER NOT NULL,
  birth_date DATE,
  expected_end_date DATE,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'closed')),
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_flocks_status ON flocks(status);
CREATE INDEX idx_flocks_type ON flocks(flock_type);
CREATE INDEX idx_flocks_entry_date ON flocks(entry_date);

ALTER TABLE flocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all flocks"
  ON flocks FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create flocks"
  ON flocks FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update flocks"
  ON flocks FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Tabla de producción diaria
CREATE TABLE IF NOT EXISTS daily_production (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flock_id UUID NOT NULL REFERENCES flocks(id) ON DELETE CASCADE,
  production_date DATE NOT NULL,
  eggs_jumbo INTEGER DEFAULT 0 CHECK (eggs_jumbo >= 0),
  eggs_extra_large INTEGER DEFAULT 0 CHECK (eggs_extra_large >= 0),
  eggs_large INTEGER DEFAULT 0 CHECK (eggs_large >= 0),
  eggs_medium INTEGER DEFAULT 0 CHECK (eggs_medium >= 0),
  eggs_small INTEGER DEFAULT 0 CHECK (eggs_small >= 0),
  eggs_dirty INTEGER DEFAULT 0 CHECK (eggs_dirty >= 0),
  eggs_broken INTEGER DEFAULT 0 CHECK (eggs_broken >= 0),
  total_eggs INTEGER GENERATED ALWAYS AS (
    eggs_jumbo + eggs_extra_large + eggs_large + eggs_medium + eggs_small + eggs_dirty + eggs_broken
  ) STORED,
  hen_count INTEGER NOT NULL,
  laying_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
    CASE WHEN hen_count > 0 THEN (eggs_jumbo + eggs_extra_large + eggs_large + eggs_medium + eggs_small)::DECIMAL / hen_count * 100 ELSE 0 END
  ) STORED,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(flock_id, production_date)
);

CREATE INDEX idx_daily_production_flock ON daily_production(flock_id);
CREATE INDEX idx_daily_production_date ON daily_production(production_date);

ALTER TABLE daily_production ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all production"
  ON daily_production FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create production records"
  ON daily_production FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update production records"
  ON daily_production FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Tabla de mortalidad
CREATE TABLE IF NOT EXISTS mortality_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flock_id UUID NOT NULL REFERENCES flocks(id) ON DELETE CASCADE,
  mortality_date DATE NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  cause VARCHAR(100),
  age_weeks INTEGER,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_mortality_flock ON mortality_records(flock_id);
CREATE INDEX idx_mortality_date ON mortality_records(mortality_date);

ALTER TABLE mortality_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all mortality records"
  ON mortality_records FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create mortality records"
  ON mortality_records FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update mortality records"
  ON mortality_records FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Tabla de consumo de alimento
CREATE TABLE IF NOT EXISTS feed_consumption (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flock_id UUID NOT NULL REFERENCES flocks(id) ON DELETE CASCADE,
  consumption_date DATE NOT NULL,
  feed_kg DECIMAL(10,2) NOT NULL CHECK (feed_kg >= 0),
  feed_type VARCHAR(100),
  bird_count INTEGER NOT NULL,
  feed_per_bird DECIMAL(8,4) GENERATED ALWAYS AS (
    CASE WHEN bird_count > 0 THEN feed_kg / bird_count ELSE 0 END
  ) STORED,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(flock_id, consumption_date)
);

CREATE INDEX idx_feed_consumption_flock ON feed_consumption(flock_id);
CREATE INDEX idx_feed_consumption_date ON feed_consumption(consumption_date);

ALTER TABLE feed_consumption ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all feed consumption"
  ON feed_consumption FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create feed consumption records"
  ON feed_consumption FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update feed consumption records"
  ON feed_consumption FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Tabla de muestras de peso (para pollos de engorda)
CREATE TABLE IF NOT EXISTS weight_samples (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flock_id UUID NOT NULL REFERENCES flocks(id) ON DELETE CASCADE,
  sample_date DATE NOT NULL,
  age_weeks INTEGER NOT NULL,
  sample_size INTEGER NOT NULL CHECK (sample_size > 0),
  total_weight_kg DECIMAL(10,2) NOT NULL CHECK (total_weight_kg > 0),
  average_weight_kg DECIMAL(8,4) GENERATED ALWAYS AS (
    total_weight_kg / sample_size
  ) STORED,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_weight_samples_flock ON weight_samples(flock_id);
CREATE INDEX idx_weight_samples_date ON weight_samples(sample_date);

ALTER TABLE weight_samples ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all weight samples"
  ON weight_samples FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create weight samples"
  ON weight_samples FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update weight samples"
  ON weight_samples FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Triggers para updated_at
CREATE TRIGGER update_flocks_updated_at BEFORE UPDATE ON flocks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_production_updated_at BEFORE UPDATE ON daily_production
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mortality_records_updated_at BEFORE UPDATE ON mortality_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_feed_consumption_updated_at BEFORE UPDATE ON feed_consumption
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_weight_samples_updated_at BEFORE UPDATE ON weight_samples
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para actualizar current_quantity en flocks cuando hay mortalidad
CREATE OR REPLACE FUNCTION update_flock_quantity_on_mortality()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE flocks
  SET current_quantity = current_quantity - NEW.quantity
  WHERE id = NEW.flock_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_flock_quantity
  AFTER INSERT ON mortality_records
  FOR EACH ROW
  EXECUTE FUNCTION update_flock_quantity_on_mortality();