# ERP Avícola Metepec

Sistema ERP completo para la gestión de producción avícola de libre pastoreo en Metepec, Estado de México.

## Características Implementadas (Fase 1)

### Infraestructura Base
- ✅ Sistema de autenticación con Supabase Auth
- ✅ Sistema modular activable/desactivable desde base de datos
- ✅ Layout responsivo con sidebar dinámico
- ✅ Progressive Web App (PWA) instalable
- ✅ Gestión de estado con Zustand
- ✅ Data fetching con React Query
- ✅ Validación de formularios con Zod + React Hook Form

### Módulos Funcionales

#### 1. Dashboard
- KPIs en tiempo real (parvadas activas, alertas de stock, producción promedio, porcentaje de postura)
- Cards informativos con iconos y colores diferenciados
- Preparado para gráficas de producción y KPIs financieros

#### 2. Producción Avícola
- Gestión de parvadas (postura/engorda)
- Registro de datos: número, tipo, raza, fechas, cantidades
- Vista de tarjetas con información detallada
- Estados: activa, completada, cerrada
- CRUD completo de parvadas
- Cálculo automático de mortalidad (pendiente UI)

#### 3. Inventario
- Catálogo de items con categorías
- Control de stock actual vs stock mínimo
- Alertas de stock bajo
- Sistema de SKU y códigos de barras
- Vista de tabla con búsqueda
- Indicadores visuales de estado de stock

#### 4. Contabilidad
- Catálogo de cuentas conforme al Anexo 24 SAT
- Códigos SAT (800+ cuentas básicas insertadas)
- Clasificación por tipo de cuenta
- Balance normal (deudora/acreedora)
- Saldos actuales
- Preparado para pólizas y libro mayor

### Base de Datos (Supabase)

#### Tablas Implementadas
1. **Sistema Core**
   - `system_modules` - Control de módulos
   - `user_profiles` - Perfiles de usuario (admin/manager/operator)
   - `system_config` - Configuraciones globales

2. **Producción**
   - `flocks` - Parvadas/lotes
   - `daily_production` - Producción diaria de huevo
   - `mortality_records` - Registro de mortalidad
   - `feed_consumption` - Consumo de alimento
   - `weight_samples` - Muestras de peso

3. **Inventario**
   - `inventory_categories` - Categorías de inventario
   - `inventory_items` - Catálogo de productos
   - `inventory_batches` - Control de lotes
   - `inventory_movements` - Movimientos de inventario
   - `inventory_alerts` - Alertas automáticas

4. **Contabilidad**
   - `sat_account_codes` - Códigos SAT Anexo 24
   - `chart_of_accounts` - Catálogo de cuentas
   - `accounting_periods` - Períodos contables
   - `journal_entries` - Libro diario (pólizas)
   - `journal_entry_lines` - Líneas de póliza
   - Vistas: `general_ledger`, `trial_balance`

### Seguridad
- Row Level Security (RLS) habilitado en todas las tablas
- Políticas restrictivas por rol de usuario
- Validación de partida doble en contabilidad
- Triggers automáticos para mantener integridad

## Stack Tecnológico

### Frontend
- **React 18** + **TypeScript** + **Vite**
- **Tailwind CSS** - Estilos
- **Lucide React** - Iconos
- **Zustand** - Estado global
- **React Query** - Data fetching
- **React Hook Form** + **Zod** - Formularios y validación
- **date-fns** - Manejo de fechas

### Backend
- **Supabase** - Base de datos PostgreSQL
- **Supabase Auth** - Autenticación

### PWA
- Manifest configurado
- Meta tags para instalación móvil
- Theme color verde (#16a34a)

## Instalación y Desarrollo

### Prerrequisitos
- Node.js 18+
- npm o yarn
- Cuenta de Supabase

### Variables de Entorno
El archivo `.env` ya está configurado con:
```env
VITE_SUPABASE_URL=https://tbvausgzvjnwersmgxpb.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Comandos

```bash
# Instalar dependencias
npm install

# Desarrollo
npm run dev

# Build para producción
npm run build

# Preview del build
npm run preview
```

### Primer Usuario
Al registrarte por primera vez en el sistema, se creará un usuario con rol `operator`. Para convertirlo en `admin`, ejecuta en Supabase SQL Editor:

```sql
UPDATE user_profiles
SET role = 'admin'
WHERE id = 'TU_USER_ID';
```

## Plan de Desarrollo por Fases

### FASE 2: Módulos Operacionales Completos (Semanas 1-4)

#### Producción Avícola
- [ ] Registro de producción diaria de huevo
- [ ] Registro de consumo de alimento
- [ ] Registro de mortalidad
- [ ] Muestras de peso (pollos de engorda)
- [ ] Dashboard de producción con gráficas
- [ ] Cálculo automático de conversión alimenticia
- [ ] Comparativo vs estándares Ross 308

#### Inventario
- [ ] Formularios de alta/edición de items
- [ ] Registro de movimientos (entrada/salida/ajuste)
- [ ] Control de lotes con fecha de caducidad
- [ ] Sistema de alertas automatizado
- [ ] Generación de códigos QR/códigos de barras
- [ ] Reportes de rotación de inventario
- [ ] Exportación a Excel

#### Proveedores y Clientes
- [ ] CRUD completo de proveedores
- [ ] CRUD completo de clientes
- [ ] Gestión de contactos
- [ ] Rating/evaluación de proveedores
- [ ] Límites de crédito para clientes
- [ ] Historial de operaciones

### FASE 3: Operaciones Comerciales (Semanas 5-8)

#### Compras
- [ ] Órdenes de compra
- [ ] Recepción de mercancía
- [ ] Registro de facturas de proveedores
- [ ] Cuentas por pagar
- [ ] Programación de pagos
- [ ] Dashboard de compras

#### Ventas
- [ ] Cotizaciones
- [ ] Pedidos/órdenes de venta
- [ ] Registro de facturas emitidas
- [ ] Notas de crédito
- [ ] Remisiones
- [ ] Cuentas por cobrar
- [ ] Dashboard de ventas

#### Tesorería
- [ ] Catálogo de cuentas bancarias
- [ ] Importación de estados de cuenta CSV
- [ ] Conciliación bancaria automática
- [ ] Flujo de efectivo proyectado vs real
- [ ] Control de préstamos
- [ ] Alertas de vencimientos

### FASE 4: Contabilidad Avanzada (Semanas 9-12)

#### Contabilidad Core
- [ ] Pólizas de diario/ingresos/egresos
- [ ] Interfaz de Cuentas T
- [ ] Libro mayor completo
- [ ] Balanza de comprobación
- [ ] Estados financieros (Balance, Estado de Resultados)
- [ ] Contabilidad de costos (NIF E-1)
- [ ] Depreciación de activos biológicos

#### Contabilidad Electrónica SAT
- [ ] Catálogo de cuentas completo (800+ cuentas)
- [ ] Generación de XML (Anexo 24)
- [ ] Balanza de comprobación mensual XML
- [ ] Pólizas con UUID de CFDI
- [ ] Validaciones SAT

#### Ledger Inmutable
- [ ] Registro de todas las operaciones
- [ ] Hash SHA-256 encadenado
- [ ] Sistema append-only
- [ ] Exportación para auditorías

### FASE 5: Fiscalidad y Reportes (Semanas 13-16)

#### Emulador Fiscal
- [ ] Separación facturado/no facturado
- [ ] Proyección ISR mensual/anual
- [ ] Proyección IVA
- [ ] Simulador fiscal
- [ ] Alertas de límites

#### Reportes
- [ ] Generador de reportes personalizado
- [ ] Exportación a Excel/PDF
- [ ] Plantillas de reportes
- [ ] Reportes programados
- [ ] Dashboard de reportes

#### KPIs
- [ ] ROI, ROA, ROE
- [ ] Razones financieras
- [ ] DSO, DPO, rotación
- [ ] KPIs avícolas (FCR, mortalidad, postura)
- [ ] Dashboard ejecutivo

### FASE 6: Inteligencia Artificial (Semanas 17-20)

#### RAG y Clasificación
- [ ] Integración con Ollama local
- [ ] Embedding de 14 documentos contables/avícolas
- [ ] Clasificación automática de transacciones
- [ ] Generación de pólizas desde lenguaje natural
- [ ] Mapeo automático a cuentas SAT
- [ ] Sistema de aprendizaje de correcciones

#### Vector Store
- [ ] Configuración de pgvector
- [ ] Indexación de documentos
- [ ] Búsqueda semántica
- [ ] Actualización incremental

### FASE 7: Optimizaciones y Features Avanzados (Semanas 21-24)

#### Offline First
- [ ] Integración de PowerSync
- [ ] SQLite local en cliente
- [ ] Sincronización automática
- [ ] Resolución de conflictos
- [ ] Queue de operaciones offline

#### Legal/Documentos
- [ ] Repositorio de contratos
- [ ] Clasificación por tipo
- [ ] Alertas de vencimiento
- [ ] Versionamiento de documentos

#### Optimizaciones
- [ ] Code splitting
- [ ] Lazy loading de módulos
- [ ] Optimización de bundle
- [ ] Service Worker avanzado
- [ ] Cache strategies
- [ ] Background sync

## Estructura del Proyecto

```
src/
├── components/
│   ├── layout/
│   │   └── Sidebar.tsx
│   └── ui/ (shadcn/ui - pendiente)
├── modules/
│   ├── auth/
│   │   └── Login.tsx
│   ├── dashboard/
│   │   └── Dashboard.tsx
│   ├── production/
│   │   ├── FlockList.tsx
│   │   └── FlockForm.tsx
│   ├── inventory/
│   │   └── InventoryList.tsx
│   ├── accounting/
│   │   └── ChartOfAccounts.tsx
│   └── [otros módulos...]
├── stores/
│   ├── authStore.ts
│   └── moduleStore.ts
├── lib/
│   └── supabase.ts
├── types/
│   └── database.ts
└── App.tsx
```

## Arquitectura Modular

El sistema usa una tabla `system_modules` en Supabase que controla qué módulos están habilitados. El sidebar se genera dinámicamente mostrando solo los módulos activos.

Para activar/desactivar módulos:
```sql
UPDATE system_modules
SET is_enabled = true
WHERE module_key = 'ai_classification';
```

Los módulos pueden tener dependencias:
```sql
-- El módulo de compras requiere suppliers e inventory
requires_modules = '{suppliers, inventory}'
```

## Próximos Pasos Inmediatos

1. **Implementar Producción Diaria**
   - Crear formulario de captura diaria
   - Gráficas de producción con Recharts
   - Exportación a Excel

2. **Completar Inventario**
   - Formularios de alta/edición
   - Registro de movimientos
   - Alertas automáticas

3. **Módulo de Proveedores**
   - CRUD completo
   - Gestión de contactos

4. **Módulo de Clientes**
   - CRUD completo
   - Control de crédito

## Notas Técnicas

### Contabilidad de Activos Biológicos (NIF E-1)
- Aves de engorda = inventario en proceso
- Aves de postura = activos fijos depreciables
- Huevo = producto agropecuario
- Fórmula de costo: C_L(t) = C_pollito + ∫(Alimento + Sanidad + MOD + GastosInd)

### Anexo 24 SAT
- Catálogo de cuentas con código agrupador
- Balanza de comprobación mensual XML
- Pólizas con UUID de CFDI vinculado

### Estándares Ross 308
- FCR objetivo: 1.85
- Mortalidad objetivo: < 5%
- Curvas de crecimiento por semana

## Contribución

Este proyecto está listo para ser clonado y continuado en GitHub. La fase 1 proporciona una base sólida con autenticación, módulos base y arquitectura escalable.

## Licencia

Proyecto privado - Avícola Metepec

## Contacto

Para soporte o consultas sobre el desarrollo del sistema.

---

**Última actualización:** Enero 2026
**Versión:** 1.0.0 (Fase 1 Completa)
