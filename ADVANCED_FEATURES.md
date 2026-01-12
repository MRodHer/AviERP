# Funcionalidades Avanzadas - ERP Avícola

Guía para implementar las funcionalidades más complejas del sistema.

## Integración con Ollama (IA Local)

### 1. Configurar Ollama en VPS

```bash
# Instalar Ollama en Ubuntu 24.04
curl -fsSL https://ollama.com/install.sh | sh

# Descargar modelos
ollama pull mistral:7b
ollama pull llama3.1:8b
ollama pull nomic-embed-text

# Verificar instalación
ollama list
```

### 2. Habilitar pgvector en Supabase

```sql
-- Crear extensión pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Tabla para embeddings
CREATE TABLE IF NOT EXISTS document_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_name VARCHAR(255) NOT NULL,
  document_type VARCHAR(50),
  chunk_text TEXT NOT NULL,
  chunk_index INTEGER NOT NULL,
  embedding vector(768),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_embeddings_vector ON document_embeddings
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

ALTER TABLE document_embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all embeddings"
  ON document_embeddings FOR SELECT
  TO authenticated
  USING (true);
```

### 3. Edge Function para Embeddings

```typescript
// supabase/functions/generate-embeddings/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const OLLAMA_URL = "http://tu-vps:11434";

serve(async (req) => {
  const { text, model = "nomic-embed-text" } = await req.json();

  const response = await fetch(`${OLLAMA_URL}/api/embeddings`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ model, prompt: text }),
  });

  const { embedding } = await response.json();

  return new Response(JSON.stringify({ embedding }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

### 4. Edge Function para RAG

```typescript
// supabase/functions/rag-query/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OLLAMA_URL = "http://tu-vps:11434";

serve(async (req) => {
  const { query } = await req.json();

  // 1. Generar embedding de la query
  const embeddingRes = await fetch(`${OLLAMA_URL}/api/embeddings`, {
    method: "POST",
    body: JSON.stringify({ model: "nomic-embed-text", prompt: query }),
  });
  const { embedding } = await embeddingRes.json();

  // 2. Buscar documentos relevantes
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { data: chunks } = await supabase.rpc("match_documents", {
    query_embedding: embedding,
    match_threshold: 0.7,
    match_count: 5,
  });

  // 3. Construir contexto
  const context = chunks.map((c: any) => c.chunk_text).join("\n\n");

  // 4. Generar respuesta con LLM
  const promptText = `Contexto:\n${context}\n\nPregunta: ${query}\n\nRespuesta:`;

  const llmRes = await fetch(`${OLLAMA_URL}/api/generate`, {
    method: "POST",
    body: JSON.stringify({
      model: "mistral:7b",
      prompt: promptText,
      stream: false,
    }),
  });

  const { response } = await llmRes.json();

  return new Response(JSON.stringify({ response, chunks }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

### 5. Función de Búsqueda Semántica

```sql
-- Función para buscar documentos similares
CREATE OR REPLACE FUNCTION match_documents(
  query_embedding vector(768),
  match_threshold float DEFAULT 0.7,
  match_count int DEFAULT 5
)
RETURNS TABLE (
  id uuid,
  document_name varchar,
  chunk_text text,
  similarity float
)
LANGUAGE sql STABLE
AS $$
  SELECT
    id,
    document_name,
    chunk_text,
    1 - (embedding <=> query_embedding) AS similarity
  FROM document_embeddings
  WHERE 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
$$;
```

### 6. Cliente React para IA

```typescript
// src/lib/ollama.ts
export async function generateEmbedding(text: string) {
  const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/generate-embeddings`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ text }),
  });

  return response.json();
}

export async function queryRAG(query: string) {
  const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/rag-query`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query }),
  });

  return response.json();
}
```

### 7. Componente de Chat con IA

```typescript
import { useState } from 'react';
import { queryRAG } from '../../lib/ollama';

export function AIAssistant() {
  const [query, setQuery] = useState('');
  const [response, setResponse] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const result = await queryRAG(query);
      setResponse(result.response);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Asistente IA</h1>

      <form onSubmit={handleSubmit} className="mb-6">
        <textarea
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="w-full px-4 py-2 border rounded-lg mb-4"
          rows={4}
          placeholder="Pregunta sobre contabilidad, producción avícola, etc."
        />
        <button
          type="submit"
          disabled={loading}
          className="bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700"
        >
          {loading ? 'Procesando...' : 'Preguntar'}
        </button>
      </form>

      {response && (
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h3 className="font-bold mb-3">Respuesta:</h3>
          <p className="text-gray-700 whitespace-pre-wrap">{response}</p>
        </div>
      )}
    </div>
  );
}
```

## PowerSync (Offline-First)

### 1. Instalación

```bash
npm install @powersync/web @powersync/react
```

### 2. Configuración

```typescript
// src/lib/powersync.ts
import { PowerSyncDatabase } from '@powersync/web';
import { AppSchema } from './schema';

export const db = new PowerSyncDatabase({
  schema: AppSchema,
  database: {
    dbFilename: 'erp-avicola.db',
  },
});

// Conectar con Supabase
await db.connect({
  endpoint: import.meta.env.VITE_POWERSYNC_URL,
  token: async () => {
    const session = await supabase.auth.getSession();
    return session.data.session?.access_token ?? '';
  },
});
```

### 3. Schema de PowerSync

```typescript
// src/lib/schema.ts
import { Column, Schema, Table } from '@powersync/web';

export const AppSchema = new Schema([
  new Table({
    name: 'flocks',
    columns: [
      new Column({ name: 'flock_number', type: 'TEXT' }),
      new Column({ name: 'flock_type', type: 'TEXT' }),
      new Column({ name: 'current_quantity', type: 'INTEGER' }),
      new Column({ name: 'status', type: 'TEXT' }),
    ],
  }),
  new Table({
    name: 'daily_production',
    columns: [
      new Column({ name: 'flock_id', type: 'TEXT' }),
      new Column({ name: 'production_date', type: 'TEXT' }),
      new Column({ name: 'total_eggs', type: 'INTEGER' }),
      new Column({ name: 'laying_percentage', type: 'REAL' }),
    ],
  }),
  // Agregar más tablas según necesidad
]);
```

### 4. Hooks con PowerSync

```typescript
import { useQuery as usePowerSyncQuery } from '@powersync/react';
import { db } from '../lib/powersync';

export function useFlocks() {
  return usePowerSyncQuery(
    'SELECT * FROM flocks WHERE status = ? ORDER BY entry_date DESC',
    ['active']
  );
}
```

### 5. Sincronización Bidireccional

```typescript
// Operaciones offline se guardan en queue local
await db.execute(
  'INSERT INTO flocks (flock_number, flock_type, initial_quantity) VALUES (?, ?, ?)',
  [number, type, quantity]
);

// PowerSync automáticamente sincroniza cuando hay conexión
```

## Contabilidad Electrónica SAT

### 1. Generación de XML (Balanza de Comprobación)

```typescript
// src/lib/sat-xml.ts
import { create } from 'xmlbuilder2';

interface BalanceAccount {
  code: string;
  name: string;
  initialBalance: number;
  debit: number;
  credit: number;
  finalBalance: number;
}

export function generateBalanceXML(
  rfc: string,
  year: number,
  month: number,
  accounts: BalanceAccount[]
) {
  const root = create({ version: '1.0', encoding: 'UTF-8' })
    .ele('BCE:Balanza', {
      'xmlns:BCE': 'http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/BalanzaComprobacion',
      'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation': 'http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/BalanzaComprobacion http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/BalanzaComprobacion/BalanzaComprobacion_1_3.xsd',
      'Version': '1.3',
      'RFC': rfc,
      'Mes': month.toString().padStart(2, '0'),
      'Anio': year.toString(),
      'TipoEnvio': 'N',
    });

  const ctas = root.ele('BCE:Ctas');

  accounts.forEach(account => {
    ctas.ele('BCE:Cta', {
      NumCta: account.code,
      Desc: account.name,
      SaldoIni: account.initialBalance.toFixed(2),
      Debe: account.debit.toFixed(2),
      Haber: account.credit.toFixed(2),
      SaldoFin: account.finalBalance.toFixed(2),
    });
  });

  return root.end({ prettyPrint: true });
}
```

### 2. Generación de Pólizas XML

```typescript
export function generateJournalEntriesXML(
  rfc: string,
  year: number,
  month: number,
  entries: JournalEntry[]
) {
  const root = create({ version: '1.0', encoding: 'UTF-8' })
    .ele('PLZ:Polizas', {
      'xmlns:PLZ': 'http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/PolizasPeriodo',
      'Version': '1.3',
      'RFC': rfc,
      'Mes': month.toString().padStart(2, '0'),
      'Anio': year.toString(),
    });

  entries.forEach(entry => {
    const poliza = root.ele('PLZ:Poliza', {
      NumUnIdenPol: entry.number,
      Fecha: entry.date,
      Concepto: entry.description,
    });

    entry.lines.forEach(line => {
      if (line.debit > 0) {
        poliza.ele('PLZ:Transaccion', {
          NumCta: line.accountCode,
          DesCta: line.accountName,
          Concepto: line.description,
          Debe: line.debit.toFixed(2),
        });
      } else {
        poliza.ele('PLZ:Transaccion', {
          NumCta: line.accountCode,
          DesCta: line.accountName,
          Concepto: line.description,
          Haber: line.credit.toFixed(2),
        });
      }
    });
  });

  return root.end({ prettyPrint: true });
}
```

### 3. Validación contra XSD del SAT

```typescript
// Nota: La validación XSD se hace típicamente en el backend
// con librerías especializadas. En Node.js:

import { XMLValidator } from 'fast-xml-parser';

export function validateSATXML(xmlContent: string): boolean {
  const result = XMLValidator.validate(xmlContent);
  return result === true;
}
```

## Ledger Inmutable (Blockchain-like)

### 1. Tabla con Hash Encadenado

```sql
CREATE TABLE IF NOT EXISTS immutable_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sequence_number BIGSERIAL NOT NULL,
  operation_type VARCHAR(50) NOT NULL,
  operation_table VARCHAR(100) NOT NULL,
  operation_id UUID NOT NULL,
  operation_data JSONB NOT NULL,
  previous_hash VARCHAR(64),
  current_hash VARCHAR(64),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ledger_sequence ON immutable_ledger(sequence_number);
CREATE INDEX idx_ledger_operation ON immutable_ledger(operation_table, operation_id);

ALTER TABLE immutable_ledger ENABLE ROW LEVEL SECURITY;

-- Solo lectura, no se puede editar ni borrar
CREATE POLICY "Users can only view ledger"
  ON immutable_ledger FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert to ledger"
  ON immutable_ledger FOR INSERT
  TO authenticated
  WITH CHECK (true);
```

### 2. Función de Hash Encadenado

```sql
CREATE OR REPLACE FUNCTION calculate_ledger_hash(
  prev_hash TEXT,
  seq_num BIGINT,
  op_type TEXT,
  op_table TEXT,
  op_id UUID,
  op_data JSONB
)
RETURNS TEXT AS $$
DECLARE
  hash_input TEXT;
BEGIN
  hash_input := COALESCE(prev_hash, '') ||
                seq_num::TEXT ||
                op_type ||
                op_table ||
                op_id::TEXT ||
                op_data::TEXT;

  RETURN encode(digest(hash_input, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### 3. Trigger para Registro Automático

```sql
CREATE OR REPLACE FUNCTION log_to_immutable_ledger()
RETURNS TRIGGER AS $$
DECLARE
  last_hash TEXT;
  last_seq BIGINT;
  new_hash TEXT;
BEGIN
  -- Obtener último hash y secuencia
  SELECT current_hash, sequence_number
  INTO last_hash, last_seq
  FROM immutable_ledger
  ORDER BY sequence_number DESC
  LIMIT 1;

  -- Calcular nuevo hash
  new_hash := calculate_ledger_hash(
    last_hash,
    COALESCE(last_seq, 0) + 1,
    TG_OP,
    TG_TABLE_NAME,
    NEW.id,
    row_to_json(NEW)::JSONB
  );

  -- Insertar en ledger
  INSERT INTO immutable_ledger (
    sequence_number,
    operation_type,
    operation_table,
    operation_id,
    operation_data,
    previous_hash,
    current_hash,
    created_by
  ) VALUES (
    COALESCE(last_seq, 0) + 1,
    TG_OP,
    TG_TABLE_NAME,
    NEW.id,
    row_to_json(NEW)::JSONB,
    last_hash,
    new_hash,
    auth.uid()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a tablas críticas
CREATE TRIGGER ledger_journal_entries
  AFTER INSERT OR UPDATE ON journal_entries
  FOR EACH ROW
  EXECUTE FUNCTION log_to_immutable_ledger();
```

### 4. Verificación de Integridad

```sql
CREATE OR REPLACE FUNCTION verify_ledger_integrity()
RETURNS TABLE (
  sequence_number BIGINT,
  is_valid BOOLEAN,
  expected_hash TEXT,
  actual_hash TEXT
) AS $$
DECLARE
  rec RECORD;
  calc_hash TEXT;
  prev_hash TEXT := NULL;
BEGIN
  FOR rec IN
    SELECT *
    FROM immutable_ledger
    ORDER BY sequence_number
  LOOP
    calc_hash := calculate_ledger_hash(
      prev_hash,
      rec.sequence_number,
      rec.operation_type,
      rec.operation_table,
      rec.operation_id,
      rec.operation_data
    );

    sequence_number := rec.sequence_number;
    expected_hash := rec.current_hash;
    actual_hash := calc_hash;
    is_valid := (calc_hash = rec.current_hash);

    RETURN NEXT;

    prev_hash := rec.current_hash;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

## Importación de Estados de Cuenta

### 1. Parser de CSV Bancario

```typescript
// src/lib/bank-parser.ts
import Papa from 'papaparse';

interface BankTransaction {
  date: string;
  description: string;
  reference: string;
  debit: number;
  credit: number;
  balance: number;
}

export function parseBBVA(file: File): Promise<BankTransaction[]> {
  return new Promise((resolve, reject) => {
    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: (results) => {
        const transactions = results.data.map((row: any) => ({
          date: row['Fecha'],
          description: row['Descripción'],
          reference: row['Referencia'],
          debit: parseFloat(row['Cargo'] || '0'),
          credit: parseFloat(row['Abono'] || '0'),
          balance: parseFloat(row['Saldo'] || '0'),
        }));
        resolve(transactions);
      },
      error: reject,
    });
  });
}

// Parsers para otros bancos: Banorte, Santander, Banamex
```

### 2. Componente de Importación

```typescript
import { useState } from 'react';
import { parseBBVA } from '../../lib/bank-parser';

export function BankImporter() {
  const [transactions, setTransactions] = useState([]);

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const parsed = await parseBBVA(file);
    setTransactions(parsed);
  };

  const handleImport = async () => {
    // Guardar en Supabase
    const { error } = await supabase
      .from('bank_transactions')
      .insert(transactions);

    if (error) {
      alert('Error al importar');
    } else {
      alert('Importación exitosa');
    }
  };

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Importar Estado de Cuenta</h1>

      <input
        type="file"
        accept=".csv"
        onChange={handleFileUpload}
        className="mb-4"
      />

      {transactions.length > 0 && (
        <div>
          <p className="mb-4">{transactions.length} transacciones encontradas</p>
          <button
            onClick={handleImport}
            className="bg-green-600 text-white px-6 py-3 rounded-lg"
          >
            Importar
          </button>
        </div>
      )}
    </div>
  );
}
```

## Conciliación Bancaria Automática

```sql
-- Función para sugerir conciliaciones
CREATE OR REPLACE FUNCTION suggest_bank_reconciliation(
  bank_account_id UUID,
  start_date DATE,
  end_date DATE
)
RETURNS TABLE (
  bank_transaction_id UUID,
  journal_entry_id UUID,
  match_score DECIMAL,
  amount_match BOOLEAN,
  date_match BOOLEAN,
  description_similarity DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    bt.id AS bank_transaction_id,
    je.id AS journal_entry_id,
    -- Score de similitud (0-100)
    (
      CASE WHEN ABS(bt.amount - je.total_debit) < 0.01 THEN 40 ELSE 0 END +
      CASE WHEN bt.transaction_date = je.entry_date THEN 30 ELSE 0 END +
      (similarity(bt.description, je.description) * 30)
    ) AS match_score,
    ABS(bt.amount - je.total_debit) < 0.01 AS amount_match,
    bt.transaction_date = je.entry_date AS date_match,
    similarity(bt.description, je.description) AS description_similarity
  FROM bank_transactions bt
  CROSS JOIN journal_entries je
  WHERE
    bt.bank_account_id = suggest_bank_reconciliation.bank_account_id
    AND bt.transaction_date BETWEEN start_date AND end_date
    AND bt.reconciled = false
    AND je.status = 'posted'
    AND ABS(bt.amount - je.total_debit) < 100 -- Tolerancia
  ORDER BY match_score DESC;
END;
$$ LANGUAGE plpgsql;
```

---

Estas funcionalidades avanzadas requieren configuración adicional en tu VPS y conocimientos específicos de cada tecnología. Implementarlas gradualmente conforme el sistema base esté estable.
