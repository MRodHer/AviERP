/*
  # Módulo de Inventario
  
  ## Tablas Creadas
  
  ### 1. Categorías de Inventario
  - `inventory_categories` - Clasificación de items
    - Alimento, Medicamentos, Insumos, Producto Terminado
  
  ### 2. Items de Inventario
  - `inventory_items` - Catálogo de productos
    - SKU, nombre, unidad de medida, stock mínimo
  
  ### 3. Movimientos de Inventario
  - `inventory_movements` - Entradas y salidas
    - Tipo: entrada, salida, ajuste, traspaso
    - Trazabilidad completa
  
  ### 4. Lotes de Inventario
  - `inventory_batches` - Control de lotes
    - Fecha de caducidad, proveedor, número de lote
  
  ## Seguridad
  - RLS habilitado
  - Control por usuario autenticado
*/

-- Tabla de categorías de inventario
CREATE TABLE IF NOT EXISTS inventory_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_code VARCHAR(20) UNIQUE NOT NULL,
  category_name VARCHAR(100) NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES inventory_categories(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE inventory_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all inventory categories"
  ON inventory_categories FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can manage inventory categories"
  ON inventory_categories FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Insertar categorías básicas
INSERT INTO inventory_categories (category_code, category_name, description) VALUES
('FEED', 'Alimento', 'Alimento balanceado para aves'),
('MED', 'Medicamentos', 'Medicamentos y vacunas'),
('SUPPLIES', 'Insumos', 'Materiales y suministros'),
('PACKAGING', 'Empaques', 'Cajas, cartones y empaques'),
('FINISHED', 'Producto Terminado', 'Huevo y pollo procesado')
ON CONFLICT (category_code) DO NOTHING;

-- Tabla de items de inventario
CREATE TABLE IF NOT EXISTS inventory_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku VARCHAR(50) UNIQUE NOT NULL,
  item_name VARCHAR(200) NOT NULL,
  description TEXT,
  category_id UUID REFERENCES inventory_categories(id),
  unit_of_measure VARCHAR(20) NOT NULL,
  min_stock DECIMAL(10,2) DEFAULT 0,
  max_stock DECIMAL(10,2),
  current_stock DECIMAL(10,2) DEFAULT 0,
  unit_cost DECIMAL(10,2) DEFAULT 0,
  barcode VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  requires_batch BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inventory_items_sku ON inventory_items(sku);
CREATE INDEX idx_inventory_items_category ON inventory_items(category_id);
CREATE INDEX idx_inventory_items_active ON inventory_items(is_active);

ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all inventory items"
  ON inventory_items FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can manage inventory items"
  ON inventory_items FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Tabla de lotes de inventario
CREATE TABLE IF NOT EXISTS inventory_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  batch_number VARCHAR(100) NOT NULL,
  entry_date DATE NOT NULL,
  expiry_date DATE,
  quantity DECIMAL(10,2) NOT NULL DEFAULT 0,
  unit_cost DECIMAL(10,2),
  supplier_id UUID,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'depleted')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(item_id, batch_number)
);

CREATE INDEX idx_inventory_batches_item ON inventory_batches(item_id);
CREATE INDEX idx_inventory_batches_expiry ON inventory_batches(expiry_date);
CREATE INDEX idx_inventory_batches_status ON inventory_batches(status);

ALTER TABLE inventory_batches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all inventory batches"
  ON inventory_batches FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can manage inventory batches"
  ON inventory_batches FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Tabla de movimientos de inventario
CREATE TABLE IF NOT EXISTS inventory_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  movement_type VARCHAR(20) NOT NULL CHECK (movement_type IN ('in', 'out', 'adjustment', 'transfer')),
  movement_date DATE NOT NULL,
  item_id UUID NOT NULL REFERENCES inventory_items(id),
  batch_id UUID REFERENCES inventory_batches(id),
  quantity DECIMAL(10,2) NOT NULL,
  unit_cost DECIMAL(10,2),
  total_cost DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
  reference_type VARCHAR(50),
  reference_id UUID,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inventory_movements_item ON inventory_movements(item_id);
CREATE INDEX idx_inventory_movements_date ON inventory_movements(movement_date);
CREATE INDEX idx_inventory_movements_type ON inventory_movements(movement_type);
CREATE INDEX idx_inventory_movements_batch ON inventory_movements(batch_id);

ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all inventory movements"
  ON inventory_movements FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create inventory movements"
  ON inventory_movements FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update inventory movements"
  ON inventory_movements FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Tabla de alertas de inventario
CREATE TABLE IF NOT EXISTS inventory_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type VARCHAR(20) NOT NULL CHECK (alert_type IN ('low_stock', 'expiring', 'expired', 'overstock')),
  item_id UUID REFERENCES inventory_items(id) ON DELETE CASCADE,
  batch_id UUID REFERENCES inventory_batches(id) ON DELETE CASCADE,
  alert_date DATE NOT NULL DEFAULT CURRENT_DATE,
  current_value DECIMAL(10,2),
  threshold_value DECIMAL(10,2),
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inventory_alerts_type ON inventory_alerts(alert_type);
CREATE INDEX idx_inventory_alerts_resolved ON inventory_alerts(is_resolved);
CREATE INDEX idx_inventory_alerts_item ON inventory_alerts(item_id);

ALTER TABLE inventory_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all inventory alerts"
  ON inventory_alerts FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can manage inventory alerts"
  ON inventory_alerts FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Triggers para updated_at
CREATE TRIGGER update_inventory_categories_updated_at BEFORE UPDATE ON inventory_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_items_updated_at BEFORE UPDATE ON inventory_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_batches_updated_at BEFORE UPDATE ON inventory_batches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_movements_updated_at BEFORE UPDATE ON inventory_movements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para actualizar stock de items cuando hay movimiento
CREATE OR REPLACE FUNCTION update_inventory_stock_on_movement()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.movement_type = 'in' THEN
    UPDATE inventory_items
    SET current_stock = current_stock + NEW.quantity
    WHERE id = NEW.item_id;
  ELSIF NEW.movement_type = 'out' THEN
    UPDATE inventory_items
    SET current_stock = current_stock - NEW.quantity
    WHERE id = NEW.item_id;
  ELSIF NEW.movement_type = 'adjustment' THEN
    UPDATE inventory_items
    SET current_stock = NEW.quantity
    WHERE id = NEW.item_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_inventory_stock
  AFTER INSERT ON inventory_movements
  FOR EACH ROW
  EXECUTE FUNCTION update_inventory_stock_on_movement();

-- Función para crear alertas de stock bajo
CREATE OR REPLACE FUNCTION check_low_stock_alerts()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.current_stock <= NEW.min_stock AND NEW.current_stock > 0 THEN
    INSERT INTO inventory_alerts (alert_type, item_id, current_value, threshold_value)
    VALUES ('low_stock', NEW.id, NEW.current_stock, NEW.min_stock)
    ON CONFLICT DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_low_stock
  AFTER UPDATE OF current_stock ON inventory_items
  FOR EACH ROW
  EXECUTE FUNCTION check_low_stock_alerts();