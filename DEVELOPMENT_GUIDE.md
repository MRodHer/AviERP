# Guía de Desarrollo - ERP Avícola

Esta guía te ayudará a continuar el desarrollo del sistema ERP avícola desde la Fase 2 en adelante.

## Convenciones del Proyecto

### Nomenclatura

#### Archivos
- Componentes React: `PascalCase.tsx` (ej: `FlockList.tsx`)
- Stores: `camelCaseStore.ts` (ej: `authStore.ts`)
- Utilidades: `camelCase.ts` (ej: `formatDate.ts`)
- Tipos: `database.ts`, `models.ts`

#### Base de Datos
- Tablas: `snake_case` (ej: `daily_production`)
- Columnas: `snake_case` (ej: `flock_number`)
- Triggers: `trigger_nombre` (ej: `trigger_update_flock_quantity`)
- Funciones: `verbo_sustantivo()` (ej: `update_inventory_stock_on_movement()`)

#### Código
- Variables/funciones: `camelCase`
- Constantes: `UPPER_SNAKE_CASE`
- Interfaces/Types: `PascalCase`
- Enums: `PascalCase`

### Estructura de Componentes

Cada módulo debe seguir esta estructura:

```
src/modules/nombre-modulo/
├── index.ts              # Exportaciones
├── ListaView.tsx         # Vista de listado
├── FormView.tsx          # Formulario crear/editar
├── DetailView.tsx        # Vista de detalle (opcional)
├── components/           # Componentes específicos
│   ├── Card.tsx
│   └── Table.tsx
├── hooks/               # Hooks personalizados
│   └── useNombreModulo.ts
└── types.ts             # Tipos específicos del módulo
```

### Patrón de Formularios

Todos los formularios deben usar:
1. React Hook Form para el manejo del formulario
2. Zod para validación
3. React Query mutation para envío
4. Feedback visual con estados de carga/error

Ejemplo:

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';

const schema = z.object({
  campo: z.string().min(1, 'Requerido'),
});

type FormData = z.infer<typeof schema>;

export function MiFormulario() {
  const queryClient = useQueryClient();

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      const { error } = await supabase.from('tabla').insert(data);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clave'] });
    },
  });

  return (
    <form onSubmit={handleSubmit((data) => mutation.mutate(data))}>
      {/* campos */}
    </form>
  );
}
```

## Migraciones de Base de Datos

### Crear Nueva Migración

Usa el tool `mcp__supabase__apply_migration`:

```typescript
{
  filename: "nombre_descriptivo",
  content: `/*
  # Título de la Migración

  ## Cambios

  1. Nuevas Tablas
    - \`nombre_tabla\` - Descripción
      - \`columna\` (tipo) - Descripción

  2. Seguridad
    - RLS habilitado
    - Políticas creadas
*/

CREATE TABLE IF NOT EXISTS nombre_tabla (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  columna VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE nombre_tabla ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Nombre de política"
  ON nombre_tabla FOR SELECT
  TO authenticated
  USING (true);
`
}
```

### Checklist de Migración

- [ ] Usar `IF NOT EXISTS` / `IF EXISTS`
- [ ] Habilitar RLS en todas las tablas
- [ ] Crear políticas restrictivas
- [ ] Agregar triggers para `updated_at`
- [ ] Validaciones con CHECK constraints
- [ ] Índices en columnas de búsqueda frecuente
- [ ] Valores por defecto apropiados
- [ ] Comentarios descriptivos al inicio

## Queries con React Query

### Patrón Estándar

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';

// Query
const { data, isLoading, error } = useQuery({
  queryKey: ['clave', parametro],
  queryFn: async () => {
    const { data, error } = await supabase
      .from('tabla')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },
});

// Mutation
const mutation = useMutation({
  mutationFn: async (payload) => {
    const { error } = await supabase
      .from('tabla')
      .insert(payload);

    if (error) throw error;
  },
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['clave'] });
  },
});
```

### Claves de Query Recomendadas

```typescript
['flocks'] - Todas las parvadas
['flocks', flockId] - Una parvada específica
['daily-production', flockId] - Producción de una parvada
['inventory-items'] - Items de inventario
['inventory-alerts'] - Alertas activas
['chart-of-accounts'] - Catálogo de cuentas
['journal-entries', period] - Pólizas de un período
```

## Componentes UI Reutilizables

### Botones

```typescript
// Botón primario
<button className="bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 transition-colors font-semibold">
  Acción
</button>

// Botón secundario
<button className="border border-gray-300 px-6 py-3 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors font-semibold">
  Cancelar
</button>

// Botón peligro
<button className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors">
  Eliminar
</button>
```

### Cards

```typescript
<div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
  {/* contenido */}
</div>
```

### Inputs

```typescript
<input
  type="text"
  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-600 focus:border-transparent"
  placeholder="Placeholder"
/>
```

### Badges de Estado

```typescript
// Éxito
<span className="px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
  Activo
</span>

// Advertencia
<span className="px-3 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
  Pendiente
</span>

// Error
<span className="px-3 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
  Inactivo
</span>
```

## Agregar Nuevo Módulo

### 1. Crear Módulo en Base de Datos

```sql
INSERT INTO system_modules (module_key, module_name, description, is_enabled, icon, sort_order)
VALUES ('mi_modulo', 'Mi Módulo', 'Descripción', true, 'IconName', 20);
```

### 2. Crear Estructura de Carpetas

```bash
mkdir -p src/modules/mi-modulo
touch src/modules/mi-modulo/index.ts
touch src/modules/mi-modulo/MiModuloList.tsx
touch src/modules/mi-modulo/MiModuloForm.tsx
```

### 3. Implementar Componente Principal

```typescript
// src/modules/mi-modulo/MiModuloList.tsx
export function MiModuloList() {
  const { data, isLoading } = useQuery({
    queryKey: ['mi-modulo'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('mi_tabla')
        .select('*');
      if (error) throw error;
      return data;
    },
  });

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-900">Mi Módulo</h1>
      {/* contenido */}
    </div>
  );
}
```

### 4. Agregar al Router en App.tsx

```typescript
import { MiModuloList } from './modules/mi-modulo/MiModuloList';

// En renderModule()
case 'mi_modulo':
  return <MiModuloList />;
```

## Exportación a Excel

### Instalar xlsx (ya instalado)

```typescript
import * as XLSX from 'xlsx';

function exportToExcel(data: any[], filename: string) {
  const worksheet = XLSX.utils.json_to_sheet(data);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Datos');
  XLSX.writeFile(workbook, `${filename}.xlsx`);
}
```

## Generación de PDFs

### Usando @react-pdf/renderer

```typescript
import { Document, Page, Text, View, StyleSheet, pdf } from '@react-pdf/renderer';

const styles = StyleSheet.create({
  page: { padding: 30 },
  header: { fontSize: 20, marginBottom: 20 },
});

const MiDocumento = ({ data }: { data: any }) => (
  <Document>
    <Page size="A4" style={styles.page}>
      <Text style={styles.header}>Título</Text>
      <View>
        {/* contenido */}
      </View>
    </Page>
  </Document>
);

// Generar y descargar
const blob = await pdf(<MiDocumento data={data} />).toBlob();
const url = URL.createObjectURL(blob);
const link = document.createElement('a');
link.href = url;
link.download = 'documento.pdf';
link.click();
```

## Gráficas con Recharts

### Ejemplo de Gráfica de Línea

```typescript
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export function ProductionChart({ data }: { data: any[] }) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="date" />
        <YAxis />
        <Tooltip />
        <Legend />
        <Line type="monotone" dataKey="eggs" stroke="#16a34a" strokeWidth={2} />
      </LineChart>
    </ResponsiveContainer>
  );
}
```

## Formateo de Datos

### Fechas

```typescript
import { format, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';

// Formato corto
format(new Date(), 'dd/MM/yyyy'); // "12/01/2026"

// Formato largo
format(new Date(), "d 'de' MMMM 'de' yyyy", { locale: es }); // "12 de enero de 2026"

// Parse de ISO
format(parseISO('2026-01-12'), 'dd/MM/yyyy');
```

### Moneda

```typescript
function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
  }).format(amount);
}

formatCurrency(1500.50); // "$1,500.50"
```

### Números

```typescript
function formatNumber(num: number, decimals: number = 2): string {
  return num.toLocaleString('es-MX', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}

formatNumber(1234.56); // "1,234.56"
```

## Testing (Pendiente)

Para agregar tests en el futuro:

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom
```

## Deployment

### Build para Producción

```bash
npm run build
```

Los archivos compilados estarán en `dist/`.

### Deployment en VPS con Easypanel

1. Conectar repositorio de GitHub
2. Configurar build command: `npm run build`
3. Configurar output directory: `dist`
4. Agregar variables de entorno
5. Deploy

## Troubleshooting Común

### Error: "RLS policy violation"
- Verificar que las políticas RLS permiten la operación
- Revisar el rol del usuario (admin/manager/operator)

### Error: "null value in column violates not-null constraint"
- Verificar valores requeridos en el formulario
- Agregar valores por defecto en la migración

### Query no se actualiza después de mutation
- Verificar que `queryClient.invalidateQueries()` se llame
- Revisar que la clave de query coincida

### Tipos de TypeScript no coinciden
- Regenerar tipos desde Supabase o actualizar `src/types/database.ts`

## Recursos Útiles

- [Supabase Docs](https://supabase.com/docs)
- [React Query Docs](https://tanstack.com/query/latest)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Recharts Docs](https://recharts.org/)
- [date-fns Docs](https://date-fns.org/)
- [Zod Docs](https://zod.dev/)

## Próximas Tareas Prioritarias

1. **Producción Diaria de Huevo**
   - Formulario de captura por parvada
   - Validación de cantidad de aves
   - Gráfica de tendencia semanal/mensual

2. **Movimientos de Inventario**
   - Formulario de entrada/salida
   - Selección de item y cantidad
   - Actualización automática de stock

3. **CRUD de Proveedores**
   - Lista con búsqueda y filtros
   - Formulario con datos fiscales
   - Gestión de contactos

4. **CRUD de Clientes**
   - Lista con búsqueda
   - Control de límite de crédito
   - Historial de compras

---

Esta guía se actualizará conforme avance el desarrollo del proyecto.
